#!/bin/sh
. /lib/functions.sh
. /usr/share/libubox/jshn.sh

timer=1
timeout=30
while [ $timer -gt 0 ]; do
    wan_status=`ubus call network.interface.wan status`
    json_load "$wan_status"
    json_get_vars up
    echo "up=$up"
    if [ "x$up" == "x0" ]; then
		sleep $timeout
		continue
    fi
#    echo "update ts file" > /dev/ttyS0
    /usr/bin/auto-check-ts-version.sh
    if [ -f "/etc/config/sf-ts-cfg.bin.tar.gz" ]; then
        echo "ts file avaiable now!"
        exit
    fi
	sleep $timeout
	timeout=$(($timeout + 30))
done
