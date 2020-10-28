include $(TOPDIR)/rules.mk

PKG_NAME:=ath10k-ct-firmware
PKG_VERSION:=2020-07-02
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

ATH10K_FIRMWARE_REV:=d622d160e9f552ead68d9ae81b715422892dc2ef
ATH10K_FIRMWARE_URL:=@GITHUB/kvalo/ath10k-firmware/$(ATH10K_FIRMWARE_REV)

QCA9887_BOARD_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca9887-board.bin
define Download/qca9887-board
  FILE:=$(QCA9887_BOARD_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA9887/hw1.0
  URL_FILE:=board.bin
  MD5SUM:=ebf3af10160c45373f19e0b8226b02ae
endef
$(eval $(call Download,qca9887-board))

QCA988X_BOARD_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca988x-board.bin
define Download/qca988x-board
  FILE:=$(QCA988X_BOARD_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA988X/hw2.0
  URL_FILE:=board.bin
  MD5SUM:=ab36ef267d15cfc02317ceeb38e8f548
endef
$(eval $(call Download,qca988x-board))

QCA99X0_BOARD_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca99x0-board.bin
define Download/qca99x0-board
  FILE:=$(QCA99X0_BOARD_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA99X0/hw2.0
  URL_FILE:=boardData_AR900B_CUS239_5G_v2_001.bin
  MD5SUM:=b6c3736b057c07da0584f43d90b1e04c
endef
$(eval $(call Download,qca99x0-board))

QCA99X0_BOARD2_REV:=ddcec9efd245da9365c474f513a855a55f3ac7fe
QCA99X0_BOARD2_FILE:=ath10k-firmware-$(QCA99X0_BOARD2_REV)-qca99x0-board-2.bin
define Download/qca99x0-board2
  FILE:=$(QCA99X0_BOARD2_FILE)
  URL:=https://source.codeaurora.org/quic/qsdk/oss/firmware/ath10k-firmware/plain/ath10k/QCA99X0/hw2.0
  URL_FILE:=board-2.bin?id=$(QCA99X0_BOARD2_REV)
  MD5SUM:=a2b3c653c2363a5641200051d6333d0a
endef
$(eval $(call Download,qca99x0-board2))

QCA9984_BOARD2_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca9984-board-2.bin
define Download/qca9984-board2
  FILE:=$(QCA9984_BOARD2_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA9984/hw1.0
  URL_FILE:=board-2.bin
  MD5SUM:=2e70c06eb8217c0bea05a4c7c888ca0f
endef
$(eval $(call Download,qca9984-board2))

QCA4019_BOARD2_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca4019-board-2.bin
define Download/qca4019-board2
  FILE:=$(QCA4019_BOARD2_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA4019/hw1.0
  URL_FILE:=board-2.bin
  MD5SUM:=93ee138ebf04fab3ea03a33b24e35f05
endef
$(eval $(call Download,qca4019-board2))

QCA9888_BOARD2_FILE:=ath10k-firmware-$(ATH10K_FIRMWARE_REV)-qca9888-board-2.bin
define Download/qca9888-board2
  FILE:=$(QCA9888_BOARD2_FILE)
  URL:=$(ATH10K_FIRMWARE_URL)/QCA9888/hw2.0
  URL_FILE:=board-2.bin
  MD5SUM:=cd62d0656a0ab3526cb86f13bf54757a
endef
$(eval $(call Download,qca9888-board2))

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

QCA988X_FIRMWARE_FILE_CT:=firmware-2-ct-full-community-22.bin.lede.019
define Download/ath10k-firmware-qca988x-ct
  $(call Download/ct-firmware,QCA988X,)
  MD5SUM:=f0c4ffe048c46afd514ac2a58202e4d6
endef
$(eval $(call Download,ath10k-firmware-qca988x-ct))

QCA988X_FIRMWARE_FILE_CT_FULL_HTT:=firmware-2-ct-full-htt-mgt-community-22.bin.lede.019
define Download/ath10k-firmware-qca988x-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA988X,)
  MD5SUM:=90127f92fbd7ccd543e0aa2f9b457c79
endef
$(eval $(call Download,ath10k-firmware-qca988x-ct-full-htt))


QCA9887_FIRMWARE_FILE_CT:=firmware-2-ct-full-community-22.bin.lede.019
define Download/ath10k-firmware-qca9887-ct
  $(call Download/ct-firmware,QCA9887,ath10k-9887)
  MD5SUM:=f47695a8e82b8e1f836d5ab7668e78b9
endef
$(eval $(call Download,ath10k-firmware-qca9887-ct))

QCA9887_FIRMWARE_FILE_CT_FULL_HTT:=firmware-2-ct-full-htt-mgt-community-22.bin.lede.019
define Download/ath10k-firmware-qca9887-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9887,ath10k-9887)
  MD5SUM:=8470257f438ba7a8b96023c1f1b42590
endef
$(eval $(call Download,ath10k-firmware-qca9887-ct-full-htt))


QCA99X0_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.019
define Download/ath10k-firmware-qca99x0-ct
  $(call Download/ct-firmware,QCA99X0,ath10k-10-4b)
  MD5SUM:=f81acea3802f912530bac53cc3b0c096
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct))

QCA99X0_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca99x0-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA99X0,ath10k-10-4b)
  MD5SUM:=54b8e7c2292d10559d5efaad46211482
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct-full-htt))

