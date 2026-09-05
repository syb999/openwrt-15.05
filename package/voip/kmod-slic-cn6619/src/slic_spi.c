/*
 * slic_spi.c -- AR9341 SPI bit-bang for Si32176 (ZM-WR2500 TEL SLIC)
 *
 * Faithful port of stock slic.ko SPI path:
 *   - SPI controller @0x1f000000 kseg1 0xbf000000, FS bit0 = GPIO mode
 *   - IOC (base+8): DO=bit0, CLK=bit8, CS pins bit16+; SLIC CS = CS1(bit17)
 *   - one byte clocked with CS1 held low (0x50000 = CS0|CS2 hi, CS1 lo)
 *   - read frame (stock slic_read_reg): FS=1, xfer(cmd+addr), xfer(hi),
 *     xfer(0) returns data clocked in; FS=0 after.
 * Registers read via opcode 0x60, write via 0x20, low addr bits reversed.
 */

#include <linux/io.h>
#include <linux/delay.h>
#include <linux/spi/spi.h>

#define SLIC_SPI_BASE		0xbf000000	/* 0x1f000000 kseg1 */
#define SLIC_SPI_FS		0x00
#define SLIC_SPI_IOC		0x08
#define SLIC_SPI_RDS		0x0c

#define IOC_CS_IDLE		0x70100		/* CS0|CS1|CS2 hi + CLK hi */
#define IOC_CS1_SEL_CLK		0x50100		/* CS1 lo, CS0|CS2 hi, CLK hi */
#define IOC_CS1_SEL		0x50000		/* CS1 lo, CLK lo */

static void slic_spi_enter(void)
{
	__raw_writel(0x1, (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_FS));
}

static void slic_spi_leave(void)
{
	__raw_writel(0x0, (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_FS));
}

/* one byte out over CS1 (stock func 0xd510) */
static u8 slic_xfer_cs1(u8 out)
{
	void __iomem *ioc = (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_IOC);
	int bit;

	__raw_writel(IOC_CS_IDLE, ioc);
	__raw_writel(IOC_CS1_SEL_CLK, ioc);	/* CS1 low */

	for (bit = 7; bit >= 0; bit--) {
		u32 d = (out >> bit) & 1;
		__raw_writel(IOC_CS1_SEL | d, ioc);	/* CLK lo, DO=d */
		__raw_writel(IOC_CS1_SEL_CLK | d, ioc);	/* CLK hi -> out */
	}
	__raw_writel(IOC_CS_IDLE, ioc);		/* CS release */
	return __raw_readl((void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_RDS)) & 0xff;
}

/* generic one byte over given CS select word */
static u8 slic_xfer_cs(u8 out, u32 sel)
{
	void __iomem *ioc = (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_IOC);
	int bit;

	__raw_writel(sel | 0x100, ioc);
	for (bit = 7; bit >= 0; bit--) {
		u32 d = (out >> bit) & 1;
		__raw_writel(sel | d, ioc);
		__raw_writel(sel | 0x100 | d, ioc);
	}
	return __raw_readl((void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_RDS)) & 0xff;
}

/* low 5 address bits bit-reversed into command bits 0..4 */
static u8 slic_addr_reorder(u8 reg)
{
	u8 a = 0;

	a  = ((reg >> 4) & 0x01);
	a |= ((reg >> 2) & 0x02);
	a |= (reg & 0x04);
	a |= ((reg << 2) & 0x08);
	a |= ((reg << 4) & 0x10);
	return a;
}

u8 slic_reg_read_cs1(u8 reg)
{
	u8 b0, r;

	slic_spi_enter();
	b0 = 0x60 | slic_addr_reorder(reg);
	slic_xfer_cs1(b0);
	slic_xfer_cs1(0x00);
	r = slic_xfer_cs1(0x00);
	slic_spi_leave();
	return r;
}

u8 slic_reg_write_cs1(u8 reg, u8 val)
{
	u8 r;

	slic_spi_enter();
	slic_xfer_cs1(0x20 | slic_addr_reorder(reg));
	slic_xfer_cs1(0x00);
	r = slic_xfer_cs1(val);
	slic_spi_leave();
	return r;
}

static void slic_flash_jedec(void)
{
	void __iomem *ioc = (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_IOC);
	u8 id[3];
	int i;

	slic_spi_enter();
	slic_xfer_cs(0x9f, 0x60000);	/* CS0 low, JEDEC cmd */
	id[0] = slic_xfer_cs(0x00, 0x60000);
	id[1] = slic_xfer_cs(0x00, 0x60000);
	id[2] = slic_xfer_cs(0x00, 0x60000);
	__raw_writel(0x70000, ioc);
	slic_spi_leave();
	pr_info("ath_slic: flash jedec = %02x %02x %02x\n", id[0], id[1], id[2]);
}

/* generic byte over IOC with a GPIO CS (gpio number) */
static u8 slic_xfer_gpio_cs(u8 out, int cs_gpio, int active_low)
{
	void __iomem *ioc = (void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_IOC);
	void __iomem *gb = (void __iomem *)0xb8040000;
	u32 mask = (1u << cs_gpio);
	int bit;
	u8 r;

	__raw_writel(__raw_readl(gb + 0x00) | mask, gb + 0x00); /* OE out */
	if (active_low)
		__raw_writel(mask, gb + 0x10);	/* clear = select */
	else
		__raw_writel(mask, gb + 0x0c);	/* set = select */

	for (bit = 7; bit >= 0; bit--) {
		u32 d = (out >> bit) & 1;
		__raw_writel(0x70000 | d, ioc);		/* CLK lo, DO=d */
		__raw_writel(0x70100 | d, ioc);		/* CLK hi */
	}
	r = __raw_readl((void __iomem *)(SLIC_SPI_BASE + SLIC_SPI_RDS)) & 0xff;

	if (active_low)
		__raw_writel(mask, gb + 0x0c);	/* set = de-select */
	else
		__raw_writel(mask, gb + 0x10);
	return r;
}

