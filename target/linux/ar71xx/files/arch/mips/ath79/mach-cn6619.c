/*
 *  BaiCells CN6619 board support
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

#define CN6619_GPIO_LED_TEL	13
#define CN6619_GPIO_LED_RSSIHIGH	22
#define CN6619_GPIO_LED_RSSIMEDIUM	0
#define CN6619_GPIO_LED_RSSILOW	14
#define CN6619_GPIO_LED_LAN	15
#define CN6619_GPIO_LED_WIFI	18

#define CN6619_GPIO_BTN_RESET	17
#define CN6619_GPIO_BTN_WPS	19
#define CN6619_GPIO_BTN_BTN1	21

#define CN6619_KEYS_POLL_INTERVAL	20	/* msecs */
#define CN6619_KEYS_DEBOUNCE_INTERVAL (3 * CN6619_KEYS_POLL_INTERVAL)

static const char *cn6619_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data cn6619_flash_data = {
	.part_probes	= cn6619_part_probes,
};

static struct gpio_led cn6619_leds_gpio[] __initdata = {
	{
		.name		= "cn6619:green:tel",
		.gpio		= CN6619_GPIO_LED_TEL,
		.active_low	= 1,
	}, {
		.name		= "cn6619:green:rssihigh",
		.gpio		= CN6619_GPIO_LED_RSSIHIGH,
		.active_low	= 1,
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
		.name		= "cn6619:green:wifi",
		.gpio		= CN6619_GPIO_LED_WIFI,
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
	}, {
		.desc		= "button 1",
		.type		= EV_KEY,
		.code		= BTN_1,
		.debounce_interval = CN6619_KEYS_DEBOUNCE_INTERVAL,
		.gpio		=CN6619_GPIO_BTN_BTN1,
		.active_low	= 0,
	}, 
};

static void __init tl_ap123_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(&cn6619_flash_data);

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

MIPS_MACHINE(ATH79_MACH_CN6619, "CN6619", "CN6619",
	     cn6619_setup);
