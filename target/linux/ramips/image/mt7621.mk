#
# MT7621A Profiles
#

define Device/mt7621
  DTS := MT7621
  IMAGE_SIZE := $(ralink_default_fw_size_4M)
endef

define Device/wsr-600
  DTS := WSR-600
endef

define Device/raisecom-msg1501
  DTS := RAISECOM-MSG1501
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
  DEVICE_TITLE := RAISECOM MSG1501
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2
endef
TARGET_DEVICES += raisecom-msg1501

define Device/re6500
  DTS := RE6500
  IMAGE_SIZE := $(ralink_default_fw_size_8M)
endef
TARGET_DEVICES += re6500

define Device/wsr-1166
  DTS := WSR-1166
  IMAGE/sysupgrade.bin := trx | pad-rootfs | append-metadata
endef

define Device/dir-860l-b1
  DTS := DIR-860L-B1
  BLOCKSIZE := 64k
  IMAGES += factory.bin
  KERNEL := kernel-bin | patch-dtb | relocate-kernel | lzma | uImage lzma
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  IMAGE/sysupgrade.bin := \
	append-kernel | pad-offset 65536 64 | append-rootfs | \
	seama -m "dev=/dev/mtdblock/2" -m "type=firmware" | \
	pad-rootfs | append-metadata | check-size $$$$(IMAGE_SIZE)
  IMAGE/factory.bin := \
	append-kernel | pad-offset 65536 64 | \
	append-rootfs | pad-rootfs -x 64 | \
	seama -m "dev=/dev/mtdblock/2" -m "type=firmware" | \
	seama-seal -m "signature=wrgac13_dlink.2013gui_dir860lb" | \
	check-size $$$$(IMAGE_SIZE)
endef

define Device/firewrt
  DTS := FIREWRT
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef

define Device/pbr-m1
  DTS := PBR-M1
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += pbr-m1

define Device/zbt-wg2626
  DTS := ZBT-WG2626
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef

define Device/mt7621-rtl8367s
  DTS := MT7621-RTL8367S
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += mt7621-rtl8367s

define Device/bussiness-router
  DTS := BUSSINESS-ROUTER
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += bussiness-router

define Device/newifi-d1
  DTS := Newifi-D1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += newifi-d1

define Device/newifi-d2
  DTS := Newifi-D2
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += newifi-d2

define Device/zbt-we1326
  DTS := ZBT-WE1326
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += zbt-we1326

define Device/jcg-y2
  DTS := JCG-Y2
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += jcg-y2

define Device/k2p
  DTS := K2P
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
endef
TARGET_DEVICES += k2p

define Device/ghl-r-001-e
  DTS := GHL-R-001-E
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += ghl-r-001-e

define Device/ghl-r-001-f
  DTS := GHL-R-001-F
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += ghl-r-001-f

define Device/jdcloud-re-sp-01b
  DTS := JDCloud_RE-SP-01B
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := JDCloud RE-SP-01B
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-usb-hid kmod-sdhci-mt7620 \
		     kmod-ledtrig-usbdev kmod-mt7603 \
		     kmod-mt7615e wpad-mini fixwlanmac
endef
TARGET_DEVICES += jdcloud-re-sp-01b

define Device/todaair-in1251y
  DTS := TodaAir-IN1251Y
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := TodaAir IN1251Y
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e mt7663-firmware-ap mt7663-firmware-sta
endef
TARGET_DEVICES += todaair-in1251y

define Device/xiaoyu-xy-c5
  DTS := XIAOYU-XY-C5
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += xiaoyu-xy-c5
