#include <linux/gpio.h>
#include <linux/pci.h>

#include <asm/mach-ath79/ath79.h>
#include <asm/mach-ath79/ar71xx_regs.h>

#include "common.h"
#include "dev-ap9x-pci.h"
#include "dev-eth.h"
#include "dev-gpio-buttons.h"
#include "dev-leds-gpio.h"
#include "dev-m25p80.h"
#include "dev-usb.h"
#include "dev-spi.h"
#include "dev-wmac.h"
#include "machtypes.h"
#include "pci.h"

#define HQ65_GPIO_LED_WLAN		14
#define HQ65_GPIO_LED_WAN		13
#define HQ65_GPIO_LED_SYSTEM	        12
#define HQ65_GPIO_BTN_RESET	        3
#define HQ65_GPIO_BTN_LEFT	        0
#define HQ65_GPIO_BTN_RIGHT	        1

#define HQ65_KEYS_POLL_INTERVAL        20  /* msecs */
#define HQ65_KEYS_DEBOUNCE_INTERVAL    (3 * HQ65_KEYS_POLL_INTERVAL)

#define HQ65_MAC0_OFFSET   0
#define HQ65_MAC1_OFFSET   6
#define HQ65_WMAC_CALDATA_OFFSET   0x1000
#define HQ65_PCIE_CALDATA_OFFSET   0x5000

static struct gpio_led hq65_leds_gpio[] __initdata = {
    {
        .name = "hq65:green:wlan",
        .gpio = HQ65_GPIO_LED_WLAN,
        .active_low = 1,
    },
    {
        .name = "hq65:green:wan",
        .gpio = HQ65_GPIO_LED_WAN,
        .active_low = 1,
    },
    {
        .name = "hq65:red:system",
        .gpio = HQ65_GPIO_LED_SYSTEM,
        .active_low = 1,
        .default_state = 1,
    },
};

static struct gpio_keys_button hq65_gpio_keys[] __initdata = {
    {
        .desc = "reset",
        .type = EV_KEY,
        .code = KEY_RESTART,
        .debounce_interval = HQ65_KEYS_DEBOUNCE_INTERVAL,
        .gpio = HQ65_GPIO_BTN_RESET,
        .active_low = 1,
    },
    {
        .desc = "button right",
        .type = EV_KEY,
        .code = BTN_0,
        .debounce_interval = HQ65_KEYS_DEBOUNCE_INTERVAL,
        .gpio = HQ65_GPIO_BTN_LEFT,
        .active_low = 0,
    },
    {
        .desc = "button left",
        .type = EV_KEY,
        .code = BTN_1,
        .debounce_interval = HQ65_KEYS_DEBOUNCE_INTERVAL,
        .gpio = HQ65_GPIO_BTN_RIGHT,
        .active_low = 0,
    },
};

static void __init hq65_setup(void)
{
    u8 *art = (u8 *) KSEG1ADDR(0x1fff0000);
    u8 tmpmac[ETH_ALEN];

    ath79_register_m25p80(NULL);

    /* register gpio LEDs and keys */
    ath79_register_leds_gpio(-1, ARRAY_SIZE(hq65_leds_gpio),
                 hq65_leds_gpio);
    ath79_register_gpio_keys_polled(-1, HQ65_KEYS_POLL_INTERVAL,
                    ARRAY_SIZE(hq65_gpio_keys),
                    hq65_gpio_keys);

    ath79_register_mdio(0, 0x0);

    /* WAN */
    ath79_init_mac(ath79_eth0_data.mac_addr, art + HQ65_MAC0_OFFSET, 0);
    ath79_eth0_data.phy_if_mode = PHY_INTERFACE_MODE_MII;
    ath79_eth0_data.speed = SPEED_100;
    ath79_eth0_data.duplex = DUPLEX_FULL;
    ath79_eth0_data.phy_mask = BIT(4);
    ath79_register_eth(0);

    /* LAN */
    ath79_init_mac(ath79_eth1_data.mac_addr, art + HQ65_MAC1_OFFSET, 0);
    ath79_eth1_data.phy_if_mode = PHY_INTERFACE_MODE_GMII;
    ath79_eth1_data.speed = SPEED_1000;
    ath79_eth1_data.duplex = DUPLEX_FULL;
    ath79_switch_data.phy_poll_mask |= BIT(4);
    ath79_switch_data.phy4_mii_en = 1;
    ath79_register_eth(1);

    ath79_init_mac(tmpmac, art + HQ65_WMAC_CALDATA_OFFSET + 2, 0);
    ath79_register_wmac(art + HQ65_WMAC_CALDATA_OFFSET, tmpmac);

    /* enable usb */
    ath79_register_usb();
    /* enable pci */
    ath79_register_pci();
}

MIPS_MACHINE(ATH79_MACH_HQ65, "HQ65", "100mshBOX HQ65",
         hq65_setup);
