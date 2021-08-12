include $(TOPDIR)/rules.mk

PKG_NAME:=mt7615-dbdc-setup
PKG_VERSION:=0.2.3

include $(INCLUDE_DIR)/package.mk

define Package/mt7615-dbdc-setup
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:= mt7615-dbdc autoset
	PKGARCH:=all
endef

define Build/Compile
endef

define Package/mt7615-dbdc-setup/install
	$(INSTALL_DIR) $(1)/lib/wifi
	$(INSTALL_BIN) ./files/wifi/* $(1)/lib/wifi
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init.d/wifi-init $(1)/etc/init.d/wifi-init
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/base_config $(1)/etc/config/base_config
endef

$(eval $(call BuildPackage,mt7615-dbdc-setup))
