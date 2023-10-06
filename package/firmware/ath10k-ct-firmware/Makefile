include $(TOPDIR)/rules.mk

PKG_NAME:=ath10k-ct-firmware
PKG_VERSION:=2020-11-08
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

CT_FIRMWARE_FILE = $(1)-$($(1)_FIRMWARE_FILE_CT)
CT_FIRMWARE_FILE_FULL_HTT = $(1)-$($(1)_FIRMWARE_FILE_CT_FULL_HTT)
CT_FIRMWARE_FILE_HTT = $(1)-$($(1)_FIRMWARE_FILE_CT_HTT)

define Download/ct-firmware
  URL:=https://www.candelatech.com/downloads/$(2)
  FILE:=$(call CT_FIRMWARE_FILE,$(1))
  URL_FILE:=$($(1)_FIRMWARE_FILE_CT)
endef

define Download/ct-firmware-full-htt
  URL:=https://www.candelatech.com/downloads/$(2)
  FILE:=$(call CT_FIRMWARE_FILE_FULL_HTT,$(1))
  URL_FILE:=$($(1)_FIRMWARE_FILE_CT_FULL_HTT)
endef

define Download/ct-firmware-htt
  URL:=https://www.candelatech.com/downloads/$(2)
  FILE:=$(call CT_FIRMWARE_FILE_HTT,$(1))
  URL_FILE:=$($(1)_FIRMWARE_FILE_CT_HTT)
endef

QCA988X_FIRMWARE_FILE_CT:=firmware-2-ct-full-community-22.bin.lede.022
define Download/ath10k-firmware-qca988x-ct
  $(call Download/ct-firmware,QCA988X,)
  MD5SUM:=3466a8f5e2edf8f737ce82d5aba71bd1
endef
$(eval $(call Download,ath10k-firmware-qca988x-ct))

QCA988X_FIRMWARE_FILE_CT_FULL_HTT:=firmware-2-ct-full-htt-mgt-community-22.bin.lede.022
define Download/ath10k-firmware-qca988x-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA988X,)
  MD5SUM:=d4d1793dbebf091af59a5b814e091177
endef
$(eval $(call Download,ath10k-firmware-qca988x-ct-full-htt))


QCA9887_FIRMWARE_FILE_CT:=firmware-2-ct-full-community-22.bin.lede.022
define Download/ath10k-firmware-qca9887-ct
  $(call Download/ct-firmware,QCA9887,ath10k-9887)
  MD5SUM:=2eea235880623054e41f29f92018aa5d
endef
$(eval $(call Download,ath10k-firmware-qca9887-ct))

QCA9887_FIRMWARE_FILE_CT_FULL_HTT:=firmware-2-ct-full-htt-mgt-community-22.bin.lede.022
define Download/ath10k-firmware-qca9887-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9887,ath10k-9887)
  MD5SUM:=040b8f47961f082c31b79432251934c0
endef
$(eval $(call Download,ath10k-firmware-qca9887-ct-full-htt))


QCA99X0_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.022
define Download/ath10k-firmware-qca99x0-ct
  $(call Download/ct-firmware,QCA99X0,ath10k-10-4b)
  MD5SUM:=03fc283178729692c2c15499971cce9a
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct))

QCA99X0_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca99x0-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA99X0,ath10k-10-4b)
  MD5SUM:=4fcb56a4e4d3c499e1a43302c599d7ab
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct-full-htt))

QCA99X0_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca99x0-ct-htt
  $(call Download/ct-firmware-htt,QCA99X0,ath10k-10-4b)
  MD5SUM:=c61e5a9ffcded858faac2c90e1e4c5e0
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct-htt))


QCA9984_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.022
define Download/ath10k-firmware-qca9984-ct
  $(call Download/ct-firmware,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=42b1615b8a8b8b3aae3ba777961a4993
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct))

QCA9984_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca9984-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=370bd5f7f046459002730661dd897bce
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct-full-htt))

QCA9984_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca9984-ct-htt
  $(call Download/ct-firmware-htt,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=ad19706d0c34e57fab55481d12358c47
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct-htt))


QCA4019_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.022
define Download/ath10k-firmware-qca4019-ct
  $(call Download/ct-firmware,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=5dfb3152796b275349f92684240d9ab4
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct))

QCA4019_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca4019-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=ba01248df2b9e2acba5b4c572d108475
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct-full-htt))

QCA4019_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca4019-ct-htt
  $(call Download/ct-firmware-htt,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=f5d90d64a650ab2843261a41a55fa74a
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct-htt))


