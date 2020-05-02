#
# Copyright (C) 2008-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define imgname
$(BIN_DIR)/$(IMG_PREFIX)-$(2)-$(1)
endef

define sysupname
$(call imgname,$(1),$(2))-sysupgrade.bin
endef

VMLINUX:=$(IMG_PREFIX)-vmlinux
UIMAGE:=$(IMG_PREFIX)-uImage

define Image/Build/Initramfs
	$(call Image/Build/Profile/$(PROFILE),initramfs)
endef

DEVICE_VARS += DTS

loadaddr-y := 0x80000000
loadaddr-$(CONFIG_TARGET_ramips_rt288x) := 0x88000000
loadaddr-$(CONFIG_TARGET_ramips_mt7621) := 0x80001000
loadaddr-$(CONFIG_TARGET_ramips_mt7621_nand) := 0x80001000

KERNEL_LOADADDR := $(loadaddr-y)

KERNEL_DTB = kernel-bin | patch-dtb | lzma
define Device/Default
  PROFILES = Default $$(DTS)
  KERNEL_DEPENDS = $$(wildcard ../dts/$$(DTS).dts)
  KERNEL := $(KERNEL_DTB) | uImage lzma
  IMAGES := sysupgrade.bin
  IMAGE_SIZE := $(ralink_default_fw_size_16M)
  SUPPORTED_DEVICES = $(1)
  sysupgrade_bin := append-kernel | append-rootfs | pad-rootfs
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata | check-size $$$$(IMAGE_SIZE)
endef

define Build/patch-dtb
	$(LINUX_DIR)/scripts/dtc/dtc -O dtb -o $@.dtb ../dts/$(DTS).dts
	$(STAGING_DIR_HOST)/bin/patch-dtb $@ $@.dtb
endef

define Build/trx
	$(STAGING_DIR_HOST)/bin/trx \
		-o $@ \
		-m $(IMAGE_SIZE) \
		-f $(word 1,$^) \
		-a 4 -f $(word 2,$^)
endef

define Build/seama
	$(STAGING_DIR_HOST)/bin/seama -i $@ $(1)
	mv $@.seama $@
endef

define Build/seama-seal
	$(call Build/seama,-s $@.seama $(1))
endef

define Build/relocate-kernel
	( \
		dd if=$(KDIR)/loader.bin bs=32 conv=sync && \
		perl -e '@s = stat("$@"); print pack("V", @s[7])' && \
		cat $@ \
	) > $@.new
	mv $@.new $@
endef

define MkCombineduImage
	$(call PatchKernelLzma,$(2),$(3))
	if [ `stat -c%s "$(KDIR)/vmlinux-$(2).bin.lzma"` -gt `expr $(4) - 64` ]; then \
		echo "Warning: $(KDIR)/vmlinux-$(2).bin.lzma is too big" >&2; \
	else if [ `stat -c%s "$(KDIR)/root.$(1)"` -gt $(5) ]; then \
		echo "Warning: $(KDIR)/root.$(1) is too big" >&2; \
	else \
		( dd if=$(KDIR)/vmlinux-$(2).bin.lzma bs=`expr $(4) - 64` conv=sync ; dd if=$(KDIR)/root.$(1) ) > $(KDIR)/vmlinux-$(2).bin.lzma.combined ; \
	fi ; fi
	$(call MkImage,lzma,$(KDIR)/vmlinux-$(2).bin.lzma.combined,$(call sysupname,$(1),$(2)),$(6))
endef


#
# The real magic happens inside these templates
#
# $(1), compression method
# $(2), filename of image data
# $(3), output filename
define MkImage
	$(eval imagename=$(if $(4),$(4),MIPS OpenWrt Linux-$(LINUX_VERSION)))
	-mkimage -A mips -O linux -T kernel -C $(1) -a $(loadaddr-y) -e $(loadaddr-y) \
		-n "$(imagename)" \
		-d $(2) $(3)
