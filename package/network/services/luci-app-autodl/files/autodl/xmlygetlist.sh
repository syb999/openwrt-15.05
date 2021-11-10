#!/bin/sh
. /usr/autodl/testplayer
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

cd $paudiopath/$paudioname

if [ -e /tmp/tmp.Audioxm.list ];then
	rm /tmp/tmp.Audioxm.list
fi

if [ ! "$testplayer" ];then
	find $paudiopath/$paudioname/*.mp3 > /tmp/tmp.Audioxm.list
else
	find $paudiopath/$paudioname/*.mp3 > /tmp/tmp.Audioxm.list
	find $paudiopath/$paudioname/*.m4a >> /tmp/tmp.Audioxm.list
	find $paudiopath/$paudioname/*.aac >> /tmp/tmp.Audioxm.list
fi
