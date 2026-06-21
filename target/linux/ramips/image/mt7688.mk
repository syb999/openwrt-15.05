#
# MT7688 Profiles
#

define Device/ENJOYLINK
  DTS := MT7688_ENJOYLINK
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  SUPPORTED_DEVICES := enjoylink
  DEVICE_TITLE := ENJOY LINK
  DEVICE_PACKAGES:= kmod-mt7603 panel-ap-setup
endef
TARGET_DEVICES += ENJOYLINK

define Device/LinkIt7688
  DTS := LINKIT7688
  IMAGE_SIZE := $(ralink_default_fw_size_32M)
  SUPPORTED_DEVICES := linkits7688 linkits7688d
  DEVICE_TITLE := MediaTek LinkIt Smart 7688
  DEVICE_PACKAGES:= kmod-usb2 kmod-usb-ohci uboot-envtools
endef
TARGET_DEVICES += LinkIt7688
