#!/bin/sh
. /usr/autodl/testplayer
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

cd $paudiopath/$paudioname

if [ -e /tmp/myatdl.play.list ];then
	rm /tmp/myatdl.play.list
fi

if [ ! "$testplayer" ];then
	find $paudiopath/$paudioname/*.mp3 > /tmp/myatdl.play.list
	getfiles="/tmp/myatdl.play.list"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		curl -s $(cat $getfiles | head -n 1) --connect-timeout 5  | mpg123 --timeout 2 --no-resync -
		sed "1d" -i ${getfiles}
	done
else
	find $paudiopath/$paudioname/*.mp3 > /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.m4a >> /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.aac >> /tmp/myatdl.play.list
	getfiles="/tmp/myatdl.play.list"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		gst-play-1.0 -q $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
fi

rm /tmp/myatdl.play.list
