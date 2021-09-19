include $(TOPDIR)/rules.mk

PKG_NAME:=foo2zjs
PKG_VERSION:=2021-04-26
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/koenkooi/foo2zjs
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=e04290de6b7a30d588f3411fd9834618e09f7b9b
PKG_M5SUM:=b2c1f602fa57a490e684c9de934fd60a

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/foo2zjs
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=A linux printer driver for ZjStream protocol.
  URL:=http://foo2zjs.rkkda.com/
  DEPENDS:= +cups-filters
endef

define Package/foo2zjs/description
	A linux printer driver for ZjStream protocol.
endef

define Package/foo2zjs/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/getweb $(1)/usr/bin/
	$(CP) $(PKG_BUILD_DIR)/PPD/ $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/* $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/share
	$(CP) $(PKG_INSTALL_DIR)/usr/share/* $(1)/usr/share/
endef

$(eval $(call BuildPackage,foo2zjs))
