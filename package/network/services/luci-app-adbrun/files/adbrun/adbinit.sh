#!/bin/sh
sleep 1
adbdevlist=$(adb devices | sed '1d;$d' 2>/dev/null)
for i in $adbdevlist;do
	adb -s $i tcpip 5555 &
	sleep 3
	kill -9 $(busybox ps | grep -i adb | grep "tcpip 5555" | grep -v grep | awk '{print $1}') > /dev/null 2>&1
done
