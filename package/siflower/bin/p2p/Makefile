#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=p2p
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/p2p
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=p2p client
  MAINTAINER:=Phoenix.Shen <phoenix.shen@siflower.com.cn>
  DEPENDS:=+libstdcpp +libpthread
endef

define Package/p2p/description
test for p2p set up
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
$(MAKE) -C $(PKG_BUILD_DIR) \
	CXX="$(TARGET_CXX)" \
	CCFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
	LDFLAGS="$(TARGET_LDFLAGS) -L$(PKG_BUILD_DIR) -lsunloginsdk -lpthread "
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libsunloginsdk.so $(1)/usr/lib/
endef

define Package/p2p/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/p2p $(1)/usr/sbin/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libsunloginsdk.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,p2p))