QCA99X0_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca99x0-ct-htt
  $(call Download/ct-firmware-htt,QCA99X0,ath10k-10-4b)
  MD5SUM:=65b363973916c0f8ed83e39b96259bc5
endef
$(eval $(call Download,ath10k-firmware-qca99x0-ct-htt))


QCA9984_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.019
define Download/ath10k-firmware-qca9984-ct
  $(call Download/ct-firmware,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=31b44734ac41b94ef14af02c4f1ce8ec
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct))

QCA9984_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca9984-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=8b8847ffb0083976969a5a13389a66ed
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct-full-htt))

QCA9984_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca9984-ct-htt
  $(call Download/ct-firmware-htt,QCA9984,ath10k-9984-10-4b)
  MD5SUM:=0b53462a4b2d59f699035c65bd8a3601
endef
$(eval $(call Download,ath10k-firmware-qca9984-ct-htt))


QCA4019_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.019
define Download/ath10k-firmware-qca4019-ct
  $(call Download/ct-firmware,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=afadeec98b358685fa603dc78c2722a8
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct))

QCA4019_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca4019-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=8444f17eab53485eff881711ca64ed1e
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct-full-htt))

QCA4019_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca4019-ct-htt
  $(call Download/ct-firmware-htt,QCA4019,ath10k-4019-10-4b)
  MD5SUM:=13b6a9de406fdd79627ec483a28cda52
endef
$(eval $(call Download,ath10k-firmware-qca4019-ct-htt))


