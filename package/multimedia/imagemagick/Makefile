#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=imagemagick
PKG_VERSION:=7.0.9
PKG_REVISION:=5
PKG_RELEASE:=2
PKG_MAINTAINER:=Val Kulkov <val.kulkov@gmail.com>

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_REVISION).tar.gz
PKG_SOURCE_URL:=http://github.com/ImageMagick/ImageMagick/archive/$(PKG_VERSION)-$(PKG_REVISION)
PKG_MD5SUM:=640f933187bf1c8f198ea5e777cca9f7
PKG_BUILD_DIR:=$(BUILD_DIR)/ImageMagick-$(PKG_VERSION)-$(PKG_REVISION)

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:imagemagick:imagemagick

PKG_USE_MIPS16:=0
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/imagemagick/Default
  SECTION:=multimedia
  CATEGORY:=Multimedia
  TITLE:=Image manipulation tools
  URL:=https://www.imagemagick.org/
endef

define Package/imagemagick
  $(call Package/imagemagick/Default)
  DEPENDS:=+libltdl +libpthread +zlib +libfreetype +libpng +libjpeg-turbo +libtiff +libwebp
endef

define Package/imagemagick/description
ImageMagick is a free and open-source software suite for displaying,
converting, and editing raster image and vector image files.
NOTE: this package may not be suitable for many embedded devices because
of its large size. Consider using extroot or alternatively consider
graphicsmagick which is smaller but similar in functionality.
endef

define Package/imagemagick/conffiles
/etc/ImageMagick-7/colors.xml
/etc/ImageMagick-7/delegates.xml
/etc/ImageMagick-7/log.xml
/etc/ImageMagick-7/mime.xml
/etc/ImageMagick-7/policy.xml
/etc/ImageMagick-7/quantization-table.xml
/etc/ImageMagick-7/thresholds.xml
/etc/ImageMagick-7/type-apple.xml
/etc/ImageMagick-7/type-dejavu.xml
/etc/ImageMagick-7/type-ghostscript.xml
/etc/ImageMagick-7/type-urw-base35.xml
/etc/ImageMagick-7/type-windows.xml
/etc/ImageMagick-7/type.xml
endef

CONFIGURE_ARGS += \
	--enable-shared \
	--disable-static \
	--disable-docs \
	--enable-dependency-tracking \
	--with-modules \
	--with-threads \
	--with-ltdl \
	--with-zlib \
	--disable-hdri \
	--with-quantum-depth=8 \
	--disable-deprecated \
	--disable-cipher \
	--without-bzlib \
	--without-autotrace \
	--without-djvu \
	--without-dps \
	--without-fftw \
	--without-flif \
	--without-fpx \
	--without-fontconfig \
	--without-gslib \
	--without-gvc \
	--without-heic \
	--without-jbig \
	--without-lcms \
	--without-lqr \
	--without-lzma \
	--without-magick-plus-plus \
	--without-openexr \
	--without-openjp2 \
	--without-raqm \
	--without-raw \
	--without-x \
	--without-zstd \
	--without-gslib \
	--without-gvc \
	--without-pango \
	--without-perl \
	--without-rsvg \
	--without-wmf \
	--without-xml \
	--with-freetype \
	--with-jpeg \
	--with-png \
	--with-tiff \
	--with-webp

TARGET_CFLAGS += $(if $(CONFIG_GCC_USE_VERSION_10),,-flto)

ifdef CONFIG_USE_UCLIBC
  TARGET_CFLAGS += -std=gnu99
endif

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/include/* \
		$(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/*.so* \
		$(1)/usr/lib/

	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(INSTALL_DATA) \
		$(PKG_INSTALL_DIR)/usr/lib/pkgconfig/* \
		$(1)/usr/lib/pkgconfig/
endef

IMlibdir:=usr/lib/ImageMagick-$(PKG_VERSION)
define Package/imagemagick/install
	$(INSTALL_DIR) $(1)/etc $(1)/usr/bin $(1)/$(IMlibdir)
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/*.so.* $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
	$(RM) $(1)/usr/bin/*-config
	$(CP) $(PKG_INSTALL_DIR)/etc/ImageMagick-* $(1)/etc/
	$(CP) $(PKG_INSTALL_DIR)/$(IMlibdir)/* $(1)/$(IMlibdir)/
endef

$(eval $(call BuildPackage,imagemagick))
