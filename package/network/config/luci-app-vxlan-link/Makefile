#
# luci-app-vxlan-link - VXLAN wireless link manager (mt76x8/ar71xx/ramips/arm/x86)
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

LUCI_TITLE:=VXLAN wireless link (mt76x8/ar71xx/ramips/arm/x86)
LUCI_DESCRIPTION:=Server (AP) / client (STA) roles with automatic switching. \
Builds a wireless backhaul plus VXLAN overlay so devices can extend layer 2 \
over WiFi. Two provider profiles: telecom (VLAN trunk over the tunnel, \
carrier private routes, msd_lite multicast-to-unicast) and unicom (plain \
layer 2 extension over one tunnel). Platforms: MT7628/MT7688, \
AR9331/9341/QCA9531, RT3052/5350/MT7620/MT7621, arm, x86. The design reads \
the device's current wan/lan layout at runtime; multi-port boards may use \
hardware switch VLANs (switch_mode=hw).
LUCI_DEPENDS:=+luci-base +kmod-vxlan +vxlan
LUCI_PKGARCH:=all

PKG_VERSION:=1.3.26
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0

define Package/luci-app-vxlan-link/conffiles
/etc/config/vxlan_link
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
