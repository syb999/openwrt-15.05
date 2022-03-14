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

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

while true
do
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
	mpg123 /tmp/online$filecount.mp3
	sleep 1
	curl -s $olip:$olp1/playrm/$filecount:$clientid
	failcount=1
	rm /tmp/online$filecount.mp3
	filecount=$(expr $filecount + 1)
	olpagenums=$filecount
	sleep 1
	if [ "$olpagenums" -eq "$olpagenume" ];then
		break
	fi
done

