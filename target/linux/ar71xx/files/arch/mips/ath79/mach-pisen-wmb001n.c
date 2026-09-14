/*
 *  PISEN_WMB001N board support
 *
 *  Copyright (C) 2012 Gabor Juhos <juhosg@openwrt.org>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/i2c.h>
#include <linux/i2c-gpio.h>
#include <linux/mtd/mtd.h>
#include <linux/mtd/partitions.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/string.h>

#include <linux/clk.h>

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/gpio.h>
#include <linux/delay.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>
#include "common.h"
#include "dev-audio.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define PISEN_WMB001N_GPIO_I2C_SDA		16
#define PISEN_WMB001N_GPIO_I2C_SCL		20

#define PISEN_WMB001N_GPIO_I2S_SD		11
#define PISEN_WMB001N_GPIO_I2S_WS		12
#define PISEN_WMB001N_GPIO_I2S_CLK		13
#define PISEN_WMB001N_GPIO_I2S_MCLK		14
#define PISEN_WMB001N_GPIO_SPDIF_OUT	15

#define PISEN_WMB001N_GPIO_LED_WLAN     22

#define PISEN_WMB001N_GPIO_LED_VOLUM4    4
#define PISEN_WMB001N_GPIO_LED_VOLUM3    3
#define PISEN_WMB001N_GPIO_LED_VOLUM2    2
#define PISEN_WMB001N_GPIO_LED_VOLUM1    1
#define PISEN_WMB001N_GPIO_LED_VOLUM0    0

#define PISEN_WMB001N_GPIO_BTN_RESET	17
#define PISEN_WMB001N_GPIO_BTN_VOLUMEDOWN	18
#define PISEN_WMB001N_GPIO_BTN_VOLUMEUP		19

#define PISEN_WMB001N_KEYS_POLL_INTERVAL	20	/* msecs */
#define PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL (3 * PISEN_WMB001N_KEYS_POLL_INTERVAL)

static const char *pisen_wmb001n_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data pisen_wmb001n_flash_data = {
	.part_probes	= pisen_wmb001n_part_probes,
};

/*
 * Flash layout used by the original (vendor) bootloader:
 *
 *   0x000000 - 0x00ffff  u-boot
 *   0x010000 - 0x01ffff  u-boot-env
 *   0x020000 - 0xddffff  firmware  (vendor rootfs partition, holds the
 *                                   OpenWrt image: OKLI uImage + squashfs)
 *   0xde0000 - 0xdeffff  loader    (first 64k of the vendor kernel
 *                                   partition, holds the OKLI loader)
 *   0xdf0000 - 0xfdffff  (rest of the vendor kernel partition, unused)
 *   0xfe0000 - 0xfeffff  mib0
 *   0xff0000 - 0xffffff  art
 *
 * The vendor bootloader jumps to the beginning of its 2MB kernel partition
 * which is too small for the kernel, so only an OKLI loader is stored there.
 * That loader reads the kernel from the OKLI uImage at 0x20000.  The loader
 * is written by the vendor factory image only and must not be replaced on
 * sysupgrade, therefore it gets a separate read-only partition here.
 *
 * The firmware partition is split into kernel/rootfs/rootfs_data by
 * MTD_SPLIT_UIMAGE_FW, which is why the mtdsplit uImage parser has to know
 * about the OKLI magic as well.
 */
static struct mtd_partition pisen_wmb001n_orig_partitions[] = {
	{
		.name		= "u-boot",
		.offset		= 0x000000,
		.size		= 0x010000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "u-boot-env",
		.offset		= 0x010000,
		.size		= 0x010000,
		/* the vendor bootloader reads its bootargs from here but can
		 * not write them (no savenv support), so keep them read-only */
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "firmware",
		.offset		= 0x020000,
		.size		= 0xdc0000,
	}, {
		.name		= "loader",
		.offset		= 0xde0000,
		.size		= 0x010000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "mib0",
		.offset		= 0xfe0000,
		.size		= 0x010000,
		.mask_flags	= MTD_WRITEABLE,
	}, {
		.name		= "art",
		.offset		= 0xff0000,
		.size		= 0x010000,
		.mask_flags	= MTD_WRITEABLE,
	},
};

