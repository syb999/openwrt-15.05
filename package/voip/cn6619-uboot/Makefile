#
# CN6619 / ZM-WR2500 U-Boot (built from upstream source + patches)
#
# Upstream: pepe2k/u-boot_mod @ 09c39dda - OpenWrt-friendly U-Boot for
# Qualcomm/Atheros AR71xx/AR9xxx with an HTTP recovery server.
#
# The package carries ONLY the CN6619 delta as a small patch.  The patch adds
# a "zmtel_zm-wr2500" build target:
#
#   * BOARD = db12x -> links qca95xx_pll_init.o: the AR934x PLL/clocks
#     low-level init (cpu_pll_config / cpu_pll_enable / ddr_pll_* /
#     pll_bypass_disable / pll_cfg_in_flash ...).  WITHOUT it the SoC keeps
#     the BootROM default PLL, the audio/TDM block never gets its clock and
#     the Si3217x SLIC PCM path stays dead (handset only hums).  THIS WAS
#     THE REAL ROOT CAUSE of "no audio".
#   * flash 128k(u-boot) + 64k(u-boot-env) + 16128k(firmware) + 64k(art)
#   * kernel load addr 0x9F030000
#   * reset button GPIO 21 (web recovery trigger)
#   * HTTP recovery enabled
#
# IMPORTANT - the U-Boot image is deliberately NOT installed into the
# firmware image.  It is only COMPILED and the result is copied to
# $(TOPDIR)/bin/ so it can be flashed separately.  The "u-boot" partition on
# this board is protected: flashing it needs kmod-mtd-rw (dependency below)
# and /usr/sbin/flash-uboot.sh does the unlock + write + read-back verify.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=cn6619-uboot
PKG_VERSION:=09c39dda
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/pepe2k/u-boot_mod.git
PKG_SOURCE_VERSION:=09c39ddac9df6e9bdf4289b481999ab0b6edbc77
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_PARALLEL:=0

include $(INCLUDE_DIR)/package.mk

UBOOT_BIN:=$(PKG_BUILD_DIR)/bin/u-boot_mod__zmtel_zm-wr2500__*__*.bin

define Package/cn6619-uboot
  SECTION:=utils
  CATEGORY:=ZM-TEL
  TITLE:=ZM-WR2500 (CN6619) U-Boot - AR934x PLL init + web recovery
  DEPENDS:=+kmod-mtd-rw
endef

define Package/cn6619-uboot/description
  U-Boot for the ZMTEL ZM-WR2500 (CN6619, AR9341) voice board, built from
  pepe2k/u-boot_mod plus a small CN6619 patch.  Performs the full AR934x
  low-level init (PLL, DDR, clocks) - required for the Si3217x SLIC
  audio/TDM path - and enables the HTTP recovery web server (hold reset on
  power-up).

  The compiled U-Boot image is placed in bin/ of the build tree (it is NOT
  written into the firmware image).  Flash it separately with
  /usr/sbin/flash-uboot.sh, which unlocks the protected u-boot partition
  (kmod-mtd-rw), writes the image and verifies the read-back.
endef

define Build/Compile
	+$(MAKE) -C $(PKG_BUILD_DIR) \
		BUILD_TOPDIR=$(PKG_BUILD_DIR) \
		ARCH=mips \
		CROSS_COMPILE=$(TARGET_CROSS) \
		STAGING_DIR=$(STAGING_DIR) \
		PATH="$(TARGET_PATH):$(TMP_DIR)/host/bin:$(PATH)" \
		zmtel_zm-wr2500
endef

# Publish the built U-Boot image in the build tree (NOT in the firmware)
define Build/InstallDev
	$(INSTALL_DIR) $(TOPDIR)/bin
	$(CP) $(UBOOT_BIN) $(TOPDIR)/bin/
endef

define Package/cn6619-uboot/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/flash-uboot.sh $(1)/usr/sbin/flash-uboot.sh
endef

$(eval $(call BuildPackage,cn6619-uboot))
