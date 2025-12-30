/*
 *  uRouter Plus board support
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 *
 *   I2S_SD   = R105(RIGHT)  GPIO 2
 *   I2S_CLK  = R123(LEFT)   GPIO 4
 *   I2S_WS   = R121(LEFT)   GPIO 18
 *
 *   C48(green)      = 3.3V
 *   C48(white)    = GND
 *
 *   MAX98357A I2S AUDIO CODEC:
 *   LRC   = I2S_WS
 *   BCLK = I2S_CLK
 *   DIN  = I2S_SD
 *   NO MCLK!
 *
 *   GND  = GND
 *   Vin  = 3.3V
 *
 */

#include <linux/platform_device.h>
#include <linux/ath9k_platform.h>
#include <linux/gpio.h>
#include <linux/delay.h>
#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>

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


#define WAP2600_211_PE_GPIO_I2S_SD         2	/* I2S SDO signal for AR934X  */
#define WAP2600_211_PE_GPIO_I2S_CLK        4	/* I2S SCLK signal for AR934X */
#define WAP2600_211_PE_GPIO_I2S_WS         18	/* I2S LRCK signal for AR934X */

#define WAP2600_211_PE_GPIO_BTN_RESET	20

#define WAP2600_211_PE_KEYS_POLL_INTERVAL	20	/* msecs */
#define WAP2600_211_PE_KEYS_DEBOUNCE_INTERVAL (3 * WAP2600_211_PE_KEYS_POLL_INTERVAL)

#define WAP2600_211_PE_MAC0_OFFSET   0
#define WAP2600_211_PE_WMAC_CALDATA_OFFSET   0x1000

static const char *wap2600_211_pe_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data wap2600_211_pe_flash_data = {
	.part_probes	= wap2600_211_pe_part_probes,
};

static struct platform_device wap2600_211_pe_internal_codec = {
	.name		= "ath79-internal-codec",
	.id		= -1,
};

static struct platform_device wap2600_211_pe_spdif_codec = {
	.name		= "ak4430-codec",
	.id		= -1,
};

static struct gpio_keys_button wap2600_211_pe_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = WAP2600_211_PE_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= WAP2600_211_PE_GPIO_BTN_RESET,
		.active_low	= 1,
	}
};

static void __init wap2600_211_pe_audio_setup(void)
{
	u32 t;

	/* Reset I2S internal controller */
	t = ath79_reset_rr(AR71XX_RESET_REG_RESET_MODULE);
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t | AR934X_RESET_I2S );
	udelay(1);

	gpio_request(WAP2600_211_PE_GPIO_I2S_CLK, "I2S CLK");
	ath79_gpio_output_select(WAP2600_211_PE_GPIO_I2S_CLK, AR934X_GPIO_OUT_MUX_I2S_CLK);
	gpio_direction_output(WAP2600_211_PE_GPIO_I2S_CLK, 0);

	gpio_request(WAP2600_211_PE_GPIO_I2S_WS, "I2S WS");
	ath79_gpio_output_select(WAP2600_211_PE_GPIO_I2S_WS, AR934X_GPIO_OUT_MUX_I2S_WS);
	gpio_direction_output(WAP2600_211_PE_GPIO_I2S_WS, 0);

	gpio_request(WAP2600_211_PE_GPIO_I2S_SD, "I2S SD");
	ath79_gpio_output_select(WAP2600_211_PE_GPIO_I2S_SD, AR934X_GPIO_OUT_MUX_I2S_SD);
	gpio_direction_output(WAP2600_211_PE_GPIO_I2S_SD, 0);

	/* Init stereo block registers in default configuration */
	ath79_audio_setup();
}

static void __init tl_ap123_setup(void)
{
	u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);

	/* Disable JTAG, enabling GPIOs 0-3 */
	/* Configure OBS4 line, for GPIO 4*/
	ath79_gpio_function_setup(AR934X_GPIO_FUNC_JTAG_DISABLE,
				 AR934X_GPIO_FUNC_CLK_OBS4_EN);

	ath79_register_m25p80(&wap2600_211_pe_flash_data);

	ath79_setup_ar934x_eth_cfg(AR934X_ETH_CFG_SW_PHY_SWAP);

	ath79_register_mdio(1, 0x0);

	ath79_init_mac(ath79_eth1_data.mac_addr, art + WAP2600_211_PE_MAC0_OFFSET, 0);
	ath79_init_mac(ath79_eth1_data.mac_addr, art + WAP2600_211_PE_MAC0_OFFSET, 1);

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

	ath79_register_wmac(art + WAP2600_211_PE_WMAC_CALDATA_OFFSET, art);

	ath79_register_usb();
}

static void __init wap2600_211_pe_setup(void)
{
	tl_ap123_setup();

	ath79_register_gpio_keys_polled(1, WAP2600_211_PE_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(wap2600_211_pe_gpio_keys),
					wap2600_211_pe_gpio_keys);

	wap2600_211_pe_audio_setup();
	platform_device_register(&wap2600_211_pe_spdif_codec);
	platform_device_register(&wap2600_211_pe_internal_codec);
	ath79_audio_device_register();
}

MIPS_MACHINE(ATH79_MACH_WAP2600_211_PE, "WAP2600-211-PE", "WAP2600-211-PE",
	     wap2600_211_pe_setup);
