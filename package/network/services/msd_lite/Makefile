include $(TOPDIR)/rules.mk

PKG_NAME:=msd_lite
PKG_RELEASE=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/rozhuk-im/msd_lite
PKG_SOURCE_DATE:=2022-04-17
PKG_SOURCE_VERSION:=e254782c0f2199f5351cc7dae1d0be3ebaa5a7f0
PKG_MD5SUM:=502b4868d346d301a24ea8999b7e49f4
CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/msd_lite
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Convert UDP IPTV streams into HTTP streams
  DEPENDS:=+libpthread +librt
endef


define Package/msd_lite/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/msd_lite $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/msd_lite
	$(INSTALL_DATA) $(PKG_INSTALL_DIR)/usr/etc/msd_lite/msd_lite.conf.sample $(1)/etc/msd_lite/msd_lite.conf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/msd_lite.init $(1)/etc/init.d/msd_lite
endef


$(eval $(call BuildPackage,msd_lite))
