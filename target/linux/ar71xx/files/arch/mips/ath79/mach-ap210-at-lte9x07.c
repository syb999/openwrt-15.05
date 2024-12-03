/*
 *  AP210-AT-LTE9X07 AP support
 *
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/platform_device.h>
#include <linux/ar8216_platform.h>
#include <linux/ath9k_platform.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>

#include "common.h"
#include "dev-ap9x-pci.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-wmac.h"
#include "machtypes.h"
#include "pci.h"
#include "dev-usb.h"

#define AP210_AT_LTE9X07_GPIO_LED_STATUS	13

#define AP210_AT_LTE9X07_GPIO_BTN_RESET	17

#define AP210_AT_LTE9X07_KEYS_POLL_INTERVAL	20	/* msecs */
#define AP210_AT_LTE9X07_KEYS_DEBOUNCE_INTERVAL	(3 * AP210_AT_LTE9X07_KEYS_POLL_INTERVAL)

#define AP210_AT_LTE9X07_MAC0_OFFSET	0x1000

static struct gpio_led ap210_at_lte9x07_leds_gpio[] __initdata = {
	{
		.name		= "lte9x07:green:status",
		.gpio		= AP210_AT_LTE9X07_GPIO_LED_STATUS,
		.active_low	= 1,
	},
};

static struct gpio_keys_button ap210_at_lte9x07_gpio_keys[] __initdata = {
	{
		.desc		= "reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = AP210_AT_LTE9X07_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= AP210_AT_LTE9X07_GPIO_BTN_RESET,
		.active_low	= 1,
	},
};

static void __init ap210_at_lte9x07_setup(void)
{
	u8 *art = (u8 *)KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(ap210_at_lte9x07_leds_gpio),
				 ap210_at_lte9x07_leds_gpio);

	ath79_register_gpio_keys_polled(-1, AP210_AT_LTE9X07_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(ap210_at_lte9x07_gpio_keys),
					ap210_at_lte9x07_gpio_keys);

	ath79_setup_ar933x_phy4_switch(false, false);

	ath79_register_mdio(0, 0x0);

	ath79_switch_data.phy4_mii_en = 1;
	ath79_switch_data.phy_poll_mask |= BIT(4);

	/* LAN */
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_init_mac(ath79_eth1_data.mac_addr, art + 406, 0);
	ath79_register_eth(1);

	/* WAN */
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_eth0_data.speed = SPEED_100;
	ath79_init_mac(ath79_eth0_data.mac_addr, art + 400, 0);
	ath79_register_eth(0);

	ath79_register_wmac(art + AP210_AT_LTE9X07_MAC0_OFFSET, NULL);
	ath79_register_pci();
	
	ath79_register_usb();
}

MIPS_MACHINE(ATH79_MACH_AP210_AT_LTE9X07, "AP210-AT-LTE9X07", "AP210-AT-LTE9X07", ap210_at_lte9x07_setup);
