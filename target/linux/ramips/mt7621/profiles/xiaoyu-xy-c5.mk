#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/XIAOYU-XY-C5
	NAME:=XiaoYu XY-C5
	PACKAGES:=\
		kmod-ata-core kmod-ata-ahci kmod-usb3
endef

define Profile/XIAOYU-XY-C5/Description
	Support XiaoYu-XY-C5.
endef
$(eval $(call Profile,XIAOYU-XY-C5))
