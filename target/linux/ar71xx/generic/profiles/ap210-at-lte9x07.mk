#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/AP210-AT-LTE9X07
        NAME:=AP210-AT-LTE9X07
        PACKAGES:=kmod-ath10k-smallbuffers ath10k-firmware-qca9887 kmod-mtd-rw panel-ap-setup quectel-CM
endef

define Profile/AP210-AT-LTE9X07/Description
        Package set optimized for the AP210-AT-LTE9X07 AP.
endef

$(eval $(call Profile,AP210-AT-LTE9X07))
