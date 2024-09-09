include $(TOPDIR)/rules.mk

PKG_NAME:=pppwn-cpp
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/pppwn-cpp
  TITLE:=C++ rewrite of PPPwn (PlayStation 4 PPPoE RCE)
  URL:=https://github.com/xfangfang/PPPwn_cpp
  SECTION:=multimedia
  CATEGORY:=Multimedia
  DEPENDS:=@(TARGET_kirkwood||TARGET_mvebu||TARGET_armvirt||TARGET_ar71xx||TARGET_ramips||TARGET_x86_64)
endef

define Package/pppwn-cpp/description
PPPwn is a kernel remote code execution exploit for PlayStation 4 up to FW 11.00. 
endef

define Build/Compile
endef

define Package/pppwn-cpp/install
	$(INSTALL_DIR) $(1)/etc/pppwn
	$(INSTALL_DATA) ./files/* $(1)/etc/pppwn/
	$(INSTALL_DIR) $(1)/usr/bin
ifeq ($(ARCH),mips)
	$(INSTALL_BIN) ./bin/mips $(1)/usr/bin/pppwn
endif
ifeq ($(ARCH),mipsel)
	$(INSTALL_BIN) ./bin/mipsel $(1)/usr/bin/pppwn
endif
ifeq ($(ARCH),x86_64)
	$(INSTALL_BIN) ./bin/x86_64 $(1)/usr/bin/pppwn
endif
ifeq ($(ARCH),arm)
	$(INSTALL_BIN) ./bin/arm $(1)/usr/bin/pppwn
endif
ifeq ($(ARCH),aarch64)
	$(INSTALL_BIN) ./bin/aarch64 $(1)/usr/bin/pppwn
endif
endef

$(eval $(call BuildPackage,pppwn-cpp))
