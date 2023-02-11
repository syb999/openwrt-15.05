#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=MPlayer
PKG_VERSION:=1.1.1
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=http://www.mplayerhq.hu/MPlayer/releases/
PKG_MD5SUM:=39dd55f30eb5403f219a606e79a6648a

PKG_MAINTAINER:= http://www.mplayerhq.hu
PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=Copyright

include $(INCLUDE_DIR)/package.mk

define Package/MPlayer
  SECTION:=multimedia
  CATEGORY:=Multimedia
  DEPENDS:= +libpthread +libncurses +libmad +libc +alsa-lib +zlib +liblzo +libbz2 +libmpg123 +libfaad2
  TITLE:=MPlayer1.1.1
  URL:=$(PKG_SOURCE_URL)
endef

TARGET_CFLAGS += -DHAVE_BYTESWAP_H

ifeq ($(ARCH),mipsel)
	platform=mips
else ifeq ($(ARCH),mips)
	platform=mips
else ifeq ($(ARCH),arm)
	platform=arm
else
	platform=x86_64
endif

CONFIGURE_ARGS= \
	--enable-cross-compile	\
	--host-cc=gcc		\
	--cc=$(ARCH)-openwrt-linux-gcc	\
	--target=$(platform)-linux	\
        --prefix=$(CONFIGURE_PREFIX) \
        --bindir=$(CONFIGURE_PREFIX)/bin \
        --datadir=$(CONFIGURE_PREFIX)/share \
	--disable-fbdev		\
	--disable-gif		\
	--disable-png		\
	--disable-real		\
	--disable-speex		\
	--disable-dvdread	\
	--disable-mencoder	\
	--disable-jpeg		\
	--disable-ossaudio	\
	--disable-theora	\
	--disable-tv		\
	--disable-tga		\
	--disable-pnm		\
	--disable-md5sum	\
	--disable-w32threads	\
	--disable-win32dll	\
	--disable-qtx		\
	--disable-xanim		\
	--disable-radio-v4l2	\
	--disable-radio-bsdbt848	\
	--disable-tv-v4l1	\
	--disable-tv-v4l2	\
	--disable-tv-bsdbt848	\
	--disable-pvr		\
	--disable-liba52	\
	--disable-libvpx-lavc	\
	--disable-encoder=ENCODER	\
	--disable-muxer=MUXER		\
	--enable-alsa		\
	--enable-fbdev		\
	--enable-mad		\
	--enable-v4l2		\

define Package/MPlayer/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mplayer $(1)/usr/bin/
endef

$(eval $(call BuildPackage,MPlayer))
