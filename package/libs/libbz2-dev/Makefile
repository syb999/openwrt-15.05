#
# Copyright (C) 2007-2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libbz2-dev
PKG_VERSION:=1.0.6
PKG_RELEASE:=2

PKG_SOURCE:=bzip2-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://www.bzip.org/$(PKG_VERSION)
PKG_MD5SUM:=00b516f4704d4a7cb50a1d97e6e8e15b
PKG_MAINTAINER:=Steven Barth <cyrus@openwrt.org>

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

PKG_UNPACK:=$(HOST_TAR) -C $(PKG_BUILD_DIR) --strip-components=1 -xzf $(DL_DIR)/$(PKG_SOURCE)

define Package/libbz2-dev
  SECTION:=devel
  CATEGORY:=Development
  SUBMENU:=Libraries
  DEPENDS:=libbz2
  TITLE:=Development files for the libbz2 library
endef

TARGET_CFLAGS += \
	$(FPIC) \
	$(TARGET_LDFLAGS)

CONFIGURE_ARGS += --prefix=/usr

MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS)" \
	all

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/bzlib.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libbz2.a $(1)/usr/lib/
endef

define Package/libbz2-dev/install
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/bzlib.h $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libbz2.a $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libbz2-dev))
