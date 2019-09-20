#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=wandetect
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/wandetect
  SECTION:=net
  CATEGORY:=Network
  TITLE:=wandetect
  MAINTAINER:=Xijun.guo <xijun.guo@siflower.com.cn>
endef

define Package/wandetect/description
detect wan type
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Package/wandetect/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/pppoedetect $(1)/usr/sbin/
	$(CP) ./files/wandetect $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,wandetect))
