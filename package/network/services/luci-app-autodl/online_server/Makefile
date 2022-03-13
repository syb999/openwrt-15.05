include $(TOPDIR)/rules.mk

PKG_NAME:=online_server
PKG_VERSION:=20220313

include $(INCLUDE_DIR)/package.mk

define Package/online_server
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=Web Servers/Proxies
	TITLE:= online_server
	PKGARCH:=all
endef

define Build/Compile
endef

define Package/online_server/install
	$(INSTALL_DIR) $(1)/usr/online_server
	$(INSTALL_BIN) ./files/dexmly.py $(1)/usr/online_server
	$(INSTALL_DIR) $(1)/usr/online_server/scripts
	$(INSTALL_BIN) ./files/scripts/* $(1)/usr/online_server/scripts
endef

$(eval $(call BuildPackage,online_server))
