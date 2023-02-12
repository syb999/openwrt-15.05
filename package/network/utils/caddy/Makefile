# Copyright (C) 2010-2021 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=caddy
PKG_VERSION:=1
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Caddy is an open source web server
  URL:=https://caddyserver.com
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  DEPENDS:=@(TARGET_kirkwood||TARGET_mvebu||TARGET_armvirt||TARGET_ar71xx||TARGET_ramips||TARGET_x86_64||TARGET_x86)
endef

define Package/$(PKG_NAME)/description
Caddy is an extensible server platform that uses TLS by default.
endef

ifeq ($(ARCH),x86_64)
	caddy_ARCH:=x86_64
	PKG_MD5SUM:=9db7b529884bc1fcc3879bfba910b42e
endif

ifeq ($(ARCH),i386)
	caddy_ARCH:=i386
	PKG_MD5SUM:=3e4e6f00de24311245251a2b7b851b59
endif


ifeq ($(ARCH),mipsel)
ifdef CONFIG_TARGET_ramips_mt7621
	caddy_ARCH:=mt7621
	PKG_MD5SUM:=c4d2ae4c57a38769444ab069323db81d
else
	caddy_ARCH:=mt7620
	PKG_MD5SUM:=b1abdf596133430fd89a80f3a6038a70
endif
endif

ifeq ($(ARCH),mips)
	caddy_ARCH:=ar71xx
	PKG_MD5SUM:=cbb29813483e623344fe07907d604748
endif

ifeq ($(ARCH),arm)
ifdef CONFIG_TARGET_kirkwood
	caddy_ARCH:=kirkwood
	PKG_MD5SUM:=d6d9b3a67c1dc1c64c0a598b78c4a7c7
else ifdef CONFIG_TARGET_armvirt
	caddy_ARCH:=kirkwood
	PKG_MD5SUM:=d6d9b3a67c1dc1c64c0a598b78c4a7c7
else
	caddy_ARCH:=mvebu
	PKG_MD5SUM:=3797c47aab007dacb7c7832bcd5dd1c1
endif
endif

PKG_SOURCE_URL:=https://raw.githubusercontent.com/syb999/cc-upx/master/caddy/$(caddy_ARCH)
PKG_SOURCE:=caddy

define Build/Prepare
	mv $(DL_DIR)/$(PKG_SOURCE) $(PKG_BUILD_DIR)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/caddy
	$(INSTALL_CONF) ./files/Caddyfile $(1)/etc/caddy/Caddyfile
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/caddy.init $(1)/etc/init.d/caddy
	$(INSTALL_DIR) $(1)/etc/security
	$(INSTALL_CONF) ./files/limits.conf $(1)/etc/security/limits.conf
	$(INSTALL_DIR) $(1)/usr/bin/caddy
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/caddy $(1)/usr/bin/caddy
	ln -s /usr/bin/caddy/caddy $(1)/bin/caddy
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
