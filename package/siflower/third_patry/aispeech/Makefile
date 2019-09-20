#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=aispeech
PKG_VERSION:=2
PKG_RELEASE:=1
PKG_BUILD_DIR:= $(BUILD_DIR)/$(PKG_NAME)
RES_DIR=v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/aispeech
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=aispeech audio process library
  MAINTAINER:=Franklin.wang <franklin.wang@siflower.com.cn>
  DEPENDS:=+libc +libpthread +librt +libstdcpp
endef

define Package/aispeech/description
aispeech libraries & firmware
endef

define Package/aispeech_test
  $(Package/aispeech)
  TITLE:=aispeech test
  DEPENDS+=aispeech
endef

define Package/aispeech_test/description
aispeech test programers
endef


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./test/* $(PKG_BUILD_DIR)
	$(CP) ./$(RES_DIR)/*.so $(PKG_BUILD_DIR)
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/lib/firmware
	$(CP) ./$(RES_DIR)/*.so $(1)/usr/lib/
	cp ./$(RES_DIR)/*.bin $(1)/lib/firmware/
endef

define Package/aispeech/install
	$(INSTALL_DIR) $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/lib/firmware/
	cp ./$(RES_DIR)/*.so $(1)/usr/lib/
	cp ./$(RES_DIR)/*.bin $(1)/lib/firmware/
endef

define Package/aispeech_test/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aispeech_test $(1)/usr/sbin
endef


$(eval $(call BuildPackage,aispeech))
$(eval $(call BuildPackage,aispeech_test))
