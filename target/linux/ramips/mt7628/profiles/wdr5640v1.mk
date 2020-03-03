#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WDR5640V1
	NAME:=TPLINK WDR5640 v1
	PACKAGES:=\
		kmod-mt76x2 kmod-mt7603 uboot-envtools
endef

define Profile/WDR5640V1/Description
 Support for wdr5640v1 routers
endef
$(eval $(call Profile,WDR5640V1))
