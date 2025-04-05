include $(TOPDIR)/rules.mk

PKG_NAME:=mproxy
PKG_VERSION=1.0
PKG_RELEASE:=1

PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/package.mk

define Package/mproxy
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Lightway HTTP proxy
	URL:=https://github.com/lonsx/mproxy-mod
endef

define Package/mproxy/description
	Lightway HTTP proxy in C.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/mproxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mproxy $(1)/usr/bin/mproxy
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/mproxy $(1)/etc/init.d/mproxy
endef

$(eval $(call BuildPackage,mproxy))
