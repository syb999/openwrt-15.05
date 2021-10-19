/*
 *  Audio_MW300R4 board support
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

#define TL_WR841NV8_GPIO_I2S_SD         0	/* I2S SDO signal for AR934X  */
#define TL_WR841NV8_GPIO_I2S_CLK        1	/* I2S SCLK signal for AR934X */
#define TL_WR841NV8_GPIO_I2S_WS         2	/* I2S LRCK signal for AR934X */
#define TL_WR841NV8_GPIO_I2S_MCLK       3	/* I2S MCLK signal for AR934X */

#define TL_WR841NV8_GPIO_LED_SYSTEM     14
#define TL_WR841NV8_GPIO_LED_WLAN       13

#define TL_WR841NV8_GPIO_BTN_RESET      17
#define TL_WR841NV8_GPIO_SW_RFKILL      20

#define TL_MR3420V2_GPIO_LED_3G	11
#define TL_MR3420V2_GPIO_USB_POWER      4

#define TL_WR941NDV5_GPIO_LED_WLAN      22
#define TL_WR941NDV5_GPIO_LED_SYSTEM    4

#define TL_WR841NV8_KEYS_POLL_INTERVAL	20	/* msecs */
#define TL_WR841NV8_KEYS_DEBOUNCE_INTERVAL (3 * TL_WR841NV8_KEYS_POLL_INTERVAL)

static const char *tl_wr841n_v8_part_probes[] = {
	"tp-link",
	NULL,
};

static struct flash_platform_data tl_wr841n_v8_flash_data = {
	.part_probes	= tl_wr841n_v8_part_probes,
};

static struct platform_device tl_wr841n_v8_internal_codec = {
	.name		= "ath79-internal-codec",
	.id		= -1,
};

static struct platform_device tl_wr841n_v8_spdif_codec = {
	.name		= "ak4430-codec",
	.id		= -1,
};

static struct gpio_led tl_wr841n_v8_leds_gpio[] __initdata = {
	{, {
		.name		= "tp-link:green:system",
		.gpio		= TL_WR841NV8_GPIO_LED_SYSTEM,
		.active_low	= 1,
	}, {
		.name		= "tp-link:green:wlan",
		.gpio		= TL_WR841NV8_GPIO_LED_WLAN,
		.active_low	= 1,
	},
};


static struct gpio_led tl_wr941nd_v5_leds_gpio[] __initdata = {
	{
		.name		= "tp-link:green:system",
		.gpio		= TL_WR941NDV5_GPIO_LED_SYSTEM,
		.active_low	= 1,
	}, {
		.name		= "tp-link:green:wlan",
		.gpio		= TL_WR941NDV5_GPIO_LED_WLAN,
		.active_low	= 1,
	},
};

static struct gpio_keys_button tl_wr841n_v8_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = TL_WR841NV8_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= TL_WR841NV8_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "RFKILL switch",
		.type		= EV_SW,
		.code		= KEY_RFKILL,
		.debounce_interval = TL_WR841NV8_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= TL_WR841NV8_GPIO_SW_RFKILL,
		.active_low	= 0,
	}
};

static struct gpio_keys_button tl_mr3420v2_gpio_keys[] __initdata = {
	{
		.desc		= "Reset button",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = TL_WR841NV8_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= TL_WR841NV8_GPIO_BTN_RESET,
		.active_low	= 1,
	}, {
		.desc		= "WPS",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = TL_WR841NV8_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= TL_WR841NV8_GPIO_SW_RFKILL,
		.active_low	= 0,
	}
};

