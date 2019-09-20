#!/bin/sh
echo "setup wifi $1 $2" > /dev/ttyS0

get_channel_24g(){
	#set 24g channel
	channel_24g=$(($1 % 11))
	[ "$channel_24g" -eq 0 ] && channel_24g=1
}

get_channel_5g(){
	ch_5g=36
        case "$(($1 % 4))" in
        	1) ch_5g=161;;
        	2) ch_5g=48;;
        	3) ch_5g=149;;
        	0) ch_5g=36;;
	esac
}

prepare_common_wifi_config()
{
	ssid=$1
	cat <<EOF
	config wifi-device  radio0
	option type     mac80211
	option channel  ${channel_24g}
	option hwmode   11g
	option band     2.4G
	option country  'CN'
	option ht_coex  0
	option noscan   1
	option htmode 'HT20'
	option path '10000000.palmbus/11000000.wifi-lb'

	config wifi-iface
	option device   radio0
	option ifname   wlan0
	option network  lan
	option mode     ap
	option ssid     OpenWrt-24g-${ssid}
	option encryption psk2+ccmp
	option key      12345678

	config wifi-device  radio1
	option type     mac80211
	option channel  ${ch_5g}
	option hwmode   11a
	option band     5G
	option country  'CN'
	option ht_coex  0
	option noscan   1
	option htmode 'VHT80'
	option path '10000000.palmbus/11400000.wifi-hb'

	config wifi-iface
	option device   radio1
	option ifname   wlan1
	option network  lan
	option mode     ap
	option ssid     OpenWrt-5g-${ssid}
	option encryption psk2+ccmp
	option key      12345678

EOF

}

init_master(){
	rm /etc/config/wireless
	NUM_INT=$(($1 % 256))
	NUM=`printf "%02x" $NUM_INT`
	echo $NUM_INT > /etc/wifi_num
	get_channel_24g $1
	get_channel_5g $1
	prepare_common_wifi_config $1 > /etc/config/wireless
	uci commit wireless
	#set 24g sta
	uci set wireless.@wifi-iface[0].mode='sta'
	uci set wireless.@wifi-iface[0].network='wwan'
	uci set wireless.@wifi-iface[0].ssid="OpenWrt-24g-$1"
	uci set wireless.@wifi-iface[0].bssid="12:16:88:21:19:$NUM"
	#set 5g ap mac addr&bssid
	uci set wireless.@wifi-iface[1].macaddr="14:16:88:21:19:$NUM"
	uci set wireless.@wifi-iface[1].ssid="OpenWrt-5g-$1"
	#set ip
	uci set network.lan.ipaddr="192.168.$NUM_INT.1"
	uci commit wireless
	uci commit network
	/etc/init.d/network restart
	sleep 3
	killall iperf
	iperf -s&
}

init_slave(){
	rm /etc/config/wireless
	NUM_INT=$(($1 % 256))
	NUM=`printf "%02x" $NUM_INT`
	echo $NUM_INT > /etc/wifi_num
	get_channel_24g $1
	get_channel_5g $1
	prepare_common_wifi_config $1 > /etc/config/wireless
	uci commit wireless
	#set 5g sta
	uci set wireless.@wifi-iface[1].mode='sta'
	uci set wireless.@wifi-iface[1].network='wwan'
	uci set wireless.@wifi-iface[1].ssid="OpenWrt-5g-$1"
	uci set wireless.@wifi-iface[1].bssid="14:16:88:21:19:$NUM"
	#set 24g ap mac addr&bssid
	uci set wireless.@wifi-iface[0].macaddr="12:16:88:21:19:$NUM"
	uci set wireless.@wifi-iface[0].ssid="OpenWrt-24g-$1"
	#set ip
	uci set network.lan.ipaddr="192.100.$NUM_INT.1"
	uci commit wireless
	uci commit network
	/etc/init.d/network restart
	sleep 3
	killall iperf
	iperf -s&
}

case "$1" in
		master) init_master "$2";;
        slave) init_slave "$2";;
        *) init_master "$2";;
esac
