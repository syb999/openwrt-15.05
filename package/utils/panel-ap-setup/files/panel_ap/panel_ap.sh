#!/bin/sh

panel_ap_first_init()
{
	uci set network.wan.type='bridge'
	uci commit network
	uci set firewall.@defaults[0].forward='ACCEPT'
	uci set firewall.@zone[1].input='ACCEPT'
	uci set firewall.@zone[1].forward='ACCEPT'
	uci commit firewall
	uci set wireless.radio0.txpower='13'
	uci set wireless.@wifi-iface[0].ssid='OP_panel_ap'
	uci set wireless.@wifi-iface[0].network='wan'
	uci add /etc/config/wireless wifi-iface
	uci set wireless.@wifi-iface[1].device='radio0'
	uci set wireless.@wifi-iface[1].mode='ap'
	uci set wireless.@wifi-iface[1].ssid='OP_panel_ap_local'
	uci set wireless.@wifi-iface[1].network='lan'
	uci set wireless.@wifi-iface[1].encryption='none'
	uci commit wireless
	sleep 3
	/sbin/wifi
}

