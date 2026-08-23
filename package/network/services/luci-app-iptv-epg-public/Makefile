include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-iptv-epg
PKG_VERSION:=2.11.29
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-iptv-epg
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=IPTV EPG Management (Shanghai Telecom)
	# 配置文件: opkg 重装/升级时保留用户修改 (selected 段/频道配置)
	CONFFILES:=/etc/config/iptv_epg
	PKGARCH:=all
	DEPENDS:=+luci-base +curl +tcpdump
endef

define Package/luci-app-iptv-epg/description
	IPTV EPG service: init.d management, auto route,
	cookie keepalive daemon, CGI service.
	Fetch 7-day EPG for UCI-configured channels daily.
	For DIYP player: epg.cgi provides program guide,
	play.cgi (TVOD path) enables live + EPG click lookback,
	tsproxy.cgi proxies lookback TS segments.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-iptv-epg/install
	# LuCI controller/CBI/view
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./luasrc/controller/iptv-epg.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./luasrc/model/cbi/iptv_epg.lua $(1)/usr/lib/lua/luci/model/cbi/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/iptv_epg
	$(INSTALL_DATA) ./luasrc/view/iptv_epg/*.htm $(1)/usr/lib/lua/luci/view/iptv_epg/
	# Backend tools
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./root/usr/bin/iptv_epg $(1)/usr/bin/
	$(INSTALL_BIN) ./root/usr/bin/epg_cookie_daemon.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./root/usr/bin/epg_auth.sh $(1)/usr/bin/
	$(INSTALL_BIN) ./root/usr/bin/epg_getkey.sh $(1)/usr/bin/
	# 注: 公共版不打包 EPG 认证 RSA 私钥 (电信私密凭据); epg_auth.sh 缺失时自动调用 epg_getkey.sh 从 GitHub 提取
	# init.d service
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/iptv-epg $(1)/etc/init.d/
	# CGI
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./root/www/cgi-bin/epg.cgi $(1)/www/cgi-bin/
	$(INSTALL_BIN) ./root/www/cgi-bin/play.cgi $(1)/www/cgi-bin/
	$(INSTALL_BIN) ./root/www/cgi-bin/tsproxy.cgi $(1)/www/cgi-bin/
	# TVOD symlink (DIYP 5.2.0 needs TVOD in path to enable EPG lookback)
	$(INSTALL_DIR) $(1)/www/cgi-bin/TVOD
	ln -sf ../play.cgi $(1)/www/cgi-bin/TVOD/play.cgi
	# Config
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/iptv_epg $(1)/etc/config/
	# 公共版: 不内置私钥 (电信账号直登不可用, 走机顶盒抓包采集)
	# Channel map (name|EPG_ID|multicast) — 按运营商分文件, channel_map.txt 由 init.d 软链接
	$(INSTALL_DIR) $(1)/usr/share/iptv_epg
	$(INSTALL_DATA) ./root/usr/share/iptv_epg/channel_map_telecom.txt $(1)/usr/share/iptv_epg/
	$(INSTALL_DATA) ./root/usr/share/iptv_epg/channel_map_unicom.txt $(1)/usr/share/iptv_epg/
	$(INSTALL_DATA) ./root/usr/share/iptv_epg/multicast_map.txt $(1)/usr/share/iptv_epg/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./root/etc/uci-defaults/iptv-epg $(1)/etc/uci-defaults/
	# hotplug: 修复 msd_lite 在 IPTV 接口前启动 (重启后无法播放)
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./root/etc/hotplug.d/iface/30-iptv-epg-msdlite $(1)/etc/hotplug.d/iface/
	# i18n (15.05 uses po2lmo)
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	po2lmo ./po/zh-cn/iptv-epg.po $(1)/usr/lib/lua/luci/i18n/iptv-epg.zh-cn.lmo
endef

$(eval $(call BuildPackage,luci-app-iptv-epg))
