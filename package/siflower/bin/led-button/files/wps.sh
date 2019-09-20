#!/bin/sh
mode=`cat /etc/config/network | grep wwwan`
[ -n "$mode" ] && {
	cd /var/run/wpa_supplicant
	for socket in *; do
		[ -S "$socket" ] || continue
		wpa_cli -i "$socket" wps_pbc
	done
}
[ -n "$mode" ] || {
	cd /var/run/hostapd
	for socket in *; do
		[ -S "$socket" ] || continue
		hostapd_cli -i "$socket" wps_pbc
	done
}
