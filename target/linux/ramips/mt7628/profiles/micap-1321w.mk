#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MICAP-1321W
	NAME:=ZYXEL MiCAP-1321W
	PACKAGES:=\
		kmod-mt7603 panel-ap-setup
endef

define Profile/MICAP-1321W/Description
 Support for ZYXEL MiCAP-1321W Panel AP.
endef
$(eval $(call Profile,MICAP-1321W))
