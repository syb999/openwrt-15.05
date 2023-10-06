#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/WAP750
        NAME:=WAP750
        PACKAGES:=uboot-envtools kmod-ath10k-ct ath10k-firmware-qca9887-ct-full-htt
endef

define Profile/WAP750/Description
        Package set optimized for the XinXang WAP750 Panel AP.
endef

$(eval $(call Profile,WAP750))
