#
# Copyright (C) 2008-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sf-eth-led
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/sf-eth-led
  SUBMENU:=Other modules
  TITLE:=Siflower ethernet led driver
  FILES:=$(PKG_BUILD_DIR)/sf-eth-led.ko
  AUTOLOAD:=$(call AutoLoad,80,sf-eth-led,1)
  KCONFIG:=
endef

define KernelPackage/sf-eth-led/description
  Siflower ethernet led driver
endef

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)"

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,sf-eth-led))
