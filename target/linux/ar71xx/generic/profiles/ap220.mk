#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/AP220
	NAME:=AP220
	PACKAGES:= kmod-ath10k-ct-smallbuffers ath10k-firmware-qca988x-ct-full-htt panel-ap-setup \
		kmod-mtd-rw
endef

define Profile/AP220/Description
	Package set optimized for the AP220 POE AP.
endef

$(eval $(call Profile,AP220))
