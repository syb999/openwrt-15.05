#
# Copyright (C) 2006-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=cmake
PKG_VERSION:=3.21.3
PKG_RELEASE:=1
PKG_CPE_ID:=cpe:/a:kitware:cmake

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/Kitware/CMake/releases/download/v$(PKG_VERSION)/ \
		https://cmake.org/files/v3.20/
PKG_MD5SUM:=c0feb5855604f68b09bdb3acb623619e

HOST_BUILD_PARALLEL:=1
HOST_CONFIGURE_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

# Workaround for GCC versions below 6.X and ccache
# Reference: https://github.com/openwrt/openwrt/pull/1929
GCC_DMPVER_GREPCMD := grep -E '^(4\.[8-9]|[5]\.?)'
GCC_DMPVER_STRING := $(shell $(HOSTCC_NOCACHE) -dumpversion | $(GCC_DMPVER_GREPCMD))
ifneq ($(GCC_DMPVER_STRING),)
  ifeq ($(CONFIG_CCACHE),y)
    $(info GCC version less than 6.0 detected, disabling CCACHE)
    HOST_CONFIGURE_VARS:=$(filter-out CC=% gcc%",$(HOST_CONFIGURE_VARS)) CC="$(HOSTCC_NOCACHE)"
    HOST_CONFIGURE_VARS:=$(filter-out CXX=% g++%",$(HOST_CONFIGURE_VARS)) CXX="$(HOSTCXX_NOCACHE)"
      else
    $(info GCC version greater or equal to 6.0 detected, no workaround set for CCACHE)
  endif
endif

HOST_CONFIGURE_VARS :=

HOST_CONFIGURE_ARGS := \
	$(if $(MAKE_JOBSERVER),--parallel="$(MAKE_JOBSERVER)") \
	--prefix="$(STAGING_DIR_HOST)" \
	--generator=Ninja

define Host/Compile/Default
	+$(NINJA) -C $(HOST_BUILD_DIR) $(1)
endef

define Host/Install/Default
	+$(NINJA) -C $(HOST_BUILD_DIR) install
endef

define Host/Uninstall/Default
	+$(NINJA) -C $(HOST_BUILD_DIR) uninstall
endef

ifneq ($(findstring c,$(OPENWRT_VERBOSE)),)
  HOST_MAKE_FLAGS += VERBOSE=1
endif

$(eval $(call HostBuild))
