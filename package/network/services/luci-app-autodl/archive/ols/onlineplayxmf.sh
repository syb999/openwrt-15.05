#!/bin/sh

clientid=$(uci get autodl.@autodl[0].olcid)
if [ $? -eq 1 ];then
	ramnum=$(head -n 128 /dev/urandom | tr -dc "123456789" | head -c8)
	uci set autodl.@autodl[0].olcid="id$ramnum"
	uci commit autodl
	clientid="id$ramnum"
fi

olip=$(uci get autodl.@autodl[0].olip)
olp1=$(uci get autodl.@autodl[0].olp1)
olp2=$(uci get autodl.@autodl[0].olp2)
olalbumid=$(uci get autodl.@autodl[0].olalbumid | sed "s/\/$//" | sed 's/album\//^/' | cut -d '^' -f 2)
olpagenums=$(uci get autodl.@autodl[0].olpagenums)
olpagenume=$(expr $(uci get autodl.@autodl[0].olpagenume) \* 30)
filecount=$olpagenums
failcount=1
syncswitch=on

rm /tmp/pidfind.onlineplay /tmp/filecount.onlineplay

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

while true
do
	echo $filecount > /tmp/filecount.onlineplay
	curl -s $olip:$olp1/playfree/$olalbumid:$olpagenums:$olpagenume:$clientid
	sleep 3
	wget-ssl --timeout=3 $olip:$olp2/onlineplay/online-$clientid-$filecount.mp3 -O /tmp/online$filecount.mp3
	getfile="/tmp/online$filecount.mp3"
	while [ ! -s "$getfile" ]
	do
		sleep 6
		wget-ssl --timeout=3 $olip:$olp2/onlineplay/online-$clientid-$filecount.mp3 -O /tmp/online$filecount.mp3
		failcount=$(expr $failcount + 1)
		if [ $failcount -gt 200 ];then
			break 2
		fi
	done

	if [ $syncswitch = "on" ];then
		getminnow=$(date +%M)
		getasec=$(expr $(date +%S) + $filecount)

		if [ $getasec -lt 60 ];then
			getminnew=$(expr $getminnow + 1)
			if [ $getminnew -ge 60 ];then
				getminnew=$(expr $getminnew - 60)
			fi
		else
			getminnew=$(expr $getminnow + 2)
			if [ $getminnew -ge 60 ];then
				getminnew=$(expr $getminnew - 60)
			fi
		fi

		while [ $(date +%M) -ne $(expr $getminnew) ];do
			sleep 1
		done
		syncswitch="off"
		logger -t onlineplay 同步播放时间：$(date +%Y年%m月%d日%H:%M:%S)
	fi

	if [ ! -f "/tmp/pidfind.onlineplay" ];then
		busybox ps | grep mpg123 | grep -v grep > /tmp/pidfind.onlineplay
		/usr/autodl/ols/dompg123.sh &
	else
		testmpg123=$(busybox ps | grep mpg123 | grep -v grep | grep root)
		while [ "$testmpg123" != "" ];do
			sleep 1
			testmpg123=$(busybox ps | grep mpg123 | grep -v grep | grep root)
		done
		/usr/autodl/ols/dompg123.sh &
	fi
		
	sleep 1
	curl -s $olip:$olp1/playrm/$filecount:$clientid
	failcount=1
	rm /tmp/online$filecount.mp3
	filecount=$(expr $filecount + 1)
	olpagenums=$filecount
	sleep 1
	if [ "$olpagenums" -eq "$olpagenume" ];then
		rm /tmp/pidfind.onlineplay /tmp/filecount.onlineplay
		break
	fi
done

