define Profile/ZMWR2500
	NAME:=ZMTEL ZM-WR2500 (CN6619)
	PACKAGES:=kmod-usb-core kmod-usb2 kmod-usb-acm \
		kmod-usb-net kmod-usb-net-cdc-ether \
		kmod-gpio-button-hotplug kmod-mtd-rw \
		panel-ap-setup kmod-slic-cn6619 fvphone-cn6619
endef

define Profile/ZMWR2500/Description
	Package set for the ZMTEL ZM-WR2500 4G LTE CPE (CN6619).
	SoC AR9341, 16MB flash (uboot_mod bootloader), USB 4G modem kept
	as hardware only (Sequans, 3.4-3.8GHz - not usable in CN, no SIM;
	cdc_ether/cdc_acm drivers retained, no dial/SMS tooling).
	TEL (Si3217x SLIC) VoIP port. LuCI via menuconfig; panel-ap-setup
	opens SSH on the single WAN port.
endef
$(eval $(call Profile,ZMWR2500))
