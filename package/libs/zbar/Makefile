include $(TOPDIR)/rules.mk

PKG_NAME:=zbar
PKG_VERSION:=0.10
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=@SF/$(PKG_NAME)
PKG_MD5SUM:=0fd61eb590ac1bab62a77913c8b086a5

PKG_LICENSE:=LGPLv2.1 GPLv2
PKG_LICENSE_FILES:=COPYING.LIB COPYING

PKG_INSTALL:=1
PKG_BUILD_DEPENDS:=libiconv/host

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/nls.mk

define Package/zbar
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=ZBar
  URL:=https://github.com/ZBar/ZBar
  DEPENDS:=$(ICONV_DEPENDS) +libpthread +libjpeg-turbo
endef

define Package/zbar/description
  ZBar Bar Code Reader is an open source software suite 
  for reading barcodes from various sources.
endef

TARGET_CFLAGS += -fPIC
TARGET_LDFLAGS += -liconv

define Build/Configure
	$(call Build/Configure/Default, \
		--prefix=/usr \
		--enable-shared \
		--disable-static \
		--disable-video \
		--without-imagemagick \
		--without-gtk \
		--without-qt \
		--without-python \
	)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)
endef

define Package/zbar/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/zbar
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/*.so* $(1)/usr/lib/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/include/*.h $(1)/usr/include/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/include/zbar/*.h $(1)/usr/include/zbar
endef

$(eval $(call BuildPackage,zbar))

