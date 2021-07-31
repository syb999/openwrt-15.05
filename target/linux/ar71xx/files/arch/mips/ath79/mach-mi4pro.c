/*
 * MI4PRO-III board support
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

#define MI4PRO_GPIO_LED_SYSTEM			7

#define MI4PRO_GPIO_BTN_RESET            2
#define MI4PRO_KEYS_POLL_INTERVAL        20     /* msecs */
#define MI4PRO_KEYS_DEBOUNCE_INTERVAL    (3 * MI4PRO_KEYS_POLL_INTERVAL)

#define MI4PRO_MAC0_OFFSET               0
#define MI4PRO_WMAC_CALDATA_OFFSET       0x1000


static struct gpio_led mi4pro_leds_gpio[] __initdata = {
	{
		.name		= "mi4pro:blue:system",
		.gpio		= MI4PRO_GPIO_LED_SYSTEM,
		.active_low	= 1,
	},
};

static struct gpio_keys_button mi4pro_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = MI4PRO_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= MI4PRO_GPIO_BTN_RESET,
		.active_low	= 1,
	},
};

static struct ar8327_pad_cfg mi4pro_ar8337_pad0_cfg = {
	.mode = AR8327_PAD_MAC_SGMII,
	.sgmii_delay_en = true,
};

static struct ar8327_platform_data mi4pro_ar8337_data = {
	.pad0_cfg = &mi4pro_ar8337_pad0_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
};

static struct mdio_board_info mi4pro_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &mi4pro_ar8337_data,
	},
};

static void __init mi4pro_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(mi4pro_leds_gpio),
				 mi4pro_leds_gpio);
	ath79_register_gpio_keys_polled(-1, MI4PRO_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(mi4pro_gpio_keys),
					mi4pro_gpio_keys);

	platform_device_register(&ath79_mdio0_device);

	mdiobus_register_board_info(mi4pro_mdio0_info,
				    ARRAY_SIZE(mi4pro_mdio0_info));

	ath79_register_wmac(art + MI4PRO_WMAC_CALDATA_OFFSET, NULL);

	ath79_register_pci();

	ath79_init_mac(ath79_eth0_data.mac_addr, art + MI4PRO_MAC0_OFFSET, 0);

	/* GMAC0 is connected to an AR8337 switch */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth0_data.speed = SPEED_1000;
	ath79_eth0_data.duplex = DUPLEX_FULL;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

	ath79_register_eth(0);
}

MIPS_MACHINE(ATH79_MACH_MI4PRO, "MI4PRO", "XiaoMi4-PRO",
	     mi4pro_setup);
