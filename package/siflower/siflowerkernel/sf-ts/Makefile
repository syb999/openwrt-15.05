#
# Copyright (C) 2008-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=sf-ts
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/sf-ts
  SUBMENU:=Other modules
  TITLE:=SIFLOWER TRAFFIC STATISTICS
  FILES:=$(PKG_BUILD_DIR)/sf-ts.ko
  AUTOLOAD:=$(call AutoLoad,31,sf-ts,1)
  KCONFIG:=
endef

define KernelPackage/sf-ts/description
  Kernel module to traffic statistics.
endef

EXTRA_KCONFIG:= \
	CONFIG_SIFLOWER_TS=m

EXTRA_CFLAGS:= \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=m,%,$(filter %=m,$(EXTRA_KCONFIG)))) \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=y,%,$(filter %=y,$(EXTRA_KCONFIG)))) \

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)" \
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

define KernelPackage/sf-ts/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/tscript $(1)/usr/bin/
	$(INSTALL_BIN) ./files/hiscript $(1)/usr/bin/
	$(INSTALL_BIN) ./files/ts-init $(1)/etc/init.d/
endef
$(eval $(call KernelPackage,sf-ts))
