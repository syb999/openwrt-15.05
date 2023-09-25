/*
 *  PHICOMM FAP-022WLD panel AP board support
 *
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>
#include <linux/platform_device.h>

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

#define FAP_022WLD_GPIO_LED_POWER	11
#define FAP_022WLD_GPIO_LED_WIFI	13
#define FAP_022WLD_GPIO_LED_WAN		19

#define FAP_022WLD_GPIO_BTN_RESET	17

#define FAP_022WLD_KEYS_POLL_INTERVAL	20	/* msecs */
#define FAP_022WLD_KEYS_DEBOUNCE_INTERVAL (3 * FAP_022WLD_KEYS_POLL_INTERVAL)

static const char *fap_022wld_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data fap_022wld_flash_data = {
	.part_probes	= fap_022wld_part_probes,
};

static struct gpio_led fap_022wld_leds_gpio[] __initdata = {
	{
		.name		= "fap:green:power",
		.gpio		= FAP_022WLD_GPIO_LED_POWER,
		.active_low	= 1,
	}, {
		.name		= "fap:green:wan",
		.gpio		= FAP_022WLD_GPIO_LED_WAN,
		.active_low	= 1,
	}, {
		.name		= "fap:green:wifi",
		.gpio		= FAP_022WLD_GPIO_LED_WIFI,
		.active_low	= 1,
	}, 
};

static struct gpio_keys_button fap_022wld_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = FAP_022WLD_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= FAP_022WLD_GPIO_BTN_RESET,
		.active_low	= 1,
	}
};

static void __init tl_ap123_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(&fap_022wld_flash_data);

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_SW_PHY_SWAP);

	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, mac, -1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, 0);

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

	ath79_register_wmac(ee, mac);
}

static void __init fap_022wld_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(fap_022wld_leds_gpio) - 1,
				 fap_022wld_leds_gpio);

	ath79_register_gpio_keys_polled(1, FAP_022WLD_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(fap_022wld_gpio_keys),
					fap_022wld_gpio_keys);

}

MIPS_MACHINE(ATH79_MACH_FAP_022WLD, "FAP-022WLD", "PHICOMM FAP-022WLD",
	     fap_022wld_setup);
