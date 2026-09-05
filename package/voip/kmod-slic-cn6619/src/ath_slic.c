/*
 * ath_slic.c -- ZMTEL ZM-WR2500 (AR9341) SLIC voice driver for OpenWrt 15.05
 *
 * 3.18 port of the original 3.3.8 slic.ko (from ZM-WR2500 stock firmware).
 * Provides /dev/aci0-1 (PCM voice channel) + ioctl control so the stock
 * fvphone userspace runs unmodified.
 *
 * Hardware (reverse engineered from stock slic.ko, see slic-rebuild/):
 *   - SLIC (Si3217x) control registers @0x180a9000 (SPI CS1=GPIO1)
 *   - audio PLL/clock block @0x180b0000
 *   - MBOX DMA @0x180a0000 (SLIC uses MBOX1: desc base +0x28/0x30,
 *     control +0x2c/+0x34, int status +0x48 bit16 RX ready)
 *   - IRQ 15 (MISC), descriptor chain 16B x N
 *   - TX ring 160B (1 G.711 20ms frame), RX ring 640B (4 frames)
 *
 * Interface (must match stock fvphone):
 *   read  = RX ring (<=640B), write = TX ring (<=160B)
 *   ioctl = 0x44E23 + i  (i=0..16)
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/poll.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <linux/sched.h>
#include <linux/spinlock.h>
#include <linux/wait.h>
#include <linux/uaccess.h>
#include <linux/io.h>
#include <linux/dma-mapping.h>
#include <linux/platform_device.h>
#include <linux/spi/spi.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/irq.h>

#define DRV_NAME	"ath_slic"
#define SLIC_SLOTS	2		/* /dev/aci0, /dev/aci1 */

#define ATH_SLIC_PCM_BUF_SIZE	80	/* per-desc DMA chunk (stock) */
#define ATH_SLIC_RING_TX	160	/* TX ring bytes (1 G.711 frame) */
#define ATH_SLIC_RING_RX	640	/* RX ring bytes (4 G.711 frames) */

#define ATH_SLIC_IOCTL_BASE	0x44E23

/* SLIC control block (registers) */
#define MBOX_BASE		0x180a0000
#define SLIC_BASE		0x180a9000
#define SLIC_CONTROL		(SLIC_BASE + 0x00)
#define SLIC_CLOCK_CTRL		(SLIC_BASE + 0x04)
#define SLIC_CTRL2		(SLIC_BASE + 0x08)
#define SLIC_CTRL3		(SLIC_BASE + 0x0c)
#define SLIC_TIMING_CTRL	(SLIC_BASE + 0x1c)

/* audio clock block */
#define AUDIO_BASE		0x180b0000

/* per-channel device data (mirrors stock layout semantics) */
struct ath_slic_dev {
	void __iomem	*base;		/* SLIC ctrl mapping */
	void __iomem	*mbox;		/* MBOX mapping (ath79_dma_base) */
	int		minor;

	/* ring buffers (kmalloc) */
	u8		*rx_ring;	/* size ATH_SLIC_RING_RX */
	u8		*tx_ring;	/* size ATH_SLIC_RING_TX */
	int		rx_head;	/* next read position (mod RX) */
	int		rx_len;		/* bytes pending */
	int		tx_head;	/* next write position (mod TX) */

	wait_queue_head_t rq;		/* read waiters */
	wait_queue_head_t wq;		/* write waiters */
	spinlock_t	lock;

	unsigned long	irq_cnt;
	unsigned long	read_cnt;
	unsigned long	write_cnt;
};

static int ath_slic_major;
static struct cdev ath_slic_cdev;
static struct class *ath_slic_class;
static struct ath_slic_dev slic_devs[SLIC_SLOTS];

/* ------------------------------------------------------------------ */
/* ring helpers */

static void ring_init(struct ath_slic_dev *d)
{
	d->rx_head = 0;
	d->rx_len = 0;
	d->tx_head = 0;
}

static int ring_rx_read(struct ath_slic_dev *d, char __user *buf, size_t count)
{
	unsigned long flags;
	int got = 0;

	spin_lock_irqsave(&d->lock, flags);
	while (got < count && d->rx_len > 0) {
		if (put_user(d->rx_ring[d->rx_head], buf + got)) {
			spin_unlock_irqrestore(&d->lock, flags);
			return got ? got : -EFAULT;
		}
		d->rx_head = (d->rx_head + 1) % ATH_SLIC_RING_RX;
		d->rx_len--;
		got++;
	}
	d->read_cnt++;
	spin_unlock_irqrestore(&d->lock, flags);
	return got;
}

