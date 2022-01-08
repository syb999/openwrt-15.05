#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libupnp-old
PKG_VERSION:=1.6.19
PKG_RELEASE:=2

PKG_SOURCE:=libupnp-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=@SF/pupnp
PKG_MD5SUM:=ee16e5d33a3ea7506f38d71facc057dd
PKG_MAINTAINER:=Ted Hess <thess@kitschensync.net>

PKG_SOURCE_SUBDIR:=libupnp-$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/libupnp-old/Default
  SECTION:=libs
  CATEGORY:=Libraries
  URL:=http://pupnp.sourceforge.net/
endef

define Package/libupnp-old
  $(call Package/libupnp-old/Default)
  DEPENDS:=+libpthread
  TITLE:=UPnP SDK library
  MENU:=1
endef

define Package/libupnp-old/description
The portable SDK for UPnP Devices (libupnp) provides developers with an API and
open source code for building control points, devices, and bridges that are
compliant with Version 1.0 of the  Universal Plug and Play Device Architecture
Specification.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/upnp $(1)/usr/include/
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lib{ixml,threadutil,upnp}.{a,so*,la} $(1)/usr/lib/
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/pkgconfig/libupnp.pc $(1)/usr/lib/pkgconfig/
endef

define Package/libupnp-old/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/lib{ixml,threadutil,upnp}.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libupnp-old))
