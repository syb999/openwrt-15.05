include $(TOPDIR)/rules.mk

PKG_NAME:=fixwlanmac
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/fixwlanmac
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:= fix wifi macaddress
endef

define Build/Compile
endef

define Package/fixwlanmac/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/fixwlanmac $(1)/etc/init.d/fixwlanmac
endef

$(eval $(call BuildPackage,fixwlanmac))
