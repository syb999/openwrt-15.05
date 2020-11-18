include $(TOPDIR)/rules.mk

PKG_NAME:=hexdiff
PKG_VERSION:=0.14
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/synrst/hexdiff.git
PKG_SOURCE_VERSION:=cdd702fa3b5741ef23bec2bd565c18b97669ddb2
PKG_MD5SUM:=ff2d58e697d475d68384f9286c4ab862

PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

MAKE_ARGS := CFLAGS="$(TARGET_CFLAGS)" CC=$(TARGET_CC)

define Package/hexdiff
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=hexdiff
  URL:=https://github.com/synrst/hexdiff
endef

define Package/hexdiff/description
  This program reads data from one or more files and finds bytes or groups of bytes which are different.
endef

define Package/hexdiff/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hexdiff $(1)/bin/
endef

$(eval $(call BuildPackage,hexdiff))
