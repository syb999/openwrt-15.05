#!/bin/sh

paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)
mp3selected=$(uci get autodl.@autodl[0].audio_num)

testplayer=$(opkg list-installed | grep "gst-play-1.0")

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
	testplayer=$(opkg list-installed | grep "mpg123")
	if [ ! "$testplayer" ];then
		echo "No player. Stop script."
	else
		cat /tmp/tmp.Audioxm.xlistx | while read LINE
		do
			currentmp3=$(echo $LINE)
			mpg123 -q -i $currentmp3
		done
	fi
else
	cat /tmp/tmp.Audioxm.xlistx | while read LINE
	do
		currentmp3=$(echo $LINE)
		gst-play-1.0 -q $currentmp3
	done
fi

rm /tmp/tmp.Audioxm.*
