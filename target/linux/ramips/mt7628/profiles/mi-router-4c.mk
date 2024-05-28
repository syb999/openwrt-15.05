#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MI-ROUTER-4C
	NAME:=Xiaomi Mi Router 4C
	PACKAGES:=\
		kmod-mt7603 uboot-envtools
endef

define Profile/MI-ROUTER-4C/Description
 Support for Xiaomi Mi Router 4C.
endef
$(eval $(call Profile,MI-ROUTER-4C))
