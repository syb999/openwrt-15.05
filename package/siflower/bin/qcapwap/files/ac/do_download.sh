#!/bin/sh

LOCKFILE=/tmp/wtp_download.lock

if [ -f $LOCKFILE ]; then
	pid=$(cat $LOCKFILE)
	if [ -n $pid ] && [ -n $(ps | grep "$pid") ]; then
		exit 0
	fi
fi

echo $$ >$LOCKFILE

quit() {
	rm $LOCKFILE
	exit $1
}

download() {
	siupclient $1 > /tmp/wtp_update.log
}

[ $# -lt 2 ] && quit 1

download_path=$1
expected_md5=$2
firmware_path=/tmp/firmware.img
retry=0

# Downloading and check md5
while [ $retry -lt 2 ]; do
	download $download_path
	ret=$?
	[ $ret -ne 0 ] && quit $ret

	real_md5=$(md5sum $firmware_path | awk '{print $1}')
	if [ "$real_md5" != "$expected_md5" ]; then
		logger -t capwap md5 checksum fail
		if [ $retry -lt 2 ]; then
			retry=$(($retry + 1))
			sleep 1
		else
			quit 3
		fi
	else
		quit 0
	fi
done

quit 3
