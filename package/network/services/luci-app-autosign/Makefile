include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-autosign
PKG_VERSION:=0.4
PKG_RELEASE:=20210426

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-autosign
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for auto sign in
	PKGARCH:=all
	DEPENDS:=+curl
endef

define Build/Compile
endef

define Package/luci-app-autosign/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/autosign
	$(INSTALL_BIN) ./files/autosign/* $(1)/usr/autosign
	$(INSTALL_DIR) $(1)/etc/
	$(INSTALL_CONF) ./files/autosignvacationlist $(1)/etc/autosignvacationlist
	$(INSTALL_CONF) ./files/autosignworklist $(1)/etc/autosignworklist
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/autosign.conf $(1)/etc/config/autosign
endef

$(eval $(call BuildPackage,luci-app-autosign))
