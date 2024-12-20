/*
 *  AP220 POE AP support
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/gpio.h>
#include <linux/platform_device.h>
#include <linux/ar8216_platform.h>

#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "pci.h"
#include "dev-gpio-buttons.h"
#include "dev-eth.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define AP220_GPIO_BTN_RESET	17

#define AP220_KEYS_POLL_INTERVAL	20	/* msecs */
#define AP220_KEYS_DEBOUNCE_INTERVAL (3 * AP220_KEYS_POLL_INTERVAL)

#define AP220_WAN_MAC_OFFSET	0
#define AP220_LAN_MAC_OFFSET	6
#define AP220_WMAC_CALDATA_OFFSET	0x1000
#define AP220_PCIE_CALDATA_OFFSET	0x5000

static struct gpio_keys_button ap220_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = AP220_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= AP220_GPIO_BTN_RESET,
		.active_low	= 1,
	}
};

static struct ar8327_pad_cfg ap220_ar8327_pad0_cfg = {
	/* Use the RGMII interface for the GMAC0 of the AR8337 switch */
	.mode = AR8327_PAD_MAC_RGMII,
	.txclk_delay_en = true,
	.rxclk_delay_en = true,
	.txclk_delay_sel = AR8327_CLK_DELAY_SEL1,
	.rxclk_delay_sel = AR8327_CLK_DELAY_SEL2,
	.mac06_exchange_en = true,
};

static struct ar8327_pad_cfg ap220_ar8327_pad6_cfg = {
	/* Use the SGMII interface for the GMAC6 of the AR8337 switch */
	.mode = AR8327_PAD_MAC_SGMII,
	.rxclk_delay_en = true,
	.rxclk_delay_sel = AR8327_CLK_DELAY_SEL0,
};

static struct ar8327_platform_data ap220_ar8327_data = {
	.pad0_cfg = &ap220_ar8327_pad0_cfg,
	.pad6_cfg = &ap220_ar8327_pad6_cfg,
	.port0_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
	.port6_cfg = {
		.force_link = 1,
		.speed = AR8327_PORT_SPEED_1000,
		.duplex = 1,
		.txpause = 1,
		.rxpause = 1,
	},
};

static struct mdio_board_info ap220_mdio0_info[] = {
	{
		.bus_id = "ag71xx-mdio.0",
		.phy_addr = 0,
		.platform_data = &ap220_ar8327_data,
	},
};

static void __init ap220_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	ath79_register_m25p80(NULL);

	ath79_register_gpio_keys_polled(-1, AP220_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(ap220_gpio_keys),
					ap220_gpio_keys);

	ath79_register_wmac(art + AP220_WMAC_CALDATA_OFFSET, NULL);

	ath79_register_mdio(0, 0x0);
	mdiobus_register_board_info(ap220_mdio0_info,
				    ARRAY_SIZE(ap220_mdio0_info));

	ath79_setup_qca955x_eth_cfg(QCA955X_ETH_CFG_RGMII_EN);

	ath79_init_mac(ath79_eth0_data.mac_addr,
		       art + AP220_WAN_MAC_OFFSET, 0);

	ath79_init_mac(ath79_eth1_data.mac_addr,
		       art + AP220_LAN_MAC_OFFSET, 0);

	ath79_eth0_pll_data.pll_1000 = 0xae000000;
	ath79_eth1_pll_data.pll_1000 = 0x03000101;

	/* GMAC0 is connected to the RMGII interface */
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
	ath79_eth0_data.phy_mask = BIT(0);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;

	ath79_register_eth(0);

	/* GMAC1 is connected to the SGMII interface */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_SGMII;
	ath79_eth1_data.speed = SPEED_1000;
	ath79_eth1_data.duplex = DUPLEX_FULL;

	ath79_register_eth(1);

	ath79_register_pci();

	ath79_register_usb();
}

MIPS_MACHINE(ATH79_MACH_AP220, "AP220", "AP220", ap220_setup);
