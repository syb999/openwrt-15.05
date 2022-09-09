include $(TOPDIR)/rules.mk

PKG_NAME:=ninja
PKG_VERSION:=1.11.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/ninja-build/ninja/tar.gz/v$(PKG_VERSION)?
PKG_MD5SUM:=7d1a1a2f5cdc06795b3054df5c17d5ef

include $(INCLUDE_DIR)/host-build.mk

CONFIGURE_ARGS:=
ifneq ($(findstring c,$(OPENWRT_VERBOSE)),)
  CONFIGURE_ARGS+=--verbose
endif

define Host/Configure
endef

define Host/Compile
	cd $(HOST_BUILD_DIR) && \
		CXX="$(HOSTCXX_NOCACHE)" \
		CXXFLAGS="$(HOST_CXXFLAGS) $(HOST_CPPFLAGS)" \
		LDFLAGS="$(HOST_LDFLAGS)" \
		$(STAGING_DIR_HOST)/bin/$(PYTHON) configure.py --bootstrap $(CONFIGURE_ARGS)
endef

define Host/Install
	$(INSTALL_DIR) $(STAGING_DIR_HOST)/bin
	$(INSTALL_BIN) $(HOST_BUILD_DIR)/ninja $(STAGING_DIR_HOST)/bin/
endef

define Host/Clean
	$(call Host/Clean/Default)
	rm -f $(STAGING_DIR_HOST)/bin/ninja
endef

$(eval $(call HostBuild))
