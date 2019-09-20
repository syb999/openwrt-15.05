#!/bin/sh

run_master(){
#		echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		WIFI_NUM=`cat /etc/wifi_num`
        ifconfig wlan0 192.100.$WIFI_NUM.55
        iperf -c 192.100.$WIFI_NUM.1 -d -i 1 -t 10000000
}

run_slave(){
#		echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		WIFI_NUM=`cat /etc/wifi_num`
        ifconfig wlan1 192.168.$WIFI_NUM.55
        iperf -c 192.168.$WIFI_NUM.1 -d -i 1 -t 10000000
}

case "$1" in
        master) run_master;;
        slave) run_slave;;
        *) run_master;;
esac
