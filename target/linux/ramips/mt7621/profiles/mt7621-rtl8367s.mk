#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MT7621-RTL8367S
	NAME:=MT7621-RTL8367S
	PACKAGES:=\
		-wpad-mini -iwinfo kmod-switch-rtl8367b
endef

define Profile/MT7621-RTL8367S/Description
	Package set for MT7621-RTL8367S
endef
$(eval $(call Profile,MT7621-RTL8367S))
