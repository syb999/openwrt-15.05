#!/system/bin/sh

_looptime=

i=1
while [ "$i" -le "$_looptime" ];do
	dd if=/sdcard/recordtap of=/dev/input/event
	i=$(($i + 1))
done

