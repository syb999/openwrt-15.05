#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ssst
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/ssst
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=siwifi socket server test
  MAINTAINER:=Franklin Wang <franklin.wang@siflower.com.cn>
  DEPENDS:=+libc +libpthread +librt +libm +libuci +libcurl +libnet1 +libpcap +libopenssl +libstdcpp +liblocalhttp
endef

define Package/ssst/description
use the ssct and ssst to test the socket client and server on openWRT platform
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef


define Build/Compile/ssst
endef

define Build/Compile/siwifitest
	$(MAKE) -C $(PKG_BUILD_DIR)/test \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function"
endef

define Build/Compile/devicetest
	$(MAKE) -C $(PKG_BUILD_DIR)/device_test \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function -g"
endef

define Build/Compile/bindtest
	$(MAKE) -C $(PKG_BUILD_DIR)/bind_test \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function"
endef

define Build/Compile
	$(Build/Compile/ssst)
endef


define Package/ssst/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/ssst $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/check_func $(1)/bin/
	$(INSTALL_BIN) ./files/syncservice $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/lease.sh $(1)/usr/bin/
	$(CP) ./files/devlist $(1)/etc/config/
	$(CP) ./files/wldevlist $(1)/etc/config/
	$(CP) ./files/sidefault $(1)/etc/config/
	$(CP) ./files/siserver $(1)/etc/config/
	$(CP) ./files/siversion $(1)/etc/config/
endef

$(eval $(call BuildPackage,ssst))
