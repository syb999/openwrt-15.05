#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/HC5611
	NAME:=HiWiFi HC5611
	PACKAGES:=\
		kmod-mt76x2 kmod-mt7603
endef

define Profile/HC5611/Description
 Support for hc5611 routers
endef
$(eval $(call Profile,HC5611))
