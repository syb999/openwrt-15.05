#
# Copyright (C) 2012-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=nginx-rtmp-server
PKG_VERSION:=1.25.0
PKG_RELEASE:=1

PKG_SOURCE:=nginx-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://nginx.org/download/
PKG_MD5SUM:=6f33e249f8d16b7e6ca48d410e58666e

PKG_BUILD_DIR:=$(BUILD_DIR)/nginx-$(PKG_VERSION)

PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1
PKG_INSTALL:=1

PKG_CONFIG_DEPENDS := \
	CONFIG_NGINX_SSL \
	CONFIG_NGINX_RTMP_MODULE

include $(INCLUDE_DIR)/package.mk

define Package/nginx-rtmp-server
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Web Servers/Proxies
  TITLE:=Nginx RTMP server
  URL:=http://nginx.org/
  DEPENDS:=+libopenssl +libpthread +libpcre +zlib +libpcre2
  MENU:=1
endef

define Package/nginx-rtmp-server/description
 nginx-rtmp server, written by Igor Sysoev.
endef

define Package/nginx-rtmp-server/config
  source "$(SOURCE)/Config.in"
endef

config_files=nginx.conf mime.types

define Package/nginx-rtmp-server/conffiles
/etc/nginx/
endef

ADDITIONAL_MODULES:= --with-http_ssl_module \
	--add-module=$(PKG_BUILD_DIR)/nginx-rtmp

TARGET_CFLAGS += -fvisibility=hidden -ffunction-sections -fdata-sections
TARGET_LDFLAGS += -Wl,--gc-sections

define Build/Configure
	( cd $(PKG_BUILD_DIR) ; \
		./configure \
			--crossbuild=Linux::$(ARCH) \
			--prefix=/usr \
			--conf-path=/etc/nginx/nginx-rtmp.conf \
			$(ADDITIONAL_MODULES) \
			--error-log-path=/var/log/nginx-rtmp-error.log \
			--pid-path=/var/run/nginx-rtmp.pid \
			--lock-path=/var/lock/nginx-rtmp.lock \
			--with-cc="$(TARGET_CC)" \
			--with-cc-opt="$(TARGET_CPPFLAGS) $(TARGET_CFLAGS)" \
			--with-ld-opt="$(TARGET_LDFLAGS)" \
			--without-http_upstream_zone_module \
	)
endef

define Package/nginx-rtmp-server/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/nginx $(1)/usr/sbin/nginx-rtmp
	$(INSTALL_DIR) $(1)/etc/nginx
	$(INSTALL_DATA) ./files/nginx-rtmp.conf $(1)/etc/nginx/nginx-rtmp.conf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/nginx-rtmp.init $(1)/etc/init.d/nginx-rtmp
	$(INSTALL_DIR) $(1)/usr/local/nginx-rtmp-module
	$(INSTALL_DATA) ./files/stat.xsl $(1)/usr/local/nginx-rtmp-module/stat.xsl
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(call Prepare/nginx-rtmp)
endef

define Download/nginx-rtmp
    VERSION:=f0ea62342a4eca504b311cd5df910d026c3ea4cf
    SUBDIR:=nginx-rtmp
    FILE:=nginx-rtmp-module-$(PKG_VERSION)-$$(VERSION).tar.gz
    URL:=https://github.com/ut0mt8/nginx-rtmp-module.git
    MIRROR_MD5SUM:=bdb5ebf2db90c09e5e56214f216e8e4e
    PROTO:=git
endef
$(eval $(call Download,nginx-rtmp))

define  Prepare/nginx-rtmp
	$(eval $(Download/nginx-rtmp))
	gzip -dc $(DL_DIR)/$(FILE) | tar -C $(PKG_BUILD_DIR) $(TAR_OPTIONS)
endef

$(eval $(call BuildPackage,nginx-rtmp-server))
