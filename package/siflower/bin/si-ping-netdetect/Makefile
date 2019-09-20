#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=netdetect
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/netdetect
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=netdetect for api netdetect()
  MAINTAINER:=xiaoxi <xiaoxi.lin.wang@siflower.com.cn>
  DEPENDS:=+libpthread +libuci
endef

define Package/netdetect/description
ping www.baidu.com, www.taobao.com, www.qq.com to count the package lost rate,and count the bandwidth  
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS) -lpthread -luci"
endef

define Package/netdetect/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/netdetect $(1)/usr/bin/
endef

$(eval $(call BuildPackage,netdetect))
