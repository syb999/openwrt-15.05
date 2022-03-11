#!/bin/sh

olip=$(uci get autodl.@autodl[0].olip)
olp1=$(uci get autodl.@autodl[0].olp1)
olp2=$(uci get autodl.@autodl[0].olp2)
olalbumid=$(uci get autodl.@autodl[0].olalbumid | sed "s/\/$//" | sed 's/album\//^/' | cut -d '^' -f 2)
olpagenums=$(uci get autodl.@autodl[0].olpagenums)
olpagenume=$(expr $(uci get autodl.@autodl[0].olpagenume) \* 30)

failcount=1

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

while true
do
	curl -s $olip:$olp1/playfree/$olalbumid:$olpagenums:$olpagenume
	sleep 3
	for p in $(seq 1 3);do
		sleep 3
		wget-ssl --timeout=3 $olip:$olp2/onlineplay/online$p.mp3 -O /tmp/online.mp3
		getfile="/tmp/online$adcount.mp3"
		while [ ! -s "$getfile" ]
		do
			sleep 6
			wget-ssl --timeout=3 $olip:$olp2/onlineplay/online$p.mp3 -O /tmp/online.mp3
			failcount=$(expr $failcount + 1)
			if [ $failcount -gt 30 ];then
				echo $failcount
				break 2
			fi
		done
		mpg123 /tmp/online.mp3
		sleep 1
	done
	curl -s $olip:$olp1/playrm/clear
	failcount=1
	olpagenums=$(expr $olpagenums + 1)
	sleep 1
done

