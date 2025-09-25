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
	$(INSTALL_BIN) ./files/panel_ap/panel_ap.sh $(1)/lib/panel_ap
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/init.d/panel_ap-init $(1)/etc/init.d/panel_ap-init
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/panel_ap_config $(1)/etc/config/panel_ap_config
ifdef CONFIG_TARGET_ramips_mt7628_WNA4320V2
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) ./files/button/wna4320v2 $(1)/etc/rc.button/wps
endif
ifdef CONFIG_TARGET_ar71xx_generic_100mshBOX-HQ65
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) ./files/button/100msh $(1)/etc/rc.button/BTN_1
endif
ifdef CONFIG_TARGET_ar71xx_generic_100mshBOX-HQ65-RTC-DS1307
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) ./files/button/100msh $(1)/etc/rc.button/BTN_1
endif
ifdef CONFIG_TARGET_ramips_rt305x_DEVICE_x9
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) ./files/button/hiker_wan $(1)/etc/rc.button/BTN_1
	$(INSTALL_BIN) ./files/button/hiker_usb $(1)/etc/rc.button/BTN_0
	$(INSTALL_BIN) ./files/button/hiker_lan $(1)/etc/rc.button/BTN_2
endif

endef

$(eval $(call BuildPackage,panel-ap-setup))
