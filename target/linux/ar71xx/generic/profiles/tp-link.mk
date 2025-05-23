#
# Copyright (C) 2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

define Profile/ARCHERC7
	NAME:=TP-LINK Archer C5/C7
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev kmod-ath10k
endef

define Profile/ARCHERC7/Description
	Package set optimized for the TP-LINK Archer C5/C7.
endef
$(eval $(call Profile,ARCHERC7))


define Profile/CPE510
	NAME:=TP-LINK CPE210/220/510/520
	PACKAGES:=rssileds
endef

define Profile/CPE510/Description
	Package set optimized for the TP-LINK CPE210/220/510/520.
endef
$(eval $(call Profile,CPE510))


define Profile/baicells-cn6619
	NAME:=BaiCells CN6619
	PACKAGES:= kmod-mtd-rw panel-ap-setup kmod-usb-acm kmod-usb2 kmod-usb-ohci \
		kmod-usb-uhci kmod-usb-net kmod-usb-net-qmi-wwan kmod-usb-serial \
		kmod-usb-serial-option luci-proto-3g luci-proto-ncm rssileds
endef
define Profile/baicells-cn6619/Description
	Package set optimized for the BaiCells CN6619 LTE router.
endef
$(eval $(call Profile,baicells-cn6619))


define Profile/fap-022wld
	NAME:=PHICOMM FAP-022WLD
	PACKAGES:=panel-ap-setup
endef

define Profile/fap-022wld/Description
	Package set optimized for the PHICOMM FAP-022WLD Panel AP.
endef
$(eval $(call Profile,fap-022wld))


define Profile/ikuai-ap
	NAME:=iKuai Panel AP
	PACKAGES:=panel-ap-setup
endef

define Profile/ikuai-ap/Description
	Package set optimized for the ikuai Panel AP.
endef
$(eval $(call Profile,ikuai-ap))


define Profile/kisslink-nb1210
	NAME:=Keewifi Kisslink NB1210
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-mtd-rw panel-ap-setup kmod-i2c-gpio i2c-tools
endef
define Profile/kisslink-nb1210/Description
	Package set optimized for the Keewifi Kisslink NB1210 router.
endef
$(eval $(call Profile,kisslink-nb1210))


define Profile/kisslink-nb1210-i2s
	NAME:=Keewifi Kisslink NB1210 I2S
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-mtd-rw panel-ap-setup kmod-sound-ap123-ak4430
endef
define Profile/kisslink-nb1210-i2s/Description
	Package set optimized for the Keewifi Kisslink NB1210 router.
endef
$(eval $(call Profile,kisslink-nb1210-i2s))


define Profile/TLMR10U
	NAME:=TP-LINK TL-MR10U
	PACKAGES:=kmod-usb-core kmod-usb2
endef

define Profile/TLMR10U/Description
	Package set optimized for the TP-LINK TL-MR10U.
endef
$(eval $(call Profile,TLMR10U))


define Profile/TLMR11U
	NAME:=TP-LINK TL-MR11U
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR11U/Description
	Package set optimized for the TP-LINK TL-MR11U.
endef
$(eval $(call Profile,TLMR11U))

define Profile/TLMR12U
	NAME:=TP-LINK TL-MR12U
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR12U/Description
	Package set optimized for the TP-LINK TL-MR12U.
endef

$(eval $(call Profile,TLMR12U))

define Profile/TLMR13U
	NAME:=TP-LINK TL-MR13U
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR13U/Description
	Package set optimized for the TP-LINK TL-MR13U.
endef
$(eval $(call Profile,TLMR13U))


define Profile/TLMR3020
	NAME:=TP-LINK TL-MR3020
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR3020/Description
	Package set optimized for the TP-LINK TL-MR3020.
endef
$(eval $(call Profile,TLMR3020))


define Profile/TLMR3040
	NAME:=TP-LINK TL-MR3040
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR3040/Description
	Package set optimized for the TP-LINK TL-MR3040.
endef
$(eval $(call Profile,TLMR3040))


define Profile/TLMR3220
	NAME:=TP-LINK TL-MR3220
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR3220/Description
	Package set optimized for the TP-LINK TL-MR3220.