static int ring_tx_write(struct ath_slic_dev *d, const char __user *buf,
			 size_t count)
{
	unsigned long flags;
	int done = 0;

	spin_lock_irqsave(&d->lock, flags);
	while (done < count && done < ATH_SLIC_RING_TX) {
		u8 c;
		if (get_user(c, buf + done)) {
			spin_unlock_irqrestore(&d->lock, flags);
			return done ? done : -EFAULT;
		}
		d->tx_ring[d->tx_head] = c;
		d->tx_head = (d->tx_head + 1) % ATH_SLIC_RING_TX;
		done++;
	}
	d->write_cnt++;
	spin_unlock_irqrestore(&d->lock, flags);
	return done;
}

/* ------------------------------------------------------------------ */
/* register helpers */

static inline u32 slic_rr(struct ath_slic_dev *d, unsigned off)
{
	return __raw_readl(d->base + off);
}

static inline void slic_wr(struct ath_slic_dev *d, unsigned off, u32 v)
{
	__raw_writel(v, d->base + off);
}

/* ------------------------------------------------------------------ */
/* character device fops */

static int ath_slic_open(struct inode *inode, struct file *filp)
{
	int minor = iminor(inode);

	if (minor >= SLIC_SLOTS)
		return -ENODEV;
	if ((filp->f_flags & O_ACCMODE) == O_RDONLY)
		return -EINVAL;		/* need R/W (stock requires O_RDWR) */

	filp->private_data = &slic_devs[minor];
	pr_info("ath_slic: open minor=%d flags=0x%x\n", minor, filp->f_flags);
	return 0;
}

static ssize_t ath_slic_read(struct file *filp, char __user *buf,
			     size_t count, loff_t *pos)
{
	struct ath_slic_dev *d = filp->private_data;
	ssize_t r;

	pr_info("ath_slic: read count=%zu\n", count);
	if (count > ATH_SLIC_RING_RX)
		count = ATH_SLIC_RING_RX;

	for (;;) {
		r = ring_rx_read(d, buf, count);
		if (r > 0)
			return r;
		if (filp->f_flags & O_NONBLOCK)
			return -EAGAIN;
		if (wait_event_interruptible(d->rq, d->rx_len > 0))
			return -ERESTARTSYS;
	}
}

static ssize_t ath_slic_write(struct file *filp, const char __user *buf,
			      size_t count, loff_t *pos)
{
	struct ath_slic_dev *d = filp->private_data;

	pr_info("ath_slic: write count=%zu\n", count);
	if (count > ATH_SLIC_RING_TX)
		count = ATH_SLIC_RING_TX;

	return ring_tx_write(d, buf, count);
}

static unsigned int ath_slic_poll(struct file *filp, poll_table *wait)
{
	struct ath_slic_dev *d = filp->private_data;
	unsigned int mask = 0;

	poll_wait(filp, &d->rq, wait);
	poll_wait(filp, &d->wq, wait);
	if (d->rx_len > 0)
		mask |= POLLIN | POLLRDNORM;
	return mask;
}

