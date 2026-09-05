#
# Copyright (C) 2026 ZM-WR2500 (CN6619) SLIC driver package
#
# kmod-slic-cn6619: Si32176 SLIC voice driver for ZMTEL ZM-WR2500
# (AR9341, OpenWrt 15.05 / ar71xx).  Provides /dev/aci0-1 (PCM) +
# /dev/aci control so the stock fvphone userspace runs unmodified.
#
# READ-ONLY probe: never writes chip registers on load.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=kmod-slic-cn6619
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/slic-cn6619
	SUBMENU:=Other modules
	TITLE:=CN6619 ZM-WR2500 SLIC (Si32176) driver
	DEPENDS:=@TARGET_ar71xx
	FILES:=$(PKG_BUILD_DIR)/slicdrv.ko
	AUTOLOAD:=$(call AutoLoad,61,slicdrv)
endef

define KernelPackage/slic-cn6619/description
  ZM-WR2500 (CN6619, AR9341) SLIC voice driver. 3.18 port of the
  stock 3.3.8 slic.ko. Provides /dev/aci0-1 PCM channels + ioctl
  (0xc0047801 fvphone register bridge) so stock fvphone runs on
  OpenWrt 15.05. Load-time probe is read-only (safe).
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/Makefile $(PKG_BUILD_DIR)/
	$(CP) ./src/*.c $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" M="$(PKG_BUILD_DIR)" \
		ARCH="$(LINUX_KARCH)" CROSS_COMPILE="$(TARGET_CROSS)" \
		CONFIG_MODULE_SIG=n modules
endef

$(eval $(call KernelPackage,slic-cn6619))

