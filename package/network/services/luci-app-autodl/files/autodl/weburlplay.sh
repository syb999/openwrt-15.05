#!/bin/sh

urlselected=$(uci get autodl.@autodl[0].wbaudurl)

testplayer=$(opkg list-installed | grep "gst-play-1.0")

if [ ! "$testplayer" ];then
	testplayer=$(opkg list-installed | grep "mpg123")
	if [ ! "$testplayer" ];then
		echo "No player. Stop script."
	else
		mpg123 -q -i $urlselected
	fi
else
	gst-play-1.0 -q $urlselected
fi

