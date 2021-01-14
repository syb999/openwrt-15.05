#!/bin/sh

m4apath=$(uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path)
m4aname=$(uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name)

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

testffmpeg=$(opkg list-installed | grep mpg123)

if [ ! "$testffmpeg" ];then
	echo "No mpg123. Stop script."
else
	cd /$paudiopath
	find /$paudiopath/$paudioname/*.mp3 > play.list
	mpg123 --list play.list
fi


