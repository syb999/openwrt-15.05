#!/bin/sh
. /usr/autodl/testplayer
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)
mp3selected=$(uci get autodl.@autodl[0].audio_num)

cd $paudiopath/$paudioname

if [ -e /tmp/tmp.Audioxm.xlist ];then
	rm /tmp/tmp.Audioxm.xlist
fi

cat /tmp/tmp.Audioxm.list | head -1 > /tmp/tmp.Audioxm.listf
findmp3name=$(cat /tmp/tmp.Audioxm.listf)

if [ $mp3selected != $findmp3name ];then
	if [ ! "$testplayer" ];then
		find $paudiopath/$paudioname/*.mp3 > /tmp/tmp.Audioxm.xlist
	else
		find $paudiopath/$paudioname/*.mp3 > /tmp/tmp.Audioxm.xlist
		find $paudiopath/$paudioname/*.m4a >> /tmp/tmp.Audioxm.xlist
		find $paudiopath/$paudioname/*.aac >> /tmp/tmp.Audioxm.xlist
	fi
	grep -n $mp3selected /tmp/tmp.Audioxm.xlist | cut -d ':' -f 1 > /tmp/tmp.Audioxm.listn
	numname=$(cat /tmp/tmp.Audioxm.listn)
	numnamenew=$(echo `expr $numname - 1`)
	sed -i '1,'$numnamenew'd' /tmp/tmp.Audioxm.xlist
fi	

if [ -e /tmp/tmp.Audioxm.xlist ];then
	cp /tmp/tmp.Audioxm.xlist /tmp/tmp.Audioxm.xlistx
else
	cp /tmp/tmp.Audioxm.list /tmp/tmp.Audioxm.xlistx
fi

if [ ! "$testplayer" ];then
	getfiles="/tmp/tmp.Audioxm.xlistx"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		mpg123 -q $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
else
	getfiles="/tmp/tmp.Audioxm.xlistx"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		gst-play-1.0 -q $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
fi

rm /tmp/tmp.Audioxm.*
