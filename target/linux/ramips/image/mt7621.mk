#
# MT7621A Profiles
#

# All MT7621 rootfs images are squashfs based:
#  - SPI/NOR boards: plain squashfs sysupgrade images
#  - NAND boards: squashfs wrapped into a UBI volume (append-ubi, factory.bin)
# Device/Init defaults FILESYSTEMS to $(TARGET_FILESYSTEMS), which includes
# ubifs whenever CONFIG_TARGET_ROOTFS_UBIFS is enabled (it is, because this
# subtarget now also carries the NAND boards).  With that default, SPI boards
# would additionally try to build *-ubifs-sysupgrade.bin images, which need
# $(KDIR)/root.ubifs - a file that is never produced for the Default profile
# (mkfs.ubifs only runs when $(PROFILE)_UBIFS_OPTS/UBIFS_OPTS is non-empty),
# so the build fails with:
#   [ -f ...-kernel.bin -a -f .../root.ubifs ]  -> Error 1
# Force squashfs as the root filesystem type for the whole subtarget instead.
TARGET_FILESYSTEMS := squashfs

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
  DEVICE_TITLE := Linksys RE6500
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2
endef
TARGET_DEVICES += re6500

define Device/wsr-1166
  DTS := WSR-1166
  IMAGE/sysupgrade.bin := trx | pad-rootfs | append-metadata
endef

define Device/243p
  DTS := 243P
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := 243P
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e mt7663-firmware-ap mt7663-firmware-sta
endef
TARGET_DEVICES += 243p

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
  DEVICE_TITLE := PBR-M1
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-usb-hid kmod-sdhci-mt7620 kmod-ledtrig-usbdev kmod-ata-core kmod-ata-ahci kmod-usb3-mt7621 kmod-rtc-pcf8563 kmod-mt7603 kmod-mt76x2
endef
TARGET_DEVICES += pbr-m1

define Device/zbt-wg2626
  DTS := ZBT-WG2626
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := ZBT-WG2626
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-sdhci-mt7620 kmod-ledtrig-usbdev kmod-ata-core kmod-ata-ahci kmod-usb3-mt7621 kmod-mt7603 kmod-mt76x2
endef

define Device/mt7621-rtl8367s
  DTS := MT7621-RTL8367S
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := MT7621-RTL8367S
  DEVICE_PACKAGES := -wpad-mini -iwinfo kmod-switch-rtl8367b
endef
TARGET_DEVICES += mt7621-rtl8367s

define Device/bussiness-router
  DTS := BUSSINESS-ROUTER
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Bussiness Router
  DEVICE_PACKAGES := -wpad-mini -iwinfo
endef
TARGET_DEVICES += bussiness-router

define Device/newifi-d1
  DTS := Newifi-D1
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Newifi-D1
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-ledtrig-usbdev wpad-mini kmod-sdhci-mt7620
endef
TARGET_DEVICES += newifi-d1

define Device/newifi-d2
  DTS := Newifi-D2
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Newifi-D2
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-ledtrig-usbdev wpad-mini
endef
TARGET_DEVICES += newifi-d2

define Device/treebear
  DTS := WITOWN-TREEBEAR
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := Witown TreeBear
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3
endef
TARGET_DEVICES += treebear

define Device/zbt-we1326
  DTS := ZBT-WE1326
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := ZBT-WE1326
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-sdhci-mt7620 wpad-mini
endef
TARGET_DEVICES += zbt-we1326

define Device/jcg-y2
  DTS := JCG-Y2
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := JCG-Y2
  DEVICE_PACKAGES := kmod-mt7615e kmod-usb3 kmod-ledtrig-usbdev wpad-mini mt7615-dbdc-setup
endef
TARGET_DEVICES += jcg-y2

define Device/k2p
  DTS := K2P
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  DEVICE_TITLE := K2P
  DEVICE_PACKAGES := kmod-mt7615e wpad-mini mt7615-dbdc-setup
endef
TARGET_DEVICES += k2p

define Device/ghl-r-001-e
  DTS := GHL-R-001-E
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := GHL-R-001-E
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-ledtrig-usbdev wpad-mini
endef
TARGET_DEVICES += ghl-r-001-e

define Device/ghl-r-001-f
  DTS := GHL-R-001-F
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := GHL-R-001-F
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-ledtrig-usbdev wpad-mini
endef
TARGET_DEVICES += ghl-r-001-f

define Device/jdcloud-re-sp-01b
  DTS := JDCloud_RE-SP-01B
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  DEVICE_TITLE := JDCloud RE-SP-01B
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-usb-hid kmod-sdhci-mt7620 kmod-ledtrig-usbdev kmod-mt7603 kmod-mt7615e wpad-mini fixwlanmac
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
  DEVICE_TITLE := XiaoYu XY-C5
  DEVICE_PACKAGES := kmod-ata-core kmod-ata-ahci kmod-usb3
