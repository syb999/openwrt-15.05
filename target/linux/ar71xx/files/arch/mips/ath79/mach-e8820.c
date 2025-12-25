/*
 *  ZTE E8820 support
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
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"
#include "pci.h"

#define E8820_GPIO_LED_SYSTEM	1
#define E8820_GPIO_LED_WLAN2G	19

#define E8820_GPIO_BTN_RESET	2

#define E8820_KEYS_POLL_INTERVAL	20	/* msecs */
#define E8820_KEYS_DEBOUNCE_INTERVAL	(3 * E8820_KEYS_POLL_INTERVAL)

#define E8820_MAC0_OFFSET               0
#define E8820_WMAC_CALDATA_OFFSET       0x1000


static struct gpio_led e8820_leds_gpio[] __initdata = {
	{
		.name		= "e8820:green:system",
		.gpio		= E8820_GPIO_LED_SYSTEM,
		.active_low	= 1,
	},
	{
		.name		= "e8820:green:wlan2g",
		.gpio		= E8820_GPIO_LED_WLAN2G,
		.active_low	= 1,
	},
};

static struct gpio_keys_button e8820_gpio_keys[] __initdata = {
	{
		.desc		= "reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = E8820_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= E8820_GPIO_BTN_RESET,
		.active_low	= 1,
	},
};

static const struct ar8327_led_info e8820_leds_qca8337[] = {
	AR8327_LED_INFO(PHY0_0, HW, "e8820:green:lan1"),
	AR8327_LED_INFO(PHY1_0, HW, "e8820:green:lan2"),
	AR8327_LED_INFO(PHY2_0, HW, "e8820:green:lan3"),
	AR8327_LED_INFO(PHY3_0, HW, "e8820:green:lan4"),
	AR8327_LED_INFO(PHY4_0, HW, "e8820:green:wan"),
};

static struct ar8327_led_cfg e8820_qca8337_led_cfg = {
	.led_ctrl0 = 0xcf37cf37,
	.led_ctrl1 = 0xcf37cf37,
	.led_ctrl2 = 0xcf37cf37,
	.led_ctrl3 = 0x0,
	.open_drain = true,
};

static struct ar8327_pad_cfg e8820_ar8337_pad0_cfg = {
	.mode = AR8327_PAD_MAC_SGMII,
	.sgmii_delay_en = true,
};

static struct ar8327_platform_data e8820_ar8337_data = {
	.pad0_cfg = &e8820_ar8337_pad0_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
	.led_cfg = &e8820_qca8337_led_cfg,
};

static struct mdio_board_info e8820_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &e8820_ar8337_data,
	},
};

static void __init e8820_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	e8820_qca8337_data.leds = e8820_leds_qca8337;
	e8820_qca8337_data.num_leds = ARRAY_SIZE(e8820_leds_qca8337);


	ath79_register_leds_gpio(-1, ARRAY_SIZE(e8820_leds_gpio),
				 e8820_leds_gpio);
	ath79_register_gpio_keys_polled(-1, E8820_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(e8820_gpio_keys),
					e8820_gpio_keys);

	ath79_register_usb();

	platform_device_register(&ath79_mdio0_device);

	mdiobus_register_board_info(e8820_mdio0_info,
				    ARRAY_SIZE(e8820_mdio0_info));

	ath79_register_wmac(art + E8820_WMAC_CALDATA_OFFSET, NULL);
	ath79_register_pci();

	ath79_init_mac(ath79_eth0_data.mac_addr, art + E8820_MAC0_OFFSET, 0);

	/* GMAC0 is connected to an AR8337 switch */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth0_data.speed = SPEED_1000;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

	ath79_register_eth(0);
}

MIPS_MACHINE(ATH79_MACH_ZTE_E8820, "ZTE-E8820", "ZTE E8820", e8820_setup);
