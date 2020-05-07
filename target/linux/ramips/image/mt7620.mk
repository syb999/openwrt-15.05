#
# MT7620A Profiles
#

define Device/ai-br100
  DTS := AIBR100
  DEVICE_TITLE := Aigale Ai-BR100
  DEVICE_PACKAGES:= kmod-usb2 kmod-usb-ohci
endef
TARGET_DEVICES += ai-br100

define Device/e1700
  DTS := E1700
  IMAGES += factory.bin
  DEVICE_TITLE := Linksys E1700
endef
TARGET_DEVICES += e1700

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

define Device/youku-yk1
  DTS := YOUKU-YK1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := YOUKU YK1
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += youku-yk1

define Device/daishuyun
  DTS := DAISHUYUN
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := DAISHUYUN
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport \
		     kmod-mt76x2
endef
TARGET_DEVICES += daishuyun

define Device/fwr200-v2
  DTS := FWR200_V2
  DEVICE_TITLE := FAST FWR200-V2
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


