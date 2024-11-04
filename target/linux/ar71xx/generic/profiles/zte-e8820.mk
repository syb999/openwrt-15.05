#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/ZTE-E8820
        NAME:=ZTE-E8820
        PACKAGES:=uboot-envtools kmod-ath10k-smallbuffers ath10k-firmware-qca988x kmod-usb2
endef

define Profile/ZTE-E8820/Description
        Package set optimized for the ZTE E8820.
endef

$(eval $(call Profile,ZTE-E8820))
