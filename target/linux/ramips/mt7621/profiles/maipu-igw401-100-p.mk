#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MAIPU-IGW401-100-P
	NAME:=MAIPU IGW401-100-P
	PACKAGES:=\
		-wpad-mini -iwinfo
endef

define Profile/MAIPU-IGW401-100-P/Description
	Support MAIPU IGW401-100-P.
endef

#-m <min io size> -e <LEB size> -c <Eraseblocks count>
ZTE-E8820S_UBIFS_OPTS:="-m 2048 -e 129024 -c 1024"
ZTE-E8820S_UBI_OPTS:="-m 2048 -p 128KiB -s 512"

$(eval $(call Profile,MAIPU-IGW401-100-P))
