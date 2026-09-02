
# Copyright (C) 2007-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=authsae
PKG_VERSION:=2014-06-09
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/cozybit/authsae.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=8531ab158910a525d4bcbb3ad02c08342f6987f2
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_BUILD_PARALLEL:=1
CMAKE_INSTALL:=1

CMAKE_OPTIONS += -DSYSCONF_INSTALL_DIR=/etc

PKG_MAINTAINER:=Felix Fietkau <nbd@openwrt.org>
PKG_LICENSE:=BSD-4-Clause

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/authsae
  SECTION:=net
  CATEGORY:=Network
  TITLE:=80211s mesh security
  DEPENDS:=+libopenssl +libconfig +libnl-tiny +@OPENSSL_WITH_EC
endef

TARGET_CFLAGS += -D_GNU_SOURCE

# authsae's CMakeLists uses PKG_CHECK_MODULES(libcrypto/libconfig) which
# shells out to pkg-config. Without the cross pkg-config environment it
# finds the HOST's libcrypto.pc (/usr/include) and the build fails on
# openssl/opensslconf.h. Point PKG_CONFIG at the OpenWrt cross pkg-config
# (wrapper rewrites prefix via STAGING_PREFIX) and PKG_CONFIG_PATH at the
# target staging .pc files so -I/-L resolve into the target staging dir.
define Build/Configure
	PKG_CONFIG="$(STAGING_DIR_HOST)/bin/pkg-config" \
	PKG_CONFIG_PATH="$(STAGING_DIR)/usr/lib/pkgconfig" \
	$(call Build/Configure/Default)
endef

define Package/authsae/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin
	$(INSTALL_DIR) $(1)/lib/wifi
	$(INSTALL_DATA) ./files/lib/wifi/authsae.sh $(1)/lib/wifi/
endef

$(eval $(call BuildPackage,authsae))
