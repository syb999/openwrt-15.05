#!/bin/sh

testplayer=$(opkg list-installed | grep "gst-play-1.0")

if [ ! "$testplayer" ];then
	pidof mpg123 > /tmp/tmpplayer.tmp
	runmpg123=$(cat /tmp/tmpplayer.tmp)
	kill $runmpg123 > /dev/null 2>&1
else
	pidof gst-play-1.0 > /tmp/tmpplayer.tmp
	rungst=$(cat /tmp/tmpplayer.tmp)
	kill $rungst > /dev/null 2>&1
fi

rm /tmp/tmpplayer.*
