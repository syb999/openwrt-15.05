#!/bin/sh

paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

testffmpeg=$(opkg list-installed | grep mpg123)

cd $paudiopath/$paudioname
find $paudiopath/$paudioname/*.mp3 > play.list

if [ ! "$testffmpeg" ];then
	echo "No mpg123. Stop script."
else
	cat play.list | while read LINE
	do
		currentmp3=$(echo $LINE)
		mpg123 -q -i $currentmp3
	done
fi
