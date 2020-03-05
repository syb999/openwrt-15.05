#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MAC1200RV2
	NAME:=MERCURY MAC1200R v2
	PACKAGES:=\
		kmod-mt76x2 kmod-mt7603 uboot-envtools
endef

define Profile/MAC1200RV2/Description
 Support for mac1200rv2 routers
endef
$(eval $(call Profile,MAC1200RV2))
