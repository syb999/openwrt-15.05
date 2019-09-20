#!/bin/sh

add_network_config()
{
        cat <<EOF
config interface 'lease'
        option ifname 'lease'
        option force_link '1'
        option type 'bridge'
        option proto 'static'
        option ipaddr '10.2.0.1'
        option netmask '255.255.255.0'
        option group '0'

EOF
}

add_wireless_config()
{
	for _dev in /sys/class/ieee80211/*; do
		[ -e "$_dev" ] || continue
		dev="${_dev##*/}"
		band="2.4G"
		ssidprefix="-2.4G"
		vht_cap=$(iw phy "$dev" info | grep -c 'VHT Capabilities')
		cap_5ghz=$(iw phy "$dev" info | grep -c "Band 2")
		[ "$vht_cap" -gt 0 -a "$cap_5ghz" -gt 0 ] && {
			band="5G"
		}
		ssid_lease=SiWiFi-租赁-$ssidprefix`cat /sys/class/ieee80211/${dev}/macaddress | cut -c 13- | sed 's/://g'`

	if [ "$band" == "2.4G" ]; then
		cat <<EOF
config wifi-iface
	option device   radio0
	option ifname   wlan0-lease
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
	option disabled 1

EOF
		break
	fi
	done
}


add_firewall_config()
{
        cat <<EOF
config zone
        option name 'lease'
        option input 'ACCEPT'
        option forward 'REJECT'
        option output 'ACCEPT'
        option network 'lease'

config forwarding
        option src 'lease'
        option dest 'wan'

config forwarding
        option src 'lease'
        option dest 'wwan'

config rule
        option name 'DNSGuest'
        option src 'lease'
        option dest_port '53'
        option proto 'tcpudp'
        option target 'ACCEPT'

config rule
        option name 'DHCPGuest'
        option src 'lease'
        option src_port '67-68'
        option dest_port '67-68'
        option proto 'udp'
        option target 'ACCEPT'

EOF
}

add_dhcp_config()
{
        cat <<EOF
config dhcp 'lease'
        option interface 'lease'
        option start '100'
        option limit '150'
        option leasetime '12h'

EOF
}

add_sicloud_config()
{
        cat <<EOF
config cloud 'leaseserver'
        option port '8051'
        option ip '47.100.115.17'

EOF
}
add_network_config >> /etc/config/network
add_wireless_config >> /etc/config/wireless
add_firewall_config >> /etc/config/firewall
add_dhcp_config >> /etc/config/dhcp
add_sicloud_config >> /etc/config/sicloud
