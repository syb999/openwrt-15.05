#!/bin/sh

download() {
	siupclient $1
}

[ $# -lt 2  ] && exit 1

download_path=$1
expected_md5=$2
firmware_path=/tmp/firmware.img

# Downloading and check md5
download $download_path
ret=$?
[ $ret -ne 0 ] && exit $ret

real_md5=`md5sum $firmware_path | awk '{print $1}'`
[ "$real_md5" != "$expected_md5" ] && {
	logger -t capwap md5 checksum fail
	exit 3
}

exit 0