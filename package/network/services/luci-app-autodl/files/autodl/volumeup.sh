#!/bin/sh

xmgetspkdev=$(amixer | grep 'Simple mixer control' | grep -e 'Speaker' -e 'PCM' -e 'Master' | cut -d "'" -f 2)
testMono=" Mono"
if [ $(amixer get $xmgetspkdev | grep -i channels | cut -d ':' -f 2) = $testMono ];then
	getcurrentvolume=$(amixer get $xmgetspkdev | tail -n 1 | cut -d ' ' -f 5)
else
	getcurrentvolume=$(amixer get $xmgetspkdev | tail -n 1 | cut -d ' ' -f 6)
fi
if [ "$xmgetspkdev" == "Speaker" ];then
	getmaxvolume=$(amixer get Speaker | head -n 4 | tail -n 1 | cut -d '-' -f 2 | cut -d ' ' -f 2)
	if [ $getmaxvolume -lt 100 ];then
		volumestep=5
	else
		volumestep=12
	fi
elif [ "$xmgetspkdev" == "PCM" ];then
	volumestep=8
else
	volumestep=5
fi
volume=$getcurrentvolume

if [ "$xmgetspkdev" == "Speaker" ];then
	if [ $volume -lt 151 ];then
		volume=$(echo `expr $volume + $volumestep`)
		volumeup=$volume
		amixer -q set Speaker $volumeup
	fi
elif [ "$xmgetspkdev" == "PCM" ];then
	if [ $volume -lt 255 ];then
		volume=$(echo `expr $volume + $volumestep`)
		volumeup=$volume
		amixer -q set PCM $volumeup
	fi
else
	if [ $volume -lt 128 ];then
		volume=$(echo `expr $volume + $volumestep`)
		volumeup=$volume
		amixer -q set Master $volumeup
	fi
fi

