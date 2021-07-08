#!/bin/sh

paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)
mp3selected=$(uci get autodl.@autodl[0].audio_num)

if [ -e /tmp/tmp.Audioxm.xlist ];then
	rm /tmp/tmp.Audioxm.xlist
fi

cd $paudiopath/$paudioname
cat /tmp/tmp.Audioxm.list | head -1 > /tmp/tmp.Audioxm.listf
findmp3name=$(cat /tmp/tmp.Audioxm.listf)

if [ $mp3selected != $findmp3name ];then
	find *.mp3 > /tmp/tmp.Audioxm.list
	cp /tmp/tmp.Audioxm.list /tmp/tmp.Audioxm.xlist
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

testffmpeg=$(opkg list-installed | grep mpg123)

if [ ! "$testffmpeg" ];then
	echo "No mpg123. Stop script."
else
	cat /tmp/tmp.Audioxm.xlistx | while read LINE
	do
		currentmp3=$(echo $LINE)
		mpg123 -q -i $currentmp3
	done
fi

