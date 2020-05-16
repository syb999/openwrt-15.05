# openwrt 18 gstreamer1.x gmediarender upnp player
source by https://github.com/hzeller/gmrender-resurrect

## REQUIRE
	Libraries --->
	<*> libupnp

	Sound ---> 
	<*> alsa-utils
	<*> madplay-alsa
	-*- mpg123

	Multimedia --->
	gst1-libav
	gstreamer1-libs
	gstreamer1-plugins-base
	gstreamer1-plugins-good
	gstreamer1-plugins-ugly
	gstreamer1-utils

	Kernel modules --->

	Sound Support --->
	kmod-usb-audio

	USB Support --->
	kmod-usb-ohci
	kmod-usb-storage
	kmod-usb-storage-extras
	kmod-usb-uhci

	Native Language Support --->
	kmod-nls-utf8

### Build Package
	cd openwrt/package
	git clone https://github.com/nejidev/gmrender-resurrect-openwrt18.git
	make menuconfig 
	select module
	Multimedia  --->
		gmediarender
	make -j1 V=99

## TO DO

opkg install gmediarender_0.0.7-1_mipsel_24kc.ipk
Test gmediarender or gmediarender --logfile=/dev/stdout
