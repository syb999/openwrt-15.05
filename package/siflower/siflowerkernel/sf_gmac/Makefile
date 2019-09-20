#
# Copyright (C) 2008-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sf_gmac
PKG_RELEASE:=1

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk


define KernelPackage/sf_gmac
  SUBMENU:=Network Devices
  TITLE:=Siflower SFA18 gmac support
  FILES:=$(PKG_BUILD_DIR)/sgmac.ko
  AUTOLOAD:=$(call AutoLoad,60,sgmac,1)
  KCONFIG:=
endef


define KernelPackage/sf_gmac/config
	if PACKAGE_kmod-sf_gmac

		config SFAX8_RGMII_GMAC
			bool "select RGMII mode gmac"
			default "y"

		config SFAX8_RMII_GMAC
			bool "select RMII mode gmac"
			default "n"
	endif
endef

EXTRA_KCONFIG:= \
	CONFIG_NET_VENDOR_SIFLOWER=y \
	CONFIG_SFAX8_GMAC=m \


ifdef CONFIG_TARGET_siflower_sf16a18_fullmask
NOSTDINC_FLAGS += -DCONFIG_SF16A18_FULL_MASK
endif

ifdef CONFIG_SFAX8_RGMII_GMAC
NOSTDINC_FLAGS += -DCONFIG_SFAX8_RGMII_GMAC
endif

ifdef CONFIG_SFAX8_RMII_GMAC
NOSTDINC_FLAGS += -DCONFIG_SFAX8_RMII_GMAC
endif

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

$(eval $(call KernelPackage,sf_gmac))
