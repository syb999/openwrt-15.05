include $(TOPDIR)/rules.mk

PKG_NAME:=gmediarender
PKG_VERSION:=2020-01-10
PKG_RELEASE:=1
PKG_MAINTAINER:=h.zeller@acm.org

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mill1000/gmrender-resurrect.git
PKG_SOURCE_VERSION:=26d8f7edf5336bc30f7334c6ad459bf7f4f90ff2
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_MD5SUM:=aa2196ab855b47bd874769d592d7f876

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/gmediarender
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=gmediarender
  URL:=https://github.com/mill1000/gmrender-resurrect
  DEPENDS:= +gstreamer1 +glib2 +libupn
endef

define Package/gmrender/description
	Headless UPnP Renderer
endef

TARGET_CFLAGS += -std=gnu99

define Package/gmediarender/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Enabling rc.d symlink for gmediarender"
	/etc/init.d/gmediarender enable
fi
exit 0
endef

define Package/gmediarender/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Removing rc.d symlink for gmediarender"
	/etc/init.d/gmediarender disable
fi
exit 0
endef

define Package/gmediarender/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/gmediarender $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/gmediarender.init $(1)/etc/init.d/gmediarender
	$(INSTALL_DIR) $(1)/usr/share/gmediarender/
	$(INSTALL_DATA) ./files/*.png $(1)/usr/share/gmediarender/
endef

$(eval $(call BuildPackage,gmediarender))
