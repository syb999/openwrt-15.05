include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-gmediarender
PKG_VERSION:=2024-06-13

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-gmediarender
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for gmediarender
	PKGARCH:=all
	DEPENDS:=+gmediarender +file
endef

define Package/luci-app-gmediarender/description
	Easy to change binding interface
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/luasrc/i18n/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Compile
endef

define Package/luci-app-gmediarender/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/gmediarender.conf $(1)/etc/config/gmediarender
	$(INSTALL_DIR) $(1)/usr/share/gmediarender/
	$(INSTALL_BIN) ./files/gmr* $(1)/usr/share/gmediarender
	$(INSTALL_BIN) ./files/flvtomp4 $(1)/usr/share/gmediarender
	$(INSTALL_BIN) ./files/tstomp4 $(1)/usr/share/gmediarender
	$(INSTALL_BIN) ./files/m4atomp3 $(1)/usr/share/gmediarender
endef

$(eval $(call BuildPackage,luci-app-gmediarender))
