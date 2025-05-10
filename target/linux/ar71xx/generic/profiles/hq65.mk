#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/100mshBOX-HQ65
        NAME:=100mshBOX HQ65
        PACKAGES:= panel-ap-setup kmod-i2c-gpio-custom i2c-tools
endef

define Profile/100mshBOX-HQ65/Description
        Package set optimized for the 100mshBOX HQ65 board.
endef

$(eval $(call Profile,100mshBOX-HQ65))

define Profile/100mshBOX-HQ65-RTC-DS1307
        NAME:=100mshBOX HQ65 DS1307
        PACKAGES:= panel-ap-setup kmod-i2c-gpio-custom i2c-tools kmod-rtc-ds1307
endef

define Profile/100mshBOX-HQ65-RTC-DS1307/Description
        Package set optimized for the 100mshBOX HQ65 with RTC DS1307 board.
endef

$(eval $(call Profile,100mshBOX-HQ65-RTC-DS1307))
