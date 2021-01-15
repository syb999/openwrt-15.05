#!/bin/sh

getcurrentvolume=$(amixer get Speaker | tail -n 1 | cut -d ' ' -f 6)
volumestep=3
volume=$getcurrentvolume

if [ $volume -gt 0 ];then
	volume=$(echo `expr $volume - $volumestep`)
	volumedown=$volume
	amixer -q set Speaker $volumedown
fi

