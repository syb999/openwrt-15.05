include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-wifi-disconnect-low-signal
PKG_VERSION:=1
PKG_RELEASE:=

include $(INCLUDE_DIR)/package.mk


define Package/luci-app-wifi-disconnect-low-signal
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support for wifi-disconnect-low-signal
	DEPENDS:=+lua +libiwinfo-lua +libubus-lua +luci-lib-nixio +libuci-lua
endef

define Package/luci-app-wifi-disconnect-low-signal/description
	This package contains LuCI configuration no page for wifi-disconnect-low-signal.
endef

define Build/Compile
endef

define Package/luci-app-wifi-disconnect-low-signal/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) ./files/etc/uci-defaults/luci-wifi-disconnect-low-signal $(1)/etc/uci-defaults/luci-wifi-disconnect-low-signal
	$(INSTALL_BIN) ./files/etc/init.d/* $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/usr/lib/lua/luci/controller/wifi-disconnect.lua $(1)/usr/lib/lua/luci/controller/wifi-disconnect.lua
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/* $(1)/usr/lib/lua/luci/view/

	$(INSTALL_BIN) ./files/bin/* $(1)/usr/bin/
endef


$(eval $(call BuildPackage,luci-app-wifi-disconnect-low-signal))
