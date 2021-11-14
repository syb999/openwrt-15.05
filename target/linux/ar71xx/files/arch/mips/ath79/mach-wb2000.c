/*
 *  Winchannel WB2000 board support
 *
 *  Copyright (C) 2012 Gabor Juhos <juhosg@openwrt.org>
 *  Copyright (C) 2013 Gui Iribarren <gui@altermundi.net>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/pci.h>
#include <linux/phy.h>
#include <linux/gpio.h>
#include <linux/platform_device.h>
#include <linux/delay.h>
#include <linux/ath9k_platform.h>
#include <linux/ar8216_platform.h>
#include <linux/platform_data/phy-at803x.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>
#include "common.h"
#include "dev-audio.h"
#include "dev-ap9x-pci.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define WB2000_GPIO_I2S_SD		0
#define WB2000_GPIO_I2S_CLK	1
#define WB2000_GPIO_I2S_WS		2
//#define WB2000_GPIO_SPDIF_OUT	4

#define AUDIO_RELAY                 4  /* relay1*/
#define WB2000_GPIO_LED_USB		21
#define WB2000_GPIO_LED_WLAN2G		20
#define WB2000_GPIO_LED_SYSTEM		22

#define WB2000_GPIO_BTN_RESET		3
#define WB2000_GPIO_BTN_0  		16  /* play or stop */
#define WB2000_GPIO_BTN_1  		17  /* volume+ or volume- */
#define WB2000_GPIO_BTN_2  		15  

#define WB2000_KEYS_POLL_INTERVAL	20	/* msecs */
#define WB2000_KEYS_DEBOUNCE_INTERVAL	(3 * WB2000_KEYS_POLL_INTERVAL)

#define WB2000_MAC0_OFFSET		0
#define WB2000_MAC1_OFFSET		6
#define WB2000_WMAC_CALDATA_OFFSET	0x1000
#define WB2000_PCIE_CALDATA_OFFSET	0x5000

static const char *wb2000_part_probes[] = {
	"tp-link",
	NULL,
};

static struct platform_device wb2000_internal_codec = {
	.name		= "ath79-internal-codec",
	.id		= -1,
};

static struct platform_device wb2000_spdif_codec = {
	.name		= "ak4430-codec",
	.id		= -1,
};

static struct at803x_platform_data mi124_ar8035_data = {
    .enable_rgmii_rx_delay = 1,
    .fixup_rgmii_tx_delay = 1,
    };

static struct mdio_board_info mi124_mdio0_info[] = {
    {
    .bus_id = "ag71xx-mdio.0",
    .phy_addr = 4,
    .platform_data = &mi124_ar8035_data,
    },
};

static struct flash_platform_data wb2000_flash_data = {
	.part_probes	= wb2000_part_probes,
    };

static struct gpio_led wb2000_leds_gpio[] __initdata = {
	{
		.name		= "tp-link:green:system",
		.gpio		= WB2000_GPIO_LED_SYSTEM,
		.active_low	= 1,
	},
	{
		.name		= "tp-link:green:usb",
		.gpio		= WB2000_GPIO_LED_USB,
		.active_low	= 0,
	},
	{
		.name		= "tp-link:green:wlan2g",
		.gpio		= WB2000_GPIO_LED_WLAN2G,
		.active_low	= 0,
	},{
		.name		= "tp-link:relay:audio",
		.gpio		= AUDIO_RELAY,
		.active_low	= 0,
	},
};

