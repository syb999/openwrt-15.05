#!/bin/sh

wtpConfigFile=/etc/capwap/config.wtp

if [ -f "/tmp/anomaly_check" ];then
	val=`cat /tmp/anomaly_check`
fi

if [ "$val" == "anomaly" ];then
	#echo "find anomaly!" > /dev/ttyS0
	return 0
fi

if [ "$1" == "sync" ];then
	status=`cat /tmp/wifi_onoff_status`
	if [ $status -eq 1 ];then
		led.sh set led1
	else
		led.sh clear led1
	fi
	return 0
fi

mode=`cat /proc/sfax8_mode_info`
if [ "$mode" == "1" ];then
	wifi_enable=`uci get led.BTN0.wifi_enable`
	if [ "$wifi_enable" == "1" ];then

#add wifi on/off operation here
	status=`cat /tmp/wifi_onoff_status`
	if [ $status -eq 1 ];then
		echo 0 > /tmp/wifi_onoff_status
		/sbin/wifi down
		led.sh clear led1
	else
		echo 1 > /tmp/wifi_onoff_status
		/sbin/wifi up
		led.sh set led1
	fi
	return 0
	fi
fi

onoff=`cat /sys/class/leds/led1/brightness`
if [ $onoff -ge 1 ];then
	#echo "led off" > /dev/ttyS0
	led.sh clear led1
else
	#echo "led on" > /dev/ttyS0
	led.sh set led1
fi

# This should be done after led has been set
if [ "$mode" == "0" ]; then
	wtpstat=`cat /tmp/wtpstatus`
	[ "$wtpstat" != "run" ] && return 0
	onoff=`cat /sys/class/leds/led1/brightness`
	if [ $onoff -ge 1 ]; then
		sed -i "s|</WTP_LED>.*|</WTP_LED>1|" ${wtpConfigFile}
	else
		sed -i "s|</WTP_LED>.*|</WTP_LED>0|" ${wtpConfigFile}
	fi
	wtp_pid=`ps | grep WTP | grep -v grep | awk '{print $1}'`
	kill -USR1 $wtp_pid
fi

return 0
