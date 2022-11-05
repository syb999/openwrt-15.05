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
	sed '1!G;h;$!d' /tmp/myatdl.play.list > /tmp/myatdl.xplay.list
	getfiles="/tmp/myatdl.xplay.list"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		mpg123 $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
else
	find $paudiopath/$paudioname/*.mp3 > /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.m4a >> /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.aac >> /tmp/myatdl.play.list
	sed '1!G;h;$!d' /tmp/myatdl.play.list > /tmp/myatdl.xplay.list
	getfiles="/tmp/myatdl.xplay.list"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		gst-play-1.0 $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
fi

rm /tmp/myatdl.play.list /tmp/myatdl.xplay.list
