#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/ZBT-WE1226
	NAME:=ZBT-WE1226
	PACKAGES:=\
		kmod-mt7603
endef

define Profile/ZBT-WE1226/Description
 Support for zbt-we1226 routers
endef
$(eval $(call Profile,ZBT-WE1226))