endef

define CompressLzma
	$(STAGING_DIR_HOST)/bin/lzma e $(1) -lc1 -lp2 -pb2 $(2)
endef

define MkImageSysupgrade/squashfs
	$(eval output_name=$(IMG_PREFIX)-$(2)-$(1)-$(if $(4),$(4),sysupgrade).bin)
	cat $(KDIR)/vmlinux-$(2).uImage $(KDIR)/root.$(1) > $(KDIR)/$(output_name)
	$(call prepare_generic_squashfs,$(KDIR)/$(output_name))
	if [ `stat -c%s "$(KDIR)/$(output_name)"` -gt $(3) ]; then \
		echo "Warning: $(KDIR)/$(output_name) is too big" >&2; \
	else \
		$(CP) $(KDIR)/$(output_name) $(BIN_DIR)/$(output_name); \
	fi
endef

define MkImageTpl/squashfs
	$(eval output_name=$(IMG_PREFIX)-$(2)-$(1)-$(if $(4),$(4),sysupgrade).bin)
	$(STAGING_DIR_HOST)/bin/mktplinkfw2 -V "ver. 2.0" -B "$(2)" -j \
		-o $(KDIR)/$(output_name) \
		-k $(KDIR)/vmlinux-$(1)$(4).bin.lzma \
		-r $(KDIR)/root.$(1)
	$(CP) $(KDIR)/$(output_name) $(BIN_DIR)/$(output_name)
endef

define MkImageTpl/initramfs
	$(eval output_name=$(IMG_PREFIX)-$(2)-$(1).bin)
	$(STAGING_DIR_HOST)/bin/mktplinkfw2 -V "ver. 2.0" -B "$(2)" -c \
		-o $(KDIR)/$(output_name) \
		-k $(KDIR)/vmlinux-$(1).bin.lzma
	$(CP) $(KDIR)/$(output_name) $(BIN_DIR)/$(output_name)
endef

# $(1), lowercase board name like "mt7620a_v22sg"
# $(2), DTS filename without .dts extension
# $(3), optional filename suffix, e.g. "-initramfs"
define PatchKernelLzmaDtb
	cp $(KDIR)/vmlinux$(3) $(KDIR)/vmlinux-$(1)$(3)
	$(LINUX_DIR)/scripts/dtc/dtc -O dtb -o $(KDIR)/$(2).dtb ../dts/$(2).dts
	$(STAGING_DIR_HOST)/bin/patch-dtb $(KDIR)/vmlinux-$(1)$(3) $(KDIR)/$(2).dtb
	$(call CompressLzma,$(KDIR)/vmlinux-$(1)$(3),$(KDIR)/vmlinux-$(1)$(3).bin.lzma)
endef

# $(1), lowercase board name
# $(2), DTS filename without .dts extension
# $(3), ih_name field of uImage header
# $(4), optional filename suffix, e.g. "-initramfs"
define MkImageLzmaDtb
	$(call PatchKernelLzmaDtb,$(1),$(2),$(4))
	$(call MkImage,lzma,$(KDIR)/vmlinux-$(1)$(4).bin.lzma,$(KDIR)/vmlinux-$(1)$(4).uImage,$(3))
endef

# $(1), Rootfs type, e.g. squashfs
# $(2), lowercase board name
# $(3), DTS filename without .dts extension
# $(4), maximum size of sysupgrade image
# $(5), uImage header's ih_name field
define BuildFirmware/OF
	$(call MkImageLzmaDtb,$(2),$(3),$(5))
	$(call MkImageSysupgrade/$(1),$(1),$(2),$(4),$(6))
endef

define BuildFirmware/OF/tplink
	$(call PatchKernelLzmaDtb,$(1),$(2),$(4))
	$(call MkImageTpl/$(1),$(1),$(2),$(4),$(5))
endef

