#!/bin/sh

getcurrentvolume=$(amixer get Speaker | tail -n 1 | cut -d ' ' -f 6)
volumestep=3
volume=$getcurrentvolume

if [ $volume -lt 30 ];then
	volume=$(echo `expr $volume + $volumestep`)
	volumeup=$volume
	amixer -q set Speaker $volumeup
fi

