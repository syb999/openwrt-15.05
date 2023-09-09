#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WNA4320V2
	NAME:=ZYXEL WNA4320 v2
	PACKAGES:=\
		kmod-mt7603 panel-ap-setup
endef

define Profile/WNA4320V2/Description
 Support for ZYXEL WNA4320 v2 Panel AP.
endef
$(eval $(call Profile,WNA4320V2))
