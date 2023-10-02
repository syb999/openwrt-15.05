#!/bin/sh
. /usr/autodl/stopmp3.sh
. /usr/autodl/testplayer
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

stopaudio

ps -w | grep playnext.sh | grep -v grep | awk '{print$1}' > /tmp/tmpmpg123.pid

cd $paudiopath/$paudioname
if [ ! "$testplayer" ];then
	getfiles="/tmp/pdtmp.playnext"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		sed "1d" -i ${getfiles}
		curl -s $(cat $getfiles | head -n 1) --connect-timeout 5  | mpg123 --timeout 2 --no-resync -
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
