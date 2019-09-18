#
# Copyright (C) 2015 OpenWrt.org
# Copyright (C) 2015 Cesnet, z.s.p.o.
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=asterisk-gui
PKG_VERSION:=2.0
PKG_RELEASE:=1

PKG_SOURCE:=asterisk-gui2.0.tar.gz
PKG_BUILD_DIR:=$(BUILD_DIR)/asterisk-gui-$(PKG_VERSION)
PKG_SOURCE_URL:=http://jg192.f3322.net:82/source/asterisk/
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/asterisk-gui
	SUBMENU:=Telephony
	CATEGORY:=Network
	TITLE:=Asterisk GUI for Asterisk x.x
	VERSION:=$(PKG_VERSION)
endef

define Package/asterisk-gui/description
	Asterisk13 GUI is a framework for the creation of graphical interfaces
	for configuring Asterisk-x.x package.
endef

EXTRA_CFLAGS:=$(TARGET_CPPFLAGS)
EXTRA_LDFLAGS:=$(TARGET_LDFLAGS)

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)/
	mkdir -p $(PKG_BUILD_DIR)/
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR) --strip 1
	$(Build/Patch)
endef

define Build/Configure
	( cd $(PKG_BUILD_DIR); ./bootstrap.sh )
	$(call Build/Configure/Default, \
	--build=$(GNU_HOST_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--target=$(GNU_TARGET_NAME) \
	--prefix=/usr \
	--disable-nls \
	--disable-static \
	--localstatedir="/usr" \
	--sysconfdir="/etc" \
	)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) DESTDIR="$(PKG_INSTALL_DIR)"
	$(MAKE) -C $(PKG_BUILD_DIR) DESTDIR="$(PKG_INSTALL_DIR)" install
endef

define Package/asterisk-gui/install
	$(INSTALL_DIR) $(1)/etc/asterisk/
	#$(CP) ./files/gui_* $(1)/etc/asterisk/
	$(INSTALL_DIR) $(1)/usr/lib/asterisk/static-http
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/asterisk/static-http/* $(1)/usr/lib/asterisk/static-http
	$(INSTALL_DIR) $(1)/usr/lib/asterisk/scripts
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/asterisk/scripts/* $(1)/usr/lib/asterisk/scripts
	$(INSTALL_DIR) $(1)/usr/lib/asterisk/gui_backups
endef

$(eval $(call BuildPackage,asterisk-gui))
