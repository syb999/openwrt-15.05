/*
 *  PISEN WMM003N board support
 *
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

#define PISEN_WMM003N_GPIO_BTN_RESET	12

#define PISEN_WMM003N_GPIO_LED_WLAN	0

#define PISEN_WMM003N_KEYS_POLL_INTERVAL	20	/* msecs */
#define PISEN_WMM003N_KEYS_DEBOUNCE_INTERVAL (3 * PISEN_WMM003N_KEYS_POLL_INTERVAL)

static const char *pisen_wmm003n_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data pisen_wmm003n_flash_data = {
	.part_probes	= pisen_wmm003n_part_probes,
};

static struct gpio_led pisen_wmm003n_leds_gpio[] __initdata = {
	{
		.name		= "pisen:blue:wlan",
		.gpio		= PISEN_WMM003N_GPIO_LED_WLAN,
		.active_low	= 0,
	},
};

static struct gpio_keys_button pisen_wmm003n_gpio_keys[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = PISEN_WMM003N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMM003N_GPIO_BTN_RESET,
		.active_low	= 0,
	}
};

static void __init pisen_wmm003n_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	ath79_setup_ar933x_phy4_switch(true, true);

	ath79_gpio_function_disable(AR933X_GPIO_FUNC_ETH_SWITCH_LED0_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED1_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED2_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED3_EN |
				    AR933X_GPIO_FUNC_ETH_SWITCH_LED4_EN);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(pisen_wmm003n_leds_gpio),
				 pisen_wmm003n_leds_gpio);
	ath79_register_gpio_keys_polled(1, PISEN_WMM003N_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(pisen_wmm003n_gpio_keys),
					pisen_wmm003n_gpio_keys);

	ath79_register_m25p80(&pisen_wmm003n_flash_data);
	ath79_init_mac(ath79_eth0_data.mac_addr, mac, 1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, -1);

	ath79_register_mdio(0, 0x0);
	ath79_register_eth(1);
	ath79_register_eth(0);

	ath79_register_wmac(ee, mac);

	ath79_register_usb();
}

MIPS_MACHINE(ATH79_MACH_PISEN_WMM003N, "PISEN-WMM003N",
	     "PISEN WMM003N", pisen_wmm003n_setup);
