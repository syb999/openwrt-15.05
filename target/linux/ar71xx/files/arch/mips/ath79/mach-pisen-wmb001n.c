/*
 *  PISEN_WMB001N board support
 *
 *  Copyright (C) 2012 Gabor Juhos <juhosg@openwrt.org>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/gpio.h>
#include <linux/delay.h>
#include <asm/mach-ath79/ar71xx_regs.h>
#include <asm/mach-ath79/ath79.h>
#include "common.h"
#include "dev-audio.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-spi.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "machtypes.h"

#define PISEN_WMB001N_GPIO_I2S_SD		11
#define PISEN_WMB001N_GPIO_I2S_WS		12
#define PISEN_WMB001N_GPIO_I2S_CLK		13
#define PISEN_WMB001N_GPIO_I2S_MCLK		14
#define PISEN_WMB001N_GPIO_SPDIF_OUT	15
#define PISEN_WMB001N_GPIO_I2S_MIC_SD   16
#define PISEN_WMB001N_GPIO_LED_WLAN     4

#define PISEN_WMB001N_GPIO_BTN_RESET	17
#define PISEN_WMB001N_GPIO_SW_RFKILL	18

#define PISEN_WMB001N_KEYS_POLL_INTERVAL	20	/* msecs */
#define PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL (3 * PISEN_WMB001N_KEYS_POLL_INTERVAL)

static const char *pisen_wmb001n_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data pisen_wmb001n_flash_data = {
	.part_probes	= pisen_wmb001n_part_probes,
};

static struct platform_device pisen_wmb001n_internal_codec = {
	.name		= "ath79-internal-codec",
	.id		= -1,
};

static struct platform_device pisen_wmb001n_spdif_codec = {
	.name		= "ak4430-codec",
	.id		= -1,
};

static struct gpio_led pisen_wmb001n_leds_gpio[] __initdata = {
	 {
		.name		= "tp-link:green:wlan",
		.gpio		= PISEN_WMB001N_GPIO_LED_WLAN,
		.active_low	= 1,
	}, 
};

static struct gpio_keys_button pisen_wmb001n_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMB001N_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "RFKILL switch",
		.type		= EV_SW,
		.code		= KEY_RFKILL,
		.debounce_interval = PISEN_WMB001N_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= PISEN_WMB001N_GPIO_SW_RFKILL,
		.active_low	= 0,
	}
};

static void __init pisen_wmb001n_audio_setup(void)
{
	u32 t;

	/* Reset I2S internal controller */
	t = ath79_reset_rr(AR71XX_RESET_REG_RESET_MODULE);
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t | AR934X_RESET_I2S );
	udelay(1);

	/* GPIO configuration
	   GPIOs 11,12,13,14 are configured as I2S signal - Output
	   GPIO 16 is MIC - Input
	   GPIO 18 is SPDIF - Output
	   Please note that the value in direction_output doesn't really matter
	   here as GPIOs are configured to relay internal data signal
	*/
	gpio_request(PISEN_WMB001N_GPIO_I2S_CLK, "I2S CLK");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_CLK, AR934X_GPIO_OUT_MUX_I2S_CLK);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_CLK, 0);

	gpio_request(PISEN_WMB001N_GPIO_I2S_WS, "I2S WS");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_WS, AR934X_GPIO_OUT_MUX_I2S_WS);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_WS, 0);

	gpio_request(PISEN_WMB001N_GPIO_I2S_SD, "I2S SD");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_SD, AR934X_GPIO_OUT_MUX_I2S_SD);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_SD, 0);

	gpio_request(PISEN_WMB001N_GPIO_I2S_MCLK, "I2S MCLK");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_I2S_MCLK, AR934X_GPIO_OUT_MUX_I2S_MCK);
	gpio_direction_output(PISEN_WMB001N_GPIO_I2S_MCLK, 0);

	gpio_request(PISEN_WMB001N_GPIO_SPDIF_OUT, "SPDIF OUT");
	ath79_gpio_output_select(PISEN_WMB001N_GPIO_SPDIF_OUT, AR934X_GPIO_OUT_MUX_SPDIF_OUT);
	gpio_direction_output(PISEN_WMB001N_GPIO_SPDIF_OUT, 0);

	gpio_request(PISEN_WMB001N_GPIO_I2S_MIC_SD, "I2S MIC_SD");
	ath79_gpio_input_select(PISEN_WMB001N_GPIO_I2S_MIC_SD, AR934X_GPIO_IN_MUX_I2S_MIC_SD);
	gpio_direction_input(PISEN_WMB001N_GPIO_I2S_MIC_SD);

	/* Init stereo block registers in default configuration */
	ath79_audio_setup();
}

static void __init tl_ap123_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(&pisen_wmb001n_flash_data);

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_SW_ONLY_MODE);

	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth0_data.mac_addr, mac, -1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, 0);

	/* GMAC0 is connected to the PHY0 of the internal switch */
	ath79_switch_data.phy4_mii_en = 1;
	ath79_switch_data.phy_poll_mask = BIT(4);
	ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
	ath79_eth0_data.phy_mask = BIT(4);
	ath79_eth0_data.mii_bus_dev = &ath79_mdio1_device.dev;
	ath79_register_eth(0);

	/* GMAC1 is connected to the internal switch */
	ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
	ath79_register_eth(1);

	ath79_register_wmac(ee, mac);
}

static void __init pisen_wmb001n_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(pisen_wmb001n_leds_gpio) - 1,
				 pisen_wmb001n_leds_gpio);

	ath79_register_gpio_keys_polled(1, PISEN_WMB001N_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(pisen_wmb001n_gpio_keys),
					pisen_wmb001n_gpio_keys);
	ath79_register_usb();
		/* Audio initialization: PCM/I2S and CODEC */
	pisen_wmb001n_audio_setup();
	platform_device_register(&pisen_wmb001n_spdif_codec);
	platform_device_register(&pisen_wmb001n_internal_codec);
	ath79_audio_device_register();
}

MIPS_MACHINE(ATH79_MACH_PISEN_WMB001N, "PISEN_WMB001N", "PISEN_WMB001N",
	     pisen_wmb001n_setup);
