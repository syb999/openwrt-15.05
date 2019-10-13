#!/bin/sh
append DRIVERS "mac80211"

lookup_phy() {
	[ -n "$phy" ] && {
		[ -d /sys/class/ieee80211/$phy ] && return
	}

	local devpath
	config_get devpath "$device" path
	[ -n "$devpath" ] && {
		for _phy in /sys/devices/$devpath/ieee80211/phy*; do
			[ -e "$_phy" ] && {
				phy="${_phy##*/}"
				return
			}
		done
	}

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	[ -n "$macaddr" ] && {
		for _phy in /sys/class/ieee80211/*; do
			[ -e "$_phy" ] || continue

			[ "$macaddr" = "$(cat ${_phy}/macaddress)" ] || continue
			phy="${_phy##*/}"
			return
		done
	}
	phy=
	return
}

find_mac80211_phy() {
	local device="$1"

	config_get phy "$device" phy
	lookup_phy
	[ -n "$phy" -a -d "/sys/class/ieee80211/$phy" ] || {
		echo "PHY for wifi device $1 not found"
		return 1
	}
	config_set "$device" phy "$phy"

	config_get macaddr "$device" macaddr
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/ieee80211/${phy}/macaddress)"
	}

	return 0
}

check_mac80211_device() {
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_mac80211_phy "$1" >/dev/null || return 0
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}

detect_mac80211() {
	devidx=0
	config_load wireless
	while :; do
		config_get type "radio$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done

	for _dev in /sys/class/ieee80211/*; do
		[ -e "$_dev" ] || continue

		dev="${_dev##*/}"

		found=0
		config_foreach check_mac80211_device wifi-device
		[ "$found" -gt 0 ] && continue

		mode_band="g"
		channel="auto"
		htmode=""
		ht_capab=""
		ssidprefix="-2.4G"
		noscan="0"
		band="2.4G"
		htcodex="0"

		iw phy "$dev" info | grep -q 'Capabilities:' && htmode=HT20
		iw phy "$dev" info | grep -q '2412 MHz' || { mode_band="a"; channel="36"; ssidprefix=""; htmode="HT40";}

		vht_cap=$(iw phy "$dev" info | grep -c 'VHT Capabilities')
		cap_5ghz=$(iw phy "$dev" info | grep -c "Band 2")
		[ "$vht_cap" -gt 0 -a "$cap_5ghz" -gt 0 ] && {
			mode_band="a";
			channel="161"
			htmode="VHT80"
			noscan="1"
			band="5G"
			htcodex="0"
		}

		[ -n $htmode ] && append ht_capab "	option htmode	$htmode" "$N"

		if [ -x /usr/bin/readlink -a -h /sys/class/ieee80211/${dev} ]; then
			path="$(readlink -f /sys/class/ieee80211/${dev}/device)"
		else
			path=""
		fi
		if [ -n "$path" ]; then
			path="${path##/sys/devices/}"
			dev_id="	option path	'$path'"
		else
			dev_id="	option macaddr	$(cat /sys/class/ieee80211/${dev}/macaddress)"
		fi
		ssid=SiWiFi-`cat /sys/class/ieee80211/${dev}/macaddress | cut -c 13- | sed 's/://g'`$ssidprefix
		ssid_lease=SiWiFi-租赁-$ssidprefix`cat /sys/class/ieee80211/${dev}/macaddress | cut -c 13- | sed 's/://g'`
		country=`cat sys/devices/factory-read/countryid`
		if [ ! -n "$country" ]; then
			country='CN'
		fi
		txpower_lvl=2
		[ -f "/etc/ext_pa_exist" ] && {
			txpower_lvl=1
		}
		if [ "$band" == "2.4G" ]; then
			rps_cpus=2
		else
			rps_cpus=3
		fi

		cat <<EOF
config wifi-device  radio$devidx
	option type     mac80211
	option channel  ${channel}
	option band     ${band}
	option max_all_num_sta 40
	option netisolate 0
	option country  '$country'
	option ht_coex	${htcodex}
	option noscan   $noscan
	option radio 1
	option txpower_lvl '$txpower_lvl'
$dev_id
$ht_capab
	option hwmode	11${mode_band}

config wifi-iface
	option device   radio$devidx
	option ifname   wlan$devidx
	option network  lan
	option mode     ap
	option ssid     $ssid
	option encryption psk2+ccmp
	option key      12345678
	option isolate '0'
	option hidden '0'
	option macfilter   disable
	option macfile   /etc/wlan-file/wlan${devidx}.allow
	option group 1
	option netisolate 0
	option disable_input 0
	option wps_pushbutton '1'
	option wps_label '0'
	option rps_cpus $rps_cpus

EOF
	[ -f "/etc/ignore_guest" ] || {
		cat <<EOF
config wifi-iface
	option device   radio$devidx
	option ifname   wlan$devidx-guest
	option network  guest
	option mode     ap
	option ssid     $ssid-guest
	option encryption psk2+ccmp
	option key      12345678
	option isolate 1
	option hidden '0'
	option group 1
	option netisolate 0
	option disable_input 0
	option wps_pushbutton '0'
	option wps_label '0'
	option rps_cpus $rps_cpus
	option disabled 1

EOF
	if [ "$band" == "2.4G" ]; then
		cat <<EOF
config wifi-iface
	option device   radio$devidx
	option ifname   wlan$devidx-lease
	option network  lease
	option mode     ap
	option ssid     $ssid_lease
	option encryption none
	option isolate 1
	option hidden '0'
	option group 1
	option netisolate 0
	option maxassoc 40
	option disable_input 0
	option rps_cpus $rps_cpus
	option disabled 1

EOF
	fi
	}
	devidx=$(($devidx + 1))
	done
}
