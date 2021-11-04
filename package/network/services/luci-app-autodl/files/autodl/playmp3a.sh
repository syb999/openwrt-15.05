#!/bin/sh

paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

testplayer=$(opkg list-installed | grep "gst-play-1.0")

cd $paudiopath/$paudioname

if [ -e /tmp/myatdl.play.list ];then
	rm /tmp/myatdl.play.list
fi

if [ ! "$testplayer" ];then
	testplayer=$(opkg list-installed | grep "mpg123")
	if [ ! "$testplayer" ];then
		echo "No player. Stop script."
	else
		find $paudiopath/$paudioname/*.mp3 > /tmp/myatdl.play.list
		cat /tmp/myatdl.play.list | while read LINE
		do
			currentmp3=$(echo $LINE)
			mpg123 -q -i $currentmp3
		done
	fi
else
	find $paudiopath/$paudioname/*.mp3 > /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.m4a >> /tmp/myatdl.play.list
	find $paudiopath/$paudioname/*.aac >> /tmp/myatdl.play.list
	cat /tmp/myatdl.play.list | while read LINE
	do
		currentmp3=$(echo $LINE)
		gst-play-1.0 -q $currentmp3
	done
fi

rm /tmp/myatdl.play.list
