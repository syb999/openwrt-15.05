#
# Copyright (C) 2017 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=jq-full
PKG_VERSION:=1.6
PKG_RELEASE:=1
PKG_LICENSE:=BSD

PKG_SOURCE:=jq-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/stedolan/jq/releases/download/jq-$(PKG_VERSION)/
PKG_MD5SUM:=f5f70ad5dc46d95e0128dc94c25c4d5d
PKG_BUILD_DIR:=$(BUILD_DIR)/jq-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

ifdef CONFIG_USE_MIPS16
  TARGET_CFLAGS += -fno-ipa-sra
endif

TARGET_CFLAGS += -std=c99 -D_GNU_SOURCE

CONFIGURE_ARGS+= \
	--disable-docs \
	--disable-valgrind

define Package/jq-full
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Lightweight and flexible command-line JSON processor with regex support.
  URL:=https://stedolan.github.io/jq/
  MAINTAINER:=Marko Ratkaj <marko.ratkaj@sartura.hr>
  DEPENDS:=+oniguruma
endef

define Package/jq-full/description
  Lightweight and flexible command-line JSON processor.
  This package was compiled with ONIGURUMA regex libary and has full regex support.
endef

define Package/jq-full/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
endef

$(eval $(call BuildPackage,jq-full))
