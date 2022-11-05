#!/bin/sh
. /usr/autodl/stopmp3.sh
. /usr/autodl/testplayer
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

stopaudio

ps | grep playnext.sh | grep -v grep | cut -d 'r' -f 1 > /tmp/tmpmpg123.pid

cd $paudiopath/$paudioname
if [ ! "$testplayer" ];then
	getfiles="/tmp/pdtmp.playnext"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		sed "1d" -i ${getfiles}
		mpg123 $(cat $getfiles | head -n 1)
	done
else
	getfiles="/tmp/pdtmp.playnext"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		sed "1d" -i ${getfiles}
		gst-play-1.0 $(cat $getfiles | head -n 1)
	done
fi
