include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ffmpegtool
PKG_VERSION:=20251226

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-ffmpegtool
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for ffmpeg
	PKGARCH:=all
	DEPENDS:=+ffmpeg +ffprobe
endef

define Build/Compile
endef

define Package/luci-app-ffmpegtool/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci
	$(INSTALL_DIR) $(1)/usr/ffmpegtool
	$(INSTALL_BIN) ./files/ffmpegtool/* $(1)/usr/ffmpegtool
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/ffmpegtool.conf $(1)/etc/config/ffmpegtool
endef

$(eval $(call BuildPackage,luci-app-ffmpegtool))
