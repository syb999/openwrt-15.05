#!/bin/sh

panel_ap_first_init()
{
	uci set network.wan.type='bridge'
	uci commit network
	uci set firewall.@defaults[0].forward='ACCEPT'
	uci set firewall.@zone[1].input='ACCEPT'
	uci set firewall.@zone[1].forward='ACCEPT'
	uci commit firewall
	uci set network.lan.proto='dhcp'
	uci set network.lan.delegate='0'
	uci set network.lan.igmp_snooping='1'
	uci commit network
}