static long ath_slic_ioctl(struct file *filp, unsigned int cmd,
			   unsigned long arg)
{
	struct ath_slic_dev *d = filp->private_data;
	int idx;
	u32 v;

	/* fvphone control cmd: _IOWR(0x78,1,4) = 0xc0047801
	 * protocol (reverse engineered from fvphone):
	 *   buf[0] = len (4=read reg, 3=write reg, 20=special cmd)
	 *   buf[4] = register address
	 *   buf[8] = arg2 (unused for reg ops)
	 *   buf[12]= write data (len=3) / read-back value (len=4, driver
	 *            copies chip reg value back here)
	 * buf is 260 bytes (fvphone memsets then ioctls with 4/3/20). */
	if (cmd == 0xc0047801) {
		u32 buf[65] = {0};	/* 260 bytes */
		u32 len, reg, data;
		u8 v;
		extern u8 slic_reg_read_cs1(u8 reg);
		extern u8 slic_reg_write_cs1(u8 reg, u8 val);

		if (copy_from_user(buf, (void __user *)arg, 260))
			return -EFAULT;
		len = buf[0];
		reg = buf[1] & 0xff;
		data = buf[3];
		if (len == 4) {		/* read register */
			v = slic_reg_read_cs1(reg);
			buf[3] = v;
			pr_info("ath_slic: ioctl READ reg=0x%02x -> 0x%02x\n",
			       reg, v);
			if (copy_to_user((void __user *)arg, buf, 260))
				return -EFAULT;
			return 0;
		} else if (len == 3) {	/* write register */
			pr_info("ath_slic: ioctl WRITE reg=0x%02x = 0x%02x\n",
			       reg, data);
			slic_reg_write_cs1(reg, data & 0xff);
			return 0;
		}
		pr_info("ath_slic: ioctl CMD len=%u reg=0x%02x data=0x%02x\n",
		       len, reg, data);
		return 0;
	}
	/* legacy commands are 0x80044E23 + i (doc) or 0x44E23+i */
	idx = cmd - ATH_SLIC_IOCTL_BASE;
	if (cmd < 0x80044E23 || cmd >= 0x80044E23 + 17) {
		if (cmd < ATH_SLIC_IOCTL_BASE || cmd >= ATH_SLIC_IOCTL_BASE + 17)
			return -EINVAL;
	}
	pr_info("ath_slic: ioctl idx=%d arg=0x%lx\n", idx, arg);

	switch (idx) {
	case 0:		/* read-modify-write MBOX +0x14 (DMA policy/ctrl) */
		if (!d->mbox)
			return -ENXIO;
		v = __raw_readl(d->mbox + AR934X_DMA_REG_SLIC_MBOX_DMA_POLICY);
		__raw_writel(v, d->mbox + AR934X_DMA_REG_SLIC_MBOX_DMA_POLICY);
		return 0;
	case 1:		/* clear/reset ring buffers */
		ring_init(d);
		d->irq_cnt = 0;
		return 0;
	case 13:	/* reset ring buffer + set flag */
		ring_init(d);
		return 0;
	case 14:	/* reset statistics */
		d->irq_cnt = 0;
		d->read_cnt = 0;
		d->write_cnt = 0;
		return 0;
	case 15:	/* enable */
		return 0;
	case 16:	/* disable */
		return 0;
	default:
		/* fvphone actually uses _IOWR(0x78,1,4) = 0xc0047801
		 * (not the 0x80044E23+i table).  Until the SPI control
		 * path is implemented, treat it as a no-op success so
		 * fvphone init can proceed past the SLIC reset step. */
		pr_info("ath_slic: ioctl unknown cmd=0x%x idx=%d\n", cmd, idx);
		return 0;
	}
}

static int ath_slic_release(struct inode *inode, struct file *filp)
{
	return 0;
}

static loff_t ath_slic_llseek(struct file *filp, loff_t off, int whence)
{
	return 0;
}

static const struct file_operations ath_slic_fops = {
	.owner		= THIS_MODULE,
	.llseek		= ath_slic_llseek,
	.read		= ath_slic_read,
	.write		= ath_slic_write,
	.poll		= ath_slic_poll,
	.unlocked_ioctl = ath_slic_ioctl,
	.open		= ath_slic_open,
	.release	= ath_slic_release,
};

/* ------------------------------------------------------------------ */
/* proc /proc/slic */

static int slic_proc_show(struct seq_file *m, void *v)
{
	int i;

	for (i = 0; i < SLIC_SLOTS; i++) {
		struct ath_slic_dev *d = &slic_devs[i];
		seq_printf(m, "aci%d: irq=%lu read=%lu write=%lu rxlen=%d\n",
			   i, d->irq_cnt, d->read_cnt, d->write_cnt, d->rx_len);
	}
	return 0;
}

static int slic_proc_open(struct inode *inode, struct file *file)
{
	pr_info("ath_slic: proc open flags=0x%x\n", file->f_flags);
	return single_open(file, slic_proc_show, NULL);
}

static ssize_t slic_proc_read(struct file *file, char __user *buf,
			      size_t count, loff_t *ppos)
{
	ssize_t r;
	pr_info("ath_slic: proc read count=%zu pos=%lld\n", count, *ppos);
	r = seq_read(file, buf, count, ppos);
	pr_info("ath_slic: proc read ret=%zd\n", r);
	return r;
}

static const struct file_operations slic_proc_fops = {
	.owner		= THIS_MODULE,
	.open		= slic_proc_open,
	.read		= slic_proc_read,
	.unlocked_ioctl	= ath_slic_ioctl,
	.llseek		= seq_lseek,
	.release	= single_release,
};

/* ------------------------------------------------------------------ */
/* interrupt: MISC IRQ 15, SLIC MBOX int status 0x48 bit16 = RX ready */

