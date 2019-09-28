#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/FWR200_V2
 NAME:=FAST FWR200 V2
 PACKAGES:=
endef

define Profile/FWR200_V2/Description
 Support for FAST FWR200 V2 routers
endef
$(eval $(call Profile,FWR200_V2))