static struct flash_platform_data pisen_wmb001n_orig_flash_data = {
	.parts		= pisen_wmb001n_orig_partitions,
	.nr_parts	= ARRAY_SIZE(pisen_wmb001n_orig_partitions),
};

#define PISEN_WMB001N_FLASH_BASE	0x1f000000
#define PISEN_WMB001N_ORIG_FW_OFFS	0x020000

/*
 * Both flash layouts store the kernel at 0x20000, but in different formats:
 * the image for the original bootloader starts with an OKLI uImage there
 * (the loader scans for that magic), while breed keeps the TP-LINK layout
 * with its tag.  The machine type is the same for both variants, so pick
 * the partition table from the layout which is actually present in the
 * flash.  KSEG1 lets us look at the mapping before mtd is registered.
 */
static struct flash_platform_data *pisen_wmb001n_get_flash_data(void)
{
	static const u8 okli_magic[4] = { 0x4f, 0x4b, 0x4c, 0x49 };
	const u8 *p;

	p = (const u8 *) KSEG1ADDR(PISEN_WMB001N_FLASH_BASE +
				   PISEN_WMB001N_ORIG_FW_OFFS);

	if (!memcmp(p, okli_magic, sizeof(okli_magic))) {
		printk(KERN_INFO "PISEN_WMB001N: original bootloader layout "
		       "detected\n");
		return &pisen_wmb001n_orig_flash_data;
	}

	return &pisen_wmb001n_flash_data;
}

static struct i2c_board_info pisen_wmb001n_i2c_devices[] __initdata = {
	{
		I2C_BOARD_INFO("wm8904", 0x1a),
	},
};

static struct i2c_gpio_platform_data pisen_wmb001n_i2c_gpio_data = {
	.sda_pin	= PISEN_WMB001N_GPIO_I2C_SDA,
	.scl_pin	= PISEN_WMB001N_GPIO_I2C_SCL,
	/*
	 * The board has no pull-up on SCL (measured: the line stays low when
	 * nobody drives it), so SCL must always be driven - that is what
	 * upstream's DTS does with i2c-gpio,scl-output-only.  SDA has a
	 * pull-up but is a plain GPIO: it has to be released by switching
	 * the pin to input (true open drain), otherwise the push-pull high
	 * level fights the WM8918 which then fails to answer (its ID reads
	 * back as 0 and the codec probe fails).
	 */
	.sda_is_open_drain = 0,
	.scl_is_open_drain = 1,
	.scl_is_output_only = 1,
	.udelay = 5,
	.timeout = 100,
};

static struct platform_device pisen_wmb001n_i2c_gpio_device = {
	.name	= "i2c-gpio",
	.id	= 0,
	.dev	= {
		.platform_data	= &pisen_wmb001n_i2c_gpio_data,
	},
};

static struct platform_device pisen_wmb001n_internal_codec = {
	.name		= "ath79-internal-codec",
	.id		= -1,
};

static struct platform_device pisen_wmb001n_sound_device = {
	.name = "ath79-wm8904",
	.id = -1,
};

static struct gpio_led pisen_wmb001n_leds_gpio[] __initdata = {
	{
		.name		= "pisen:blue:wlan",
		.gpio		= PISEN_WMB001N_GPIO_LED_WLAN,
		.active_low	= 0,
	}, {
		.name		= "pisen:blue:volum4",
		.gpio		= PISEN_WMB001N_GPIO_LED_VOLUM4,
		.active_low	= 0,
	}, {
		.name		= "pisen:blue:volum3",
		.gpio		= PISEN_WMB001N_GPIO_LED_VOLUM3,
		.active_low	= 0,
	}, {
		.name		= "pisen:blue:volum2",
		.gpio		= PISEN_WMB001N_GPIO_LED_VOLUM2,
		.active_low	= 0,
	}, {
		.name		= "pisen:blue:volum1",
		.gpio		= PISEN_WMB001N_GPIO_LED_VOLUM1,
		.active_low	= 0,
	}, {
		.name		= "pisen:blue:volum0",
		.gpio		= PISEN_WMB001N_GPIO_LED_VOLUM0,
		.active_low	= 0,
	}
};

