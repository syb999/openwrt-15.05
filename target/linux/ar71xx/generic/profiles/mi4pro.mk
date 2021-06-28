#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/MI4PRO
        NAME:=MI4PRO
        PACKAGES:=kmod-ath10k ath10k-firmware-qca9888
endef

define Profile/MI4PRO/Description
        Package set optimized for the XIAOMI4 Pro.
endef

$(eval $(call Profile,MI4PRO))
