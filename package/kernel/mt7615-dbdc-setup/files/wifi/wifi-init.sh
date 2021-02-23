#!/bin/sh

wifi_setup_radio()
{
	if test -e /sys/kernel/debug/ieee80211/phy0/mt76/dbdc &&
	   [ "$(readlink /sys/class/ieee80211/phy0/device)" = "$(readlink /sys/class/ieee80211/phy1/device)" ]; then
		cp /lib/wifi/mt7615dbdc.conf /etc/config/wireless
		getphy0mac=$(cat /sys/class/ieee80211/phy0/macaddress)
		getphy1mac=$(cat /sys/class/ieee80211/phy1/macaddress)
		uci set wireless.radio0.macaddr=$getphy0mac
		uci set wireless.radio1.macaddr=$getphy1mac
		sed -i 's/START=60/START=70/' /etc/init.d/wifistart
		sed -i 's/\/sbin\/wifi/sleep\ 10\n\t\/sbin\/wifi/' /etc/init.d/wifistart
	fi
}

wifi_first_init()
{
	wifi_setup_radio
	uci commit wireless
}
