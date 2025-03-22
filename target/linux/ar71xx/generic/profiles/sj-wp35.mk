#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/SJ-WP35
	NAME:=SJ-WP35
	PACKAGES:= kmod-usb-core kmod-usb2 kmod-usb-storage \
		-kmod-ath9k -wpad-mini
endef

define Profile/SJ-WP35/Description
	Package set optimized for the SJ-WP35.
endef

$(eval $(call Profile,SJ-WP35))
