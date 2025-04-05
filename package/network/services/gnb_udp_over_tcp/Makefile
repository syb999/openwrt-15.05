include $(TOPDIR)/rules.mk

PKG_NAME:=gnb_udp_over_tcp
PKG_VERSION:=1.2.1
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/gnbdev/gnb_udp_over_tcp.git
PKG_SOURCE_VERSION:=fa4fef32de2d254a5768511c3d80dc4dceb8d564
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.xz
PKG_MD5SUM:=6e9b877ca21efb56c219833720a764ac

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/gnb_udp_over_tcp
  SECTION:=net
  CATEGORY:=Network
  TITLE:=GNB UDP over TCP tunnel
  DEPENDS:=+libpthread
  URL:=https://github.com/gnbdev/gnb_udp_over_tcp
endef

define Package/gnb_udp_over_tcp/description
  gnb_udp_over_tcp is a service that forwards UDP packets through TCP link relay.
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS) -I$(PKG_BUILD_DIR)/src -I$(PKG_BUILD_DIR)/libs/hash" \
		LDFLAGS="$(TARGET_LDFLAGS) -lpthread"
endef

define Package/gnb_udp_over_tcp/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/gnb_udp_over_tcp $(1)/usr/bin/
endef

$(eval $(call BuildPackage,gnb_udp_over_tcp))
