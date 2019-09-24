#
# Copyright (C) 2010-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/version.mk
include $(INCLUDE_DIR)/package.mk


PKG_NAME:=siflower-utils
PKG_VERSION:=1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/siflower-utils/Default
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=siflowr-utils
  MAINTAINER:=Xijun.guo <xijun.guo@siflower.com.cn>
  SUBMENU:=siflower-utils
endef

define Build/Compile
endef

define Package/si-cron
$(call Package/siflower-utils/Default)
  TITLE+=(siflowr-cron)
endef

define Package/si-cron/description
 siflower cron event
endef

define Package/si-cron/install
	$(INSTALL_DIR) $(1)/etc/crontabs/
	if [ "$(CONFIG_PACKAGE_log-system)" = "y" ]; then\
	cat ./files/si-cron/log_cron >> $(1)/etc/crontabs/admin;\
	fi
	if [ "$(CONFIG_PACKAGE_kmod-sf-ts)" = "y" ]; then\
	cat ./files/si-cron/sf_ts_cron >> $(1)/etc/crontabs/admin;\
	fi
	if [ "$(CONFIG_PACKAGE_auto-ota)" = "y" ]; then\
	cat ./files/si-cron/auto_ota_cron >> $(1)/etc/crontabs/admin;\
	fi
endef

define Package/online-warn
$(call Package/siflower-utils/Default)
  TITLE+=(online-warn)
endef

define Package/online-warn/description
 new wifi device online warning
endef

define Package/online-warn/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(CP) ./files/online-warning/online-warn $(1)/usr/sbin/
	$(CP) ./files/online-warning/siwarning $(1)/usr/sbin/
	$(CP) ./files/online-warning/online-warn-init $(1)/etc/init.d/
endef

define Package/parents-control
$(call Package/siflower-utils/Default)
  TITLE+=(parents-control)
endef

define Package/parents-control/description
parents-control
endef

define Package/parents-control/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/ntp
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/parents-control/pctl $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/parents-control/init_pctl $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/parents-control/sync_acl $(1)/etc/hotplug.d/ntp/
	$(INSTALL_BIN) ./files/parents-control/60-speedlimit $(1)/etc/hotplug.d/iface/
endef

define Package/log-system
$(call Package/siflower-utils/Default)
  TITLE+=(log-system)
endef

define Package/log-system/description
 new log system
endef

define Package/log-system/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/sbin/clean_log $(1)/usr/sbin/
endef

define Package/auto-ota
$(call Package/siflower-utils/Default)
  TITLE+=(auto-ota)
endef

define Package/auto-ota/description
auto ota
endef

define Package/auto-ota/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/sbin/auto_ota $(1)/usr/sbin/
endef

define Package/aclscript
$(call Package/siflower-utils/Default)
TITLE+=(aclscript)
endef

define Package/aclscript/description
aclscript
endef

define Package/aclscript/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(CP) ./files/base-files/bin/aclscript $(1)/usr/sbin/
	$(CP) ./files/base-files/etc/init.d/acl $(1)/etc/init.d/
endef

define Package/devlistclean
$(call Package/siflower-utils/Default)
TITLE+=(devlistclean)
endef

define Package/devlistclean/description
devlistclean
endef

define Package/devlistclean/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/bin/devlistclean $(1)/usr/sbin/
endef

define Package/gwifi
$(call Package/siflower-utils/Default)
TITLE+=(gwifi)
endef

define Package/gwifi/description
gwifi
endef

define Package/gwifi/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/bin/gwifi $(1)/usr/sbin/
endef

define Package/netclash
$(call Package/siflower-utils/Default)
TITLE+=(netclash)
endef

define Package/netclash/description
netclash
endef

define Package/netclash/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/bin/netclash $(1)/usr/sbin/
endef

define Package/set_cpufreq
$(call Package/siflower-utils/Default)
TITLE+=(set_cpufreq)
endef

define Package/set_cpufreq/description
set_cpufreq
endef

