/*
 *  SJ-WP35 board support
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

#define SJ_WP35_GPIO_LED_WAN	4
#define SJ_WP35_GPIO_LED_LAN1	16
#define SJ_WP35_GPIO_LED_LAN2	15
#define SJ_WP35_GPIO_LED_LAN3	14
#define SJ_WP35_GPIO_LED_LAN4	11
#define SJ_WP35_GPIO_LED_STATUS	13

#define SJ_WP35_GPIO_BTN_RESET	17

#define SJ_WP35_KEYS_POLL_INTERVAL	20	/* msecs */
#define SJ_WP35_KEYS_DEBOUNCE_INTERVAL	(3 * SJ_WP35_KEYS_POLL_INTERVAL)

#define SJ_WP35_MAC0_OFFSET	0x1000

static struct gpio_led sj_wp35_leds_gpio[] __initdata = {
	{
		.name		= "wp35:green:status",
		.gpio		= SJ_WP35_GPIO_LED_STATUS,
		.active_low	= 1,
	}, {
		.name		= "wp35:green:lan1",
		.gpio		= SJ_WP35_GPIO_LED_LAN1,
		.active_low	= 1,
	}, {
		.name		= "wp35:green:lan2",
		.gpio		= SJ_WP35_GPIO_LED_LAN2,
		.active_low	= 1,
	}, {
		.name		= "wp35:green:lan3",
		.gpio		= SJ_WP35_GPIO_LED_LAN3,
		.active_low	= 1,
	}, {
		.name		= "wp35:green:lan4",
		.gpio		= SJ_WP35_GPIO_LED_LAN4,
		.active_low	= 1,
	}, {
		.name		= "wp35:green:wan",
		.gpio		= SJ_WP35_GPIO_LED_WAN,
		.active_low	= 1,
	},
};

static struct gpio_keys_button sj_wp35_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = SJ_WP35_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= SJ_WP35_GPIO_BTN_RESET,
		.active_low	= 1,
	}
};

static void __init sj_wp35_setup(void)
{
	u8 *art = (u8 *)KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);
	ath79_register_leds_gpio(-1, ARRAY_SIZE(sj_wp35_leds_gpio),
				 sj_wp35_leds_gpio);
	ath79_register_gpio_keys_polled(-1, SJ_WP35_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(sj_wp35_gpio_keys),
					sj_wp35_gpio_keys);

	ath79_register_usb();

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

MIPS_MACHINE(ATH79_MACH_SJ_WP35, "SJ-WP35", "SJ-WP35", sj_wp35_setup);
