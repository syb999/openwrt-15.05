#
# Copyright (C) 2006-2009 OpenWrt.org
# Copyright (C) 2005-2016 Weijie Gao <hackpascal@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=brlaser
PKG_VERSION:=20230221
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://github.com/pdewacht/brlaser.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=2a49e3287c70c254e7e3ac9dabe9d6a07218c3fa
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_FIXUP:=autoreconf

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/brlaser
  SECTION:=print
  CATEGORY:=Printing and Imaging
  TITLE:=Driver for (some) Brother laster printers
  DEPENDS:=+libcupsimage +libstdcpp
  URL:=https://github.com/pdewacht/brlaser
endef

define Package/brlaser/description
  Driver for Brother DCP/HL/MFC series
endef

define Package/brlaser/install
	$(INSTALL_DIR) $(1)/usr/lib/cups/filter
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/cups/filter/rastertobrlaser $(1)/usr/lib/cups/filter/

	$(INSTALL_DIR) $(1)/usr/share/cups/drv
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/share/cups/drv/brlaser.drv $(1)/usr/share/cups/drv/

	(cd $(PKG_BUILD_DIR) && ppdc brlaser.drv)

	$(INSTALL_DIR) $(1)/usr/share/ppd/Brother
	$(CP) $(PKG_BUILD_DIR)/ppd/*.ppd $(1)/usr/share/ppd/Brother

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/brlaser-set-cups-filter-permission $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,brlaser))
