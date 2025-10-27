#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/UROUTER-SE
	NAME:=BHU uRouter SE
	PACKAGES:=\
		kmod-mt7603
endef

define Profile/UROUTER-SE/Description
 Support for BHU uRouter SE routers
endef
$(eval $(call Profile,UROUTER-SE))
