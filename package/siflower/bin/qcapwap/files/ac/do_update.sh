#!/bin/sh

WTP_DIR=/etc/capwap

set_update_status() {
	touch /etc/config/ap_update
	uci set ap_update.info.status=$1
	uci commit
}

exit_with_error() {
	set_update_status $1
	rm /tmp/wtpstatus
	exit $1
}

[ $# -lt 1 ] && exit_with_error 3

firmware_version=$1
firmware_path=/tmp/firmware.img

# Wait WTP quit
result=`ps | grep WTP | grep -v grep`
while [ -n "$result" ]; do
	result=`ps | grep WTP | grep -v grep`
done

# Do update
touch /etc/config/ap_update
uci set ap_update.info=update_info
uci set ap_update.info.version=$firmware_version
uci set ap_update.info.status=2
uci commit

/sbin/sysupgrade $firmware_path