define BuildFirmware/OF/tplink/initramfs
	$(call PatchKernelLzmaDtb,$(2),$(3),-initramfs)
	$(call MkImageTpl/$(1),$(1),$(2),$(4),$(5))
endef

# $(1), squashfs/initramfs
# $(2), lowercase board name
# $(3), DTS filename without .dts extension
# $(4), ih_name field of uImage header
define BuildFirmware/OF/initramfs
	$(call MkImageLzmaDtb,$(2),$(3),$(4),-initramfs)
	$(CP) $(KDIR)/vmlinux-$(2)-initramfs.uImage $(call imgname,$(1),$(2))-uImage.bin
endef


# Build images for default ralink layout for 4MB flash
# kernel + roots = 0x3b0000
# $(1) = squashfs/initramfs
# $(2) = lowercase board name
# $(3) = dts file
ralink_default_fw_size_4M=3866624
BuildFirmware/Default4M/squashfs=$(call BuildFirmware/OF,$(1),$(2),$(3),$(ralink_default_fw_size_4M),$(4))
BuildFirmware/Default4M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3),$(4))

# Build images for default ralink layout for 8MB flash
# kernel + roots = 0x7b0000
# $(1) = squashfs/initramfs
# $(2) = lowercase board name
# $(3) = dts file
# $(4) = uImage header name field
ralink_default_fw_size_8M=8060928
BuildFirmware/Default8M/squashfs=$(call BuildFirmware/OF,$(1),$(2),$(3),$(ralink_default_fw_size_8M),$(4))
BuildFirmware/Default8M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3),$(4))
BuildFirmware/Tplink/squashfs=$(call BuildFirmware/OF/tplink,$(1),$(2),$(3),$(4))
BuildFirmware/Tplink/initramfs=$(call BuildFirmware/OF/tplink/initramfs,$(1),$(2),$(3),$(4))

ralink_default_fw_size_16M=16121856
BuildFirmware/Default16M/squashfs=$(call BuildFirmware/OF,$(1),$(2),$(3),$(ralink_default_fw_size_16M),$(4))
BuildFirmware/Default16M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3),$(4))

ralink_default_fw_size_32M=33226752
BuildFirmware/Default32M/squashfs=$(call BuildFirmware/OF,$(1),$(2),$(3),$(ralink_default_fw_size_32M),$(4))
BuildFirmware/Default32M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3),$(4))

# Build images for a custom sized flash layout
# $(1) = squashfs/initramfs
# $(2) = lowercase board name
# $(3) = dts file
# $(4) = kernel + rootfs size
BuildFirmware/CustomFlash/squashfs=$(call BuildFirmware/OF,$(1),$(2),$(3),$(4),$(5),$(6))
BuildFirmware/CustomFlash/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# wrappers for boards that have 4MB and 8MB versions
define BuildFirmware/DefaultDualSize/squashfs
	$(call BuildFirmware/Default4M/$(1),$(1),$(2)-4M,$(3)-4M)
	$(call BuildFirmware/Default8M/$(1),$(1),$(2)-8M,$(3)-8M)
endef
define BuildFirmware/DefaultDualSize/initramfs
	$(call BuildFirmware/OF/initramfs,$(1),$(2)-4M,$(3)-4M)
	$(call BuildFirmware/OF/initramfs,$(1),$(2)-8M,$(3)-8M)
endef

# Some boards need a special header inside the uImage to make them bootable
define BuildFirmware/CustomFlashFactory/squashfs
	$(call BuildFirmware/CustomFlash/$(1),$(1),$(2),$(3),$(4))
	$(call BuildFirmware/CustomFlash/$(1),$(1),$(2),$(3),$(4),$(5),$(6))
endef
BuildFirmware/CustomFlashFactory/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# sign an image to make it work with edimax tftp recovery
define BuildFirmware/Edimax/squashfs
	$(call BuildFirmware/OF,$(1),$(2),$(3),$(4))
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		mkedimaximg -i $(call sysupname,$(1),$(2)) \
			-o $(call imgname,$(1),$(2))-factory.bin \
			-s $(5) -m $(6) -f $(7) -S $(8); \
	fi
