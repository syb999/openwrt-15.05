#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/AN1201L
	NAME:=AN1201L
	PACKAGES := kmod-mt7603 kmod-mt7615e mt7663-firmware-ap \
		      mt7663-firmware-sta wpad-mini
endef

define Profile/AN1201L/Description
	Support CMCC AN1201L.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
AN1201L_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
AN1201L_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,AN1201L))
