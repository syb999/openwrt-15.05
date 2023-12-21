# 
# Copyright (C) 2006 OpenWrt.org
# Copyright (C) 2012 Connectify
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-netem
PKG_RELEASE:=1
PKG_VERSION:=0.1

PKG_BUILD_DEPENDS:=$(if $(STAGING_DIR_ROOT),lua/host)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-netem
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  URL:=http://luci.freifunk-halle.net/
  MAINTAINER:=Brian Prodoehl <bprodoehl-at-connectify-dot-me>
  TITLE:=LuCI WAN Emulation Frontend
  DEPENDS:=+luci +netem-control
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) * $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-netem/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/controller/* $(1)/usr/lib/lua/luci/controller/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/netem/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/model/cbi/netem/* $(1)/usr/lib/lua/luci/model/cbi/netem/

	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/luasrc/i18n/* $(1)/usr/lib/lua/luci/i18n/
endef

$(eval $(call BuildPackage,luci-app-netem))
