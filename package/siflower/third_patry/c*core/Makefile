#
# Copyright (C)  mark.cai@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ccm3310test
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/ccm3310test
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=ccm3310test
  MAINTAINER:=mark.cai <mark.cai@siflower.com.cn>
  DEPENDS:= +libpthread
endef

define Package/ccm3310test/description
test ccm3310 func
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

TARGET_CFLAGS += \
	-I$(LINUX_DIR)/include \
	-I$(LINUX_DIR)/drivers/char

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/ccm3310test/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/lib
#$(INSTALL_DIR) $(1)/etc/ccm3310
#$(INSTALL_BIN) $(PKG_BUILD_DIR)/ccm3310 $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ccm3310test $(1)/bin/ccm3310test
	$(CP) $(PKG_BUILD_DIR)/*.so $(1)/lib/
#$(INSTALL_BIN) ./files/ccm3310test $(1)/etc/init.d/
#$(CP) ./files/*  $(1)/etc/ccm3310test/
endef


$(eval $(call BuildPackage,ccm3310test))
