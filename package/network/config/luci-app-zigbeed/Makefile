#
# Copyright (C) 2026
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=Zigbee gateway management (zigbeed)
LUCI_DEPENDS:=+zigbeed
LUCI_PKGARCH:=all
PKG_VERSION:=1.0
PKG_RELEASE:=15

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

define Package/luci-app-zigbeed/postinst
#!/bin/sh
# fix exec permissions for vendor tools packaged via luci.mk (root/ files lose mode)
chmod 0755 /usr/bin/zigbeed-rebuild.sh 2>/dev/null
chmod 0755 /usr/bin/DeviceHub 2>/dev/null
exit 0
endef
