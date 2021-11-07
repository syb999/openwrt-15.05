#!/bin/sh
. /usr/autodl/stopmp3.sh

stopaudio

testplayer=$(opkg list-installed | grep "gst-play-1.0")

if [ ! "$testplayer" ];then
	testplayer=$(opkg list-installed | grep "mpg123")
	if [ ! "$testplayer" ];then
		echo "No player. Stop script."
	else
		ps | grep playnext.sh | grep -v grep | cut -d 'r' -f 1 > /tmp/tmpmpg123.playnext
		getfiles="/tmp/pdtmp.playnext"
		countfiles=$(awk 'END{print NR}' $getfiles)
		for i in $(seq 1 $countfiles)
		do
			sed "1d" -i ${getfiles}
			mpg123 -q -i $(cat $getfiles | head -n 1)
		done
	fi
else
	ps | grep playnext.sh | grep -v grep | cut -d 'r' -f 1 > /tmp/tmpmpg123.playnext
	getfiles="/tmp/pdtmp.playnext"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		sed "1d" -i ${getfiles}
		gst-play-1.0 -q $(cat $getfiles | head -n 1)
	done
fi
