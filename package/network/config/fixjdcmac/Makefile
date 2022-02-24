include $(TOPDIR)/rules.mk

PKG_NAME:=fixjdcmac
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/fixjdcmac
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:= fix JDCloud wifi macaddress
endef

define Build/Compile
endef

define Package/fixjdcmac/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/jdcfixmac $(1)/etc/init.d/jdcfixmac
endef

$(eval $(call BuildPackage,fixjdcmac))
