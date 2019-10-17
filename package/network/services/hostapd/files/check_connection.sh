#!/bin/sh

cnt=0
status=`wpa_cli -i $1 status | awk -F "wpa_state=" '{printf "%s", $2}'`
#echo "wds interface detected!" > /dev/ttyS0

while [ "$status" == "SCANNING" ]
do
	let cnt=$cnt+1
	if [ $cnt -gt 10 ]; then
		#echo "disconnected!" > /dev/ttyS0
		uci set dhcp.lan.ignore=0
		uci commit dhcp
		/etc/init.d/dnsmasq reload
		exit 0
	fi

	status=`wpa_cli -i $1 status | awk -F "wpa_state=" '{printf "%s", $2}'`
	# check status "scanning" every second
	# attention: status=disconnected is also accpeted
	# because wpa_cli_event.sh will deal with it.
	sleep 1
done
#echo "check_connection $status!!!!" > /dev/ttyS0
