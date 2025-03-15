#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/H3C-WTU430H
        NAME:=H3C-WTU430H
        PACKAGES:=kmod-ath10k-smallbuffers ath10k-firmware-qca9888
endef

define Profile/H3C-WTU430H/Description
        Package set optimized for the H3C WTU430H board.
endef

$(eval $(call Profile,H3C-WTU430H))