endef
BuildFirmware/Edimax/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# build Seama header images
define BuildFirmware/Seama/squashfs
	$(call MkImageLzmaDtb,$(2),$(3),$(5))
	$(eval output_name=$(IMG_PREFIX)-$(2)-$(1)-sysupgrade.bin)
	cat $(KDIR)/vmlinux-$(2).bin.lzma $(KDIR)/root.$(1) > $(KDIR)/img_$(2).$(1).tmp
	if [ `stat -c%s "$(KDIR)/img_$(2).$(1).tmp"` -gt $$$$(($(5) - 64)) ]; then \
		echo "Warning: $(KDIR)/img_$(2).$(1).tmp is too big" >&2; \
	else \
		dd if=$(KDIR)/vmlinux-$(2).bin.lzma of=$(KDIR)/vmlinux-$(2).bin.lzma.padded bs=64k conv=sync; \
		( \
			dd if=$(KDIR)/vmlinux-$(2).bin.lzma.padded bs=1 count=`expr \`stat -c%s $(KDIR)/vmlinux-$(2).bin.lzma.padded\` - 64`; \
			dd if=$(KDIR)/root.$(1) bs=64k conv=sync; \
		) > $(KDIR)/vmlinux-$(2).tmp; \
		$(STAGING_DIR_HOST)/bin/seama \
			-i $(KDIR)/vmlinux-$(2).tmp \
			-m "dev=/dev/mtdblock/2" -m "type=firmware"; \
		$(STAGING_DIR_HOST)/bin/seama \
			-s $(call imgname,$(1),$(2))-factory.bin \
			-m "signature=$(4)" \
			-i $(KDIR)/vmlinux-$(2).tmp.seama; \
		dd if=$(KDIR)/vmlinux-$(2).bin.lzma.padded bs=1 count=`expr \`stat -c%s $(KDIR)/vmlinux-$(2).bin.lzma.padded\` - 64` of=$(KDIR)/vmlinux-$(2)-sysupgrade.tmp; \
		$(STAGING_DIR_HOST)/bin/seama \
			-i $(KDIR)/vmlinux-$(2)-sysupgrade.tmp \
			-m "dev=/dev/mtdblock/2" -m "type=firmware"; \
		( \
			dd if=$(KDIR)/vmlinux-$(2)-sysupgrade.tmp.seama; \
			dd if=$(KDIR)/root.$(1) bs=64k conv=sync; \
		) > $(BIN_DIR)/$(output_name); \
	fi
endef
BuildFirmware/Seama/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# sign Buffalo images
define BuildFirmware/Buffalo
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		buffalo-enc -p $(3) -v 1.76 \
			-i $(KDIR)/vmlinux-$(2).uImage \
			-o $(KDIR)/vmlinux-$(2).uImage.enc; \
		buffalo-enc -p $(3) -v 1.76 \
			-i $(KDIR)/root.$(1) \
			-o $(KDIR)/root.$(2).enc; \
		buffalo-tag -b $(3) -p $(3) -a ram -v 1.76 -m 1.01 \
			-l mlang8 -f 1 -r EU \
			-i $(KDIR)/vmlinux-$(2).uImage.enc \
			-i $(KDIR)/root.$(2).enc \
			-o $(call imgname,$(1),$(2))-factory-EU.bin; \
	fi
endef

# sign trednet / UMedia images
define BuildFirmware/UMedia/squashfs
	$(call BuildFirmware/Default8M/$(1),$(1),$(2),$(3))
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		fix-u-media-header -T 0x46 -B $(4) \
			-i $(call sysupname,$(1),$(2)) \
			-o $(call imgname,$(1),$(2))-factory.bin; \
	fi
