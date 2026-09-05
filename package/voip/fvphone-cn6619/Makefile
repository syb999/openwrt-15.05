#
# fvphone-cn6619: stock CN6619 (ZM-WR2500) VoIP userspace for OpenWrt 15.05
# fvphone daemon + libortp + looprun + voipcmd_proxy/fvcli + configs.
# Needs kmod-slic-cn6619 (slicdrv). No compilation - binary package.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/package.mk

PKG_NAME:=fvphone-cn6619
PKG_RELEASE:=1

define Package/fvphone-cn6619
  SUBMENU:=Telephony
  SECTION:=net
  CATEGORY:=Network
  TITLE:=CN6619 VoIP fvphone userspace (ZM-WR2500)
  DEPENDS:=kmod-slic-cn6619 +libpthread
endef

define Package/fvphone-cn6619/description
  ZM-WR2500 (CN6619) stock VoIP userspace: fvphone daemon + libortp +
  looprun watchdog + voipcmd_proxy/fvcli + default account config
  (edit /opt/voip/fv_voip.cfg). Requires
  kmod-slic-cn6619 (/dev/aci0-1 + /proc/slic ioctl bridge).
endef

define Build/Compile
endef

define Package/fvphone-cn6619/install
	$(INSTALL_DIR) $(1)/opt/voip
	$(INSTALL_BIN) ./files/fvphone $(1)/opt/voip/
	$(INSTALL_BIN) ./files/looprun $(1)/opt/voip/
	$(INSTALL_BIN) ./files/voipcmd_proxy $(1)/opt/voip/
	$(INSTALL_BIN) ./files/fvcli $(1)/opt/voip/
	$(INSTALL_DATA) ./files/libortp.so.8.0.0 $(1)/opt/voip/
	ln -sf libortp.so.8.0.0 $(1)/opt/voip/libortp.so.8
	$(INSTALL_DATA) ./files/fv_voip.cfg $(1)/opt/voip/
	$(INSTALL_DATA) ./files/fv_voip_tones_china.cfg $(1)/opt/voip/
	$(INSTALL_DATA) ./files/signature $(1)/opt/voip/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/voip $(1)/etc/init.d/
endef

$(eval $(call BuildPackage,fvphone-cn6619))
