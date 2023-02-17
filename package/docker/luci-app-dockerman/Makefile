include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dockerman
PKG_VERSION:=v0.5.25

PKG_LICENSE:=AGPL-3.0
PKG_MAINTAINER:=lisaac <lisaac.cn@gmail.com> \
		Florian Eckert <fe@dev.tdt.de>

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-dockerman
 	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for docker
	PKGARCH:=all
	DEPENDS:=+luci-lib-docker \
		+luci-lib-ip \
		+docker \
		+ttyd \
		+cgroup-tools
endef

define Build/Compile
endef

define Package/luci-app-dockerman/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	cp -pR ./luasrc/* $(1)/usr/lib/lua/luci

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_CONF) ./root/usr/share/rpcd/acl.d/luci-app-dockerman.json $(1)/usr/share/rpcd/acl.d/luci-app-dockerman.json

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/dockerman $(1)/etc/init.d/dockerman

	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./root/etc/uci-defaults/luci-app-dockerman $(1)/etc/uci-defaults/luci-app-dockerman

	$(INSTALL_DIR) $(1)/www/luci-static/resources/dockerman
	$(INSTALL_CONF) ./files/* $(1)/www/luci-static/resources/dockerman
endef

$(eval $(call BuildPackage,luci-app-dockerman))
