include $(TOPDIR)/rules.mk

PKG_NAME:=urlencode
PKG_VERSION:=2013-10-30
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/wcharczuk/urlencode.git
PKG_SOURCE_VERSION:=24e31fe41f319f185c3b582b25a6a0a81fa0c9db
PKG_MD5SUM:=9e7b9ff9c0b9670c472c907f1bd7d51c

PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

MAKE_ARGS := CFLAGS="$(TARGET_CFLAGS)" CC=$(TARGET_CC)

define Package/urlencode
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Url encode/decode tools.
  URL:=https://github.com/wcharczuk/urlencode
  DEPENDS:=
endef

define Package/urlencode/description
  A simple (set of) commandline utilities to url encode/decode strings.
endef

define Package/urlencode/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/urlencode $(1)/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/urldecode $(1)/bin/
endef

$(eval $(call BuildPackage,urlencode))
