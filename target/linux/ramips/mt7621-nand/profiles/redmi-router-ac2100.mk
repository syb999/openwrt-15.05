#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/REDMI-ROUTER-AC2100
	NAME:=Xiaomi Redmi Router AC2100
	PACKAGES:=\
		kmod-mt7603 kmod-mt7615e uboot-envtools wpad-mini
endef

define Profile/REDMI-ROUTER-AC2100/Description
	Support XIAOMI REDMI-ROUTER-AC2100.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
REDMI-ROUTER-AC2100_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
REDMI-ROUTER-AC2100_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,REDMI-ROUTER-AC2100))