QCA9888_FIRMWARE_FILE_CT:=firmware-5-ct-full-community-12.bin-lede.019
define Download/ath10k-firmware-qca9888-ct
  $(call Download/ct-firmware,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=333a104f5ba1189371bea77d43df4b56
endef
$(eval $(call Download,ath10k-firmware-qca9888-ct))

QCA9888_FIRMWARE_FILE_CT_FULL_HTT:=firmware-5-ct-full-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca9888-ct-full-htt
  $(call Download/ct-firmware-full-htt,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=2f326293e4d23d1f44e108131aeb1749
endef
$(eval $(call Download,ath10k-firmware-qca9888-ct-full-htt))

QCA9888_FIRMWARE_FILE_CT_HTT:=firmware-5-ct-htt-mgt-community-12.bin-lede.019
define Download/ath10k-firmware-qca9888-ct-htt
  $(call Download/ct-firmware-htt,QCA9888,ath10k-9888-10-4b)
  MD5SUM:=5b5e861e5e41e62dceb2107feecc9536
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
endef
define Package/ath10k-firmware-qca988x-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 full-htt-mgt fw for QCA988x
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca988x
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9887-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 firmware for QCA9887 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9887
endef
define Package/ath10k-firmware-qca9887-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.1 full-htt-mgt fw for QCA9887
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9887
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca99x0-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA99x0 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca99x0
endef
define Package/ath10k-firmware-qca99x0-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA99x0
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca99x0
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca99x0-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA99x0
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca99x0
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9984-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA9984 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9984
endef
define Package/ath10k-firmware-qca9984-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA9984
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9984
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca9984-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA9984
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9984
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca4019-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 firmware for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca4019
endef
define Package/ath10k-firmware-qca4019-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca4019
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca4019-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt for QCA4018/9
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca4019
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef

define Package/ath10k-firmware-qca9888-ct
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 fw for QCA9886/8 devices
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9888
endef
define Package/ath10k-firmware-qca9888-ct-full-htt
$(Package/ath10k-ct-firmware-default)
  TITLE:=ath10k CT 10.4 full-htt-mgt fw for QCA9886/8
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9888
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
endef
define Package/ath10k-firmware-qca9888-ct-htt
$(Package/ath10k-firmware-default)
  TITLE:=ath10k CT 10.4 htt-mgt fw for QCA9886/8
  SECTION:=firmware
  CATEGORY:=Firmware
  PROVIDES:=ath10k-firmware-qca9888
  DEPENDS:=+!PACKAGE_kmod-ath10k-ct-smallbuffers:kmod-ath10k-ct
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
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA9887_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA9887/hw1.0/board.bin
endef
define Package/ath10k-firmware-qca9887-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9887/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA9887) \
		$(1)/lib/firmware/ath10k/QCA9887/hw1.0/ct-firmware-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA9887_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA9887/hw1.0/board.bin
endef

define Package/ath10k-firmware-qca988x-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA988X/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA988X_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA988X) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/firmware-2.bin
endef
define Package/ath10k-firmware-qca988x-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA988X/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA988X_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA988X) \
		$(1)/lib/firmware/ath10k/QCA988X/hw2.0/ct-firmware-2.bin
endef

define Package/ath10k-firmware-qca99x0-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca99x0-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca99x0-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA99X0/hw2.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA99X0_BOARD_FILE) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/board.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA99X0) \
		$(1)/lib/firmware/ath10k/QCA99X0/hw2.0/ct-firmware-5.bin
endef

define Package/ath10k-firmware-qca9984-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA9984_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca9984-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA9984_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca9984-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA9984/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA9984_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_HTT,QCA9984) \
		$(1)/lib/firmware/ath10k/QCA9984/hw1.0/ct-firmware-5.bin
endef

define Package/ath10k-firmware-qca4019-ct/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA4019_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE,QCA4019) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/firmware-5.bin
endef
define Package/ath10k-firmware-qca4019-ct-full-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA4019_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin
	$(INSTALL_DATA) \
		$(DL_DIR)/$(call CT_FIRMWARE_FILE_FULL_HTT,QCA4019) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/ct-firmware-5.bin
endef
define Package/ath10k-firmware-qca4019-ct-htt/install
	$(INSTALL_DIR) $(1)/lib/firmware/ath10k/QCA4019/hw1.0
	$(INSTALL_DATA) \
		$(DL_DIR)/$(QCA4019_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA4019/hw1.0/board-2.bin
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
		$(DL_DIR)/$(QCA9888_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board-2.bin
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
		$(DL_DIR)/$(QCA9888_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board-2.bin
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
		$(DL_DIR)/$(QCA9888_BOARD2_FILE) \
		$(1)/lib/firmware/ath10k/QCA9888/hw2.0/board-2.bin
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
