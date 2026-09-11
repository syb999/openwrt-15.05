#
# MT7628 Profiles
#

define Device/mt7628
  DTS := MT7628
  BLOCKSIZE := 64k
  IMAGE_SIZE := $(ralink_default_fw_size_4M)
  DEVICE_TITLE := MediaTek MT7628 EVB
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-ledtrig-usbdev
endef
TARGET_DEVICES += mt7628

define Device/zbt-we1226
  DTS := ZBT-WE1226
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := ZBT-WE1226
  DEVICE_PACKAGES := kmod-mt7603
endef
TARGET_DEVICES += zbt-we1226

define Device/mac1200rv2
  DTS := MAC1200RV2
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := MERCURY MAC1200R v2
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603 uboot-envtools
endef
TARGET_DEVICES += mac1200rv2

define Device/wdr5620v1
  DTS := WDR5620V1
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := TPLINK WDR5620 v1
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603 uboot-envtools
endef
TARGET_DEVICES += wdr5620v1

define Device/urouter
  DTS := UROUTER
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := BHU uRouter
  DEVICE_PACKAGES := kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci kmod-mt7603
endef
TARGET_DEVICES += urouter

define Device/urouter-se
  DTS := UROUTER-SE
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := BHU uRouter SE
  DEVICE_PACKAGES := kmod-mt7603
endef
TARGET_DEVICES += urouter-se


define Device/micap-1321w
  DTS := MICAP-1321W
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := ZYXEL MiCAP-1321W
  DEVICE_PACKAGES := kmod-mt7603 panel-ap-setup
endef
TARGET_DEVICES += micap-1321w

define Device/wna4320v2
  DTS := WNA4320V2
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := ZYXEL WNA4320 v2
  DEVICE_PACKAGES := kmod-mt7603 panel-ap-setup
endef
TARGET_DEVICES += wna4320v2

define Device/ytxc-oem-ap
  DTS := YTXC-OEM-AP
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := YTXC OEM AP
  DEVICE_PACKAGES := kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci kmod-mt7603 panel-ap-setup
endef
TARGET_DEVICES += ytxc-oem-ap

define Device/wdr5640v1
  DTS := WDR5640V1
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := TPLINK WDR5640 v1
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603 uboot-envtools
endef
TARGET_DEVICES += wdr5640v1

define Device/miwifi-nano
  DTS := MIWIFI-NANO
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := MiWiFi Nano
  DEVICE_PACKAGES := kmod-usb-core kmod-usb2 kmod-usb-ohci kmod-mt7603 kmod-ledtrig-usbdev uboot-envtools
endef
TARGET_DEVICES += miwifi-nano

define Device/mi-router-4c
  DTS := MI-ROUTER-4C
  IMAGE_SIZE := 14976k
  DEVICE_TITLE := Xiaomi Mi Router 4C
  DEVICE_PACKAGES := kmod-mt7603 uboot-envtools
endef
TARGET_DEVICES += mi-router-4c

define Device/360p2
  DTS := 360P2
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := 360 P2
  DEVICE_PACKAGES := kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci kmod-mt76x2 kmod-mt7603 uboot-envtools
endef
TARGET_DEVICES += 360p2

define Device/hc5661a
  DTS := HC5661A
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := HiWiFi HC5661A
  DEVICE_PACKAGES := kmod-mt7603 kmod-sdhci-mt7620
endef
TARGET_DEVICES += hc5661a

define Device/hc5611
  DTS := HC5611
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := HiWiFi HC5611
  DEVICE_PACKAGES := kmod-mt76x2 kmod-mt7603
endef
TARGET_DEVICES += hc5611
