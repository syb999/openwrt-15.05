#
# Copyright (C)  mark.cai@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=anomaly_check
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/anomaly_check
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=anomaly_check
  MAINTAINER:=mark.cai <mark.cai@siflower.com.cn>
  DEPENDS:=
endef

define Package/anomaly_check/description
anomaly_check.
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

define Package/anomaly_check/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
#$(INSTALL_DIR) $(1)/etc/anomaly_check
#$(INSTALL_BIN) $(PKG_BUILD_DIR)/anomaly_check $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/anomaly_server $(1)/etc/anomaly_server
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/anomaly_client $(1)/etc/anomaly_client
#$(INSTALL_BIN) ./files/anomaly_check $(1)/etc/init.d/
#$(CP) ./files/*  $(1)/etc/anomaly_check/
endef


$(eval $(call BuildPackage,anomaly_check))
