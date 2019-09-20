#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=siupgrade
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/siupserver
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=siwifi upgrade server
  MAINTAINER:=Phoenix
  DEPENDS:=+libc +libpthread
endef

define Package/siupclient
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=siwifi upgrade  client
  MAINTAINER:=Phoenix
  DEPENDS:=+libc +libpthread
endef

define Package/siupserver/description
ac server for send firmware to ap
endef

define Package/siupclient/description
ap download firmware from ac
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) -r ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

#for memory leak debug
#TARGET_CFLAGS += -g3 -O0
#TARGET_LDFLAGS += -rdynamic

define Build/Compile/siupserver
	$(MAKE) -C $(PKG_BUILD_DIR)/server \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(PKG_BUILD_DIR) -lpthread -lc"
endef

define Build/Compile/siupclient
	$(MAKE) -C $(PKG_BUILD_DIR)/client \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(PKG_BUILD_DIR) -lpthread -lc"
endef

define Build/Compile
	$(Build/Compile/siupserver)
	$(Build/Compile/siupclient)
endef

define Package/siupserver/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/server/siupserver $(1)/usr/sbin/
endef

define Package/siupclient/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/siupclient $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,siupserver))
$(eval $(call BuildPackage,siupclient))
