include $(TOPDIR)/rules.mk

PKG_NAME:=sexpect
PKG_VERSION:=2020-04-16
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/clarkwang/sexpect.git
PKG_SOURCE_VERSION:=a5c9a2eeab348cab2c2894cb6dc0803281400b41
PKG_MD5SUM:=6361c3b4cf48719d9b261564c17836be

PKG_LICENSE:=GPL-3.0

include $(INCLUDE_DIR)/package.mk

MAKE_ARGS := CFLAGS="$(TARGET_CFLAGS)" CC=$(TARGET_CC)

define Package/sexpect
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Expect for Shells (sh, bash, zsh, ksh, ...)
  URL:=https://github.com/clarkwang/sexpect
  DEPENDS:=+librt
endef

define Package/sexpect/description
  sexpect is another implementation of Expect.
endef

define Build/Configure
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) $(MAKE_ARGS) all
endef

define Package/sexpect/install
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sexpect $(1)/bin/
	$(INSTALL_BIN) ./files/sexpect_ssh.sh $(1)/bin/
endef

$(eval $(call BuildPackage,sexpect))
