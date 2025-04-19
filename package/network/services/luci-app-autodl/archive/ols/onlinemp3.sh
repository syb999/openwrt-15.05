#!/bin/sh

name=$(uci get autodl.@autodl[0].xmlyname)
paudiopath=$(uci get autodl.@autodl[0].xmlypath)
olip=$(uci get autodl.@autodl[0].olip)
olp1=$(uci get autodl.@autodl[0].olp1)
olp2=$(uci get autodl.@autodl[0].olp2)

localip=$(ubus call network.interface.wan status |grep address | grep -v ipv | grep -v addresses | head -n1 | cut -d '"' -f 4)
localport=$(uci get uhttpd.main.listen_http | awk '/0.0.0.0/ {print $1}' | cut -d ':' -f 2)
localddns=$(uci get ddns.myddns_ipv4.domain)

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

ls $paudiopath/$name | grep ".m4a" > /tmp/tmp.xm.filelist

mkdir /tmp/tmptmp
rm /www/tmptmp /tmp/tmptmp/tmpradio.m4a

cat /tmp/tmp.xm.filelist | while read LINE
do
	mp3name=$(echo $LINE | sed 's/m4a$/mp3/g')
	mv $paudiopath/$name/$LINE /tmp/tmptmp/tmpradio.m4a
	ln -s /tmp/tmptmp /www
	if [ $localddns != "yourhost.example.com" ];then
		ping -c 2 $localddns >/dev/null 2>&1
		if [ $? -eq 1 ];then
			curl -s $olip:$olp1/m4atomp3/$localip:$localport
		else
			curl -s $olip:$olp1/m4atomp3/$localddns:$localport
		fi
	else
		curl -s $olip:$olp1/m4atomp3/$localip:$localport
	fi

	sleep 16

	remotefile="/tmp/tmpradio.mp3"
	while [ ! -s "$remotefile" ]
	do
		sleep 5
		wget-ssl --timeout=3 -q $olip:$olp2/tmptmp/tmpradio.mp3 -O /tmp/tmpradio.mp3
	done

	mv $remotefile $paudiopath/$name/$mp3name
	rm /tmp/tmptmp/tmpradio.m4a
done

rm /tmp/tmp.xm.filelist