endef
$(eval $(call Profile,TLMR3220))


define Profile/TLMR3420
	NAME:=TP-LINK TL-MR3420
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLMR3420/Description
	Package set optimized for the TP-LINK TL-MR3420.
endef
$(eval $(call Profile,TLMR3420))


define Profile/TLWR703
	NAME:=TP-LINK TL-WR703N
	PACKAGES:=kmod-usb-core kmod-usb2
endef


define Profile/TLWR703/Description
	Package set optimized for the TP-LINK TL-WR703N.
endef
$(eval $(call Profile,TLWR703))


define Profile/TLWR710
	NAME:=TP-LINK TL-WR710N
	PACKAGES:=kmod-usb-core kmod-usb2
endef


define Profile/TLWR710/Description
	Package set optimized for the TP-LINK TL-WR710N.
endef
$(eval $(call Profile,TLWR710))


define Profile/TLWR720
	NAME:=TP-LINK TL-WR720N
	PACKAGES:=kmod-usb-core kmod-usb2
endef


define Profile/TLWR720/Description
	Package set optimized for the TP-LINK TL-WR720N.
endef
$(eval $(call Profile,TLWR720))


define Profile/TLWA701
	NAME:=TP-LINK TL-WA701N/ND
	PACKAGES:=
endef

define Profile/TLWA701/Description
	Package set optimized for the TP-LINK TL-WA701N/ND.
endef
$(eval $(call Profile,TLWA701))

define Profile/TLWA7210
        NAME:=TP-LINK TL-WA7210N
        PACKAGES:=rssileds kmod-ledtrig-netdev
endef

define Profile/TLWA7210/Description
        Package set optimized for the TP-LINK TL-WA7210N.
endef
$(eval $(call Profile,TLWA7210))

define Profile/TLWA730RE
	NAME:=TP-LINK TL-WA730RE
	PACKAGES:=
endef

define Profile/TLWA730RE/Description
	Package set optimized for the TP-LINK TL-WA730RE.
endef
$(eval $(call Profile,TLWA730RE))

define Profile/TLWA750
	NAME:=TP-LINK TL-WA750RE
	PACKAGES:=rssileds
endef

define Profile/TLWA750/Description
	Package set optimized for the TP-LINK TL-WA750RE.
endef
$(eval $(call Profile,TLWA750))


define Profile/TLWA7510
	NAME:=TP-LINK TL-WA7510N
	PACKAGES:=
endef

define Profile/TLWA7510/Description
	Package set optimized for the TP-LINK TL-WA7510N.
endef
$(eval $(call Profile,TLWA7510))

define Profile/TLWA801
	NAME:=TP-LINK TL-WA801N/ND
	PACKAGES:=
endef

define Profile/TLWA801/Description
	Package set optimized for the TP-LINK TL-WA801N/ND.
endef
$(eval $(call Profile,TLWA801))

define Profile/TLWA830
	NAME:=TP-LINK TL-WA830RE
	PACKAGES:=
endef

define Profile/TLWA830/Description
	Package set optimized for the TP-LINK TL-WA830RE.
endef
$(eval $(call Profile,TLWA830))


define Profile/TLWA850
	NAME:=TP-LINK TL-WA850RE
	PACKAGES:=rssileds
endef

define Profile/TLWA850/Description
	Package set optimized for the TP-LINK TL-WA850RE.
endef
$(eval $(call Profile,TLWA850))


define Profile/TLWA860
	NAME:=TP-LINK TL-WA860RE
	PACKAGES:=
endef

define Profile/TLWA860/Description
	Package set optimized for the TP-LINK TL-WA860RE.
endef
$(eval $(call Profile,TLWA860))


define Profile/TLWA901
	NAME:=TP-LINK TL-WA901N/ND
	PACKAGES:=
endef

define Profile/TLWA901/Description
	Package set optimized for the TP-LINK TL-WA901N/ND.
endef
$(eval $(call Profile,TLWA901))


define Profile/WB2000
	NAME:=WB2000
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev kmod-sound-ak4430
endef

define Profile/WB2000/Description
	Package set optimized for WB2000.
