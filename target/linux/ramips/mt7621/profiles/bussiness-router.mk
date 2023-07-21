#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/BUSSINESS-ROUTER
	NAME:=Bussiness Router
	PACKAGES:=\
		-wpad-mini -iwinfo
endef

define Profile/BUSSINESS-ROUTER/Description
	Package set for Bussiness Router.
endef
$(eval $(call Profile,BUSSINESS-ROUTER))
