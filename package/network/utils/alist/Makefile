#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=alist
PKG_VERSION:=3.23.0
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

ifeq ($(ARCH),x86_64)
	alist_ARCH:=x86_64
	PKG_MD5SUM:=dd6c954014586fb87528f27d4700bbac
endif

ifeq ($(ARCH),mipsel)
ifdef CONFIG_TARGET_ramips_mt7621
	alist_ARCH:=mt7621
	PKG_MD5SUM:=bf2f4f386ce505c572c8c9ae6b838295
else
	alist_ARCH:=mt7620
	PKG_MD5SUM:=9923eab4f1fccaa66f36a93eff341a5d
endif
endif

ifeq ($(ARCH),mips)
	alist_ARCH:=ar71xx
	PKG_MD5SUM:=4f243a6ebb901f1c41847bda893b94ae
endif

ifeq ($(ARCH),arm)
ifdef CONFIG_TARGET_kirkwood
	alist_ARCH:=kirkwood
	PKG_MD5SUM:=2b9a3a4777b1cbf61686a88da243c86a
endif
endif

PKG_SOURCE_URL:=https://raw.githubusercontent.com/syb999/cc-upx/master/alist3/$(alist_ARCH)
PKG_SOURCE:=alist

define Build/Prepare
	mv $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/alist $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
