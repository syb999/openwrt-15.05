/*
 * H3C_WTU430H board support
 *
 */

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/ar8216_platform.h>
#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-m25p80.h"
#include "machtypes.h"
#include "pci.h"
#include "dev-eth.h"
#include "dev-ap9x-pci.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-spi.h"
#include "dev-wmac.h"

#define H3C_WTU430H_GPIO_LED_SYSTEM1		7
#define H3C_WTU430H_GPIO_LED_SYSTEM2		8
#define H3C_WTU430H_GPIO_LED_WLAN		1

#define H3C_WTU430H_GPIO_BTN_RESET            2
#define H3C_WTU430H_KEYS_POLL_INTERVAL        20     /* msecs */
#define H3C_WTU430H_KEYS_DEBOUNCE_INTERVAL    (3 * H3C_WTU430H_KEYS_POLL_INTERVAL)

#define H3C_WTU430H_MAC0_OFFSET               0
#define H3C_WTU430H_WMAC_CALDATA_OFFSET       0x1000


static struct gpio_led h3c_wtu430h_leds_gpio[] __initdata = {
	{
		.name		= "wtu430h:orange:power",
		.gpio		= H3C_WTU430H_GPIO_LED_SYSTEM1,
		.active_low	= 0,
	},
	{
		.name		= "wtu430h:green:power",
		.gpio		= H3C_WTU430H_GPIO_LED_SYSTEM2,
		.active_low	= 1,
	},
	{
		.name		= "wtu430h:orange:wlan",
		.gpio		= H3C_WTU430H_GPIO_LED_WLAN,
		.active_low	= 1,
	},
};

static struct gpio_keys_button h3c_wtu430h_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = H3C_WTU430H_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= H3C_WTU430H_GPIO_BTN_RESET,
		.active_low	= 1,
	},
};

static struct ar8327_pad_cfg h3c_wtu430h_ar8337_pad0_cfg = {
	.mode = AR8327_PAD_MAC_SGMII,
	.sgmii_delay_en = true,
};

static struct ar8327_platform_data h3c_wtu430h_ar8337_data = {
	.pad0_cfg = &h3c_wtu430h_ar8337_pad0_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
};

static struct mdio_board_info h3c_wtu430h_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &h3c_wtu430h_ar8337_data,
	},
};

static void __init h3c_wtu430h_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(h3c_wtu430h_leds_gpio),
				 h3c_wtu430h_leds_gpio);
	ath79_register_gpio_keys_polled(-1, H3C_WTU430H_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(h3c_wtu430h_gpio_keys),
					h3c_wtu430h_gpio_keys);

	platform_device_register(&ath79_mdio0_device);

	mdiobus_register_board_info(h3c_wtu430h_mdio0_info,
				    ARRAY_SIZE(h3c_wtu430h_mdio0_info));

	ath79_register_wmac(art + H3C_WTU430H_WMAC_CALDATA_OFFSET, art);
	ath79_register_pci();

	ath79_init_mac(ath79_eth0_data.mac_addr, art + H3C_WTU430H_MAC0_OFFSET, 0);

	/* GMAC0 is connected to an AR8337 switch */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth0_data.speed = SPEED_1000;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

	ath79_register_eth(0);
}

MIPS_MACHINE(ATH79_MACH_H3C_WTU430H, "H3C-WTU430H", "H3C WTU430H",
	     h3c_wtu430h_setup);