endef
TARGET_DEVICES += xiaoyu-xy-c5

#
# MT7621 NAND flash based boards
#
define Device/an1201l
  DTS := AN1201L
  BLOCKSIZE := 128KiB
  PAGESIZE := 2048
  KERNEL_SIZE := 2097152
  IMAGE_SIZE := 127232k
  FILESYSTEMS := squashfs
  IMAGES := factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := AN1201L
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e mt7663-firmware-ap mt7663-firmware-sta wpad-mini
endef
TARGET_DEVICES += an1201l

define Device/hc5962
  DTS := HC5962
  BLOCKSIZE := 128KiB
  PAGESIZE := 2048
  KERNEL_SIZE := 2097152
  IMAGE_SIZE := 127232k
  FILESYSTEMS := squashfs
  IMAGES := factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := HiWiFi HC5962
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-usb-hid kmod-ledtrig-netdev kmod-mt7603 kmod-mt76x2 wpad-mini
endef
TARGET_DEVICES += hc5962

define Device/nokia-a040wq
  DTS := NOKIA-A040WQ
  BLOCKSIZE := 128KiB
  PAGESIZE := 2048
  KERNEL_SIZE := 2048k
  IMAGE_SIZE := 124928k
  FILESYSTEMS := squashfs
  IMAGES := factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := NOKIA-A040WQ
  DEVICE_PACKAGES := kmod-mt7615e kmod-usb3 kmod-ledtrig-usbdev wpad-mini mt7615-dbdc-setup
endef
TARGET_DEVICES += nokia-a040wq

define Device/maipu-igw401-100-p
  DTS := MAIPU-IGW401-100-P
  BLOCKSIZE := 128KiB
  PAGESIZE := 2048
  KERNEL_SIZE := 2097152
  IMAGE_SIZE := 127232k
  FILESYSTEMS := squashfs
  IMAGES := factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := MAIPU IGW401-100-P
  DEVICE_PACKAGES := -wpad-mini -iwinfo
endef
TARGET_DEVICES += maipu-igw401-100-p

define Device/mir3g
  DTS := MIR3G
  BLOCKSIZE := 128KiB
  IMAGES := factory.bin
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 120320k
  UBINIZE_OPTS := -E 5
  FILESYSTEMS := squashfs
  IMAGES += kernel1.bin rootfs0.bin
  IMAGE/kernel1.bin := append-kernel
  IMAGE/rootfs0.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := Xiaomi Mi Router 3G
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt76x2 kmod-usb3 kmod-ledtrig-usbdev wpad-mini uboot-envtools
endef
TARGET_DEVICES += mir3g

define Device/mi-router-ac2100
  DTS := MI-ROUTER-AC2100
  BLOCKSIZE := 128KiB
  IMAGES := factory.bin
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 120320k
  UBINIZE_OPTS := -E 5
  FILESYSTEMS := squashfs
  IMAGES += kernel1.bin rootfs0.bin
  IMAGE/kernel1.bin := append-kernel
  IMAGE/rootfs0.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := Xiaomi Mi Router AC2100
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e uboot-envtools wpad-mini
endef
TARGET_DEVICES += mi-router-ac2100

define Device/redmi-router-ac2100
  DTS := REDMI-ROUTER-AC2100
  BLOCKSIZE := 128KiB
  IMAGES := factory.bin
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 120320k
  UBINIZE_OPTS := -E 5
  FILESYSTEMS := squashfs
  IMAGES += kernel1.bin rootfs0.bin
  IMAGE/kernel1.bin := append-kernel
  IMAGE/rootfs0.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := Xiaomi Redmi Router AC2100
  DEVICE_PACKAGES := kmod-mt7603 kmod-mt7615e uboot-envtools wpad-mini
endef
TARGET_DEVICES += redmi-router-ac2100

define Device/zte-e8820s
  DTS := ZTE-E8820S
  BLOCKSIZE := 128KiB
  PAGESIZE := 2048
  KERNEL_SIZE := 2097152
  IMAGE_SIZE := 127232k
  FILESYSTEMS := squashfs
  IMAGES := factory.bin
  IMAGE/factory.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
  DEVICE_TITLE := ZTE E8820S
  DEVICE_PACKAGES := kmod-usb-core kmod-usb3 kmod-usb-hid kmod-ledtrig-netdev kmod-mt7603 kmod-mt76x2 wpad-mini
endef
TARGET_DEVICES += zte-e8820s
