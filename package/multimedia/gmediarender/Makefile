include $(TOPDIR)/rules.mk

PKG_NAME:=gmediarender
PKG_VERSION:=0.0.9
PKG_RELEASE:=1
PKG_MAINTAINER:=h.zeller@acm.org

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/hzeller/gmrender-resurrect.git
PKG_SOURCE_VERSION:=b2362c3b60991f0ed1e6493fce7de3ee2e74c8cb
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_MD5SUM:=862accc1d9aaad3991f759c522c6c17e

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
  DEPENDS:= +gstreamer1 +glib2 +libupnp \
	+gstreamer1-plugins-base +gst1-plugins-base \
	+gstreamer1-plugins-good +gst1-plugins-good \
	+gstreamer1-utils +gst1-libav
endef

define Package/gmrender/description
	Headless UPnP Renderer
endef

TARGET_CFLAGS += -std=gnu99

define Package/gmediarender/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/gmediarender $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/gmediarender.init $(1)/etc/init.d/gmediarender
	$(INSTALL_DIR) $(1)/usr/share/gmediarender/
	#$(INSTALL_DATA) ./files/*.png $(1)/usr/share/gmediarender/
endef

$(eval $(call BuildPackage,gmediarender))
