#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/NOKIA-A040WQ
	NAME:=NOKIA-A040WQ
	PACKAGES:=\
		kmod-mt7615e kmod-usb3 kmod-usb-ledtrig-usbport wpad-mini \
		kmod-ledtrig-usbdev mt7615-dbdc-setup
endef

define Profile/NOKIA-A040WQ/Description
	Support NOKIA-A-040W-Q.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
NOKIA-A040WQ_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
NOKIA-A040WQ_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,NOKIA-A040WQ))
