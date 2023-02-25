include $(TOPDIR)/rules.mk

PKG_NAME:=qt-faststart
PKG_RELEASE:=0.2

include $(INCLUDE_DIR)/package.mk
define Package/qt-faststart
 SECTION:=multimedia
 CATEGORY:=Multimedia
 TITLE+= Quicktime/MP4 Fast Start
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -Wall" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/qt-faststart/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qt-faststart $(1)/usr/bin
endef

$(eval $(call BuildPackage,qt-faststart))