endef
BuildFirmware/UMedia/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# sign dap 1350 based images
dap1350_mtd_size=7667712
define BuildFirmware/dap1350/squashfs
	$(call BuildFirmware/CustomFlash/$(1),$(1),$(2),$(3),$(dap1350_mtd_size))
	-mkdapimg -s $(4) \
		-i $(call sysupname,$(1),$(2)) \
		-o $(call imgname,$(1),$(2))-factory.bin
endef
BuildFirmware/dap1350/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# Sign Poray images
define BuildFirmware/Poray4M/squashfs
	$(call BuildFirmware/Default4M/$(1),$(1),$(2),$(3))
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		mkporayfw -B $(3) -F 4M \
			-f $(call sysupname,$(1),$(2)) \
			-o $(call imgname,$(1),$(2))-factory.bin; \
	fi
endef
BuildFirmware/Poray4M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

define BuildFirmware/Poray8M/squashfs
	$(call BuildFirmware/Default8M/$(1),$(1),$(2),$(3))
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		mkporayfw -B $(3) -F 8M \
			-f $(call sysupname,$(1),$(2)) \
			-o $(call imgname,$(1),$(2))-factory.bin; \
	fi
endef
BuildFirmware/Poray8M/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

define BuildFirmware/PorayDualSize/squashfs
	$(call BuildFirmware/DefaultDualSize/$(1),$(1),$(2),$(3))
	if [ -e "$(call sysupname,$(1),$(2)-4M)" ]; then \
		mkporayfw -B $(3) -F 4M \
			-f $(call sysupname,$(1),$(2)-4M) \
			-o $(call imgname,$(1),$(2)-4M)-factory.bin; \
	fi
	if [ -e "$(call sysupname,$(1),$(2)-8M)" ]; then \
		mkporayfw -B $(3) -F 8M \
			-f $(call sysupname,$(1),$(2)-8M) \
			-o $(call imgname,$(1),$(2)-8M)-factory.bin; \
	fi
endef
BuildFirmware/PorayDualSize/initramfs=$(call BuildFirmware/DefaultDualSize/initramfs,$(1),$(2),$(3))

define BuildFirmware/Gemtek/squashfs
	$(call BuildFirmware/Default4M/$(1),$(1),$(2),$(3))
	if [ -e "$(call sysupname,$(1),$(2))" ]; then \
		mkheader_gemtek "$(call sysupname,$(1),$(2))" \
			"$(call imgname,$(1),$(2))-factory.bin" $(2) || \
		rm -f "$(call imgname,$(1),$(2))-factory.bin"; \
	fi
endef
BuildFirmware/Gemtek/initramfs=$(call BuildFirmware/OF/initramfs,$(1),$(2),$(3))

# Airlink101 AR670W -- LZMA without uImage header
define BuildFirmware/AR670W/squashfs
	$(call PatchKernelLzmaDtb,$(2),$(3),$(5))

	$(eval output_name=$(IMG_PREFIX)-$(2)-$(1)-$(if $(4),$(4),sysupgrade).bin)
	$(eval factory_name=$(IMG_PREFIX)-$(2)-$(1)-factory.bin)

	( dd if=$(KDIR)/vmlinux-$(2).bin.lzma bs=65536 \
		conv=sync; dd if=$(KDIR)/root.$(1) ) > $(KDIR)/$(output_name)

	$(call prepare_generic_squashfs,$(KDIR)/$(output_name))

	if [ `stat -c%s "$(KDIR)/$(output_name)"` \
		-gt $(ralink_default_fw_size_4M) ]; then \
		echo "Warning: $(KDIR)/$(output_name) is too big" >&2; \
	else \
		mkwrgimg -i $(KDIR)/$(output_name) \
			-d "/dev/mtdblock/2" \
			-s "wrgn16a_airlink_ar670w" \
			-o $(BIN_DIR)/$(factory_name); \
		$(CP) $(KDIR)/$(output_name) $(BIN_DIR)/$(output_name); \
	fi
