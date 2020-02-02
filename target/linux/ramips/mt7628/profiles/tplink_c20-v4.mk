#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/tplink_c20-v4
	NAME:=ArcherC20v4
	PACKAGES:=\
		kmod-mt76x0e kmod-mt7603
endef

define Profile/tplink_c20-v4/Description
	Default package set compatible with most boards.
endef
$(eval $(call Profile,tplink_c20-v4))