define Package/set_cpufreq/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(CP) ./files/base-files/bin/set_cpufreq $(1)/usr/sbin/
	$(CP) ./files/base-files/etc/init.d/set_default_cpufreq $(1)/etc/init.d/
endef

define Package/set_pwrmgmt
$(call Package/siflower-utils/Default)
TITLE+=(set_pwrmgmt)
endef

define Package/set_pwrmgmt/description
set_pwrmgmt
endef

define Package/set_pwrmgmt/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) ./files/base-files/bin/set_pwrmgmt $(1)/usr/sbin/
endef

define Package/base-config
$(call Package/siflower-utils/Default)
TITLE+=(base-config)
endef

define Package/base-config/description
base config
endef

define Package/base-config/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/config
	$(CP) ./files/base-files/etc/sysupgrade_except.conf $(1)/etc/
	$(CP) ./files/base-files/etc/config/* $(1)/etc/config/
	if [ "$(shell echo $(PROFILE) | grep "FLASH")" != "" ] || [ "$(shell echo $(PROFILE) | grep "86V")" != "" ]; then\
		rm $(1)/etc/config/basic_setting; \
		rm $(1)/etc/config/timelist; \
		rm $(1)/etc/config/notify; \
		rm $(1)/etc/config/qos_cfg; \
		rm $(1)/etc/config/samba; \
		rm $(1)/etc/config/wifi_info; \
		rm $(1)/etc/sysupgrade_except.conf; \
	fi
endef

define Package/upgrade-file
$(call Package/siflower-utils/Default)
TITLE+=(upgrade-file)
endef

define Package/upgrade-file/description
upgrade file
endef

define Package/upgrade-file/install
	$(INSTALL_DIR) $(1)/lib/upgrade/
	$(CP) ./files/base-files/lib/upgrade/platform.sh $(1)/lib/upgrade/
endef

define Package/fixtime
$(call Package/siflower-utils/Default)
TITLE+=(fixtime)
endef

define Package/fixtime/description
sysfixtime
endef

define Package/fixtime/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(CP) ./files/base-files/etc/init.d/sysfixtime $(1)/etc/init.d/
endef

define Package/01_network
$(call Package/siflower-utils/Default)
TITLE+=(01_network)
endef

define Package/01_network/description
01_network
endef

define Package/01_network/install
	$(INSTALL_DIR) $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/board.d/
	$(CP) ./files/base-files/etc/board.d/01_network $(1)/etc/board.d/
endef

define Package/sslcert
$(call Package/siflower-utils/Default)
TITLE+=(sslcert)
endef

define Package/sslcert/description
sslcert
endef

define Package/sslcert/install
	$(INSTALL_DIR) $(1)/etc/ssl/certs/
	$(CP) ./files/base-files/etc/se_pub.key $(1)/etc/
	$(CP) ./files/base-files/etc/pubkey.pem $(1)/etc/
	$(CP) ./files/base-files/etc/ssl/certs/* $(1)/etc/ssl/certs/
endef

define Package/check_net
$(call Package/siflower-utils/Default)
TITLE+=(check_net)
endef

define Package/check_net/description
check_net
endef

define Package/check_net/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) ./files/base-files/sbin/check_net $(1)/sbin/
endef

define Package/check_wds
$(call Package/siflower-utils/Default)
TITLE+=(check_wds)
endef

define Package/check_wds/description
check_wds
endef

define Package/check_wds/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) ./files/base-files/sbin/check_wds $(1)/sbin/
	$(CP) ./files/base-files/sbin/alter_lan $(1)/sbin/
endef

define Package/init-devlist
$(call Package/siflower-utils/Default)
TITLE+=(init_devlist)
endef

define Package/init-devlist/description
init_devlist
endef

define Package/init-devlist/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) ./files/base-files/sbin/init_devlist $(1)/sbin/
endef

define Package/otaupgrade
$(call Package/siflower-utils/Default)
TITLE+=(otaupgrade)
endef

define Package/otaupgrade/description
otaupgrade
endef

define Package/otaupgrade/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) ./files/base-files/usr/bin/otaupgrade $(1)/usr/bin/
endef

define Package/speed
$(call Package/siflower-utils/Default)
TITLE+=(speed)
endef

define Package/speed/description
speed
endef

define Package/speed/install
	$(INSTALL_DIR) $(1)/sbin
	$(CP) ./files/base-files/sbin/speed $(1)/sbin/
endef

define Package/uci-defaults-new
$(call Package/siflower-utils/Default)
TITLE+=(uci-defaults-new)
endef

define Package/uci-defaults-new/description
uci-defaults-new
endef

define Package/uci-defaults-new/install
	$(INSTALL_DIR) $(1)/lib/functions
	$(CP) ./files/base-files/lib/functions/uci-defaults-new.sh $(1)/lib/functions/
endef

define Package/wlanctl
$(call Package/siflower-utils/Default)
TITLE+=(wlanctl)
endef

define Package/wlanctl/description
wlanctl
endef

define Package/wlanctl/install
	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(CP) ./files/base-files/etc/hotplug.d/net/01-wlanctl $(1)/etc/hotplug.d/net/
endef

define Package/ssst_replace
$(call Package/siflower-utils/Default)
TITLE+=(ssst_replace.sh)
endef

define Package/ssst_replace/description
ssst_replace.sh
endef

define Package/ssst_replace/install
	$(INSTALL_DIR) $(1)/etc
	$(CP) ./files/base-files/etc/ssst_replace.sh $(1)/etc/
endef

define Package/86V_FAT_DHCP
$(call Package/siflower-utils/Default)
TITLE+=(dhcp.sh)
endef

define Package/86V_FAT_DHCP/description
dhcp.sh
endef

define Package/86V_FAT_DHCP/install
	$(INSTALL_DIR) $(1)/bin
	$(CP) ./files/base-files/bin/dhcp.sh $(1)/bin/
endef

define Package/get_dhcpserver_status
$(call Package/siflower-utils/Default)
TITLE+=(get_dhcpserver_status)
endef

define Package/get_dhcpserver_status/description
get_dhcpserver_status
endef

define Package/get_dhcpserver_status/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(CP) ./files/base-files/etc/init.d/get_dhcpserver_status $(1)/etc/init.d/
endef

define Package/dhcpserver_status
$(call Package/siflower-utils/Default)
TITLE+=(dhcpserver_status.sh)
endef

define Package/dhcpserver_status/description
dhcpserver_status.sh
endef

define Package/dhcpserver_status/install
	$(INSTALL_DIR) $(1)/bin
	$(CP) ./files/base-files/bin/dhcpserver_status.sh $(1)/bin/
endef

$(eval $(call BuildPackage,wlanctl))
$(eval $(call BuildPackage,uci-defaults-new))
$(eval $(call BuildPackage,ssst_replace))
$(eval $(call BuildPackage,86V_FAT_DHCP))
$(eval $(call BuildPackage,dhcpserver_status))
$(eval $(call BuildPackage,otaupgrade))
$(eval $(call BuildPackage,speed))
$(eval $(call BuildPackage,init-devlist))
$(eval $(call BuildPackage,sslcert))
$(eval $(call BuildPackage,01_network))
$(eval $(call BuildPackage,fixtime))
$(eval $(call BuildPackage,get_dhcpserver_status))
$(eval $(call BuildPackage,upgrade-file))
$(eval $(call BuildPackage,base-config))
$(eval $(call BuildPackage,check_net))
$(eval $(call BuildPackage,check_wds))
$(eval $(call BuildPackage,aclscript))
$(eval $(call BuildPackage,devlistclean))
$(eval $(call BuildPackage,gwifi))
$(eval $(call BuildPackage,netclash))
$(eval $(call BuildPackage,set_cpufreq))
$(eval $(call BuildPackage,set_pwrmgmt))
$(eval $(call BuildPackage,si-cron))
$(eval $(call BuildPackage,online-warn))
$(eval $(call BuildPackage,log-system))
$(eval $(call BuildPackage,auto-ota))
$(eval $(call BuildPackage,parents-control))
