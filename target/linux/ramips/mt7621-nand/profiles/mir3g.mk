#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MIR3G
	NAME:=Xiaomi Mi Router 3G
	PACKAGES:=\
		kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini \
		uboot-envtools
endef

define Profile/MIR3G/Description
	Support Xiaomi Mi Router 3G.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
MIR3G_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
MIR3G_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,MIR3G))
