#
# MT7620A Profiles
#

define Device/ai-br100
  DTS := AIBR100
  DEVICE_TITLE := Aigale Ai-BR100
  DEVICE_PACKAGES:= kmod-usb2 kmod-usb-ohci
endef
TARGET_DEVICES += ai-br100

define Device/betterspot
  DTS := BETTERSPOT
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Betterspot
  DEVICE_PACKAGES := kmod-usb-core kmod-usb-dwc2 kmod-usb2 kmod-usb-ohci \
	kmod-usb-wdm kmod-usb-net kmod-usb-net-rndis panel-ap-setup
endef
TARGET_DEVICES += betterspot

define Device/e1700
  DTS := E1700
  IMAGES += factory.bin
  DEVICE_TITLE := Linksys E1700
endef
TARGET_DEVICES += e1700

define Device/mb-0002
  DTS := NEOTEL-MB0002
  DEVICE_TITLE := NEOTel MB 0002
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_PACKAGES := panel-ap-setup
endef
TARGET_DEVICES += mb-0002

define Device/meiluyou-p1
  DTS := MEILUYOU-P1
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := MEILUYOU P1
  DEVICE_PACKAGES := panel-ap-setup
endef
TARGET_DEVICES += meiluyou-p1

define Device/mt7620a
  DTS := MT7620a
  DEVICE_TITLE := MediaTek MT7620a EVB
endef
TARGET_DEVICES += mt7620a

define Device/rt-n14u
  DTS := RT-N14U
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := Asus RT-N14u
endef
TARGET_DEVICES += rt-n14u

define Device/psg1208
  DTS := PSG1208
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := Phicomm PSG1208
  DEVICE_PACKAGES := kmod-mt76x2
endef
TARGET_DEVICES += psg1208

define Device/psg1218
  DTS := PSG1218
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := Phicomm PSG1218
  DEVICE_PACKAGES := kmod-mt76x2
endef
TARGET_DEVICES += psg1218


define Device/y1
  DTS := Y1
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Newifi Y1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-usb-ledtrig-usbport \
		     kmod-mt76x2
endef
TARGET_DEVICES += y1

define Device/y1s
  DTS := Y1S
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Lenovo Y1S
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-usb-ledtrig-usbport \
		     kmod-mt76x2
endef
TARGET_DEVICES += y1s

define Device/youku-yk-l1
  DTS := YOUKU-YK-L1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Youku YK-L1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += youku-yk-l1

define Device/youku-yk-l1c
  DTS := YOUKU-YK-L1C
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Youku YK-L1c
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += youku-yk-l1c

define Device/fwr200-v2
  DTS := FWR200_V2
  DEVICE_TITLE := FAST FWR200-V2
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += fwr200-v2

define Device/xiaomi-miwifi-mini
  DTS := XIAOMI-MIWIFI-MINI
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := XIAOMI MIWIFI MINI
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-usb-ledtrig-usbport \
		     kmod-mt76x2
endef
TARGET_DEVICES += xiaomi-miwifi-mini

define Device/dsbox-dsr1
  DTS := DSBOX-DSR1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Dsbox DSR1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport \
		     kmod-mt76x2
endef
TARGET_DEVICES += dsbox-dsr1

