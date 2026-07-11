#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/ZTE-E8820S
	NAME:=ZTE E8820S
	PACKAGES:=\
		kmod-usb-core kmod-usb3 kmod-usb-hid \
		kmod-ledtrig-netdev kmod-mt7603 kmod-mt76x2 wpad-mini
endef

define Profile/ZTE-E8820S/Description
	Support ZTE 8820S.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
ZTE-E8820S_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
ZTE-E8820S_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,ZTE-E8820S))
