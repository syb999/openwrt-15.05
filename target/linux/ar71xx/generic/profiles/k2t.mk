#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/K2T
        NAME:=K2T
        PACKAGES:=kmod-ath10k ath10k-firmware-qca9888
endef

define Profile/K2T/Description
        Package set optimized for the K2T board.
endef

$(eval $(call Profile,K2T))
