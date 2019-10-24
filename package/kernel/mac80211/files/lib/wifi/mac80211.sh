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
		channel="11"
		htmode=""
		ht_capab=""

		ssnm=_$(cat /sys/class/ieee80211/${dev}/macaddress | sed 's/.[0-9A-Fa-f]:.[0-9A-Fa-f]:.[0-9A-Fa-f]:\(.[0-9A-Fa-f]\):\(.[0-9A-Fa-f]\):\(.[0-9A-Fa-f]\)/\1\2\3/g' | tr :[a-z] :[A-Z])

		iw phy "$dev" info | grep -q 'Capabilities:' && htmode=HT20
		iw phy "$dev" info | grep -q '2412 MHz' || { mode_band="a"; channel="36"; }

		vht_cap=$(iw phy "$dev" info | grep -c 'VHT Capabilities')
		cap_5ghz=$(iw phy "$dev" info | grep -c "Band 2")
		[ "$vht_cap" -gt 0 -a "$cap_5ghz" -gt 0 ] && {
			mode_band="a";
			channel="36"
			htmode="VHT80"
		}

		[ -n $htmode ] && append ht_capab "	option htmode	$htmode" "$N"

		if [ -x /usr/bin/readlink -a -h /sys/class/ieee80211/${dev} ]; then
			path="$(readlink -f /sys/class/ieee80211/${dev}/device)"
		else
			path=""
		fi
		if [ -n "$path" ]; then
			path="${path##/sys/devices/}"
			case "$path" in
				platform*/pci*) path="${path##platform/}";;
			esac
			dev_id="	option path	'$path'"
		else
			dev_id="	option macaddr	$(cat /sys/class/ieee80211/${dev}/macaddress)"
		fi

		if [ x$mode_band == x"g" ]; then
			ssid_wlan="_2.4G"
		else
			ssid_wlan="_5G"
		fi

		cat <<EOF
config wifi-device  radio$devidx
	option type     mac80211
	option channel  ${channel}
	option hwmode	11${mode_band}
	option txpower 20
	option country CN
	option legacy_rates 0
$dev_id
$ht_capab
	# REMOVE THIS LINE TO ENABLE WIFI:
	option disabled 0

config wifi-iface
	option device   radio$devidx
	option network  lan
	option mode     ap
	option ssid     OpenWrt${ssid_wlan}${ssnm}
	option encryption none
	option disassoc_low_ack 0
	option isolate 0
	option signal_connect -95
	option signal_stay -100
	option signal_strikes 3
	option signal_poll_time 5
	option signal_drop_reason 3

EOF
	devidx=$(($devidx + 1))
	done
}

