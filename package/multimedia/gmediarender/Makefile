include $(TOPDIR)/rules.mk

PKG_NAME:=gmediarender
PKG_VERSION:=0.0.7
PKG_RELEASE:=1
PKG_MAINTAINER:=h.zeller@acm.org

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/hzeller/gmrender-resurrect.git
PKG_MIRROR_HASH:=01150d750b0cdd4ef9b221be031871f5386bd984031135fea3eff071b5f1f202
PKG_SOURCE_VERSION:=a836de4fd198bead9e05b5561073a71e84bb957d
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=COPYING

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/gmediarender
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=gmediarender
  URL:=https://github.com/hzeller/gmrender-resurrect
  DEPENDS:= +gstreamer1 +glib2 +libupnp
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