static void __init tl_wr841n_v8_audio_setup(void)
{
	u32 t;

	/* Reset I2S internal controller */
	t = ath79_reset_rr(AR71XX_RESET_REG_RESET_MODULE);
	ath79_reset_wr(AR71XX_RESET_REG_RESET_MODULE, t | AR934X_RESET_I2S );
	udelay(1);

	gpio_request(TL_WR841NV8_GPIO_I2S_CLK, "I2S CLK");
	ath79_gpio_output_select(TL_WR841NV8_GPIO_I2S_CLK, AR934X_GPIO_OUT_MUX_I2S_CLK);
	gpio_direction_output(TL_WR841NV8_GPIO_I2S_CLK, 0);

	gpio_request(TL_WR841NV8_GPIO_I2S_WS, "I2S WS");
	ath79_gpio_output_select(TL_WR841NV8_GPIO_I2S_WS, AR934X_GPIO_OUT_MUX_I2S_WS);
	gpio_direction_output(TL_WR841NV8_GPIO_I2S_WS, 0);

	gpio_request(TL_WR841NV8_GPIO_I2S_SD, "I2S SD");
	ath79_gpio_output_select(TL_WR841NV8_GPIO_I2S_SD, AR934X_GPIO_OUT_MUX_I2S_SD);
	gpio_direction_output(TL_WR841NV8_GPIO_I2S_SD, 0);

	gpio_request(TL_WR841NV8_GPIO_I2S_MCLK, "I2S MCLK");
	ath79_gpio_output_select(TL_WR841NV8_GPIO_I2S_MCLK, AR934X_GPIO_OUT_MUX_I2S_MCK);
	gpio_direction_output(TL_WR841NV8_GPIO_I2S_MCLK, 0);


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

	ath79_register_m25p80(&tl_wr841n_v8_flash_data);

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

    ath79_register_usb();
	platform_device_register(&tl_wr841n_v8_spdif_codec);
	platform_device_register(&tl_wr841n_v8_internal_codec);
	ath79_audio_device_register();
	tl_wr841n_v8_audio_setup();
}

static void __init tl_wr841n_v8_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(tl_wr841n_v8_leds_gpio) - 1,
				 tl_wr841n_v8_leds_gpio);

	ath79_register_gpio_keys_polled(1, TL_WR841NV8_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(tl_wr841n_v8_gpio_keys),
					tl_wr841n_v8_gpio_keys);
}

MIPS_MACHINE(ATH79_MACH_TL_WR841N_V8, "TL-WR841N-v8", "Audio_MW300R4",
	     tl_wr841n_v8_setup);


static void __init tl_wr842n_v2_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(tl_wr841n_v8_leds_gpio),
				 tl_wr841n_v8_leds_gpio);

	ath79_register_gpio_keys_polled(1, TL_WR841NV8_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(tl_wr841n_v8_gpio_keys),
					tl_wr841n_v8_gpio_keys);
}

MIPS_MACHINE(ATH79_MACH_TL_WR842N_V2, "TL-WR842N-v2", "TP-LINK TL-WR842N/ND v2",
	     tl_wr842n_v2_setup);

static void __init tl_mr3420v2_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(tl_wr841n_v8_leds_gpio),
				tl_wr841n_v8_leds_gpio);

	ath79_register_gpio_keys_polled(1, TL_WR841NV8_KEYS_POLL_INTERVAL,
				ARRAY_SIZE(tl_mr3420v2_gpio_keys),
				tl_mr3420v2_gpio_keys);

	/* enable power for the USB port */
	gpio_request_one(TL_MR3420V2_GPIO_USB_POWER,
			 GPIOF_OUT_INIT_HIGH | GPIOF_EXPORT_DIR_FIXED,
			 "USB power");
}

MIPS_MACHINE(ATH79_MACH_TL_MR3420_V2, "TL-MR3420-v2", "TP-LINK TL-MR3420 v2",
	     tl_mr3420v2_setup);


static void __init tl_wr941nd_v5_setup(void)
{
	tl_ap123_setup();

	ath79_register_leds_gpio(-1, ARRAY_SIZE(tl_wr941nd_v5_leds_gpio),
				 tl_wr941nd_v5_leds_gpio);

	ath79_register_gpio_keys_polled(1, TL_WR841NV8_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(tl_wr841n_v8_gpio_keys),
					tl_wr841n_v8_gpio_keys);
}

MIPS_MACHINE(ATH79_MACH_TL_WR941ND_V5, "TL-WR941ND-v5", "PISEN_WMB001N",
	     tl_wr941nd_v5_setup);

