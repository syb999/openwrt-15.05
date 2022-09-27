include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-freeradius2
PKG_VERSION:=20220925

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-freeradius2
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for freeradius2
	PKGARCH:=all
	DEPENDS:=+freeradius2 +freeradius2-utils
endef

define Package/luci-app-freeradius2/description
	freeradius2 luci page
endef

define Build/Compile
endef

define Package/luci-app-freeradius2/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/freeradius2.conf $(1)/etc/config/freeradius2
	$(INSTALL_DIR) $(1)/etc/freeradius2
	$(INSTALL_BIN) ./files/initconf $(1)/etc/freeradius2/initconf
endef

$(eval $(call BuildPackage,luci-app-freeradius2))
