#
# Copyright (C)  mark.cai@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=sf_dnsmasq_ext_cfg
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/sf_dnsmasq_ext_cfg
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=sf_dnsmasq_ext_cfg
  MAINTAINER:=xijun.guo <xijun.guo@siflower.com.cn>
endef

define Package/sf_dnsmasq_ext_cfg/description
sf_dnsmasq_ext_cfg.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall -Wno-unused-but-set-variable -Wno-unused-function" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/sf_dnsmasq_ext_cfg/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dec-tool $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,sf_dnsmasq_ext_cfg))
