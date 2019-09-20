#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wifi-dbss
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/wifi-dbss
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=dual band single ssid.
  MAINTAINER:=Nevermore <nevermore.wang@siflower.com.cn>
  DEPENDS:=+hostapd-common +libblobmsg-json +libubus +libcurl +libjson-c +libwebsockets
endef

define Build/Prepare
endef

define Package/wifi-dbss/description
Advanced wifi: dual band single ssid, auto switch.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/wifi-dbss/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/advanced_wifi  $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/wifi-dbss $(1)/usr/sbin/wifi-dbss
endef

$(eval $(call BuildPackage,wifi-dbss))
