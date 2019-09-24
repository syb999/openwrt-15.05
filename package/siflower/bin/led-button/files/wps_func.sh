#!/bin/sh


# @$1 ifname @$2 network
uci_add_station() {
	local device
	local name
	local cnt=0
	#TODO  what if we have added too much station?
	until [ "$?" = 1 ]
	do
		name=`uci -q get wireless.@wifi-iface[$cnt].ifname`
		# if station is already exist, just return.
		[ "$name" = "$1" ] && {
			uci -q set wireless.@wifi-iface[$cnt].disabled='0'
			return
		}
		let "cnt++"
		uci -q get wireless.@wifi-iface[$cnt] > /dev/null
	done

	case "$1" in
		*0)
			device="radio0"
			;;
		*1)
			device="radio1"
			;;
	esac

	uci add wireless wifi-iface > /dev/null
	# repeater has different network wwan wwwan.
	uci -q batch << EOF
set wireless.@wifi-iface[$cnt].device="$device"
set wireless.@wifi-iface[$cnt].network="$2"
set wireless.@wifi-iface[$cnt].ssid='errorssid'
set wireless.@wifi-iface[$cnt].ifname="$1"
set wireless.@wifi-iface[$cnt].mode='sta'
set wireless.@wifi-iface[$cnt].disabled='0'
EOF
}

uci_delete_wireless_iface() {
	local name
	local cnt=0
	until [ "$name" = "$1" -o "$cnt" -gt 9 ]
	do
		name=`uci -q get wireless.@wifi-iface[$cnt].ifname`
		let "cnt++"
	done
	let "cnt--"
	[ "$cnt" -gt 8 ] || uci -q delete wireless.@wifi-iface[$cnt]
}

#uci set network wwan and stabridge.
#FIXME disable_dhcp_parse WHAT TO DO WITH IT? AND SHALL WE SUPPORT REPEATER?
uci_set_network() {
	uci -q batch <<EOF
set network.wwan=interface
set network.wwan.ifname="$1"
set network.wwan.proto='dhcp'
set network.stabridge=interface
set network.stabridge.proto='relay'
set network.stabridge.network='lan wwan'
set network.stabridge.disable_dhcp_parse='1'
EOF
}

#wds fail or rewds.
uci_delete_network() {
	uci -q batch <<EOF
delete network.wwan
delete network.stabridge
EOF
}

#set wireless base ifname, if it does not exist, just not set.
uci_set_wireless_iface() {
	local cnt=0
	local ssid=$2
	local enc=$3
	local psk=$4
	until [ "$name" = "$1" -o "$cnt" -gt 9 ]
	do
		name=`uci -q get wireless.@wifi-iface[$cnt].ifname`
		let "cnt++"
	done
	let "cnt--"
	[ $cnt -gt 8 ] || {
	uci -q batch << EOF
set wireless.@wifi-iface[$cnt].ssid="$ssid"
set wireless.@wifi-iface[$cnt].encryption="$enc"
set wireless.@wifi-iface[$cnt].key="$psk"
EOF
}
}

set_channel() {
	local num=0
	local chan=`iwinfo "$1" info | grep Chan|awk -F ' ' '{print $4}'`
	case "$1" in
		sfi0)
			num=0
			;;
		sfi1)
			num=1
			;;
	esac
	[ "$chan" -gt 0 ] && {
		uci set wireless.radio${num}.channel="$chan"
		if [ "$num" = 1 ]; then
			uci set wireless.radio1.htmode="VHT80"
			[ "$chan" = "165" ] && uci set wireless.radio1.htmode="VHT20"
		fi
		uci commit wireless
		output=`wifi reload`
	}
}
