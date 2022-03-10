#!/bin/sh

m4aurl=$(echo $1 | sed 's/%3A/:/;s/%3a/:/' )
remoteip=$(echo $m4aurl | cut -d ':' -f 1 )
remoteport=$(echo $m4aurl | cut -d ':' -f 2)

mkdir /tmp/tmptmp
rm /www/tmptmp
rm /tmp/tmptmp/tmpradio.m4a /tmp/tmptmp/tmpradio.mp3

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

sleep 3

remotefile="/tmp/tmptmp/tmpradio.m4a"
while [ ! -s "$remotefile" ]
do
	sleep 5
	wget-ssl --timeout=3 -q $remoteip:$remoteport/tmptmp/tmpradio.m4a -O /tmp/tmptmp/tmpradio.m4a
done

ffmpeg -y -i $remotefile -acodec libmp3lame /tmp/tmpradio.mp3 >/dev/null 2>&1
mv /tmp/tmpradio.mp3 /tmp/tmptmp/tmpradio.mp3
ln -s /tmp/tmptmp /www

