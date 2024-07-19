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


define KernelPackage/sound-ak4430
  SUBMENU:=$(SOUND_MENU)
  TITLE:=ar71xx I2S Audio Driver
  DEPENDS:=@AUDIO_SUPPORT @TARGET_ar71xx +kmod-sound-core +kmod-sound-soc-core +kmod-regmap
  KCONFIG:= \
	CONFIG_LZO_COMPRESS=y \
	CONFIG_LZO_DECOMPRESS=y \
	CONFIG_MTD_NAND=y \
	CONFIG_MTD_NAND_AR934X=y \
	CONFIG_MTD_NAND_AR934X_HW_ECC=y \
	CONFIG_MTD_NAND_ECC=y \
	CONFIG_REGMAP=y \
	CONFIG_REGMAP_I2C=y \
	CONFIG_REGMAP_SPI=y \
	CONFIG_SND=y \
	CONFIG_SND_ATH79_SOC_CODEC=m \
	CONFIG_SND_ATH79_SOC_I2S=m \
	CONFIG_SND_COMPRESS_OFFLOAD=y \
	CONFIG_SND_PCM=y \
	CONFIG_SND_SOC=y \
	CONFIG_SND_SOC_AK4430=m \
	CONFIG_SND_SOC_I2C_AND_SPI=y \
	CONFIG_SND_TIMER=y \
	CONFIG_SOUND=y \
	CONFIG_ATH79_DEV_AUDIO=y \
	CONFIG_SND_ATH79_SOC=m \
	CONFIG_SND_ATH79_SOC_AP123_AK4430=m \
	CONFIG_SND_SOC_AK4430=m
  FILES:= \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-i2s.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-pcm.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-codec.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ap123-ak4430.ko \
	$(LINUX_DIR)/sound/soc/codecs/snd-soc-ak4430.ko
  AUTOLOAD:=$(call AutoLoad,65,snd-soc-ath79-i2s snd-soc-ath79-pcm snd-soc-ath79-codec snd-soc-ap123-ak4430 snd-soc-ak4430)
  $(call AddDepends/sound)
endef

define KernelPackage/sound-ak4430/description
 Audio modules for ar71xx ar934x i2s controller.
endef

$(eval $(call KernelPackage,sound-ak4430))


define KernelPackage/sound-uda1334
  SUBMENU:=$(SOUND_MENU)
  TITLE:=ar71xx I2S Audio Driver uda1334
  DEPENDS:=@AUDIO_SUPPORT @TARGET_ar71xx +kmod-sound-core +kmod-sound-soc-core +kmod-regmap
  KCONFIG:= \
	CONFIG_MIGRATION=y \
	CONFIG_SND=y \
	CONFIG_SND_ATH79_SOC=m \
	CONFIG_SND_ATH79_SOC_CODEC=m \
	CONFIG_SND_ATH79_SOC_I2S=m \
	CONFIG_SND_COMPRESS_OFFLOAD=y \
	CONFIG_SND_PCM=y \
	CONFIG_SND_SOC=y \
	CONFIG_SND_SOC_UDA1334=m \
	CONFIG_SND_TIMER=y \
	CONFIG_SOUND=y \
	CONFIG_ATH79_DEV_AUDIO=y
  FILES:= \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-i2s.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-pcm.ko \
	$(LINUX_DIR)/sound/soc/ath79/snd-soc-ath79-codec.ko \
	$(LINUX_DIR)/sound/soc/codecs/snd-soc-uda1334.ko
  AUTOLOAD:=$(call AutoLoad,65,snd-soc-ath79-i2s snd-soc-ath79-pcm snd-soc-ath79-codec snd-soc-uda1334)
  $(call AddDepends/sound)
endef

define KernelPackage/sound-uda1334/description
 Audio modules for ar71xx uda1334 i2s controller.
endef

$(eval $(call KernelPackage,sound-uda1334))
