#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=alist
PKG_VERSION:=2.6.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Alist - Main program
  URL:=https://alist-doc.nn.ci/
  DEPENDS:=@(TARGET_kirkwood||TARGET_ar71xx||TARGET_ramips||TARGET_x86_64) +libpthread
endef

define Package/$(PKG_NAME)/description
  A file list program that supports multiple storage.
endef

define Package/$(PKG_NAME)/conffiles
/etc/alist/
/etc/config/alist
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	[ -f /etc/uci-defaults/alist ] && /etc/uci-defaults/alist && rm -f /etc/uci-defaults/alist
fi
endef


ifeq ($(ARCH),x86_64)
	alist_ARCH:=x86_64
	PKG_MD5SUM:=bdeeaa18b2010be1a99eca57ab79b53d
endif

ifeq ($(ARCH),mipsel)
ifdef CONFIG_TARGET_ramips_mt7621
	alist_ARCH:=mt7621
	PKG_MD5SUM:=e12692c8357f18bc9350803b002a567a
else
	alist_ARCH:=mt7620
	PKG_MD5SUM:=b531d9b084327c057ab107a45e8b9330
endif
endif

ifeq ($(ARCH),mips)
	alist_ARCH:=ar71xx
	PKG_MD5SUM:=de69fe2997b0c805cc4b74ca4946ad00
endif

ifeq ($(ARCH),arm)
ifdef CONFIG_TARGET_kirkwood
	alist_ARCH:=kirkwood
	PKG_MD5SUM:=dc50bec06b90c9214a6dda65479b0d69
endif
endif

PKG_SOURCE_URL:=https://raw.githubusercontent.com/syb999/cc-upx/master/alist/$(alist_ARCH)
PKG_SOURCE:=alist

define Build/Prepare
	mv $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/alist $(1)/etc/config $(1)/etc/init.d $(1)/etc/uci-defaults $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/alist $(1)/usr/bin
	$(INSTALL_CONF) ./files/alist.config $(1)/etc/config/alist
	$(INSTALL_BIN) ./files/alist.init $(1)/etc/init.d/alist
	$(INSTALL_BIN) ./files/alist.uci-default $(1)/etc/uci-defaults/alist
	$(INSTALL_CONF) ./files/data.db $(1)/etc/alist/data.db
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
