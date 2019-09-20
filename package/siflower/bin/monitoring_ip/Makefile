#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=monitoring_ip
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/monitoring_ip
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=monitoring_ip
  DEPENDS:=+libc

endef

define Package/monitoring_ip/description
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile/monitoring_ip
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS) -L$(PKG_BUILD_DIR) -lc" \
		CCFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function"
endef

define Build/Compile
	$(Build/Compile/monitoring_ip)
endef

define Build/Clean
	rm -rf $(BUILD_DIR)/$(PKG_NAME)/
endef

define Package/monitoring_ip/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/monitoring_ip $(1)/bin
	$(INSTALL_BIN) ./files/get_ip_status $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,monitoring_ip))
