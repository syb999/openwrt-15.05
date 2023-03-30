#!/system/bin/sh

i=1
while [ "$i" -le "210" ];do
	dd if=/sdcard/recordtap of=/dev/input/event
	i=$(($i + 1))
done
