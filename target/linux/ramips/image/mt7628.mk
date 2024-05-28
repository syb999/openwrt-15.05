#
# MT7628 Profiles
#

define Device/mt7628
  DTS := MT7628
  BLOCKSIZE := 64k
  IMAGE_SIZE := $(ralink_default_fw_size_4M)
  DEVICE_TITLE := MediaTek MT7628 EVB
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += mt7628

define Device/zbt-we1226
  DTS := ZBT-WE1226
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += zbt-we1226

define Device/mac1200rv2
  DTS := MAC1200RV2
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += mac1200rv2

define Device/wdr5620v1
  DTS := WDR5620V1
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += wdr5620v1

define Device/micap-1321w
  DTS := MICAP-1321W
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += micap-1321w

define Device/wna4320v2
  DTS := WNA4320V2
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += wna4320v2

define Device/ytxc-oem-ap
  DTS := YTXC-OEM-AP
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += ytxc-oem-ap

define Device/wdr5640v1
  DTS := WDR5640V1
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += wdr5640v1

define Device/miwifi-nano
  DTS := MIWIFI-NANO
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += miwifi-nano

define Device/mi-router-4c
  DTS := MI-ROUTER-4C
  IMAGE_SIZE := 14976k
endef
TARGET_DEVICES += mi-router-4c

define Device/360p2
  DTS := 360P2
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += 360p2

define Device/hc5661a
  DTS := HC5661A
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += hc5661a

define Device/hc5611
  DTS := HC5611
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += hc5611
