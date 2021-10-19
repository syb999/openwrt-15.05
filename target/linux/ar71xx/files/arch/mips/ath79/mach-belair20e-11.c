/*
 *  BelAir Networks BelAir20E-11 board support
 *
 *  Copyright (C) 2017 Weijie Gao <juhosg@openwrt.org>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/pci.h>
#include <linux/phy.h>
#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/ar8216_platform.h>

#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-ap9x-pci.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-wmac.h"
#include "dev-usb.h"
#include "machtypes.h"

#define BELAIR_GPIO_LED_WLAN2G		11
#define BELAIR_GPIO_LED_WLAN5G		16
#define BELAIR_GPIO_LED_POWER		18
#define BELAIR_GPIO_LED_POWER_RED	19
#define BELAIR_GPIO_LED_INTERNET	20
#define BELAIR_GPIO_LED_INTERNET_RED	21

#define BELAIR_GPIO_BTN_WPS		12
#define BELAIR_GPIO_BTN_RESET		17

#define BELAIR_GPIO_USB_POWER		14

#define BELAIR_KEYS_POLL_INTERVAL	20	/* msecs */
#define BELAIR_KEYS_DEBOUNCE_INTERVAL	(3 * BELAIR_KEYS_POLL_INTERVAL)

#define BELAIR_MAC_OFFSET		0
#define BELAIR_WMAC_CALDATA_OFFSET	0x1000
#define BELAIR_PCIE_CALDATA_OFFSET	0x5000

static struct gpio_led belair_leds_gpio[] __initdata = {
	{
		.name		= "belair:blue:wlan2g",
		.gpio		= BELAIR_GPIO_LED_WLAN2G,
		.active_low	= 1,
	}, {
		.name		= "belair:blue:wlan5g",
		.gpio		= BELAIR_GPIO_LED_WLAN5G,
		.active_low	= 1,
	}, {
		.name		= "belair:blue:power",
		.gpio		= BELAIR_GPIO_LED_POWER,
		.active_low	= 0,
	}, {
		.name		= "belair:red:power",
		.gpio		= BELAIR_GPIO_LED_POWER_RED,
		.active_low	= 0,
	}, {
		.name		= "belair:blue:internet",
		.gpio		= BELAIR_GPIO_LED_INTERNET,
		.active_low	= 0,
	}, {
		.name		= "belair:red:internet",
		.gpio		= BELAIR_GPIO_LED_INTERNET_RED,
		.active_low	= 0,
	}
};

static struct gpio_keys_button belair_gpio_keys[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = BELAIR_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= BELAIR_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "wps",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = BELAIR_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= BELAIR_GPIO_BTN_WPS,
		.active_low	= 1,
	}
};

static struct ar8327_pad_cfg db120_ar8327_pad0_cfg = {
	.mode = AR8327_PAD_MAC_RGMII,
	.txclk_delay_en = true,
	.rxclk_delay_en = true,
	.txclk_delay_sel = AR8327_CLK_DELAY_SEL1,
	.rxclk_delay_sel = AR8327_CLK_DELAY_SEL2,
};

static struct ar8327_platform_data db120_ar8327_data = {
	.pad0_cfg = &db120_ar8327_pad0_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	}
};

static struct mdio_board_info db120_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &db120_ar8327_data,
	},
};

static struct flash_platform_data flash __initdata = {NULL, NULL, 0};

static void __init belair_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1f040000);
	u8 tmpmac[ETH_ALEN];

	ath79_register_m25p80_multi(&flash);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(belair_leds_gpio),
				 belair_leds_gpio);
	ath79_register_gpio_keys_polled(-1, BELAIR_KEYS_POLL_INTERVAL,
					 ARRAY_SIZE(belair_gpio_keys),
					 belair_gpio_keys);

	ath79_init_mac(tmpmac, art + BELAIR_MAC_OFFSET, 1);
	ath79_register_wmac(art + BELAIR_WMAC_CALDATA_OFFSET, tmpmac);

	ath79_init_mac(tmpmac, art + BELAIR_MAC_OFFSET, 2);
	ap91_pci_init(art + BELAIR_PCIE_CALDATA_OFFSET, tmpmac);

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_RGMII_GMAC0);

	ath79_register_mdio(0, 0x0);

	mdiobus_register_board_info(db120_mdio0_info,
				    ARRAY_SIZE(db120_mdio0_info));

	ath79_init_mac(ath79_eth0_data.mac_addr, art + BELAIR_MAC_OFFSET, 0);

	/* GMAC0 is connected to an AR8327 switch */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;
	ath79_eth0_pll_data.pll_1000 = 0x06000000;
	ath79_register_eth(0);

	ath79_register_usb();
}

MIPS_MACHINE(ATH79_MACH_BELAIR20E_11, "BELAIR20E-11",
	     "BelAir Networks BelAir20E-11", belair_setup);
