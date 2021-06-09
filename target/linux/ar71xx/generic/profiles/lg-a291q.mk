#
# Copyright (C) 2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/LG-A291Q
        NAME:=LG-A291Q
        PACKAGES:=
endef

define Profile/LG-A291Q/Description
        Package set optimized for the LG-A291Q board.
endef

$(eval $(call Profile,LG-A291Q))
