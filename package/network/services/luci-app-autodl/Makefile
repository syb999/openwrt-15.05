include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-autodl
PKG_VERSION:=0.4
PKG_RELEASE:=20201209

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-autodl
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for auto download m3u8 video
	PKGARCH:=all
	DEPENDS:=+python3-light +python3-requests +python3-logging +python3-urllib +python3-openssl
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-autodl/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/autodl
	$(INSTALL_BIN) ./files/autodl/* $(1)/usr/autodl
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/autodl.conf $(1)/etc/config/autodl
endef

$(eval $(call BuildPackage,luci-app-autodl))
