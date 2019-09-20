#
# Copyright (C) 2015-2018 neil.zhang@siflower.com.cn
#
# sifiower Software.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=buttons
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/buttons
SECTION:=utils
CATEGORY:=Utilities
TITLE:=86v_buttons.
MAINTAINER:=Nevermore <nevermore.wang@siflower.com.cn>
DEPENDS:=+button-hotplug
endef

define Package/buttons/description
SiFlower 86v buttons & led control.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/buttons/install

ifdef CONFIG_FLASH_OPTIMIZE
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_BIN) ./files/led_86v  $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/BTN_*  $(1)/etc/rc.button/
	$(INSTALL_BIN) ./files/blink  $(1)/etc/rc.button/
	$(INSTALL_BIN) ./files/reset  $(1)/etc/rc.button/
	$(INSTALL_CONF) ./files/led    $(1)/etc/config/
endif

endef


$(eval $(call BuildPackage,buttons))