static irqreturn_t ath_slic_intr(int irq, void *dev_id)
{
	struct ath_slic_dev *d = dev_id;
	u32 st;

	if (!d->mbox)
		return IRQ_NONE;
	st = __raw_readl(d->mbox + AR934X_DMA_REG_SLIC_MBOX_INT_STATUS);
	if (st & BIT(16)) {
		/* RX data ready: stock driver walks descriptor chain and
		 * copies 40B steps into RX ring.  TODO: implement the
		 * descriptor walk + copy.  For now just wake readers so
		 * the channel plumbing is exercised. */
		__raw_writel(st & BIT(16),
			     d->mbox + AR934X_DMA_REG_SLIC_MBOX_INT_STATUS);
		d->irq_cnt++;
		wake_up_interruptible(&d->rq);
		return IRQ_HANDLED;
	}
	/* ack MISC_DMA */
	ath79_reset_wr(AR71XX_RESET_REG_MISC_INT_STATUS,
		       ~(MISC_INT_DMA));
	return IRQ_HANDLED;
}

/* ------------------------------------------------------------------ */
/* hardware init (values from stock dmesg / disasm) */

static void ath_slic_hw_config(struct ath_slic_dev *d)
{
	void __iomem *gb = (void __iomem *)0xb8040000;
	void __iomem *rst = (void __iomem *)0xb806001c;
	void __iomem *pll = (void __iomem *)0xb8050030;
	void __iomem *sl = (void __iomem *)0xb80a9000;
	void __iomem *stereo = (void __iomem *)0xb80b0000;
	u32 t;

	/* --- exact live config read from STOCK CN6619 (10.80.1.68),
	 * SLIC working (phone powered). Do NOT invent values. --- */

	/* GPIO function: DISABLE_JTAG only (bit1); no CLK_OBS4 */
	__raw_writel(0x00000002, gb + 0x6c);

	/* GPIO output mux: GPIO1=mux7(SPI_CS1), GPIO2=mux6(SLIC refclk),
	 * GPIO3=mux5(SLIC), GPIO5=mux9(CS0), GPIO6=mux10(CLK),
	 * GPIO7=mux11(MOSI) */
	__raw_writel(0x05060700, gb + 0x2c);	/* OUT_FUNC0 GPIO0-3 */
	__raw_writel(0x0b0a0904, gb + 0x30);	/* OUT_FUNC1 GPIO4-7 */

	/* GPIO OE + OUT: stock running values (0x281b00 / 0x13e003).
	 * CRITICAL: without these the SLIC chip stays un-powered/dead and
	 * reads 0x00.  GPIO17-21 driven high (chip enable/reset paths). */
	__raw_writel(0x00281b00, gb + 0x00);	/* GPIO_OE */
	__raw_writel(0x0013e003, gb + 0x08);	/* GPIO_OUT */

	/* reset module: set bit14 (stock holds it = 1, do not clear) */
	t = __raw_readl(rst);
	__raw_writel(t | 0x4000, rst);

	/* stereo/audio block (stock 0x00a01300) */
	__raw_writel(0x00a01300, stereo);

	/* audio PLL (stock values) */
	__raw_writel(0x80006081, pll);		/* AUDIO_PLL_CONFIG */
	__raw_writel(0x1751081e, pll + 0x04);	/* AUDIO_PLL_MODULATION */
	__raw_writel(0x00004000, pll + 0x08);	/* AUDIO_PLL_MOD_STEP */
	__raw_writel(0x0ba8841e, pll + 0x0c);	/* CURRENT_AUDIO_PLL_MOD */

	/* SLIC controller registers (stock values) */
	slic_wr(d, 0x00, 0x20);		/* SLIC_SLOT: 32 */
	slic_wr(d, 0x04, 0x0f);		/* SLIC_CLOCK_CTRL DIV 15 */
	slic_wr(d, 0x08, 0x0e);		/* SLIC_CTRL: CLK_EN|MASTER|SLIC_EN */
	slic_wr(d, 0x0c, 0x03);
	slic_wr(d, 0x14, 0x03);
	slic_wr(d, 0x1c, 0xc3);		/* SLIC_TIMING_CTRL */
	udelay(1000);
	pr_info("ath_slic: hwcfg stock: ctrl=0x%x clk=0x%x slot=0x%x\n",
		slic_rr(d, 0x08), slic_rr(d, 0x04), slic_rr(d, 0x00));
}
static int ath_slic_setup_dma(struct ath_slic_dev *d)
{
	/* TODO: allocate descriptor chain + DMA buffers, program
	 * MBOX1 RX/TX descriptor base (+0x28/+0x30), start DMA
	 * (write 2 = START to +0x2c/+0x34).  Register mapping is
	 * fully known; needs stock desc layout walk in the ISR.
	 *
	 * Minimal start here so /dev/aci0 + fvphone open work. */
	if (!d->mbox)
		return -ENXIO;
	__raw_writel(0, d->mbox + 0x28);
	__raw_writel(0, d->mbox + 0x30);
	return 0;
}

