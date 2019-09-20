#!/bin/sh
# Copyright (C) 2006 OpenWrt.org

sfwifi_ate remove
sleep 1


if [ $1 == "lb" ]
then
sfwifi_ate reload $1 $2
sleep 2

ifconfig wlan0 up
ate_cmd wlan0 set ATE = ATESTART
fi

if [ $1 == "hb" ]
then
sfwifi_ate reload $1 $2
sleep 2

ifconfig wlan0 up
ate_cmd wlan1 set ATE = ATESTART
fi

if [ $1 == "hp" ]
then
sfwifi_ate reload
sleep 2

ifconfig wlan0 up
ifconfig wlan1 up
ate_cmd wlan0 set ATE = ATESTART
ate_cmd wlan1 set ATE = ATESTART
devmem 0x1150b100 32 0x007F7F7F
devmem 0x1110b100 32 0x007F7F7F

devmem 0x11c00cfe 16 0x0800
devmem 0x11c01cfe 16 0x0800
fi

if [ -z "$1" ]
then
sfwifi_ate reload
sleep 2

ifconfig wlan0 up
ifconfig wlan1 up
ate_cmd wlan0 set ATE = ATESTART
ate_cmd wlan1 set ATE = ATESTART
fi
killall ate_server
if [ -w "/sys/kernel/debug/aetnensis/recalibrate" ];then
echo 200 > /sys/kernel/debug/aetnensis/recalibrate
fi
if [ -w "/sys/kernel/debug/aetnensis/cooling_temp" ];then
echo 0 > /sys/kernel/debug/aetnensis/cooling_temp
fi

ate_server
