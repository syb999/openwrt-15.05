#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=eth0_listen
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/eth0_listen
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=eth0_listen
  DEPENDS:=+libnl-tiny +ubusd +jshn +libubox
endef

define Package/eth0_listen/description
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

TARGET_CFLAGS += \
	-I$(STAGING_DIR)/usr/include/libnl-tiny \
	-I$(STAGING_DIR)/usr/include

define Build/Compile/eth0_listen
endef

define Build/Compile
	$(Build/Compile/eth0_listen)
endef


define Package/eth0_listen/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/et_listen $(1)/etc/init.d/
	$(CP) ./files/eth0_listen  $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,eth0_listen))
