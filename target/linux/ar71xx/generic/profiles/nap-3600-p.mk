#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
 
define Profile/NAP-3600-P
        NAME:=NAP-3600-P
        PACKAGES:=kmod-ath10k-smallbuffers ath10k-firmware-qca988x panel-ap-setup
endef

define Profile/NAP-3600-P/Description
        Package set optimized for the NAP-3600-P Panel AP.
endef

$(eval $(call Profile,NAP-3600-P))
