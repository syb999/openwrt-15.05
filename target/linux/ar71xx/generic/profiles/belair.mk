#
# Copyright (C) 2009-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/BELAIR20E11
	NAME:=BelAir Networks BelAir20E-11 board
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-storage
endef

define Profile/BELAIR20E11/Description
	Package set optimized for the BelAir Networks BelAir20E-11 board.
endef

$(eval $(call Profile,BELAIR20E11))
