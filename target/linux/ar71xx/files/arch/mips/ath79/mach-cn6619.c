/*
 *  ZMTEL ZM-WR2500 (CN6619) board support
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>
#include <linux/platform_device.h>
#include <linux/mtd/partitions.h>

#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include <linux/spi/spi.h>
#include <asm/mach-ath79/ath79_spi_platform.h>
#include "dev-eth.h"
#include "dev-spi.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define CN6619_GPIO_LED_TEL	13
#define CN6619_GPIO_LED_RSSIMAX	17
#define CN6619_GPIO_LED_RSSIHIGH	22
#define CN6619_GPIO_LED_RSSIMEDIUM	0
#define CN6619_GPIO_LED_RSSILOW	14
#define CN6619_GPIO_LED_LAN	15
#define CN6619_GPIO_LED_WPS	18

#define CN6619_GPIO_BTN_RESET	21
#define CN6619_GPIO_BTN_WPS	19

#define CN6619_KEYS_POLL_INTERVAL	20	/* msecs */
#define CN6619_KEYS_DEBOUNCE_INTERVAL (3 * CN6619_KEYS_POLL_INTERVAL)

#define CN6619_MAC0_OFFSET   0
#define CN6619_MAC1_OFFSET   6   /* wlan MAC right after eth MAC (12B block @art+0) */
#define CN6619_WMAC_CALDATA_OFFSET   0x1000

/* uboot_mod (pepe2k, web failsafe) 16MB layout:
 *   128k u-boot + 64k u-boot-env + 16128k firmware (0x30000-0xFF0000)
 *   + 64k art (0xFF0000). Kernel uImage at firmware base (0x30000),
 *   booted by uboot_mod "bootm 0x9f030000"; kernel/rootfs/rootfs_data are
 *   auto-split by MTD_SPLIT_UIMAGE_FW. (Original tp-link probe no longer
 *   applies - no TP-LINK header on uboot_mod OpenWrt images.) */
static struct mtd_partition cn6619_partitions[] = {
	{ .name = "u-boot",		.offset = 0,		.size = 0x20000 },
	{ .name = "u-boot-env",		.offset = 0x20000,	.size = 0x10000 },
	{ .name = "firmware",		.offset = 0x30000,	.size = 0xfc0000 },
	{ .name = "art",		.offset = 0xff0000,	.size = 0x10000 },
};

static struct flash_platform_data cn6619_flash_data = {
	.parts		= cn6619_partitions,
	.nr_parts	= ARRAY_SIZE(cn6619_partitions),
};

/* SPI: flash on CS0 (internal), Si32176 SLIC on CS1 (GPIO1, spi0.1) */
static struct ath79_spi_controller_data cn6619_spi_flash_cdata = {
	.cs_type	= ATH79_SPI_CS_TYPE_INTERNAL,
	.cs_line	= 0,
	.is_flash	= true,
};

static struct ath79_spi_controller_data cn6619_spi_slic_cdata = {
	.cs_type	= ATH79_SPI_CS_TYPE_GPIO,
	.cs_line	= 1,	/* GPIO1 = SLIC chip select */
	.is_flash	= false,
};

static struct spi_board_info cn6619_spi_info[] __initdata = {
	{
		.bus_num	= 0,
		.chip_select	= 0,
		.max_speed_hz	= 25000000,
		.modalias	= "m25p80",
		.platform_data	= &cn6619_flash_data,
		.controller_data = &cn6619_spi_flash_cdata,
	},
	{
		.bus_num	= 0,
		.chip_select	= 1,
		.max_speed_hz	= 1000000,
		.modalias	= "slic32176",
		.controller_data = &cn6619_spi_slic_cdata,
	},
};

static struct ath79_spi_platform_data cn6619_spi_data = {
	.bus_num	= 0,
	.num_chipselect	= 2,
};

static struct gpio_led cn6619_leds_gpio[] __initdata = {
	{
		.name		= "cn6619:green:tel",
		.gpio		= CN6619_GPIO_LED_TEL,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:rssimax",
		.gpio		= CN6619_GPIO_LED_RSSIMAX,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:rssihigh",
		.gpio		= CN6619_GPIO_LED_RSSIHIGH,
		.active_low	= 0,
	}, {
		.name		= "cn6619:green:rssimedium",
		.gpio		= CN6619_GPIO_LED_RSSIMEDIUM,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:rssilow",
		.gpio		= CN6619_GPIO_LED_RSSILOW,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:lan",
		.gpio		= CN6619_GPIO_LED_LAN,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:wps",
		.gpio		= CN6619_GPIO_LED_WPS,
		.active_low	= 1,
	},
};

static struct gpio_keys_button cn6619_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = CN6619_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= CN6619_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "WPS button",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = CN6619_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= CN6619_GPIO_BTN_WPS,
		.active_low	= 0,
	}, 
};

static void __init tl_ap123_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_spi(&cn6619_spi_data, cn6619_spi_info,
			   ARRAY_SIZE(cn6619_spi_info));

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_SW_PHY_SWAP);

	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + CN6619_MAC0_OFFSET, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, art + CN6619_MAC0_OFFSET, 1);

	/* GMAC0 is connected to the PHY0 of the internal switch */
	ath79_switch_data.phy4_mii_en = 1;
	ath79_switch_data.phy_poll_mask = BIT(0);
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio1_device.dev;
	ath79_register_eth(0);

	/* GMAC1 is connected to the internal switch */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_register_eth(1);

	ath79_register_wmac(art + CN6619_WMAC_CALDATA_OFFSET, art + CN6619_MAC1_OFFSET);
}

static void __init cn6619_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(cn6619_leds_gpio),
				 cn6619_leds_gpio);

	ath79_register_gpio_keys_polled(1, CN6619_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(cn6619_gpio_keys),
					cn6619_gpio_keys);

	gpio_request_one(16, GPIOF_OUT_INIT_HIGH | GPIOF_EXPORT_DIR_FIXED,
			 "pcie-rst");
					
	ath79_register_usb();

}

MIPS_MACHINE(ATH79_MACH_CN6619, "ZM-WR2500", "ZMTEL ZM-WR2500 (CN6619)",
	     cn6619_setup);
