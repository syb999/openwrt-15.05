#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/K2P
	NAME:=K2P
	PACKAGES:=\
		kmod-mt7615e wpad-mini mt7615-dbdc-setup
endef

define Profile/K2P/Description
	Package set for Phicomm K2P
endef

$(eval $(call Profile,K2P))
