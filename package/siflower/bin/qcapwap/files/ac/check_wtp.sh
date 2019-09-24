#!/bin/sh

myFile="/tmp/wtpstatus"
apModeFile="/proc/sfax8_mode_info"
update_file="/tmp/update_status"
fit_ap=0

start_wtp() {
	WTP &
}

get_led() {
	cat /tmp/wtp_ledstatus
}

apMode=`cat ${apModeFile}`
echo ${apMode}
if [ "${apMode}" != "${fit_ap}" ]; then
	exit
fi

/bin/led-button -l 28

if [ -f /etc/config/ap_update ]; then
	local version=`cat /etc/openwrt_version`
	local expect_version=`uci get ap_update.info.version`

	if [ "$expect_version" != "0" ] && [ "$version" != "$expect_version" ]; then
		echo 5 > $update_file
	else
		echo 4 > $update_file
	fi
	rm /etc/config/ap_update
fi

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
		/bin/led-button -l 27
	elif [ "$status" == "run" ]; then
		if [ "$led" == "1" ]; then
			/bin/led-button -l 1
		else
			/bin/led-button -l 3
		fi
	else
		/bin/led-button -l 28
	fi
	sleep 2
done

