include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-netdata
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-netdata
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for netdata
	PKGARCH:=all
	DEPENDS:=+netdata
endef

define Package/luci-app-netdata/description
endef


define Build/Compile
endef

define Package/luci-app-netdata/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
endef

$(eval $(call BuildPackage,luci-app-netdata))
