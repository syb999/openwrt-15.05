include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-gmediarender
PKG_VERSION:=1
PKG_RELEASE:=

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-gmediarender
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for gmediarender
	PKGARCH:=all
	DEPENDS:=+gmediarender
endef

define Package/luci-app-gmediarender/description
	Easy to change binding IP
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
endef

$(eval $(call BuildPackage,luci-app-gmediarender))
