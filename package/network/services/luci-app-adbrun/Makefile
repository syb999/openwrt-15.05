include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-adbrun
PKG_VERSION:=0.1
PKG_RELEASE:=20201101

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-adbrun
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for adb
	PKGARCH:=all
	DEPENDS:=+adb +coreutils +coreutils-nohup
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-adbrun/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/adbrun
	$(INSTALL_BIN) ./files/adbrun/* $(1)/usr/adbrun
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/adbrun.conf $(1)/etc/config/adbrun
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/adbrun.init $(1)/etc/init.d/adbrun
endef

$(eval $(call BuildPackage,luci-app-adbrun))