static void __init wb2000_audio_setup(void)
{
	u32 t;

	/* Reset I2S internal controller */
	t = ath79_reset_rr(AR71XX_RESET_REG_RESET_MODULE);
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t | AR934X_RESET_I2S );
	udelay(1);

	/* GPIO configuration
	   GPIOs 4,11,12,13 are configured as I2S signal - Output
	   GPIO 15 is SPDIF - Output
	   GPIO 14 is MIC - Input
	   Please note that the value in direction_output doesn't really matter
	   here as GPIOs are configured to relay internal data signal
	*/
	gpio_request(WB2000_GPIO_I2S_CLK, "I2S CLK");
	ath79_gpio_output_select(WB2000_GPIO_I2S_CLK, AR934X_GPIO_OUT_MUX_I2S_CLK);
	gpio_direction_output(WB2000_GPIO_I2S_CLK, 0);

	gpio_request(WB2000_GPIO_I2S_WS, "I2S WS");
	ath79_gpio_output_select(WB2000_GPIO_I2S_WS, AR934X_GPIO_OUT_MUX_I2S_WS);
	gpio_direction_output(WB2000_GPIO_I2S_WS, 0);

	gpio_request(WB2000_GPIO_I2S_SD, "I2S SD");
	ath79_gpio_output_select(WB2000_GPIO_I2S_SD, AR934X_GPIO_OUT_MUX_I2S_SD);
	gpio_direction_output(WB2000_GPIO_I2S_SD, 0);

	//gpio_request(WB2000_GPIO_SPDIF_OUT, "SPDIF OUT");
	//ath79_gpio_output_select(WB2000_GPIO_SPDIF_OUT, AR934X_GPIO_OUT_MUX_SPDIF_OUT);
	//gpio_direction_output(WB2000_GPIO_SPDIF_OUT, 0);

	/* Init stereo block registers in default configuration */
	ath79_audio_setup();
}

static struct gpio_keys_button wb2000_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = WB2000_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= WB2000_GPIO_BTN_RESET,
		.active_low	= 1,
	},
	{
		.desc		= "PLAY button",
		.type		= EV_SW,
		.code		= BTN_0,
		.debounce_interval = WB2000_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= WB2000_GPIO_BTN_0,
        .active_low	= 1,
	},
    {
		.desc		= "VOL+ button",
		.type		= EV_SW,
		.code		= BTN_1,
		.debounce_interval = WB2000_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= WB2000_GPIO_BTN_1,
        .active_low	= 1,
	},
    {
		.desc		= "VOL- button",
		.type		= EV_SW,
		.code		= BTN_2,
		.debounce_interval = WB2000_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= WB2000_GPIO_BTN_2,
        .active_low	= 1,
	},
};


static void __init wb2000_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);
	u8 tmpmac[ETH_ALEN];

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(&wb2000_flash_data);
	ath79_register_leds_gpio(-1, ARRAY_SIZE(wb2000_leds_gpio),
				 wb2000_leds_gpio);
	ath79_register_gpio_keys_polled(-1, WB2000_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(wb2000_gpio_keys),
					wb2000_gpio_keys);

	ath79_init_mac(ath79_eth0_data.mac_addr, art + WB2000_MAC0_OFFSET, -1);

	ath79_init_mac(tmpmac, mac, 0);
	ath79_register_wmac(art + WB2000_WMAC_CALDATA_OFFSET, tmpmac);

	ath79_init_mac(tmpmac, mac, 1);
	ap9x_pci_setup_wmac_led_pin(0, 0);
	ap91_pci_init(art + WB2000_PCIE_CALDATA_OFFSET, tmpmac);

    ath79_register_mdio(0, 0x0);

    mdiobus_register_board_info(mi124_mdio0_info, ARRAY_SIZE(mi124_mdio0_info));

    ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_RGMII_GMAC0);

    /* GMAC0 is connected to an AR8035 Gigabit PHY */
    ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_RGMII;
    ath79_eth0_data.phy_mask = BIT(4);
    ath79_eth0_data.mii_bus_dev = &ath79_mdio0_device.dev;
    ath79_eth0_pll_data.pll_1000 = 0x0e000000;
    ath79_eth0_pll_data.pll_100 = 0x0101;
    ath79_eth0_pll_data.pll_10 = 0x1313;
    ath79_register_eth(0);

	ath79_register_usb();

    /* Audio initialization: PCM/I2S and CODEC */
	wb2000_audio_setup();
	platform_device_register(&wb2000_spdif_codec);
    platform_device_register(&wb2000_internal_codec);
	ath79_audio_device_register();
}

MIPS_MACHINE(ATH79_MACH_WB2000, "WB2000",
	     "WB2000",
	     wb2000_setup);

