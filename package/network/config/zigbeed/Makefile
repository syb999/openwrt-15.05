#
# Copyright (C) 2026
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=zigbeed
PKG_VERSION:=1.0
PKG_RELEASE:=3

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_USE_MIPS16:=0

include $(INCLUDE_DIR)/package.mk

define Package/zigbeed
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Independent Zigbee gateway daemon (MT7688 + EFR32MG1B)
	URL:=https://example.com
	DEPENDS:=+libc
endef

define Package/zigbeed/description
	Independent Zigbee gateway daemon for MT7688 boards with a
	Silabs EFR32MG1B coordinator on ttyS1 (GPIO36 reset).
	Replaces the vendor DeviceHub stack.
	Includes gw-link peer-to-peer gateway interconnect service.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) -std=gnu99 -static \
		-o $(PKG_BUILD_DIR)/zigbeed \
		$(CURDIR)/src/zigbeed.c
	$(TARGET_CC) $(TARGET_CFLAGS) -std=gnu99 -static \
		-o $(PKG_BUILD_DIR)/gw-link \
		$(CURDIR)/src/gw-link.c
endef

define Package/zigbeed/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/zigbeed $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/gw-link $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/share/zigbeed
	$(INSTALL_DATA) ./files/usr/share/zigbeed/device_models.txt $(1)/usr/share/zigbeed/
	$(INSTALL_DATA) ./files/usr/share/zigbeed/deviceModel.json $(1)/usr/share/zigbeed/
	$(INSTALL_DATA) ./files/usr/share/zigbeed/deviceMete.json $(1)/usr/share/zigbeed/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/gw_link $(1)/etc/config/
	$(INSTALL_DIR) $(1)/etc/gw-master
	$(INSTALL_DATA) ./files/etc/gw-master/rules.conf $(1)/etc/gw-master/
endef

$(eval $(call BuildPackage,zigbeed))