endef

#
# RT288X Profiles
#

Image/Build/Profile/AR670W=$(call BuildFirmware/AR670W/$(1),$(1),ar670w,AR670W)

Image/Build/Profile/AR725W=$(call BuildFirmware/Gemtek/$(1),$(1),ar725w,AR725W)

# 0x790000
belkin_f5d8235v1_mtd_size=7929856
Image/Build/Profile/F5D8235V1=$(call BuildFirmware/CustomFlash/$(1),$(1),f5d8235v1,F5D8235_V1,$(belkin_f5d8235v1_mtd_size))

Image/Build/Profile/RTN15=$(call BuildFirmware/Default4M/$(1),$(1),rt-n15,RT-N15)

Image/Build/Profile/V11STFE=$(call BuildFirmware/Default4M/$(1),$(1),v11st-fe,V11STFE)

Image/Build/Profile/WLITX4AG300N=$(call BuildFirmware/Default4M/$(1),$(1),wli-tx4-ag300n,WLI-TX4-AG300N)

Image/Build/Profile/WZRAGL300NH=$(call BuildFirmware/Default4M/$(1),$(1),wzr-agl300nh,WZR-AGL300NH)

ifeq ($(SUBTARGET),rt288x)
define Image/Build/Profile/Default
	$(call Image/Build/Profile/AR670W,$(1))
	$(call Image/Build/Profile/AR725W,$(1))
	$(call Image/Build/Profile/F5D8235V1,$(1))
	$(call Image/Build/Profile/RTN15,$(1))
	$(call Image/Build/Profile/V11STFE,$(1))
	$(call Image/Build/Profile/WLITX4AG300N,$(1))
	$(call Image/Build/Profile/WZRAGL300NH,$(1))
endef
endif



#
# RT305X Profiles
#

ifeq ($(SUBTARGET),rt305x)
include rt305x.mk
endif



#
# RT3662/RT3883 Profiles
#

# $(1) = squashfs/initramfs
# $(2) = lowercase board name
# $(3) = dts file
# $(4) = kernel size
# $(5) = rootfs size
# $(6) = signature
# $(7) = model
# $(8) = flash address
# $(9) = start address
define BuildFirmware/EdimaxCombined/squashfs
	$(call PatchKernelLzmaDtb,$(2),$(3))
	$(call MkImage,lzma,$(KDIR)/vmlinux-$(2).bin.lzma,$(KDIR)/vmlinux-$(2).bin.uImage)
	if [ `stat -c%s "$(KDIR)/vmlinux-$(2).bin.uImage"` -gt `expr $(4) - 20` ]; then \
		echo "Warning: $(KDIR)/vmlinux-$(2).bin.uImage is too big" >&2; \
		exit 1; \
	else if [ `stat -c%s "$(KDIR)/root.$(1)"` -gt $(5) ]; then \
		echo "Warning: $(KDIR)/root.$(1) is too big" >&2; \
		exit 1; \
	else \
		( dd if=$(KDIR)/vmlinux-$(2).bin.uImage bs=`expr $(4) - 20` conv=sync ; dd if=$(KDIR)/root.$(1) ) > $(KDIR)/vmlinux-$(2).bin.uImage.combined ; \
	fi ; fi
	mkedimaximg -i "$(KDIR)/vmlinux-$(2).bin.uImage.combined" \
		-o $(call imgname,$(1),$(2)).bin \
		-s $(6) -m $(7) -f $(8) -S $(9)
endef

Image/Build/Profile/CYSWR1100=$(call BuildFirmware/Seama/$(1),$(1),cy-swr1100,CY-SWR1100,wrgnd10_samsung_ss815,$(ralink_default_fw_size_8M))

Image/Build/Profile/DIR645=$(call BuildFirmware/Seama/$(1),$(1),dir-645,DIR-645,wrgn39_dlob.hans_dir645,$(ralink_default_fw_size_8M))

