#!/bin/sh

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

testffmpeg=$(opkg list-installed | grep mpg123)

if [ ! "$testffmpeg" ];then
	echo "No mpg123. Stop script."
else
	cd /$paudiopath
	find /$paudiopath/paudioname/*.mp3 > play.list
	mpg123 --list play.list
fi

