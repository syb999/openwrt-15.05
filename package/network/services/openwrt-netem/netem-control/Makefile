# 
# Copyright (C) 2006 OpenWrt.org
# Copyright (C) 2012 Connectify
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=netem-control
PKG_VERSION:=0.2
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/ipkg-install

include $(INCLUDE_DIR)/package.mk

define Package/netem-control
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+kmod-netem +kmod-sched +lua +tc +luaposix +libuci-lua
  TITLE:=WAN emulation with netem.
endef

define Build/Compile
endef

define Package/netem-control/conffiles
/etc/config/netem
endef

define Package/netem-control/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) ./files/sbin/netem-control.lua $(1)/sbin/netem-control

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/netem.config $(1)/etc/config/netem

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/netem.init $(1)/etc/init.d/netem-control
endef

define Package/netem-control/postinst
#!/bin/sh

# do not change below
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	/etc/init.d/netem-control enable
fi
endef

define Package/netem-control/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    /etc/init.d/netem-control disable
fi
exit 0
endef

$(eval $(call BuildPackage,netem-control))
