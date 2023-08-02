#
# Copyright © 1997-2011 by Secret Labs AB
# Copyright © 1995-2011 by Fredrik Lundh
# Copyright © 2016 by Alex Clark and contributors
#

include $(TOPDIR)/rules.mk

PKG_NAME:=python3-pytesseract
PKG_VERSION:=0.3.10
PKG_RELEASE:=1

PYPI_NAME:=pytesseract
PKG_MD5SUM:=8abcce2d353750780c2e74b43571a0a3

include $(TOPDIR)/feeds/packages/lang/python/pypi.mk
include $(INCLUDE_DIR)/package.mk
include $(TOPDIR)/feeds/packages/lang/python/python3-package.mk

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

$(eval $(call Py3Package,python3-pytesseract))
$(eval $(call BuildPackage,python3-pytesseract))
$(eval $(call BuildPackage,python3-pytesseract-src))
