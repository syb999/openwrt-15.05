#
# MT7628 Profiles
#

define Device/tplink
  TPLINK_FLASHLAYOUT :=
  TPLINK_HWID :=
  TPLINK_HWREV :=
  TPLINK_HWREVADD :=
  TPLINK_HVERSION :=
  KERNEL := $(KERNEL_DTB)
  KERNEL_INITRAMFS := $(KERNEL_DTB) | tplink-v2-header -e
  IMAGES += tftp-recovery.bin
  IMAGE/factory.bin := tplink-v2-image -e
  IMAGE/tftp-recovery.bin := pad-extra 128k | $$(IMAGE/factory.bin)
  IMAGE/sysupgrade.bin := tplink-v2-image -s -e | append-metadata | \
	check-size $$$$(IMAGE_SIZE)
endef
DEVICE_VARS += TPLINK_FLASHLAYOUT TPLINK_HWID TPLINK_HWREV TPLINK_HWREVADD TPLINK_HVERSION

define Device/mt7628
  DTS := MT7628
  BLOCKSIZE := 64k
  IMAGE_SIZE := $(ralink_default_fw_size_4M)
  DEVICE_TITLE := MediaTek MT7628 EVB
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += mt7628


define Device/tplink_c20-v4
  $(Device/tplink)
  DTS := ArcherC20v4
  IMAGE_SIZE := 7808k
  DEVICE_TITLE := TP-Link ArcherC20 v4
  TPLINK_FLASHLAYOUT := 8Mmtk
  TPLINK_HWID := 0xc200004
  TPLINK_HWREV := 0x1
  TPLINK_HWREVADD := 0x4
  TPLINK_HVERSION := 3
  DEVICE_PACKAGES := kmod-mt76x0e
endef
TARGET_DEVICES += tplink_c20-v4

