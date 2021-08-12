#!/bin/sh

wifi_setup_radio()
{
	if test -e /sys/kernel/debug/ieee80211/phy0/mt76/dbdc &&
	   [ "$(readlink /sys/class/ieee80211/phy0/device)" = "$(readlink /sys/class/ieee80211/phy1/device)" ]; then
		cp /lib/wifi/mt7615dbdc.conf /etc/config/wireless
	fi
}

wifi_first_init()
{
	wifi_setup_radio
	uci commit wireless
	sleep 5
	/sbin/wifi
}
