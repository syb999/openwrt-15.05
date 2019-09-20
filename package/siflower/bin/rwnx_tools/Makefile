#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=rwnxtools
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/rwnxtools
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=rwnx wifi debug tools
  MAINTAINER:=Robert chang <robert.chang@siflower.com.cn>
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/rwnxtools/install
	$(INSTALL_DIR) $(1)/bin $(1)/lib/firmware/
	$(INSTALL_BIN) ./files/gendesc $(1)/bin/
	$(INSTALL_BIN) ./files/gendiags $(1)/bin/
	$(INSTALL_BIN) ./files/genvcd $(1)/bin/
	$(INSTALL_BIN) ./files/rwnx_umh.sh $(1)/bin/
	$(INSTALL_DATA) ./files/*.txt $(1)/lib/firmware/
endef

$(eval $(call BuildPackage,rwnxtools))