static struct gpio_keys_button pisen_wmb001n_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMB001N_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "volume_down",
		.type		= EV_KEY,
		.code		= KEY_VOLUMEDOWN,
		.debounce_interval = PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMB001N_GPIO_BTN_VOLUMEDOWN,
		.active_low	= 1,
	}, {
		.desc		= "volume_up",
		.type		= EV_KEY,
		.code		= KEY_VOLUMEUP,
		.debounce_interval = PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMB001N_GPIO_BTN_VOLUMEUP,
		.active_low	= 1,
	}
};

static void __init pisen_wmb001n_audio_setup(void)
{
	u32 t;

	/* Reset I2S internal controller */
	t = ath79_reset_rr(AR71XX_RESET_REG_RESET_MODULE);
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t | AR934X_RESET_I2S);
	udelay(10);

	/* Configure I2S MCLK pin - critical for WM8904 */
	gpio_request(PISEN_WMB001N_GPIO_I2S_MCLK, "i2s_mclk");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_MCLK, AR934X_GPIO_OUT_MUX_I2S_MCK);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_MCLK, 0);

	/* Configure I2S CLK pin (BCLK) */
	gpio_request(PISEN_WMB001N_GPIO_I2S_CLK, "i2s_clk");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_CLK, AR934X_GPIO_OUT_MUX_I2S_CLK);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_CLK, 0);

	/* Configure I2S WS pin (LRCLK) */
	gpio_request(PISEN_WMB001N_GPIO_I2S_WS, "i2s_ws");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_WS, AR934X_GPIO_OUT_MUX_I2S_WS);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_WS, 0);

	/* Configure I2S SD pin (DATA) */
	gpio_request(PISEN_WMB001N_GPIO_I2S_SD, "i2s_sd");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_SD, AR934X_GPIO_OUT_MUX_I2S_SD);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_SD, 0);

	/* Release reset of I2S controller */
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t & ~AR934X_RESET_I2S);
	udelay(10);

	/* Initialize stereo block registers */
	ath79_audio_setup();
	
	printk(KERN_INFO "PISEN_WMB001N: I2S GPIO pins configured for WM8904\n");
}

static void __init tl_ap123_setup(struct flash_platform_data *flash_data)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1fff0000);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(flash_data);

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_SW_ONLY_MODE);

	ath79_register_mdio(1, 0x0);

	/*
	 * The vendor firmware uses art+0 for the WAN (GMAC0 / switch PHY0
	 * port) and the next address for the LAN.  Using art-1 for eth0
	 * made the WAN MAC one lower than the vendor default, which is
	 * visible in the ISP DHCP leases.
	 */
	ath79_init_mac(ath79_eth0_data.mac_addr, mac, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, -1);

	/* GMAC0 is connected to the PHY0 of the internal switch */
	ath79_switch_data.phy4_mii_en = 1;
	ath79_switch_data.phy_poll_mask = BIT(4);
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio1_device.dev;
	ath79_register_eth(0);

	/* GMAC1 is connected to the internal switch */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_register_eth(1);

	ath79_register_wmac(ee, mac);
}

static void __init pisen_wmb001n_setup(void)
{
	tl_ap123_setup(pisen_wmb001n_get_flash_data());

	ath79_register_leds_gpio(-1, ARRAY_SIZE(pisen_wmb001n_leds_gpio),
				 pisen_wmb001n_leds_gpio);

	ath79_register_gpio_keys_polled(1, PISEN_WMB001N_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(pisen_wmb001n_gpio_keys),
					pisen_wmb001n_gpio_keys);

	/* Register I2C GPIO first */
	platform_device_register(&pisen_wmb001n_i2c_gpio_device);

	/* Register I2C devices (WM8904) */
	i2c_register_board_info(0, pisen_wmb001n_i2c_devices, 
				ARRAY_SIZE(pisen_wmb001n_i2c_devices));

	ath79_register_usb();

	/* Audio setup for WM8904 */
	pisen_wmb001n_audio_setup();
	platform_device_register(&pisen_wmb001n_internal_codec);
	platform_device_register(&pisen_wmb001n_sound_device);
	ath79_audio_device_register();
}

MIPS_MACHINE(ATH79_MACH_PISEN_WMB001N, "PISEN_WMB001N", "PISEN_WMB001N",
	     pisen_wmb001n_setup);
