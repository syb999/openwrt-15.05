# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=qcapwap
PKG_VERSION:=1.0.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

PKG_FILES_AC:=./files/ac
PKG_FILES_WTP:=./files/wtp

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/siwifi_version.mk

define Package/qcapwap
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Implementation of the CAPWAP protocol
  DEPENDS:= +libpthread +libuci +libjson-c +libevent2-core
endef

define Package/qcapwap_ac
  $(Package/qcapwap)
  TITLE:=Opencapwap Access Controller(AC)
  DEPENDS+=qcapwap
endef

define Package/qcapwap_wtp
  $(Package/qcapwap)
  TITLE:=Opencapwap Wireless Terminator Point(WTP)
  DEPENDS+=qcapwap
endef

define Package/qcapwap/description
  Open source implementation of the CAPWAP protocol according to RFC 4515 and RFC 4516.
endef

SF_DOWNLOAD_BIN=/usr/sbin/wtp_do_download
SF_UPDATE_BIN=/usr/sbin/wtp_do_update

define Build/Compile/qcapwap_ac
endef

define Build/Compile/qcapwap_wtp
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/qcapwap_ac/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/capwap
	$(INSTALL_BIN) $(PKG_FILES_AC)/AC $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_FILES_AC)/WUM $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_FILES_AC)/wtp_update.sh $(1)/usr/sbin/wtp_update
	$(INSTALL_BIN) $(PKG_FILES_AC)/check_ac.sh $(1)/etc/capwap
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(PKG_FILES_AC)/ap_groups $(1)/etc/config
ifneq ($(CONFIG_PACKAGE_qcapwap_wtp),y)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_FILES_AC)/ac_server.sh $(1)/etc/init.d/ac_server
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) $(PKG_FILES_AC)/acserver.hotplug $(1)/etc/hotplug.d/iface/96-acserver
endif
endef

define Package/qcapwap_wtp/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/capwap
	$(INSTALL_BIN) $(PKG_FILES_WTP)/WTP $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_FILES_WTP)/check_wtp.sh $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_FILES_WTP)/do_update.sh $(1)$(SF_UPDATE_BIN)
	$(INSTALL_BIN) $(PKG_FILES_WTP)/do_download.sh $(1)$(SF_DOWNLOAD_BIN)
	$(INSTALL_BIN) $(PKG_FILES_WTP)/hostapd_config.sh $(1)/usr/sbin/hostapd_config
ifneq ($(CONFIG_PACKAGE_qcapwap_ac),y)
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_FILES_WTP)/wtp_server.sh $(1)/etc/init.d/wtp_server
endif
endef

$(eval $(call BuildPackage,qcapwap_ac))
$(eval $(call BuildPackage,qcapwap_wtp))