omniembhpm_mtd_size=16449536
Image/Build/Profile/OMNIEMBHPM=$(call BuildFirmware/CustomFlash/$(1),$(1),omni-emb-hpm,OMNI-EMB-HPM,$(omniembhpm_mtd_size))

define BuildFirmware/RTN56U/squashfs
	$(call BuildFirmware/Default8M/$(1),$(1),rt-n56u,RTN56U)
	-mkrtn56uimg -s $(call sysupname,$(1),rt-n56u)
	-cp $(call sysupname,$(1),rt-n56u) $(call imgname,$(1),rt-n56u)-factory.bin
	-mkrtn56uimg -f $(call imgname,$(1),rt-n56u)-factory.bin
endef
Image/Build/Profile/RTN56U=$(call BuildFirmware/RTN56U/$(1),$(1),rt-n56u,RTN56U)

Image/Build/Profile/TEW691GR=$(call BuildFirmware/UMedia/$(1),$(1),tew-691gr,TEW-691GR,0x026910)

Image/Build/Profile/TEW692GR=$(call BuildFirmware/UMedia/$(1),$(1),tew-692gr,TEW-692GR,0x026920)

kernel_size_BR6475ND:=2097152
rootfs_size_BR6475ND:=5832704
Image/Build/Profile/BR6475ND=$(call BuildFirmware/EdimaxCombined/$(1),$(1),br-6475nd,BR-6475ND,$(kernel_size_BR6475ND),$(rootfs_size_BR6475ND),CSYS,RN54,0x70000,0x01100000)

ifeq ($(SUBTARGET),rt3883)
define Image/Build/Profile/Default
	$(call Image/Build/Profile/CYSWR1100,$(1))
	$(call Image/Build/Profile/DIR645,$(1))
	$(call Image/Build/Profile/OMNIEMBHPM,$(1))
	$(call Image/Build/Profile/RTN56U,$(1))
	$(call Image/Build/Profile/BR6475ND,$(1))
	$(call Image/Build/Profile/TEW691GR,$(1))
	$(call Image/Build/Profile/TEW692GR,$(1))
endef
endif

#
# MT7620A Profiles
#

# $(1): (ignored)
# $(2): lowercase board name
# $(3): uppercase board name (must match DTS filename w/o extension)
# $(4): erase block size
# $(5): hardware id for mkdniimg
# $(6): maximum image size
define BuildFirmware/Netgear/squashfs
	$(call PatchKernelLzmaDtb,$(2),$(3))
	# Pad kernel to eraseblock boundary, minus 2 uImage headers (=128 bytes):
	# bs = (eraseblock * (1 + (128 + kernelsize)/eraseblock)) - 128
	dd if=$(KDIR)/vmlinux-$(2).bin.lzma \
		of=$(KDIR)/vmlinux-$(2).bin.lzma.tmp \
		bs=`expr \( $(4) \* \( 1 + \( 128 + \`wc -c < $(KDIR)/vmlinux-$(2).bin.lzma\` \) / $(4) \) \) - 128` \
		count=1 conv=sync

	$(call MkImage,lzma,$(KDIR)/vmlinux-$(2).bin.lzma.tmp,$(KDIR)/vmlinux-$(2).uImage)
	cat ex2700-fakeroot.uImage >> $(KDIR)/vmlinux-$(2).uImage
	$(call MkImageSysupgrade/squashfs,squashfs,$(2),$(6))

	$(STAGING_DIR_HOST)/bin/mkdniimg \
		-B $(3) -H $(5) -v OpenWrt \
		-i $(call imgname,squashfs,$(2))-sysupgrade.bin \
		-o $(call imgname,squashfs,$(2))-factory.bin
endef

ifeq ($(SUBTARGET),mt7620)
include mt7620.mk
endif

#
# MT7621 Profiles
#

ifeq ($(SUBTARGET),mt7621)
include mt7621.mk
endif

