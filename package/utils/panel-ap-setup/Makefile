include $(TOPDIR)/rules.mk

PKG_NAME:=panel-ap-setup
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/panel-ap-setup
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:= panel-ap-setup
	PKGARCH:=all
endef

define Build/Compile
endef

define Package/panel-ap-setup/install
	$(INSTALL_DIR) $(1)/lib/panel_ap
	$(INSTALL_BIN) ./files/panel_ap/* $(1)/lib/panel_ap
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init.d/panel_ap-init $(1)/etc/init.d/panel_ap-init
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/panel_ap_config $(1)/etc/config/panel_ap_config
ifdef CONFIG_TARGET_ramips_mt7628_WNA4320V2
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) ./files/wlan/wna4320v2 $(1)/etc/rc.button/wps
endif
endef

$(eval $(call BuildPackage,panel-ap-setup))
