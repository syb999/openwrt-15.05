#/bin/sh

myFile="/tmp/wtpstatus"
apModeFile="/proc/sfax8_mode_info"
update_file="/tmp/update_status"
fit_ap=0

# $1: led on time in ms
# $2: led off time in ms
blink() {
	[ ! -d /sys/class/leds/led1 ] && return
	local trigger=`cat /sys/class/leds/led1/trigger | awk '{print $2}'`
	[ "$trigger" == "[timer]" ] && local delay_on=`cat /sys/class/leds/led1/delay_on`
	[ "$trigger" == "[timer]" ] && local delay_off=`cat /sys/class/leds/led1/delay_off`

	if [ "$trigger" != "[timer]" ] || [ "$delay_on" != "$1" ] || [ "$delay_off" != "$1" ]; then
		echo "timer" > /sys/class/leds/led1/trigger
		echo $1 > /sys/class/leds/led1/delay_on
		echo $2 > /sys/class/leds/led1/delay_off
	fi
}

set_led() {
	[ ! -d /sys/class/leds/led1 ] && return
	local trigger=`cat /sys/class/leds/led1/trigger | awk '{print $1}'`
	local stat=$1
	local real_stat=`cat /sys/class/leds/led1/brightness`

	if [ "$trigger" != "[none]" ] || [ "$stat" != "$real_stat" ]; then
		echo none > /sys/class/leds/led1/trigger
		echo $stat > /sys/class/leds/led1/brightness
	fi
}

start_wtp() {
	WTP &
}

get_led() {
	cat /tmp/wtp_ledstatus
}

blink 2000 2000

if [ -f /etc/config/ap_update ]; then
	local version=`cat /etc/openwrt_version`
	local expect_version=`uci get ap_update.info.version`

	if [ "$expect_version" != "0" ] && [ "$version" != "$expect_version" ]; then
		echo 5 > $update_file
	else
		echo 4 > $update_file
	fi
fi

apMode=`cat ${apModeFile}`
echo ${apMode}
if [ "${apMode}" == "${fit_ap}" ]; then
	echo "#################check WTP status############"

	while [ 1 ]
	do
		result=`ps | grep WTP | grep -v grep`
		status=`cat $myFile`
		led=`get_led`
		if [ "$result" = "" ] && [ "$status" != "update" ];then
			start_wtp
		fi
		if [ "$status" == "update" ]; then
			blink 1000 1000
		elif [ "$status" == "run" ]; then
			if [ "$led" == "1" ]; then
				set_led 1
			else
				set_led 0
			fi
		else
			blink 2000 2000
		fi
		sleep 2
	done

fi