QCA9888_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.022
define Download/ath10k-firmware-qca9888-ct
  $(call Download/ct-firmware,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=7851c7074c720502070b4a1fd7956fd6
endef
$(eval $(call Download,ath10k-firmware-qca9888-ct))

QCA9888_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca9888-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=c6e047cf64128ac3ba7e48cc0d75f058
endef
$(eval $(call Download,ath10k-firmware-qca9888-ct-full-htt))

QCA9888_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.022
define Download/ath10k-firmware-qca9888-ct-htt
  $(call Download/ct-firmware-htt,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=47a5cf21e8cfc6a01a079b0a39c34040
endef
$(eval $(call Download,ath10k-firmware-qca9888-ct-htt))


define Package/ath10k-ct-firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=https://www.candelatech.com/ath10k.php
  DEPENDS:=
endef

define Package/ath10k-firmware-qca988x-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 firmware for QCA988x devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca988x
  CONFLICTS:=ath10k-firmware-qca988x
  DEPENDS:=+ath10k-board-qca988x
endef
define Package/ath10k-firmware-qca988x-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 full-htt-mgt fw for QCA988x
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca988x \
    ath10k-firmware-qca988x-ct
  CONFLICTS:=\
    ath10k-firmware-qca988x \
    ath10k-firmware-qca988x-ct
  DEPENDS:=\
    +ath10k-board-qca988x \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9887-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 firmware for QCA9887 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9887
  CONFLICTS:=ath10k-firmware-qca9887
  DEPENDS:=+ath10k-board-qca9887
endef
define Package/ath10k-firmware-qca9887-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 full-htt-mgt fw for QCA9887
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca9887 \
    ath10k-firmware-qca9887-ct
  CONFLICTS:=\
    ath10k-firmware-qca9887 \
    ath10k-firmware-qca9887-ct
  DEPENDS:=\
    +ath10k-board-qca9887 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca99x0-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA99x0 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca99x0
  CONFLICTS:=ath10k-firmware-qca99x0
  DEPENDS:=+ath10k-board-qca99x0
endef
define Package/ath10k-firmware-qca99x0-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA99x0
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca99x0 \
    ath10k-firmware-qca99x0-ct
  CONFLICTS:=\
    ath10k-firmware-qca99x0 \
    ath10k-firmware-qca99x0-ct \
    ath10k-firmware-qca99x0-ct-htt
  DEPENDS:=\
    +ath10k-board-qca99x0 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca99x0-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA99x0
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca99x0 \
    ath10k-firmware-qca99x0-ct
  CONFLICTS:=\
    ath10k-firmware-qca99x0 \
    ath10k-firmware-qca99x0-ct
  DEPENDS:=\
    +ath10k-board-qca99x0 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9984-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA9984 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9984
  CONFLICTS:=ath10k-firmware-qca9984
  DEPENDS:=+ath10k-board-qca9984
endef
define Package/ath10k-firmware-qca9984-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA9984
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca9984 \
    ath10k-firmware-qca9984-ct
  CONFLICTS:=\
    ath10k-firmware-qca9984 \
    ath10k-firmware-qca9984-ct \
    ath10k-firmware-qca9984-ct-htt
  DEPENDS:=\
    +ath10k-board-qca9984 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca9984-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA9984
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca9984 \
    ath10k-firmware-qca9984-ct
  CONFLICTS:=\
    ath10k-firmware-qca9984 \
    ath10k-firmware-qca9984-ct
  DEPENDS:=\
    +ath10k-board-qca9984 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca4019-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca4019
  CONFLICTS:=ath10k-firmware-qca4019
  DEPENDS:=+ath10k-board-qca4019
endef
define Package/ath10k-firmware-qca4019-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca4019 \
    ath10k-firmware-qca4019-ct
  CONFLICTS:=\
    ath10k-firmware-qca4019 \
    ath10k-firmware-qca4019-ct \
    ath10k-firmware-qca4019-ct-htt
  DEPENDS:=\
    +ath10k-board-qca4019 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca4019-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca4019 \
    ath10k-firmware-qca4019-ct
  CONFLICTS:=\
    ath10k-firmware-qca4019 \
    ath10k-firmware-qca4019-ct
  DEPENDS:=\
    +ath10k-board-qca4019 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9888-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 fw for QCA9886/8 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9888
  CONFLICTS:=ath10k-firmware-qca9888
  DEPENDS:=+ath10k-board-qca9888
endef
define Package/ath10k-firmware-qca9888-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA9886/8
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca9888 \
    ath10k-firmware-qca9888-ct
  CONFLICTS:=\
    ath10k-firmware-qca9888 \
    ath10k-firmware-qca9888-ct \
    ath10k-firmware-qca9888-ct-htt
  DEPENDS:=\
    +ath10k-board-qca9888 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca9888-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA9886/8
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=\
    ath10k-firmware-qca9888 \
    ath10k-firmware-qca9888-ct
  CONFLICTS:=\
    ath10k-firmware-qca9888 \
    ath10k-firmware-qca9888-ct
  DEPENDS:=\
    +ath10k-board-qca9888 \
    +!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef


define Package/ath10k-firmware-qca9887-ct/description
Alternative ath10k firmware for QCA9887 from Candela Technologies.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.1.php
This firmware conflicts with the standard 9887 firmware, so select only
one.
endef
define Package/ath10k-firmware-qca9887-ct-full-htt/description
Alternative ath10k firmware for QCA9887 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and fixes .11r authentication.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.1.php
This firmware selects and requires the ath10k-ct driver.
endef

define Package/ath10k-firmware-qca988x-ct/description
Alternative ath10k firmware for QCA988X from Candela Technologies.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.1.php
This firmware will NOT be used unless the standard ath10k-firmware-qca988x
is un-selected since the driver will try to load firmware-5.bin before
firmware-2.bin
endef
define Package/ath10k-firmware-qca988x-ct-full-htt/description
Alternative ath10k firmware for QCA988X from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and fixes .11r authentication.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.1.php
This firmware selects and requires the ath10k-ct driver.
endef

define Package/ath10k-firmware-qca99x0-ct/description
Alternative ath10k firmware for QCA99x0 from Candela Technologies.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware conflicts with the standard 99x0 firmware, so select only
one.
endef
define Package/ath10k-firmware-qca99x0-ct-full-htt/description
Alternative ath10k firmware for QCA99x0 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef
define Package/ath10k-firmware-qca99x0-ct-htt/description
Alternative ath10k firmware for QCA99x0 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
This firmware lacks a lot of features that ath10k does not use, saving
a lot of resources.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef

define Package/ath10k-firmware-qca9984-ct/description
Alternative ath10k firmware for QCA9984 from Candela Technologies.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware conflicts with the standard 9984 firmware, so select only
one.
endef
define Package/ath10k-firmware-qca9984-ct-full-htt/description
Alternative ath10k firmware for QCA9984 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef
define Package/ath10k-firmware-qca9984-ct-htt/description
Alternative ath10k firmware for QCA9984 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
This firmware lacks a lot of features that ath10k does not use, saving
a lot of resources.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef

define Package/ath10k-firmware-qca4019-ct/description
Alternative ath10k firmware for IPQ4019 radio from Candela Technologies.
Enables IBSS and other features.  Works with standard or ath10k-ct driver.
See:  http://www.candelatech.com/ath10k-10.4.php
endef
define Package/ath10k-firmware-qca4019-ct-full-htt/description
Alternative ath10k firmware for IPQ4019 radio from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
Enables IBSS and other features.
See:  http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef
define Package/ath10k-firmware-qca4019-ct-htt/description
Alternative ath10k firmware for IPQ4019 radio from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
This firmware lacks a lot of features that ath10k does not use, saving
a lot of resources.
Enables IBSS and other features.
See:  http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef

define Package/ath10k-firmware-qca9888-ct/description
Alternative ath10k firmware for QCA9886 and QCA9888 from Candela Technologies.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware conflicts with the standard 9886 and 9888 firmware, so select only
one.
endef
define Package/ath10k-firmware-qca9888-ct-full-htt/description
Alternative ath10k firmware for QCA9886 and QCA9888 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef
define Package/ath10k-firmware-qca9888-ct-htt/description
Alternative ath10k firmware for QCA9886 and QCA9888 from Candela Technologies.
Uses normal HTT TX data path for management frames, which improves
stability in busy networks and may be required for .11r authentication.
This firmware lacks a lot of features that ath10k does not use, saving
a lot of resources.
Enables IBSS and other features.  See:
http://www.candelatech.com/ath10k-10.4.php
This firmware selects and requires the ath10k-ct driver.
endef


define Build/Compile

endef


define Package/ath10k-firmware-qca9887-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9887/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA9887) \
		$(1)/lib/firmware/ath10k/QCA9887/hw1.0/firmware-2.bin
endef
define Package/ath10k-firmware-qca9887-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9887/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA9887) \
		$(1)/lib/firmware/ath10k/QCA9887/hw1.0/ct-firmware-2.bin
