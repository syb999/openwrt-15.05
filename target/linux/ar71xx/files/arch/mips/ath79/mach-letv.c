/*
 *  Atheros AP147 reference board support
 *
 *  Copyright (C) 2014 Matthias Schiffer <mschiffer@universe-factory.net>
 *  Copyright (C) 2015 Sven Eckelmann <sven@open-mesh.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/platform_device.h>
#include <linux/ar8216_platform.h>

#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>

#include "common.h"
#include "dev-ap9x-pci.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"
#include "pci.h"

#define LETV_GPIO_LED_WAN	4
#define LETV_GPIO_LED_LAN1	16
#define LETV_GPIO_LED_LAN2	15
#define LETV_GPIO_LED_LAN3	14
#define LETV_GPIO_LED_LAN4	11
#define LETV_GPIO_LED_STATUS	13
#define LETV_GPIO_LED_WLAN_2G	12

#define LETV_GPIO_BTN_WPS	17

#define LETV_KEYS_POLL_INTERVAL	20	/* msecs */
#define LETV_KEYS_DEBOUNCE_INTERVAL	(3 * LETV_KEYS_POLL_INTERVAL)

#define LETV_MAC0_OFFSET	0x1000

static struct gpio_led letv_leds_gpio[] __initdata = {
	{
		.name		= "letv:green:status",
		.gpio		= LETV_GPIO_LED_STATUS,
		.active_low	= 1,
	}, {
		.name		= "letv:green:wlan-2g",
		.gpio		= LETV_GPIO_LED_WLAN_2G,
		.active_low	= 1,
	}, {
		.name		= "letv:green:lan1",
		.gpio		= LETV_GPIO_LED_LAN1,
		.active_low	= 1,
	}, {
		.name		= "letv:green:lan2",
		.gpio		= LETV_GPIO_LED_LAN2,
		.active_low	= 1,
	}, {
		.name		= "letv:green:lan3",
		.gpio		= LETV_GPIO_LED_LAN3,
		.active_low	= 1,
	}, {
		.name		= "letv:green:lan4",
		.gpio		= LETV_GPIO_LED_LAN4,
		.active_low	= 1,
	}, {
		.name		= "letv:green:wan",
		.gpio		= LETV_GPIO_LED_WAN,
		.active_low	= 1,
	},
};

static struct gpio_keys_button letv_gpio_keys[] __initdata = {
	{
		.desc		= "wps button",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = LETV_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= LETV_GPIO_BTN_WPS,
		.active_low	= 1,
	}
};

static void __init letv_setup(void)
{
	u8 *art = (u8 *)KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);
	ath79_register_leds_gpio(-1, ARRAY_SIZE(letv_leds_gpio),
				 letv_leds_gpio);
	ath79_register_gpio_keys_polled(-1, LETV_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(letv_gpio_keys),
					letv_gpio_keys);

	ath79_register_usb();

	ath79_register_pci();

	ath79_register_wmac(art + LETV_MAC0_OFFSET, NULL);

	ath79_setup_ar933x_phy4_switch(false, false);

	ath79_register_mdio(0, 0x0);

	/* LAN */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_switch_data.phy_poll_mask |= BIT(4);
	ath79_init_mac(ath79_eth1_data.mac_addr, art, 0);
	ath79_register_eth(1);

	/* WAN */
	ath79_switch_data.phy4_mii_en = 1;
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.speed = SPEED_100;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_init_mac(ath79_eth0_data.mac_addr, art, 1);
	ath79_register_eth(0);
}

MIPS_MACHINE(ATH79_MACH_LETV, "LETV", "LETV board", letv_setup);