endef
$(eval $(call Profile,WB2000))


define Profile/TLWDR4300
	NAME:=TP-LINK TL-WDR3500/3600/4300/4310/MW4350R
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLWDR4300/Description
	Package set optimized for the TP-LINK TL-WDR3500/3600/4300/4310/MW4350R.
endef
$(eval $(call Profile,TLWDR4300))


define Profile/TLWDR4900V2
	NAME:=TP-LINK TL-WDR4900v2
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLWDR4900V2/Description
	Package set optimized for the TP-LINK TL-WDR4900v2.
endef
$(eval $(call Profile,TLWDR4900V2))


define Profile/TLWR740
	NAME:=TP-LINK TL-WR740N/ND
	PACKAGES:=
endef

define Profile/TLWR740/Description
	Package set optimized for the TP-LINK TL-WR740N/ND.
endef
$(eval $(call Profile,TLWR740))


define Profile/TLWR741
	NAME:=TP-LINK TL-WR741N/ND
	PACKAGES:=
endef

define Profile/TLWR741/Description
	Package set optimized for the TP-LINK TL-WR741N/ND.
endef
$(eval $(call Profile,TLWR741))


define Profile/MW153R
	NAME:=MERCURY MW153R
	PACKAGES:=
endef

define Profile/MW153R/Description
	Package set optimized for the MERCURY MW153R.
endef
$(eval $(call Profile,MW153R))


define Profile/TLWR743
	NAME:=TP-LINK TL-WR743N/ND
	PACKAGES:=
endef

define Profile/TLWR743/Description
	Package set optimized for the TP-LINK TL-WR743N/ND.
endef
$(eval $(call Profile,TLWR743))


define Profile/TLWR841
	NAME:=TP-LINK TL-WR841N/ND
	PACKAGES:=
endef

define Profile/TLWR841/Description
	Package set optimized for the TP-LINK TL-WR841N/ND.
endef
$(eval $(call Profile,TLWR841))


define Profile/PISEN
	NAME:=PISEN Cloud Router
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-sound-ak4430
endef

define Profile/PISEN/Description
	Package set optimized for the PISEN_WFR101N/PISEN_WMB001N/PISEN_WPR003N.
endef
$(eval $(call Profile,PISEN))


define Profile/PISEN-WMM003N
	NAME:=PISEN WMM003N
	PACKAGES:=kmod-usb-core kmod-usb2
endef

define Profile/PISEN-WMM003N/Description
	Package set optimized for the PISEN WMM003N.
endef
$(eval $(call Profile,PISEN-WMM003N))


define Profile/TLWR842
	NAME:=TP-LINK TL-WR842N/ND
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLWR842/Description
	Package set optimized for the TP-LINK TL-WR842N/ND.
endef
$(eval $(call Profile,TLWR842))


define Profile/TLWR843
	NAME:=TP-LINK TL-WR843N/ND
	PACKAGES:=
endef

define Profile/TLWR843/Description
	Package set optimized for the TP-LINK TL-WR843N/ND.
endef
$(eval $(call Profile,TLWR843))


define Profile/TLWR941
	NAME:=TP-LINK TL-WR941N/ND
	PACKAGES:=
endef

define Profile/TLWR941/Description
	Package set optimized for the TP-LINK TL-WR941N/ND.
endef
$(eval $(call Profile,TLWR941))


define Profile/TLWR1041
	NAME:=TP-LINK TL-WR1041N
	PACKAGES:=
endef

define Profile/TLWR1041/Description
	Package set optimized for the TP-LINK TL-WR1041N/ND.
endef
$(eval $(call Profile,TLWR1041))


define Profile/TLWR1043
	NAME:=TP-LINK TL-WR1043N/ND
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLWR1043/Description
	Package set optimized for the TP-LINK TL-WR1043N/ND.
endef
$(eval $(call Profile,TLWR1043))


define Profile/TLWR2543
	NAME:=TP-LINK TL-WR2543N/ND
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-ledtrig-usbdev
endef

define Profile/TLWR2543/Description
	Package set optimized for the TP-LINK TL-WR2543N/ND.
endef
$(eval $(call Profile,TLWR2543))
