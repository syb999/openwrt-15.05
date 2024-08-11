#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/XINXANG-X-WAP750
        NAME:=XINXANG-X-WAP750
        PACKAGES:=uboot-envtools kmod-ath10k-smallbuffers ath10k-firmware-qca9887 panel-ap-setup
endef

define Profile/XINXANG-X-WAP750/Description
        Package set optimized for the XinXang X-WAP750 Panel AP.
endef

$(eval $(call Profile,XINXANG-X-WAP750))
