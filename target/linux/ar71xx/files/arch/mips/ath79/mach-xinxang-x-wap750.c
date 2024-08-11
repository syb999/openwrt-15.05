/*
 *  XinXang X-WAP750 Panel AP support
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

#define X_WAP750_GPIO_LED_STATUS	13

#define X_WAP750_GPIO_BTN_RESET	17

#define X_WAP750_KEYS_POLL_INTERVAL	20	/* msecs */
#define X_WAP750_KEYS_DEBOUNCE_INTERVAL	(3 * X_WAP750_KEYS_POLL_INTERVAL)

#define X_WAP750_MAC0_OFFSET	0x1000

static struct gpio_led x_wap750_leds_gpio[] __initdata = {
	{
		.name		= "x-wap750:green:status",
		.gpio		= X_WAP750_GPIO_LED_STATUS,
		.active_low	= 1,
	},
};

static struct gpio_keys_button x_wap750_gpio_keys[] __initdata = {
	{
		.desc		= "reset button",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = X_WAP750_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= X_WAP750_GPIO_BTN_RESET,
		.active_low	= 1,
	}
};

static void __init x_wap750_setup(void)
{
	u8 *art = (u8 *)KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(x_wap750_leds_gpio),
				 x_wap750_leds_gpio);

	ath79_register_gpio_keys_polled(-1, X_WAP750_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(x_wap750_gpio_keys),
					x_wap750_gpio_keys);

	ath79_setup_ar933x_phy4_switch(false, false);

	ath79_register_mdio(0, 0x0);

	ath79_switch_data.phy4_mii_en = 1;
	ath79_switch_data.phy_poll_mask |= BIT(4);

	/* LAN */
	ath79_eth1_data.duplex = DUPLEX_FULL;
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_init_mac(ath79_eth1_data.mac_addr, art + 6, 0);
	ath79_register_eth(1);

	/* WAN */
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_eth0_data.speed = SPEED_100;
	ath79_init_mac(ath79_eth0_data.mac_addr, art, 0);
	ath79_register_eth(0);

	ath79_register_wmac(art + X_WAP750_MAC0_OFFSET, NULL);
	ath79_register_pci();
}

MIPS_MACHINE(ATH79_MACH_XINXANG_X_WAP750, "XINXANG-X-WAP750", "XinXanG X-WAP750", x_wap750_setup);
