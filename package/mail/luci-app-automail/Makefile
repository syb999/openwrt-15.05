include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-automail
PKG_VERSION:=20230825

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-automail
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for automail
	PKGARCH:=all
	DEPENDS:=+mutt +msmtp +fetchmail
endef

define Build/Compile
endef

define Package/luci-app-automail/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/automail
	$(INSTALL_BIN) ./files/automail/* $(1)/usr/automail
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/automail.conf $(1)/etc/config/automail
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/automail.init $(1)/etc/init.d/automail
endef

$(eval $(call BuildPackage,luci-app-automail))
