#
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define KernelPackage/leds-rb750
  SUBMENU:=$(LEDS_MENU)
  TITLE:=RouterBOARD 750 LED support
  DEPENDS:=@TARGET_ar71xx
  KCONFIG:=CONFIG_LEDS_RB750
  FILES:=$(LINUX_DIR)/drivers/leds/leds-rb750.ko
  AUTOLOAD:=$(call AutoLoad,60,leds-rb750)
endef

define KernelPackage/leds-rb750/description
 Kernel module for the LEDs on the MikroTik RouterBOARD 750.
endef

$(eval $(call KernelPackage,leds-rb750))


define KernelPackage/leds-wndr3700-usb
  SUBMENU:=$(LEDS_MENU)
  TITLE:=WNDR3700 USB LED support
  DEPENDS:=@TARGET_ar71xx
  KCONFIG:=CONFIG_LEDS_WNDR3700_USB
  FILES:=$(LINUX_DIR)/drivers/leds/leds-wndr3700-usb.ko
  AUTOLOAD:=$(call AutoLoad,60,leds-wndr3700-usb)
endef

define KernelPackage/leds-wndr3700-usb/description
 Kernel module for the USB LED on the NETGEAR WNDR3700 board.
endef

$(eval $(call KernelPackage,leds-wndr3700-usb))


define KernelPackage/spi-vsc7385
  SUBMENU:=$(SPI_MENU)
  TITLE:=Vitesse VSC7385 ethernet switch driver
  DEPENDS:=@TARGET_ar71xx
  KCONFIG:=CONFIG_SPI_VSC7385
  FILES:=$(LINUX_DIR)/drivers/spi/spi-vsc7385.ko
  AUTOLOAD:=$(call AutoLoad,93,spi-vsc7385)
endef

define KernelPackage/spi-vsc7385/description
  This package contains the SPI driver for the Vitesse VSC7385 ethernet switch.
endef

$(eval $(call KernelPackage,spi-vsc7385))

define KernelPackage/sound-ap123-ak4430
  SUBMENU:=$(SOUND_MENU)
  TITLE:=ar71xx ak4430 I2S Audio Driver
  DEPENDS:=@TARGET_ar71xx +alsa-lib +kmod-sound-soc-core
  KCONFIG:= \
	CONFIG_SND=y \
	CONFIG_SND_ATH79_SOC_CODEC=y \
	CONFIG_SND_ATH79_SOC_I2S=y \
	CONFIG_SND_SOC=y \
	CONFIG_SND_SOC_AK4430=y \
	CONFIG_SND_SOC_I2C_AND_SPI=y \
	CONFIG_ATH79_DEV_AUDIO=y \
	CONFIG_SND_ATH79_SOC=y \
	CONFIG_SND_ATH79_SOC_AP123_AK4430=y
  FILES:= \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-i2s.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-pcm.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-codec.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ap123-ak4430.ko \
	$(LINUX_DIR)/sound/soc/codecs/snd-soc-ak4430.ko
  AUTOLOAD:=$(call AutoLoad,90,snd-soc-ath79-codec snd-soc-ath79-i2s snd-soc-ath79-pcm snd-soc-ak4430 snd-soc-ap123-ak4430)
endef

define KernelPackage/sound-ap123-ak4430/description
 Audio modules for ar71xx ar934x i2s controller.
endef

$(eval $(call KernelPackage,sound-ap123-ak4430))
