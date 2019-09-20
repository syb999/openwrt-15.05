#!/bin/sh
while true
do
	udhcpc -n -q -s /bin/true -t 1 -i br-lan >&- && rv=1 || rv=0
	ac_enable=`uci get auto_tmp.tmp.ac`
	if [ $rv - eq 1 ];then
		uci set auto_tmp.tmp.ac=$rv
		uci commit auto_tmp
	else
		uci set auto_tmp.tmp.ac=$rv
		uci commit auto_tmp
	fi
	connectmode=`uci get auto_tmp.tmp.connectmode`
	dhcp_enable=`uci get auto_tmp.tmp.dhcp_enable`
	if [ $connectmode -eq 1 -a $dhcp_enable -eq 1 ];then
		apMode=`cat /proc/sfax8_mode_info`
		if [ "${apMode}" != "0"  ]; then
			if [ !  $rv -eq $ac_enable ];then
				devmem 0x19e04040 32 0x10
				ubus call network.wireless down
				/bin/sh /bin/dhcp.sh
				sleep 6
				devmem 0x19e04040 32 0x11
				ubus call network.wireless up
			fi
		fi
	elif [ $connectmode -eq 0 -a $dhcp_enable -eq 1 ];then
		apMode=`cat /proc/sfax8_mode_info`
		if [ "${apMode}" != "0"  ]; then
			proto=`uci get network.lan.proto`
			count=`uci get auto_tmp.tmp.count`
			if [ $? -eq 1  ];then
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				count=`uci get auto_tmp.tmp.count`
			fi
			if [ $dhcp_enable -eq 1 -a $rv -eq 0 -a $count -lt 2  ] ;then
				let count=count+1
				uci set auto_tmp.tmp.count=$count
				uci commit auto_tmp
				if [ $count -eq 2  ];then
					uci set network.lan.proto='static'
					uci set network.lan.ipaddr='192.168.4.251'
					uci set network.lan.gateway='255.255.255.0'
					uci commit network
					uci set auto_tmp.tmp.ipaddr="192.168.4.251"
					uci set auto_tmp.tmp.netmask="255.255.255.0"
					uci set auto_tmp.tmp.gateway=""
					uci set auto_tmp.tmp.dns=""
					uci set auto_tmp.tmp.standbyDns=""
					uci commit auto_tmp
					/etc/init.d/network restart
				fi
			elif [ $dhcp_enable -eq 1 -a $rv -eq 1 -a $count -eq 2  ];then
				uci set network.lan.proto='dhcp'
				uci commit network
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				/etc/init.d/network reload
			fi
		fi
	fi
	sleep 30
done
