#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/HC5661A
	NAME:=HiWiFi HC5661A
	PACKAGES:=\
		kmod-mt7603 kmod-sdhci-mt7620
endef

define Profile/HC5661A/Description
 Support for hc5661a routers
endef
$(eval $(call Profile,HC5661A))
