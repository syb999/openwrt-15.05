#!/bin/sh
. /usr/share/led-button/wps_func.sh

#echo "~$wds_if~$band~ wps setting" > /dev/ttyS0
wds_if=$1
band=$2
cnt=0

#error_exit shall clean sfi, flags, firewall and network.
error_exit() {
	[ -f /tmp/wps_status ] && rm /tmp/wps_status
	uci_delete_wireless_iface "sfi0"
	uci_delete_wireless_iface "sfi1"
	uci commit
	output=`wifi reload`
	exit 1
}

#TODO need to recode func prepare_config.
prepare_config() {
	#echo "~$wds_if~$band~ prepare_config" > /dev/ttyS0
	local check_time=0
	local n1="false"
	local data
	while [ -n "$n1" -a "$check_time" -lt 30 ]
	do
		data=`iwinfo $wds_if info`
		chan=`echo "$data" | grep Chan|awk -F ' ' '{print $4}'`
		ssid=`echo "$data" | grep ESSID|awk -F '"' '{print $2}'`
		n1=`echo "$chan" | sed 's/[0-9]//g'`
		sleep 1
		let "check_time ++"
	done

	[ "$check_time" -lt 30 ] || error_exit

	#TODO maybe we can use jshn to parse the conf and then we can get these params easily.
	data=`cat  /var/run/wpa_supplicant-$wds_if.conf`
	psk=$(echo "$data" | grep "$ssid" -A5 | grep psk | tail -1 | awk -F '"' '{print $2}')
	encription=$(echo "$data" | grep "$ssid" -A5 | grep key_mgmt | tail -1 | awk -F '=' '{print $2}')
	proto=$(echo "$data" | grep "$ssid" -A5 | grep proto | tail -1 | awk -F '=' '{print $2}')
	case "$encription" in
		NONE)
			enc="open"
			psk=''
			;;
		*PSK*)
			enc="psk2+ccmp"
			[ "$proto" = "WPA" ] && enc="psk+ccmp"
			;;
		*)
			enc="open"
			psk=''
			;;
	esac
}

set_wds() {
	#uci delete sfi node that we don't use.(to support wds 5g)
	case "$wds_if" in
		*0)
			uci_delete_wireless_iface "sfi1"
			;;
		*1)
			uci_delete_wireless_iface "sfi0"
			;;
	esac

	uci_set_wireless_iface "$wds_if" "$ssid" "$enc" "$psk"

	#if we need to sync config file, we can set wireless here
	#uci_set_wireless "wlan0" "$ssid-24" "$enc" "$psk"
	#uci_set_wireless "wlan1" "$ssid-5" "$enc" "$psk"

	#set firewall
	[ -f /etc/config/firewall ] && {
		uci -q set firewall.@zone[0].forward='ACCEPT'
		uci -q set firewall.@zone[0].network='lan wwan'
	}

	#uci set network maybecancel cause it will be reset in wpa_cli_event.sh
	uci -q set network.wan.disabled='1'
	uci -q set dhcp.lan.ignore='1'

	uci_set_network "$wds_if"

	uci commit
	output=`/etc/init.d/relayd enable`
	#wifi reload
	#rm now then we don't need to reset led.
	[ -f /tmp/wps_status ] && rm /tmp/wps_status
	output=`/etc/init.d/network restart`
	#echo "~wps~done~" > /dev/ttyS0
	exit 0
}

prepare_config
set_wds
