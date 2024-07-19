/*
 *  MERCURY MW153R board support ar9331 
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License version 2 as published
 *  by the Free Software Foundation.
 */

#include <linux/types.h>
#include <sound/core.h>
#include <sound/soc.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/delay.h>
#include <linux/ath9k_platform.h>

#include <linux/gpio.h>

#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-wmac.h"
#include "dev-audio.h"
#include "machtypes.h"

#define MW153R_GPIO_BTN_RESET	11
#define MW153R_GPIO_BTN_WPS	26

#define MW153R_GPIO_LED_WLAN	0
#define MW153R_GPIO_LED_QSS	1
#define MW153R_GPIO_LED_WAN	13
#define MW153R_GPIO_LED_LAN1	14
#define MW153R_GPIO_LED_LAN2	15
#define MW153R_GPIO_LED_LAN3	16
#define MW153R_GPIO_LED_LAN4	17
#define MW153R_GPIO_LED_SYSTEM	27

#define MW153R_KEYS_POLL_INTERVAL	20	/* msecs */
#define MW153R_KEYS_DEBOUNCE_INTERVAL (3 * MW153R_KEYS_POLL_INTERVAL)


typedef unsigned int ar933x_reg_t;

#define ar933x_reg_rd(_phys)	(*(volatile ar933x_reg_t *)KSEG1ADDR(_phys))
#define ar933x_reg_wr_nf(_phys, _val) \
	((*(volatile ar933x_reg_t *)KSEG1ADDR(_phys)) = (_val))

#define ar933x_reg_wr(_phys, _val) do {	\
	ar933x_reg_wr_nf(_phys, _val);	\
	ar933x_reg_rd(_phys);		\
} while(0)

#define ar933x_reg_rmw_set(_reg, _mask)	do {				\
	ar933x_reg_wr((_reg), (ar933x_reg_rd((_reg)) | (_mask)));	\
	ar933x_reg_rd((_reg));						\
} while(0)

#define ar933x_reg_rmw_clear(_reg, _mask) do {				\
	ar933x_reg_wr((_reg), (ar933x_reg_rd((_reg)) & ~(_mask)));	\
	ar933x_reg_rd((_reg));						\
} while(0)

#define AR933X_GPIO_FUNCTION_I2S_GPIO_18_22_EN		(1<<29)
#define AR933X_GPIO_FUNCTION_I2S_REFCLKEN		(1<<28)
#define AR933X_GPIO_FUNCTION_I2S_MCKEN			(1<<27)
#define AR933X_GPIO_FUNCTION_I2S0_EN			(1<<26)

#define AR933X_GPIO_FUNCTIONS (0x18000000+0x00040000+0x28)
#define AR933X_GPIO_FUNCTION_2 (0x18000000+0x00040000+0x30)
#define AR933X_GPIO_OE (0x18000000+0x00040000+0x00)


#define I2S_GPIOPIN_MIC					22
#define I2S_GPIOPIN_WS					19
#define I2S_GPIOPIN_SCK					18
#define I2S_GPIOPIN_SD					20
#define I2S_GPIOPIN_OMCLK				21

static const char *mw153r_part_probes[] = {
	"tp-link",
	NULL,
};

static void prepare_mw153r_i2s(void)
{
	/*
	 * FIXME: Beautify this!
	 *
	 * */
    ar933x_reg_rmw_set(AR933X_GPIO_FUNCTIONS, (AR933X_GPIO_FUNCTION_I2S_GPIO_18_22_EN |
    										   AR933X_GPIO_FUNCTION_I2S_MCKEN |
											   AR933X_GPIO_FUNCTION_I2S0_EN
											   /* | AR933X_GPIO_FUNCTION_JTAG_DISABLE */));

	/* Enable the SPDIF output on GPIO23 */
    ar933x_reg_rmw_set(AR933X_GPIO_FUNCTION_2, (1<<2));
	// Set GPIO_OE
    ar933x_reg_rmw_set(AR933X_GPIO_OE, (1<<I2S_GPIOPIN_SCK) |
    								   (1<<I2S_GPIOPIN_WS) |
									   (1<<I2S_GPIOPIN_SD) |
									   (1<<I2S_GPIOPIN_OMCLK));
    ar933x_reg_rmw_clear(AR933X_GPIO_OE, (1<<I2S_GPIOPIN_MIC));
}


static struct flash_platform_data mw153r_flash_data = {
	.part_probes	= mw153r_part_probes,
};

static struct gpio_led mw153r_leds_gpio[] __initdata = {
	{
		.name		= "mw153r:green:lan1",
		.gpio		= MW153R_GPIO_LED_LAN1,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan2",
		.gpio		= MW153R_GPIO_LED_LAN2,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan3",
		.gpio		= MW153R_GPIO_LED_LAN3,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:lan4",
		.gpio		= MW153R_GPIO_LED_LAN4,
		.active_low	= 1,
	}, {
		.name		= "mw153r:green:system",
		.gpio		= MW153R_GPIO_LED_SYSTEM,
		.active_low	= 1,
	}, {
		.name		= "mw153r:green:wan",
		.gpio		= MW153R_GPIO_LED_WAN,
		.active_low	= 0,
	}, {
		.name		= "mw153r:green:wlan",
		.gpio		= MW153R_GPIO_LED_WLAN,
		.active_low	= 0,
	},{
		.name		= "mw153r:green:qss",
		.gpio		= MW153R_GPIO_LED_QSS,
		.active_low	= 0,
	},
};

static struct gpio_keys_button mw153r_gpio_keys[] __initdata = {
	{
		.desc		= "reset",
		.type		= EV_KEY,
		.code		= KEY_RESTART,
		.debounce_interval = MW153R_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= MW153R_GPIO_BTN_RESET,
		.active_low	= 0,
	}, {
		.desc		= "WPS",
		.type		= EV_KEY,
		.code		= KEY_WPS_BUTTON,
		.debounce_interval = MW153R_KEYS_DEBOUNCE_INTERVAL,
		.gpio		= MW153R_GPIO_BTN_WPS,
		.active_low	= 0,
	}
};

static void __init mw153r_setup(void)
{
	u8 *mac = (u8 *) KSEG1ADDR(0x1f01fc00);
	u8 *ee = (u8 *) KSEG1ADDR(0x1fff1000);

	ath79_setup_ar933x_phy4_switch(true, true);

	ath79_register_m25p80(&mw153r_flash_data);
	ath79_init_mac(ath79_eth0_data.mac_addr, mac, 1);
	ath79_init_mac(ath79_eth1_data.mac_addr, mac, -1);

	ath79_register_mdio(0, 0x0);
	ath79_register_eth(1);
	ath79_register_eth(0);

	ath79_register_wmac(ee, mac);

	ath79_register_leds_gpio(-1, ARRAY_SIZE(mw153r_leds_gpio) - 1,
				 mw153r_leds_gpio);
	ath79_register_gpio_keys_polled(1, MW153R_KEYS_POLL_INTERVAL,
					ARRAY_SIZE(mw153r_gpio_keys),
					mw153r_gpio_keys);

	prepare_mw153r_i2s();
	ath79_audio_device_register();
}

MIPS_MACHINE(ATH79_MACH_MW153R, "MW153R",
	     "MERCURY MW153R", mw153r_setup);
