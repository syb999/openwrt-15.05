#!/bin/sh
status=0
wps_status=0
cnt=0
# $1 ifname

uci_get_iface_number() {
	local name
	cnt=0
	name=`uci get wireless.@wifi-iface[$cnt].ifname`
	[ "$name" = "$1"  ] || {
		until [ "$name" = "$1" -o $cnt -gt 8  ]
		do
			let "cnt++"
			name=`uci get wireless.@wifi-iface[$cnt].ifname`
		done
	}

	[ $cnt -gt 8  ] && {
		#TODO maybe we can number all kinds of error in a single func.
		#echo "ERROR: could not find the iface." > /dev/ttyS0
		cnt="null"
		#error_exit
	}
}

uci_add_station() {
	local device
	#TODO  what if we have added too much station?
	until [ "$?" = 1 ]
	do
		name=`uci get wireless.@wifi-iface[$cnt].ifname`
		# if station is already exist, just return.
		[ "$name" = "$1" ] && return
		let "cnt++"
		uci get wireless.@wifi-iface[$cnt] >/dev/null 2>&1
	done

	case "$1" in
		*0)
			device="radio0"
			;;
		*1)
			device="radio1"
			;;
	esac

	uci batch << EOF
add wireless wifi-iface
set wireless.@wifi-iface[$cnt].device='$device'
set wireless.@wifi-iface[$cnt].network='wwan'
set wireless.@wifi-iface[$cnt].ssid='errorssid'
set wireless.@wifi-iface[$cnt].ifname='$1'
set wireless.@wifi-iface[$cnt].mode='sta'
set wireless.@wifi-iface[$cnt].disabled='0'
EOF
}

check_status() {
	[ -f /tmp/wps_start ] && status=`cat /tmp/wps_start`
	[ -f /tmp/wps_status  ] && wps_status=`cat /tmp/wps_status`
	[ $status = 1 -o "$wps_status" != 0 ] && {
		exit 0
	}
}

wps_start() {
	#add sta iface conf file in wireless to up sif*.
	uci_add_station "sfi0"
	uci_add_station "sfi1"
	#TODO should support both 2.4g&5g
	#uci set network.wwan=interface
	#uci set network.wwan.ifname='sfi0'
	#uci set network.wwan.proto='dhcp'
}

check_status
echo 1 > /tmp/wps_start
wps_start
uci commit
output=`wifi reload`

sleep 2
cd /var/run/wpa_supplicant
for socket in *; do
	[ -S "$socket"  ] || continue
	wpa_cli -i "$socket" wps_pbc
done

#wps_start  shall rm here.
[ -f /tmp/wps_start ] && rm /tmp/wps_start
exit 0
