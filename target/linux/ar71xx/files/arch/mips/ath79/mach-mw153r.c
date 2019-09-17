/*
 *  MERCURY MW153R board support ar9331 
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>

#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define MW153R_GPIO_BTN_RESET	11
#define MW153R_GPIO_BTN_WPS	26

#define MW153R_GPIO_LED_WLAN	0
#define MW153R_GPIO_LED_QSS	1
#define MW153R_GPIO_LED_WAN	13
#define MW153R_GPIO_LED_LAN1	14
#define MW153R_GPIO_LED_LAN2	15
#define MW153R_GPIO_LED_LAN3	16
#define MW153R_GPIO_LED_LAN4	17
#define MW153R_GPIO_LED_SYSTEM	27

#define MW153R_KEYS_POLL_INTERVAL	20	/* msecs */
#define MW153R_KEYS_DEBOUNCE_INTERVAL (3 * MW153R_KEYS_POLL_INTERVAL)

static const char *mw153r_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data mw153r_flash_data = {
	.part_probes	= mw153r_part_probes,
};

static struct gpio_led mw153r_leds_gpio[] __initdata = {
	{
		.name		= "mw153r:green:lan1",
		.gpio		= MW153R_GPIO_LED_LAN1,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan2",
		.gpio		= MW153R_GPIO_LED_LAN2,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan3",
		.gpio		= MW153R_GPIO_LED_LAN3,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan4",
		.gpio		= MW153R_GPIO_LED_LAN4,
		.active_low	= 1,
	}, {
		.name		= "mw153r:green:system",
		.gpio		= MW153R_GPIO_LED_SYSTEM,
		.active_low	= 1,
	}, {
		.name		= "mw153r:green:wan",
		.gpio		= MW153R_GPIO_LED_WAN,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:wlan",
		.gpio		= MW153R_GPIO_LED_WLAN,
		.active_low	= 0,
	},{
		.name		= "mw153r:green:qss",
		.gpio		= MW153R_GPIO_LED_QSS,
		.active_low	= 0,
	},
};

static struct gpio_keys_button mw153r_gpio_keys[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = MW153R_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= MW153R_GPIO_BTN_RESET,
		.active_low	= 0,
	}, {
		.desc		= "WPS",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = MW153R_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= MW153R_GPIO_BTN_WPS,
		.active_low	= 0,
	}
};

static void __init mw153r_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	ath79_setup_ar933x_phy4_switch(true, true);

	ath79_gpio_function_disable(AR933X_GPIO_FUNC_ETH_SWITCH_LED0_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED1_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED2_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED3_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED4_EN);

	ath79_register_m25p80(&mw153r_flash_data);
	ath79_init_mac(ath79_eth0_data.mac_addr, mac, 1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, -1);

	ath79_register_mdio(0, 0x0);
	ath79_register_eth(1);
	ath79_register_eth(0);

	ath79_register_wmac(ee, mac);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(mw153r_leds_gpio) - 1,
				 mw153r_leds_gpio);
	ath79_register_gpio_keys_polled(1, MW153R_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(mw153r_gpio_keys),
					mw153r_gpio_keys);
}

MIPS_MACHINE(ATH79_MACH_MW153R, "MW153R",
	     "MERCURY MW153R", mw153r_setup);
