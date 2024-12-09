#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/AP210-AT-LTE9X07
        NAME:=AP210-AT-LTE9X07
        PACKAGES:= kmod-ath10k-smallbuffers ath10k-firmware-qca9887 panel-ap-setup \
		kmod-mtd-rw panel-ap-setup kmod-usb2 kmod-usb-ohci \
		kmod-usb-uhci kmod-usb-net kmod-usb-net-qmi-wwan kmod-usb-serial \
		kmod-usb-serial-option luci-proto-3g luci-proto-ncm
endef

define Profile/AP210-AT-LTE9X07/Description
        Package set optimized for the AP210-AT-LTE9X07 AP.
endef

$(eval $(call Profile,AP210-AT-LTE9X07))
