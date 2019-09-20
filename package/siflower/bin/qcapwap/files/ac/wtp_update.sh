#!/bin/sh

[ $# -lt 3  ] && echo "Must specify firmware version, path and device's mac!" && exit 1

WUMBIN=/usr/sbin/WUM

version=$1
md5=$2
shift 2
device_macs=$@

addr=`ifconfig br-lan | grep "inet addr" | awk -F ':' '{print $2}' | awk '{print $1}'`

for mac in $device_macs; do
	$WUMBIN -c jsoin -j '{"command":"ap_update", "device":"'$mac'","path":"'$addr'","md5":"'$md5'","version":"'$version'"}' &
	pid=`echo $!`
	logger -t wtp_update wum pid is $pid
done

exit 0
