#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ndscan
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/ndscan
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=net device scan
  MAINTAINER:=Kevin.feng <kevin.feng@siflower.com.cn>
  DEPENDS:=+libc +libpthread +librt +libm +libuci +libcurl +libjson-c +libnet1 +libpcap
endef

define Package/ndscan/description
use the ndscan to scan the currect device
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
		LDFLAGS="$(TARGET_LDFLAGS) -lpthread -lc -lm -luci -lcurl -ljson-c -lpcap -lnet"
endef

define Package/ndscan/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ndscan $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,ndscan))
