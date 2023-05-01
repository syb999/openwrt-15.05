#
# Copyright (C) 2011-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=scons
PKG_VERSION:=3.1.1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@SF/scons \
		https://fossies.org/linux/misc/
PKG_MD5SUM:=35b2a3993313bbedd221d4d5758fd2fd

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=

include $(INCLUDE_DIR)/host-build.mk

define Host/Configure
endef

define Host/Compile
endef

define Host/Install
	./files/pywrap.sh $(HOST_BUILD_DIR)/setup.py install --prefix=$(STAGING_DIR_HOST)
	rm -f $(STAGING_DIR_HOST)/bin/scons*.py
	for bin in $(STAGING_DIR_HOST)/bin/scons*; do \
		mv "$$$$bin" "$$$$bin.py";                \
		cp ./files/pywrap.sh "$$$$bin";           \
	done
endef

$(eval $(call HostBuild))