/* read reg using given gpio as CS, IOC clock on shared SPI pins */
static u8 slic_reg_read_gp(u8 reg, int cs_gpio, int active_low)
{
	u8 r;

	slic_spi_enter();
	slic_xfer_gpio_cs(0x60 | slic_addr_reorder(reg), cs_gpio, active_low);
	slic_xfer_gpio_cs(0x00, cs_gpio, active_low);
	r = slic_xfer_gpio_cs(0x00, cs_gpio, active_low);
	slic_spi_leave();
	return r;
}

void slic_spi_probe_chip(void)
{
	u8 v;
	int i;

	/* READ-ONLY probe.  NEVER write chip registers here: writing
	 * unknown/control regs (0x00 power-down, 0x02) has damaged the
	 * SLIC DC-DC (phone battery feed) on two boards. */
	pr_info("ath_slic: Si32176 read via IOC CS1 (stock mux)\n");
	for (i = 0; i < 16; i++) {
		v = slic_reg_read_cs1(i);
		pr_info("ath_slic:   cs1 reg[0x%02x] = 0x%02x\n", i, v);
	}
}
/* ------------------------------------------------------------------ */
/* SPI framework driver: matches "slic32176" board info (CS1/GPIO1). */
static struct spi_device *g_spi;

static u8 slic_reorder2(u8 reg)
{
	u8 a = 0;

	a  = ((reg >> 4) & 0x01);
	a |= ((reg >> 2) & 0x02);
	a |= (reg & 0x04);
	a |= ((reg << 2) & 0x08);
	a |= ((reg << 4) & 0x10);
	return a;
}

static int slic_spi_xfer_sync(u8 *tx, u8 *rx, int len)
{
	struct spi_transfer t;
	struct spi_message m;
	int ret;

	if (!g_spi)
		return -ENODEV;
	memset(&t, 0, sizeof(t));
	t.tx_buf = tx;
	t.rx_buf = rx;
	t.len = len;
	spi_message_init(&m);
	spi_message_add_tail(&t, &m);
	ret = spi_sync(g_spi, &m);
	return ret;
}

static int slic_spi_dev_read(u8 reg)
{
	u8 tx[3], rx[3] = {0, 0, 0};
	int ret;

	tx[0] = 0x60 | slic_reorder2(reg);
	tx[1] = 0x00;
	tx[2] = 0x00;
	ret = slic_spi_xfer_sync(tx, rx, 3);
	if (ret < 0)
		return ret;
	return rx[2];
}

/* start AUDIO PLL (SLIC clock source) @ 24.576MHz MCLK, 25MHz ref.
 * regs: AUDIO_PLL_CONFIG 0x18050030, AUDIO_PLL_MODULATION 0x18050034 */
static void slic_audio_pll_init(void)
{
	void __iomem *pll = (void __iomem *)0xb8050030;
	u32 cfg, mod;

	cfg = (6u << 12) |	/* EXT_DIV */
	      (2u << 7) |	/* POSTPLLPWD */
	      (0u << 5) |	/* PLLPWD = 0 power up */
	      (0u << 4) |	/* BYPASS off */
	      (1u << 0);	/* REFDIV 1 (25MHz) */
	mod = (0x24F76u << 11) | (0x17u << 1);	/* divfrac/divint 24.576M */

	__raw_writel(cfg, pll);
	__raw_writel(mod, pll + 0x04);
	udelay(2000);
	pr_info("ath_slic: audio pll cfg=0x%08x mod=0x%08x\n", cfg, mod);
}

static int slic_spi_raw(u8 *tx, u8 *rx, int len)
{
	int ret;

	ret = slic_spi_xfer_sync(tx, rx, len);
	if (ret < 0)
		return ret;
	return 0;
}

static void slic_gpio_out_high(int g)
{
	void __iomem *gb = (void __iomem *)0xb8040000;
	u32 oe;

	oe = __raw_readl(gb + 0x00);
	oe |= (1u << g);
	__raw_writel(oe, gb + 0x00);	/* output */
	__raw_writel(1u << g, gb + 0x0c);/* set high */
}

static int slic_spi_probe(struct spi_device *spi)
{
	int i, v;
	u8 tx[6], rx[6];
	void __iomem *slc = (void __iomem *)0xb80a9008;

	g_spi = spi;
	pr_info("ath_slic: spi probe %s cs=%d mode=0x%x\n",
		spi->modalias, spi->chip_select, spi->mode);

	/* keep SLIC ctrl enabled (hw_config already set stock values) */
	__raw_writel(0x0e, slc);
	udelay(1000);

	/* raw IOC CS1 reads (stock CS path via GPIO1 mux7 = SPI_CS1) */
	for (i = 0; i < 16; i++) {
		v = slic_reg_read_cs1(i);
		pr_info("ath_slic:   cs1 reg[0x%02x] = 0x%02x\n", i, v);
	}
	return 0;
}
static int slic_spi_remove(struct spi_device *spi)
{
	g_spi = NULL;
	return 0;
}

static struct spi_driver slic_spi_driver = {
	.driver = {
		.name	= "spidev",
		.owner	= THIS_MODULE,
	},
	.probe	= slic_spi_probe,
	.remove	= slic_spi_remove,
};

int slic_spi_register_driver(void)
{
	return spi_register_driver(&slic_spi_driver);
}

void slic_spi_unregister_driver(void)
{
	spi_unregister_driver(&slic_spi_driver);
}
