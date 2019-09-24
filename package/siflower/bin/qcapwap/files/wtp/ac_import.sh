#!/bin/sh

RESTORE_FILE=/tmp/ap_capwap.tar.gz
GROUP_CONFIG=/etc/config/ap_groups
GROUP_BACK=/tmp/ap_groups.bak
DEVICE_CONFIG=/etc/config/capwap_devices
DEVICE_BACK=/tmp/capwap_devices.bak

exit_with() {
	rm $RESTORE_FILE
	echo $1
	exit
}

if [ ! -f $RESTORE_FILE ]; then
	echo 1
	exit
fi

tar -zxvf $RESTORE_FILE -C /tmp >/dev/null 2>&1
if [ $? -ne 0 ]; then
	exit_with 1
fi

cp $GROUP_CONFIG $GROUP_BACK
cp $DEVICE_CONFIG $DEVICE_BACK
/etc/init.d/ac_server stop
cat /tmp/ap_groups | uci import ap_groups >/dev/null 2>&1 && cat /tmp/capwap_devices | uci import capwap_devices >/dev/null 2>&1
err=$?
if [ $err -ne 0 ]; then
	cp $GROUP_BACK $GROUP_CONFIG
	cp $DEVICE_BACK $DEVICE_CONFIG
fi

rm /tmp/ap_groups /tmp/capwap_devices
rm $GROUP_BACK $DEVICE_BACK
/etc/init.d/ac_server start

exit_with $err
