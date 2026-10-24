#
# luci-app-ndpi - frontend for kmod-ipt-ndpi (nDPI L7 identification)
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=nDPI L7 traffic identification (rules + live flows)
LUCI_DESCRIPTION:=LuCI frontend for kmod-ipt-ndpi. Turns uci rules into \
iptables mangle rules that match application protocols detected by the \
in-kernel nDPI engine (-m ndpi --proto <app>), marks matched traffic with \
-j NDPI --set-mark (for ip rule / mwan3 / QoS policy routing) or drops it, \
and renders the live per-application flow accounting from \
/proc/net/xt_ndpi/flows.
LUCI_DEPENDS:=+luci-base +kmod-ipt-ndpi +iptables-mod-ndpi
LUCI_PKGARCH:=all

PKG_VERSION:=1.0.0
PKG_RELEASE:=2
PKG_LICENSE:=Apache-2.0

define Package/luci-app-ndpi/conffiles
/etc/config/ndpi
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