#
# MT7621-nand Profiles
#

ifeq ($(SUBTARGET),mt7621-nand)
  TARGET_DEVICES +=
endif

define Device/hc5962
  DTS := HC5962
  BLOCKSIZE := 128KiB
  IMAGES := sysupgrade.bin
  PAGESIZE := 2048
  KERNEL_SIZE := 2097152
  FILESYSTEMS := squashfs
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(ralink_default_fw_size_32M)
endef
TARGET_DEVICES += hc5962

define Device/redmi-router-ac2100
  DTS := REDMI-ROUTER-AC2100
  BLOCKSIZE := 128KiB
  IMAGES := sysupgrade.bin
  PAGESIZE := 2048
  KERNEL_SIZE := 4096k
  IMAGE_SIZE := 124416k
  UBINIZE_OPTS := -E 5
  FILESYSTEMS := squashfs
  IMAGES += kernel1.bin rootfs0.bin
  IMAGE/kernel1.bin := append-kernel
  IMAGE/rootfs0.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := append-kernel | pad-to $$(KERNEL_SIZE) | append-ubi | check-size $$$$(IMAGE_SIZE)
endef
TARGET_DEVICES += redmi-router-ac2100

#
# MT7628 Profiles
#

ifeq ($(SUBTARGET),mt7628)
include mt7628.mk
endif

#
# MT7688 Profiles
#

ifeq ($(SUBTARGET),mt7688)
include mt7688.mk
endif

ifndef TARGET_DEVICES
#
# Generic Targets - only needed for legacy image building code
#
define Image/BuildKernel
	cp $(KDIR)/vmlinux.elf $(BIN_DIR)/$(VMLINUX).elf
	cp $(KDIR)/vmlinux $(BIN_DIR)/$(VMLINUX).bin
	$(call CompressLzma,$(KDIR)/vmlinux,$(KDIR)/vmlinux.bin.lzma)
	$(call MkImage,lzma,$(KDIR)/vmlinux.bin.lzma,$(KDIR)/uImage.lzma)
	cp $(KDIR)/uImage.lzma $(BIN_DIR)/$(UIMAGE).bin
endef

define Image/BuildKernel/Initramfs
	cp $(KDIR)/vmlinux-initramfs.elf $(BIN_DIR)/$(VMLINUX)-initramfs.elf
	cp $(KDIR)/vmlinux-initramfs $(BIN_DIR)/$(VMLINUX)-initramfs.bin
	$(call CompressLzma,$(KDIR)/vmlinux-initramfs,$(KDIR)/vmlinux-initramfs.bin.lzma)
	$(call MkImage,lzma,$(KDIR)/vmlinux-initramfs.bin.lzma,$(KDIR)/uImage-initramfs.lzma)
	cp $(KDIR)/uImage-initramfs.lzma $(BIN_DIR)/$(UIMAGE)-initramfs.bin
	$(call Image/Build/Initramfs)
endef

define Image/Build
	$(call Image/Build/$(1))
	dd if=$(KDIR)/root.$(1) of=$(BIN_DIR)/$(IMG_PREFIX)-root.$(1) bs=128k conv=sync
endef

define Image/Build/Profile
	$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS),$(call Image/Build/Profile/$(1),initramfs))
	$(call Image/Build/Profile/$(1),$(2))
endef
endif

ifeq ($(SUBTARGET),$(filter $(SUBTARGET),mt7621 mt7621-nand))
define Image/Prepare
#define Build/Compile
	rm -rf $(KDIR)/relocate
	$(CP) ../../generic/image/relocate $(KDIR)
	$(MAKE) -C $(KDIR)/relocate KERNEL_ADDR=$(KERNEL_LOADADDR) CROSS_COMPILE=$(TARGET_CROSS)
	$(CP) $(KDIR)/relocate/loader.bin $(KDIR)/loader.bin
endef
endif

$(eval $(call BuildImage))
