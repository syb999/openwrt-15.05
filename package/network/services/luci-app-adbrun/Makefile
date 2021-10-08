include $(TOPDIR)/rules.mk


PKG_NAME:=luci-app-adbrun
PKG_VERSION:=20211008
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-adbrun
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for adb
	PKGARCH:=all
	DEPENDS:=+adb
endef

define Package/luci-app-adbrun/description
	python3 script depends pillow
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-adbrun/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/adbrun
	$(INSTALL_BIN) ./files/adbrun/adbcommand.sh $(1)/usr/adbrun
	$(INSTALL_DIR) $(1)/usr/adbrun/720x1280
	$(INSTALL_BIN) ./files/adbrun/720x1280/* $(1)/usr/adbrun/720x1280
	$(INSTALL_DIR) $(1)/usr/adbrun/1080x2244
	$(INSTALL_BIN) ./files/adbrun/1080x2244/* $(1)/usr/adbrun/1080x2244
	$(INSTALL_DIR) $(1)/usr/adbrun/1080x1920
	$(INSTALL_BIN) ./files/adbrun/1080x1920/* $(1)/usr/adbrun/1080x1920
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/adbrun.conf $(1)/etc/config/adbrun
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/adbrun.init $(1)/etc/init.d/adbrun
endef

$(eval $(call BuildPackage,luci-app-adbrun))
