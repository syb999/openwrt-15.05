include $(TOPDIR)/rules.mk

PKG_NAME:=procmail
PKG_VERSION:=3.24
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/BuGlessRB/procmail.git
PKG_SOURCE_VERSION:=07e769f07102767242edf835e995db6646bba373
PKG_MD5SUM:=7d0d877dc481bb86f6ea3baa19530b06

include $(INCLUDE_DIR)/package.mk

define Package/procmail
  SECTION:=mail
  CATEGORY:=Mail
  TITLE:=Mail processing tool
  URL:=http://www.procmail.org
endef

define Package/procmail/description
  Procmail is able to process and classify incoming mail into
  different mail boxes.
  Very useful in conjunction with mutt.
endef

TARGET_CFLAGS += -DPROCMAIL

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/src -f ../Makefile.openwrt  \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)"
endef

define Package/procmail/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/procmail $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/formail $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/procmailrc $(1)/etc
endef

$(eval $(call BuildPackage,procmail))