endef

define Package/ath10k-firmware-qca988x-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA988X/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA988X) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/firmware-2.bin
endef
define Package/ath10k-firmware-qca988x-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA988X/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA988X) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/ct-firmware-2.bin
endef

define Package/ath10k-firmware-qca99x0-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca99x0-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca99x0-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/ct-firmware-5.bin
endef

define Package/ath10k-firmware-qca9984-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca9984-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca9984-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/ct-firmware-5.bin
endef

define Package/ath10k-firmware-qca4019-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA4019) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca4019-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA4019) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca4019-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA4019) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/ct-firmware-5.bin
endef

define Package/ath10k-firmware-qca9888-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9888/hw2.0
	ln -s \
		../../cal-pci-0000:01:00.0.bin \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA9888) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca9888-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9888/hw2.0
	ln -s \
		../../cal-pci-0000:01:00.0.bin \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA9888) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca9888-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9888/hw2.0
	ln -s \
		../../cal-pci-0000:01:00.0.bin \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA9888) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/ct-firmware-5.bin
endef


$(eval $(call BuildPackage,ath10k-firmware-qca9887-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca9887-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca988x-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca988x-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca99x0-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca99x0-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca99x0-ct-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca9984-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca9984-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca9984-ct-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca4019-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca4019-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca4019-ct-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca9888-ct))
$(eval $(call BuildPackage,ath10k-firmware-qca9888-ct-full-htt))
$(eval $(call BuildPackage,ath10k-firmware-qca9888-ct-htt))
