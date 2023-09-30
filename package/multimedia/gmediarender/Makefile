include $(TOPDIR)/rules.mk

PKG_NAME:=gmediarender
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKG_MAINTAINER:=h.zeller@acm.org

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/hzeller/gmrender-resurrect.git
PKG_SOURCE_VERSION:=c455d130d12edd4501c373aea0ecad2158c9448c
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_MD5SUM:=cdca921fa5a45e819cb8c67ea59a45fe

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

CONFIGURE_ARGS+= \
	CFLAGS="$(TARGET_CFLAGS) -std=gnu99" \
	--with-build-cc="$(HOSTCC)" \
	--prefix="\usr"

define Package/gmediarender/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/gmediarender $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/gmediarender.init $(1)/etc/init.d/gmediarender
	$(INSTALL_DIR) $(1)/usr/share/gmediarender/
	$(INSTALL_DATA) ./files/*.png $(1)/usr/share/gmediarender/
endef

$(eval $(call BuildPackage,gmediarender))
