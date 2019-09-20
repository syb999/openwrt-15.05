#!/bin/sh
apMode=`cat /proc/sfax8_mode_info`
if [ "${apMode}" != "0" ]; then
	result=`ubus list | grep "interface" |grep "cfg*"`
	alias_id=`echo $result |awk -F '.' '{print $3}'`
	old_alias=`uci get network.$alias_id`
	if [ "${old_alias}" == "alias"  ]; then
		uci set network.$alias_id=''
		uci commit network
		/etc/init.d/network restart
	fi
	uci get network.lan.connectmode
	if [ $? -eq 0  ];then
		uci set network.lan.gateway=''
		uci set network.lan.connectmode=''
		uci set network.lan.dhcp_enable=''
		uci set network.lan.proto='static'
		uci commit network
		uci set dhcp.lan.ignore=''
		uci commit dhcp
	fi

	if [ ! -f /etc/config/auto_tmp  ]; then
		touch /etc/config/auto_tmp
		chmod a+x /etc/config/auto_tmp
		uci set auto_tmp.tmp='tmp'
		uci set auto_tmp.tmp.dhcp_enable="1"
		uci set auto_tmp.tmp.connectmode="1"
		uci set auto_tmp.tmp.ac="0"
		uci commit auto_tmp
	fi

	connectmode=`uci get auto_tmp.tmp.connectmode`
	if [ $connectmode == 0 ];then                          #auto mode
		sleep 3
		ac_enable=`uci get auto_tmp.tmp.ac`
		if [ "$ac_enable" == "1" ]; then                               #ac is open
			uci set auto_tmp.tmp.count='0'
			uci commit auto_tmp
			/etc/init.d/dnsmasq stop
		else                                                          #ac is close
			ap_enable=`uci get auto_tmp.tmp.dhcp_enable`
			if [ "$ap_enable" == "1" ]; then                          #dhcp server is open
				sleep 2
				/etc/init.d/dnsmasq start
				/etc/init.d/get_dhcpserver_status stop
				/etc/init.d/get_dhcpserver_status start
			elif [ "$ap_enable" == "0" ] ; then
				uci set auto_tmp.tmp.ipaddr="192.168.4.252"
				uci set auto_tmp.tmp.netmask="255.255.255.0"
				uci set auto_tmp.tmp.gateway=""
				uci set auto_tmp.tmp.dns=""
				uci set auto_tmp.tmp.standbyDns=""
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				sleep 2
				/etc/init.d/dnsmasq stop
			fi
		fi
	else			#static mode
		uci set auto_tmp.tmp.ipaddr=""
		uci set auto_tmp.tmp.netmask=""
		uci set auto_tmp.tmp.gateway=""
		uci commit auto_tmp
		udhcpc -n -q -s /bin/true -t 1 -i br-lan >&- && rv=1 || rv=0
		uci set auto_tmp.tmp.ac="$rv"
		uci commit auto_tmp
		ac_enable=`uci get auto_tmp.tmp.ac`
		if [ $ac_enable == "1"  ];then
			ap_enable=`uci get auto_tmp.tmp.dhcp_enable`
			if [ "$ap_enable" == "1"   ]; then                          #dhcp server is open
				sleep 2
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				/etc/init.d/dnsmasq stop
			elif [ "$ap_enable" == "0"   ] ; then
				sleep 2
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				/etc/init.d/dnsmasq stop
			fi
		else
			ap_enable=`uci get auto_tmp.tmp.dhcp_enable`
			if [ "$ap_enable" == "1"   ]; then                          #dhcp server is open
				sleep 2
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				/etc/init.d/dnsmasq restart
			elif [ "$ap_enable" == "0"   ] ; then
				sleep 2
				uci set auto_tmp.tmp.count='0'
				uci commit auto_tmp
				/etc/init.d/dnsmasq stop
			fi
		fi
	fi
fi
