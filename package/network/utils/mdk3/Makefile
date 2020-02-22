#
# Copyright (C) 2009-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mdk3
PKG_VERSION:=2015-05-25
PKG_RELEASE:=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/wi-fi-analyzer/mdk3-master.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=1bf2bd31b79560aa99fc42123f70f36a03154b9e
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MD5SUM:=4388026d113ba96c61482ab3a3ebf23e

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/mdk3
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libpthread +airmon-ng
  TITLE:= MDK3
  URL:=http://homepages.tu-darmstadt.de/~p_larbig/wlan/
  SUBMENU:=wireless
endef

define Package/mdk3/description
  Tool to exploit wireless vulnerabilities
endef

MAKE_FLAGS += \
	$(TARGET_CONFIGURE_OPTS)

define Package/mdk3/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_BUILD_DIR)/mdk3 $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,mdk3))
