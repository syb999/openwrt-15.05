#
# Copyright (C) 2015-2018 neil.zhang@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ate_cmd
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/ate_cmd
SECTION:=utils
CATEGORY:=Utilities
TITLE:=atetools.
MAINTAINER:=Star jiang <star.jiang@siflower.com.cn>
DEPENDS:=+libc +libpthread +librt +libm +libubus
endef

define Package/ate_cmd/description
atetest tool.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

#TARGET_CFLAGS += \
#	-I$(LINUX_DIR)/arch/mips/include \
#	-I$(LINUX_DIR)/include \
#	-I$(LINUX_DIR)/drivers/char

define Build/Configure
endef

define Build/Compile
endef

define Package/ate_cmd/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/atetools
	$(CP) ./files/*  $(1)/etc/atetools/
	$(CP) ./files/*  $(1)/usr/bin/
endef


$(eval $(call BuildPackage,ate_cmd))
