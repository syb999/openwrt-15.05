#
# Copyright (C) 2006-2017 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=mtk_aes
PKG_RELEASE:=1.3

include $(INCLUDE_DIR)/package.mk

define Package/crypto-hw-mtk-aes/Default
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Cryptographic API modules
endef

define KernelPackage/crypto-hw-mtk-aes
  $(call Package/crypto-hw-mtk-aes/Default)
  SECTION:=kernel
  DEPENDS:=@(TARGET_ramips_mt7628||TARGET_ramips_mt7688) +kmod-crypto-core +kmod-cryptodev +libopenssl-devcrypto
  TITLE:=Kernel driver for Mediatek MT76x8 aes engine.
  FILES:=$(PKG_BUILD_DIR)/crypto-hw-mtk-aes.ko
  AUTOLOAD:=$(call AutoProbe,crypto-hw-mtk-aes)
  $(call AddDepends/crypto)
endef

# Installing this driver is enough to get hardware accelerated AES-*CBC in
# OpenSSL: the driver registers cbc(aes)/ecb(aes) with the kernel Crypto API,
# kmod-cryptodev exposes them on /dev/crypto and libopenssl-devcrypto provides
# the engine that offloads AES-128/192/256-CBC to it.  Both are pulled in by
# DEPENDS, so no openssl option has to be selected here (selecting them would
# create a Kconfig dependency loop: libopenssl-devcrypto itself selects
# PACKAGE_libopenssl and requires !OPENSSL_ENGINE_BUILTIN).
# OpenSSL 1.0.2 had that engine compiled in (-DHAVE_CRYPTODEV), on 1.1.1 the
# dynamic engine is used because it is loaded on demand (dlopen) by every
# libcrypto user reading /etc/ssl/openssl.cnf, while a built-in engine is only
# reachable for programs that pass OPENSSL_INIT_ENGINE_* flags.
define KernelPackage/crypto-hw-mtk-aes/config
	select CRYPTO_HW
	depends on !OPENSSL_ENGINE_BUILTIN
	help
	 Hardware AES for Mediatek MT76x8 (OpenSSL via /dev/crypto).
	 Pulls in kmod-cryptodev and libopenssl-devcrypto; not available when
	 the OpenSSL engines are built into libcrypto (OPENSSL_ENGINE_BUILTIN).
endef

define KernelPackage/crypto-hw-mtk-aes/description
 Kernel module to enable AES HW Crypto Engine on the Mediatek MT76x8
 (AES-128/192/256 EBC/CBC).
 It is used by OpenSSL through the /dev/crypto devcrypto engine, whose
 configuration is installed together with this package (see
 /etc/ssl/engines.cnf.d/devcrypto-mtk.cnf).
endef

# Extra file: engine configuration that makes OpenSSL's devcrypto engine
# accept this driver (kernel 3.18 reports it as a software driver).
define KernelPackage/crypto-hw-mtk-aes/install
	$(INSTALL_DIR) $(1)/etc/ssl/engines.cnf.d
	$(INSTALL_DATA) ./files/devcrypto-mtk.cnf $(1)/etc/ssl/engines.cnf.d/
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
        CROSS_COMPILE="$(TARGET_CROSS)" \
        ARCH="$(LINUX_KARCH)" \
        SUBDIRS="$(PKG_BUILD_DIR)" \
        EXTRA_CFLAGS="$(BUILDFLAGS)" \
        modules
endef

$(eval $(call KernelPackage,crypto-hw-mtk-aes))
