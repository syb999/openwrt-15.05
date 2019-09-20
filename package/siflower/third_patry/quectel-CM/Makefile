#
# Copyright (C) 2015-2018 neil.zhang@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=quectel-CM
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/quectel-CM
  SECTION:=net
  CATEGORY:=Network
  TITLE:=quectel-CM
  MAINTAINER:=Nevermore <nevermore.wang@siflower.com.cn>
  DEPENDS:=+libpthread
endef

define Package/quectel-CM/description
EC20 quectel-CM for GobiNetUSB & QMI WWAN driver.
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
		CFLAGS="$(TARGET_CFLAGS) -Wall -Werror -mips32r2 -s" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/quectel-CM/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel-CM $(1)/usr/bin/
endef


$(eval $(call BuildPackage,quectel-CM))
