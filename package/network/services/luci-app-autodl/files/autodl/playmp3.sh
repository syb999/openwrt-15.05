#!/bin/sh

mp3path=$(uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path)
mp3name=$(uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name)

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

testffmpeg=$(opkg list-installed | grep mpg123)

cd /$paudiopath
find /$paudiopath/$paudioname/*.mp3 > play.list

if [ ! "$testffmpeg" ];then
	echo "No mpg123. Stop script."
else
	cat play.list | while read LINE
	do
		currentmp3=$(echo $LINE)
		mpg123 -i $currentmp3
	done
fi

