#
# Copyright © 1997-2011 by Secret Labs AB
# Copyright © 1995-2011 by Fredrik Lundh
# Copyright © 2016 by Alex Clark and contributors
#

include $(TOPDIR)/rules.mk

PKG_NAME:=python3-pytesseract
PKG_VERSION:=0.3.7
PKG_RELEASE:=1

PKG_SOURCE:=pytesseract-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://files.pythonhosted.org/packages/a0/e6/a4e9fc8a93c1318540e8de6d8d4beb5749b7960388a7c7f27799fc2dd016
PKG_MD5SUM:=d37f1d35b5ec99d21dd0e24af90b9109

PKG_BUILD_DIR:=$(BUILD_DIR)/python3-pytesseract-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python3/python3-package.mk

PKG_UNPACK:=$(HOST_TAR) -C $(PKG_BUILD_DIR) --strip-components=1 -xzf $(DL_DIR)/$(PKG_SOURCE)

define Package/python3-pytesseract
  SUBMENU:=Python
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=Python-tesseract
  URL:=https://pypi.org/project/pytesseract/
  DEPENDS:=+python3-pillow +tesseract
endef

define Package/python3-pytesseract/description
  Python-tesseract is an optical character recognition (OCR) tool for python.
  That is, it will recognize and “read” the text embedded in images.
endef

define Build/Compile
	$(call Build/Compile/Py3Mod,., \
		install --prefix="/usr" --root="$(PKG_INSTALL_DIR)", \
	)
endef

define Package/python3-pytesseract/install
	$(INSTALL_DIR) $(1)$(PYTHON3_PKG_DIR)
	$(CP) \
	    $(PKG_INSTALL_DIR)$(PYTHON3_PKG_DIR)/* \
	    $(1)$(PYTHON3_PKG_DIR)
endef

$(eval $(call BuildPackage,python3-pytesseract))
