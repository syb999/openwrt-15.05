#!/bin/sh
. /usr/autodl/testplayer
urlselected=$(uci get autodl.@autodl[0].wbaudurl)

if [ ! "$testplayer" ];then
	while [ ! -n "$(ps -w | grep mpg123 | grep -v grep | awk '{print$1}')"  ];do
		curl -s $urlselected  --connect-timeout 5  | mpg123 --timeout 2 --no-resync - &
		sleep 2
		while [ ! -n "$(ps -w | grep mpg123 | grep -v grep | awk '{print$1}')" ];do
			kill -9 "$(ps -w | grep curl | grep -v grep | awk '{print$1}')"
		done
		sleep 1
	done
else
	gst-play-1.0 $urlselected
fi
