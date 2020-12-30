# Copyright (C) 2019 Lucian Cristian <lucian.cristian@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=libxdmcp
PKG_VERSION:=1.1.3
PKG_RELEASE:=1

PKG_SOURCE_URL:=https://www.x.org/pub/individual/lib/
PKG_SOURCE:=libXdmcp-$(PKG_VERSION).tar.bz2
PKG_MD5SUM:=115c5c12ecce0e749cd91d999a5fd160

PKG_BUILD_DIR:=$(BUILD_DIR)/libXdmcp-$(PKG_VERSION)

PKG_BUILD_DEPENDS:=xproto
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/libxdmcp
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+libbsd
  TITLE:=X11 Display Manager Control Protocol library
  URL:=http://xorg.freedesktop.org/
endef

TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

CONFIGURE_ARGS += \
  --prefix=/usr \
  --disable-docs \
  --without-fop \
  --without-xmlto \
  --without-xsltproc

define Build/InstallDev
	$(INSTALL_DIR) \
	  $(1)/usr/include \
	  $(1)/usr/lib

	$(CP) \
	  $(PKG_INSTALL_DIR)/usr/include/* \
	  $(1)/usr/include/

	$(CP) \
	  $(PKG_INSTALL_DIR)/usr/lib/{pkgconfig,*.so*} \
	  $(1)/usr/lib/
endef

define Package/libxdmcp/install
	$(INSTALL_DIR) \
	  $(1)/usr/lib

	$(CP) \
	  $(PKG_INSTALL_DIR)/usr/lib/*.so* \
	  $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libxdmcp))
