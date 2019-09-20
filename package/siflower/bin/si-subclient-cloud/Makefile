#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=subcloud
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/subcloud
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=siwifi cloud subscribe client
  MAINTAINER:=Robert chang <robert.chang@siflower.com.cn>
  DEPENDS:=+libpthread +libuci +libcurl +libwebsockets +libm +liblocalhttp
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/subcloud/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/subcloud $(1)/usr/bin/
	$(INSTALL_BIN) ./files/subservice $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) ./files/subservice.hotplug $(1)/etc/hotplug.d/iface/70-subservice
	$(CP) ./files/sicloud $(1)/etc/config/
endef

$(eval $(call BuildPackage,subcloud))
