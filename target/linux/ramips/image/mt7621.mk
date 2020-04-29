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

define Device/ghl
  DTS := GHL
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += ghl

define Device/jdcloud-1
  DTS := JDCloud-1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += jdcloud-1

