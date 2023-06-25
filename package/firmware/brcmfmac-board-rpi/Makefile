include $(TOPDIR)/rules.mk

PKG_NAME:=brcmfmac-board-rpi
PKG_VERSION:=2018-03-12
PKG_RELEASE:=86e88fbf0345da49555d0ec34c80b4fbae7d0cd3
PKG_FLAGS:=nonshared

include $(INCLUDE_DIR)/package.mk

BRCMFMAC434XX_SDIO_URL:=@GITHUB/RPi-Distro/firmware-nonfree/$(PKG_RELEASE)/brcm/
BRCMFMAC43430_SDIO_FILE:=brcmfmac43430-sdio-$(PKG_RELEASE)
BRCMFMAC43455_SDIO_FILE:=brcmfmac43455-sdio-$(PKG_RELEASE)

define Download/brcmfmac43430_sdio_txt
  FILE:=$(BRCMFMAC43430_SDIO_FILE).txt
  URL:=$(BRCMFMAC434XX_SDIO_URL)
  URL_FILE:=brcmfmac43430-sdio.txt
  MD5SUM:=9a88b55134d9f8f3ad2331b93f4b7b79
endef
$(eval $(call Download,brcmfmac43430_sdio_txt))

define Download/brcmfmac43455_sdio_txt
  FILE:=$(BRCMFMAC43455_SDIO_FILE).txt
  URL:=$(BRCMFMAC434XX_SDIO_URL)
  URL_FILE:=brcmfmac43455-sdio.txt
  MD5SUM:=93ff5a534720e3d86793007b34a1ee3e
endef
$(eval $(call Download,brcmfmac43455_sdio_txt))

define Download/brcmfmac43455_sdio_clm_blob
  FILE:=$(BRCMFMAC43455_SDIO_FILE).clm_blob
  URL:=$(BRCMFMAC434XX_SDIO_URL)
  URL_FILE:=brcmfmac43455-sdio.clm_blob
  MD5SUM:=c5aeca0e33de4ae870986c517963fef7
endef
$(eval $(call Download,brcmfmac43455_sdio_clm_blob))

define Package/brcmfmac-board-rpi/Default
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=https://github.com/RPi-Distro/firmware-nonfree/
  DEPENDS:=@TARGET_brcm2708
  PKGARCH:=all
endef

define Package/brcmfmac-board-rpi2
  $(call Package/brcmfmac-board-rpi/Default)
  TITLE:=BCM43430 RPi SDIO NVRAM
endef

define Package/brcmfmac-board-rpi2/description
  NVRAM for the Broadcom BCM43430 on RPi boards.
endef

define Package/brcmfmac-board-rpi3
  $(call Package/brcmfmac-board-rpi/Default)
  TITLE:=BCM43455 RPi SDIO NVRAM
endef

define Package/brcmfmac-board-rpi3/description
  NVRAM and localisations blob for the Broadcom BCM43455 on RPi boards.
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	cp $(DL_DIR)/$(BRCMFMAC43430_SDIO_FILE).txt $(PKG_BUILD_DIR)/brcmfmac43430-sdio.txt
	cp $(DL_DIR)/$(BRCMFMAC43455_SDIO_FILE).txt $(PKG_BUILD_DIR)/brcmfmac43455-sdio.txt
	cp $(DL_DIR)/$(BRCMFMAC43455_SDIO_FILE).clm_blob $(PKG_BUILD_DIR)/brcmfmac43455-sdio.clm_blob
endef

define Build/Compile
	true
endef

define Package/brcmfmac-board-rpi2/install
	$(INSTALL_DIR) $(1)/lib/firmware/brcm/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/brcmfmac43430-sdio.txt $(1)/lib/firmware/brcm/
endef

define Package/brcmfmac-board-rpi3/install
	$(INSTALL_DIR) $(1)/lib/firmware/brcm/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/brcmfmac43455-sdio.txt $(1)/lib/firmware/brcm/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/brcmfmac43455-sdio.clm_blob $(1)/lib/firmware/brcm/
endef

$(eval $(call BuildPackage,brcmfmac-board-rpi2))
$(eval $(call BuildPackage,brcmfmac-board-rpi3))
