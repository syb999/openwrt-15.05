include $(TOPDIR)/rules.mk

PKG_NAME:=foo2zjs
PKG_VERSION:=
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME).tar.gz
PKG_SOURCE_URL:=http://foo2zjs.rkkda.com/

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/foo2zjs
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=A linux printer driver for ZjStream protocol.
  URL:=http://foo2zjs.rkkda.com/
endef

define Package/foo2zjs/description
	A linux printer driver for ZjStream protocol.
endef

define Package/foo2zjs/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/getweb $(1)/usr/bin/
	$(CP) $(PKG_BUILD_DIR)/PPD/ $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/* $(1)/usr/bin/
endef

$(eval $(call BuildPackage,foo2zjs))
