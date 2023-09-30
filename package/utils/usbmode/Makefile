include $(TOPDIR)/rules.mk

PKG_NAME:=usbmode
PKG_VERSION:=2017-12-19
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=http://git.openwrt.org/project/usbmode.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=f40f84c27534159066c94dadc0c08e0b255c3e26
PKG_MD5SUM:=f3c73c1723c60a17d68cec4082d8f3e8
CMAKE_INSTALL:=1

PKG_LICENSE:=GPL-2.0
PKG_LICENSE_FILES:=

PKG_MAINTAINER:=Felix Fietkau <nbd@openwrt.org>

PKG_DATA_VERSION:=20191128
PKG_DATA_URL:=http://www.draisberghof.de/usb_modeswitch
PKG_DATA_PATH:=usb-modeswitch-data-$(PKG_DATA_VERSION)
PKG_DATA_FILENAME:=$(PKG_DATA_PATH).tar.bz2

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Download/data
  FILE:=$(PKG_DATA_FILENAME)
  URL:=$(PKG_DATA_URL)
  MD5SUM:=e8fce7eb949cbe16c61fb71bade4cc17
endef
$(eval $(call Download,data))

define Package/usb-modeswitch
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=+libubox +libblobmsg-json +libusb-1.0
  TITLE:=USB mode switching utility
endef

define Build/Prepare
	$(Build/Prepare/Default)
	tar xvfj $(DL_DIR)/$(PKG_DATA_FILENAME) -C $(PKG_BUILD_DIR)
	#remove devices with unsupported modes
	for filevar in $(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/* ; \
	do \
		if grep -q -E '(Quanta|Option|Blackberry|Pantech)Mode' "$$$$filevar" ; then \
			rm "$$$$filevar" ; \
		fi \
	done
	cp ./data/* $(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/
	#in order to keep the Lede GIT repo free of filenames with colons,
	#we name the files xxxx-yyyy
	# and rename here after copying to the build directory
	for filevar in $(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/*-* ; \
	do \
		[ -f "$$$$filevar" ] || continue ; \
		FILENAME=$$$$(basename $$$$filevar) ; \
		NEWNAME=$$$${FILENAME//-/:} ; \
		rm "$(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/$$$$NEWNAME" ; \
		mv "$(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/$$$$FILENAME" "$(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/$$$$NEWNAME" ; \
	done
endef

define Package/usb-modeswitch/install
	$(INSTALL_DIR) $(1)/etc/hotplug.d/usb $(1)/etc/init.d $(1)/sbin
	perl $(PKG_BUILD_DIR)/convert-modeswitch.pl \
		$(PKG_BUILD_DIR)/$(PKG_DATA_PATH)/usb_modeswitch.d/* \
		> $(1)/etc/usb-mode.json
	$(INSTALL_CONF) ./files/usbmode.hotplug $(1)/etc/hotplug.d/usb/20-usb_mode
	$(INSTALL_BIN) ./files/usbmode.init $(1)/etc/init.d/usbmode
	$(CP) $(PKG_INSTALL_DIR)/usr/sbin/usbmode $(1)/sbin/
endef

$(eval $(call BuildPackage,usb-modeswitch))
