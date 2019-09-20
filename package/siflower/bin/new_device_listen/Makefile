#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=new_device_listen
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/new_device_listen
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=new_device_listen
  DEPENDS:=+libc +libpthread +librt +libm +libuci +libcurl +libnet1 +libpcap +libopenssl +libstdcpp
endef

define Package/new_device_listen/description
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile/new_device_listen
endef

define Build/Compile
	$(Build/Compile/new_device_listen)
endef


define Package/new_device_listen/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/new_device_listen $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/device_listen $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,new_device_listen))
