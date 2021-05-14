#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/CSAC
        NAME:=CSAC
        PACKAGES:=kmod-ath10k ath10k-firmware-qca9888 kmod-usb2
endef

define Profile/CSAC/Description
        Package set optimized for the CSAC board.
endef

$(eval $(call Profile,CSAC))
