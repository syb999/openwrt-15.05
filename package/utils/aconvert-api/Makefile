# Copyright (C) 2010-2022 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=aconvert
PKG_VERSION:=2022-02-18

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/jfk9w-go/aconvert-api
PKG_SOURCE_VERSION:=82350b7fb9eaa6b2c57e2bca90923e6b4f4c8619
PKG_SOURCE:=$(PKG_NAME)-api-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MD5SUM:=6b6d311cf2d460c0cce16826bf98c7a6

PKG_BUILD_DIR=$(BUILD_DIR)/$(PKG_NAME)-api-$(PKG_VERSION)

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/jfk9w-go/aconvert-api

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
  TITLE:=aconvert-api contains aconvert.com
  URL:=https://github.com/jfk9w-go/aconvert-api
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=$(GO_ARCH_DEPENDS) +libpthread
endef

define Package/$(PKG_NAME)/description
aconvert-api contains aconvert.com HTTP client for converting media and other files.
endef


define Build/Prepare
	 $(call Build/Prepare/Default)
endef

define Build/Compile
	$(eval GO_PKG_BUILD_PKG:=$(GO_PKG)/aconvert)
	$(call GoPackage/Build/Configure)
	$(call GoPackage/Build/Compile)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/aconvert $(1)/usr/bin
endef

$(eval $(call GoBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