/* ------------------------------------------------------------------ */

extern void slic_spi_probe_chip(void);
extern int slic_spi_register_driver(void);
extern void slic_spi_unregister_driver(void);

static int __init ath_slic_init(void)
{
	int i, ret;
	dev_t devno;
	void __iomem *aud;

	pr_info("ath_slic: loading (3.18 port)\n");

	ret = alloc_chrdev_region(&devno, 0, SLIC_SLOTS, DRV_NAME);
	if (ret < 0)
		return ret;
	ath_slic_major = MAJOR(devno);

	cdev_init(&ath_slic_cdev, &ath_slic_fops);
	ath_slic_cdev.owner = THIS_MODULE;
	ret = cdev_add(&ath_slic_cdev, devno, SLIC_SLOTS);
	if (ret)
		goto err_region;

	ath_slic_class = class_create(THIS_MODULE, DRV_NAME);
	if (IS_ERR(ath_slic_class)) {
		ret = PTR_ERR(ath_slic_class);
		goto err_cdev;
	}

	aud = ioremap_nocache(AUDIO_BASE, 0x100);
	if (aud)
		__raw_writel(0xa81300, aud);

	for (i = 0; i < SLIC_SLOTS; i++) {
		struct ath_slic_dev *d = &slic_devs[i];

		memset(d, 0, sizeof(*d));
		d->minor = i;
		d->mbox = ioremap_nocache(MBOX_BASE, 0x100);
		d->base = ioremap_nocache(SLIC_BASE, 0x100);
		if (!d->mbox || !d->base) {
			ret = -ENOMEM;
			goto err_devs;
		}
		if (!d->base) {
			ret = -ENOMEM;
			goto err_devs;
		}
		d->rx_ring = kzalloc(ATH_SLIC_RING_RX, GFP_KERNEL);
		d->tx_ring = kzalloc(ATH_SLIC_RING_TX, GFP_KERNEL);
		if (!d->rx_ring || !d->tx_ring) {
			ret = -ENOMEM;
			goto err_devs;
		}
		init_waitqueue_head(&d->rq);
		init_waitqueue_head(&d->wq);
		spin_lock_init(&d->lock);
		ring_init(d);

		device_create(ath_slic_class, NULL, MKDEV(ath_slic_major, i),
			      NULL, "aci%d", i);
	}

	/* fvphone reads /proc/slic0 (stock driver created this) */
	proc_create("slic0", 0, NULL, &slic_proc_fops);
	proc_create("slic", 0, NULL, &slic_proc_fops);

	ath_slic_hw_config(&slic_devs[0]);
	slic_spi_probe_chip();
	ath_slic_setup_dma(&slic_devs[0]);

	ret = request_irq(ATH79_MISC_IRQ_DMA, ath_slic_intr, IRQF_SHARED,
			  DRV_NAME, &slic_devs[0]);
	if (ret) {
		pr_err("ath_slic: irq request failed %d\n", ret);
		goto err_devs;
	}

	slic_spi_register_driver();

	pr_info("ath_slic: /dev/aci0-1 ready (major %d)\n", ath_slic_major);
	return 0;

err_devs:
	for (i = 0; i < SLIC_SLOTS; i++) {
		kfree(slic_devs[i].rx_ring);
		kfree(slic_devs[i].tx_ring);
	}
err_cdev:
	cdev_del(&ath_slic_cdev);
err_region:
	unregister_chrdev_region(MKDEV(ath_slic_major, 0), SLIC_SLOTS);
	return ret;
}

static void __exit ath_slic_exit(void)
{
	int i;

	slic_spi_unregister_driver();
	free_irq(ATH79_MISC_IRQ_DMA, &slic_devs[0]);
	remove_proc_entry("slic", NULL);
	remove_proc_entry("slic0", NULL);
	for (i = 0; i < SLIC_SLOTS; i++) {
		device_destroy(ath_slic_class, MKDEV(ath_slic_major, i));
		kfree(slic_devs[i].rx_ring);
		kfree(slic_devs[i].tx_ring);
		if (slic_devs[i].base)
			iounmap(slic_devs[i].base);
		if (slic_devs[i].mbox)
			iounmap(slic_devs[i].mbox);
	}
	class_destroy(ath_slic_class);
	cdev_del(&ath_slic_cdev);
	unregister_chrdev_region(MKDEV(ath_slic_major, 0), SLIC_SLOTS);
	pr_info("ath_slic: unloaded\n");
}

module_init(ath_slic_init);
module_exit(ath_slic_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("AR9341 SLIC voice driver (ZM-WR2500, 3.18 port)");
