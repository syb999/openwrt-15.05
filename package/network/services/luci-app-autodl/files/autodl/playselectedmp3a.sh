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
		find *.mp3 > /tmp/tmp.Audioxm.xlist
	else
		find *.mp3 > /tmp/tmp.Audioxm.xlist
		find *.m4a >> /tmp/tmp.Audioxm.xlist
		find *.aac >> /tmp/tmp.Audioxm.xlist
	fi
	grep -n $mp3selected /tmp/tmp.Audioxm.xlist | cut -d ':' -f 1 > /tmp/tmp.Audioxm.listn
	numname=$(cat /tmp/tmp.Audioxm.listn)
	numnamenew=$(echo `expr $numname - 1`)
	sed -i '1,'$numnamenew'd' /tmp/tmp.Audioxm.xlist
fi	

realpath="${paudiopath}/${paudioname}/"
if [ -e /tmp/tmp.Audioxm.xlist ];then
	sed -i "s/^/$realpath/" /tmp/tmp.Audioxm.xlist
 	cp /tmp/tmp.Audioxm.xlist /tmp/tmp.Audioxm.xlistx
else
	sed -i "s/^/$realpath/" /tmp/tmp.Audioxm.list
	cp /tmp/tmp.Audioxm.list /tmp/tmp.Audioxm.xlistx
fi

if [ ! "$testplayer" ];then
	getfiles="/tmp/tmp.Audioxm.xlistx"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		curl -s $(cat $getfiles | head -n 1) --connect-timeout 5  | mpg123 --timeout 2 --no-resync -
		sed "1d" -i ${getfiles}
	done
else
	getfiles="/tmp/tmp.Audioxm.xlistx"
	countfiles=$(awk 'END{print NR}' $getfiles)
	for i in $(seq 1 $countfiles)
	do
		cat $getfiles > /tmp/pdtmp.playnext
		gst-play-1.0 $(cat $getfiles | head -n 1)
		sed "1d" -i ${getfiles}
	done
fi

rm /tmp/tmp.Audioxm.*
