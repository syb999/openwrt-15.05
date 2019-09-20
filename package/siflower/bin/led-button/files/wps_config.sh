#!/bin/sh
echo "~$wds_if~$band~ wps setting" > /dev/ttyS0
wds_if=$1
band=$2
cnt=0

#FIXME error_exit shall clean sfi, flags, firewall and network.
error_exit() {
	[ -f /tmp/wps_status  ] && rm /tmp/wps_status
	uci_get_iface_number "sfi0"
	[ "$cnt" = "null" ] || uci_delete_iface $cnt
	uci_get_iface_number "sfi1"
	[ "$cnt" = "null" ] || uci_delete_iface $cnt
	output=`wifi reload`
	exit 1
}

prepare_config() {
	echo "~$wds_if~$band~ prepare_config" > /dev/ttyS0
	local check_time=0
	#wps only support 2.4g / sfi0
	local n1="false"
	while [ -n $n1 -a $check_time -lt 30  ]
	do
		chan=`iwinfo $wds_if info | grep Chan|awk -F ' ' '{print $4}'`
		ssid=`iwinfo $wds_if info | grep ESSID|awk -F '"' '{print $2}'`
		n1=`echo $chan | sed 's/[0-9]//g'`
		sleep 1
		let "check_time ++"
	done

	[ $check_time -lt 30 ] || error_exit

	#TODO maybe we can use jshn to parse the conf and then we can get these params easily.
	#ssid=`iwinfo $wds_if info | grep ESSID|awk -F '"' '{print $2}'`
	psk=$(cat  /var/run/wpa_supplicant-$wds_if.conf | grep "$ssid" -A5 |grep psk | awk -F '"' '{print $2}')
	encription=$(cat  /var/run/wpa_supplicant-$wds_if.conf | grep "$ssid" -A5 |grep key_mgmt | awk -F '=' '{print $2}')
	proto=$(cat  /var/run/wpa_supplicant-$wds_if.conf | grep "$ssid" -A5 |grep proto | awk -F '=' '{print $2}')
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

#parse to get the number of iface by ifname.
uci_get_iface_number() {
	local name
	cnt=0
	name=`uci get wireless.@wifi-iface[$cnt].ifname`
	[ "$name" = "$1" ] || {
		until [ "$name" = "$1" -o $cnt -gt 8 ]
		do
			let "cnt++"
			name=`uci get wireless.@wifi-iface[$cnt].ifname`
		done
	}

	[ $cnt -gt 8 ] && {
		#TODO maybe we can number all kinds of error in a single func.
		echo "ERROR: could not find the iface."
		cnt="null"
	}
}

#FIXME set sta iface based on ifname. but we have set these conf in wds.sh yet.
uci_set_sfi() {
	local device
	uci_get_iface_number $1
	[ "$cnt" = "null" ] && error_exit
	case "$1" in
		*0)
			device="radio0"
			;;
		*1)
			device="radio1"
			;;
	esac
	uci batch << EOF
set wireless.@wifi-iface[$cnt]=wifi-iface
set wireless.@wifi-iface[$cnt].device='$device'
set wireless.@wifi-iface[$cnt].mode='sta'
set wireless.@wifi-iface[$cnt].ifname="$1"
set wireless.@wifi-iface[$cnt].network='wwan'
EOF
}

#delete iface node in wireless. only use when we support wps 5g.
#only use when iface is exist.
uci_delete_iface() {
	uci delete wireless.@wifi-iface[$1]
}

#uci set network wwan and stabridge.
uci_set_network() {
	uci batch <<EOF
set network.wwan=interface
set network.wwan.ifname='$1'
set network.wwan.proto='dhcp'
set network.stabridge=interface
set network.stabridge.proto='relay'
set network.stabridge.network='lan wwan'
set network.stabridge.disable_dhcp_parse='1'
EOF
}

#set wireless base ifname
uci_set_wireless() {
	local ssid=$2
	local enc=$3
	local psk=$4
	uci_get_iface_number $1
	uci batch << EOF
set wireless.@wifi-iface[$cnt].ssid="$ssid"
set wireless.@wifi-iface[$cnt].encryption="$enc"
set wireless.@wifi-iface[$cnt].key="$psk"
EOF
}

set_wds() {
	#uci delete sfi node that we don't use.(to support wds 5g)
	case "$wds_if" in
		*0)
			uci_get_iface_number "sfi1"
			;;
		*1)
			uci_get_iface_number "sfi0"
			;;
	esac
	[ "$cnt" = "null" ] || uci_delete_iface $cnt

	#uci set sfi*
	#uci_set_sfi $wds_if
	uci_set_wireless "$wds_if" "$ssid" "$enc" "$psk"

	#if we need to sync config file, we can set wireless here
	#uci_set_wireless "wlan0" "$ssid-24" "$enc" "$psk"
	#uci_set_wireless "wlan1" "$ssid-5" "$enc" "$psk"

	#set firewall
	[ -f /etc/config/firewall ] && {
		uci set firewall.@zone[0].forward='ACCEPT'
		uci set firewall.@zone[0].network='lan wwan'
	}

	#uci set network maybecancel cause it will be reset in wpa_cli_event.sh
	uci set network.wan.disabled='1'
	uci set dhcp.lan.ignore='1'

	uci_set_network $wds_if

	output=`/etc/init.d/relayd enable`
	uci commit
	#wifi reload
	#rm now  then we donot need to reset led.
	[ -f /tmp/wps_status ] && rm /tmp/wps_status
	/etc/init.d/network restart
	echo "~wps~done~" > /dev/ttyS0
	exit 0
}

prepare_config
set_wds
