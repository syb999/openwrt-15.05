include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-voip
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-voip
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=VoIP SIP Configuration for China Telecom IMS
  DEPENDS:=+luci-base +luci-mod-admin-full +asterisk13 +asterisk13-app-confbridge \
           +asterisk13-app-exec +asterisk13-app-system +asterisk13-bridge-builtin-features \
           +asterisk13-bridge-simple +asterisk13-bridge-softmix +asterisk13-chan-sip \
           +asterisk13-codec-a-mu +asterisk13-codec-alaw +asterisk13-codec-g722 \
           +asterisk13-codec-ulaw +asterisk13-func-channel +asterisk13-func-shell \
           +asterisk13-res-musiconhold +asterisk13-res-rtp-asterisk \
           +asterisk13-res-rtp-multicast +asterisk13-res-srtp +asterisk13-app-verbose \
           +asterisk13-app-mixmonitor +asterisk13-format-wav +asterisk13-format-gsm \
           +asterisk13-codec-gsm +asterisk13-func-db +asterisk13-app-read
  PKGARCH:=all
endef

define Package/luci-app-voip/description
  LuCI application for Asterisk13 VoIP configuration
  Supports China Telecom IMS SIP trunk with automatic config conversion
  Features: Auto recording for extensions (8bit WAV format)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-voip/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/voip
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/voip
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n

	$(INSTALL_DATA) ./luasrc/controller/voip.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) ./luasrc/model/cbi/voip/trunk.lua $(1)/usr/lib/lua/luci/model/cbi/voip/
	$(INSTALL_DATA) ./luasrc/model/cbi/voip/extension.lua $(1)/usr/lib/lua/luci/model/cbi/voip/
	$(INSTALL_DATA) ./luasrc/model/cbi/voip/record_settings.lua $(1)/usr/lib/lua/luci/model/cbi/voip/
	$(INSTALL_DATA) ./luasrc/model/cbi/voip/pstn_handler.lua $(1)/usr/lib/lua/luci/model/cbi/voip/
	$(INSTALL_DATA) ./luasrc/view/voip/status.htm $(1)/usr/lib/lua/luci/view/voip/
	$(INSTALL_DATA) ./luasrc/view/voip/record_files.htm $(1)/usr/lib/lua/luci/view/voip/
	$(INSTALL_DATA) ./luasrc/view/voip/peer.htm $(1)/usr/lib/lua/luci/view/voip/
	$(INSTALL_DATA) ./root/etc/config/voip $(1)/etc/config/
	$(INSTALL_BIN) ./root/etc/init.d/voip $(1)/etc/init.d/
	
	# Compile PO file if present
	if [ -f ./po/zh-cn/voip.po ]; then \
		po2lmo ./po/zh-cn/voip.po $(1)/usr/lib/lua/luci/i18n/voip.zh-cn.lmo; \
	fi
endef

$(eval $(call BuildPackage,luci-app-voip))
