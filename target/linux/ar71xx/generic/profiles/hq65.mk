#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/HQ65
        NAME:=100mshBOX HQ65
        PACKAGES:= panel-ap-setup kmod-i2c-gpio-custom i2c-tools fm_tea5767
endef

define Profile/HQ65/Description
        Package set optimized for the 100mshBOX HQ65 board.
endef

$(eval $(call Profile,HQ65))
