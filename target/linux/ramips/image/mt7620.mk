#
# MT7620A Profiles
#

DEVICE_VARS += TPLINK_FLASHLAYOUT TPLINK_HWID TPLINK_HWREV TPLINK_HWREVADD TPLINK_HVERSION \
	DLINK_ROM_ID DLINK_FAMILY_MEMBER DLINK_FIRMWARE_SIZE

define Build/elecom-header
	cp $@ $(KDIR)/v_0.0.0.bin
	( \
		mkhash md5 $(KDIR)/v_0.0.0.bin && \
		echo 458 \
	) | mkhash md5 > $(KDIR)/v_0.0.0.md5
	$(STAGING_DIR_HOST)/bin/tar -c \
		$(if $(SOURCE_DATE_EPOCH),--mtime=@$(SOURCE_DATE_EPOCH)) \
		-f $@ -C $(KDIR) v_0.0.0.bin v_0.0.0.md5
endef

define Build/zyimage
	$(STAGING_DIR_HOST)/bin/zyimage $(1) $@
endef

define Device/y1
  DTS := Y1
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Newifi Y1
endef
TARGET_DEVICES += y1

define Device/y1s
  DTS := Y1S
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := Lenovo Y1S
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
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci kmod-sdhci-mt7620 kmod-usb-ledtrig-usbport
endef
TARGET_DEVICES += daishuyun

define Device/rt-n14u
  DTS := RT-N14U
  DEVICE_TITLE := Asus RT-N14u
endef
TARGET_DEVICES += rt-n14u

define Device/fwr200-v2
  DTS := FWR200_V2
  DEVICE_TITLE := FAST FWR200-V2
endef
TARGET_DEVICES += fwr200-v2

define Device/xiaomi-miwifi-mini
  DTS := XIAOMI-MIWIFI-MINI
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := XIAOMI MIWIFI MINI
  DEVICE_PACKAGES := kmod-usb2 kmod-usb-ohci
endef
TARGET_DEVICES += xiaomi-miwifi-mini

