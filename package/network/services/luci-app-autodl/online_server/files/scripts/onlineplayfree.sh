#!/bin/sh

theparam=$(echo $1 | sed 's/%3A/:/;s/%3a/:/' )
thealbumid=$(echo $theparam | cut -d ':' -f 1 )
pagenums=$(echo $theparam | cut -d ':' -f 2)
clientid=$(echo $theparam | cut -d ':' -f 4)

mkdir /tmp/onlineplay
ln -s /tmp/onlineplay /www

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

urlprefix="https://www.ximalaya.com/revision/play/v1/audio?id="
urlsuffix="&ptype=1"

function gettmpm4a() {
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $weburl > /tmp/online.$clientid.tmpXM.newlist
	cat /tmp/online.$clientid.tmpXM.newlist | sed 's/\/sound\//\n/g' | sed '1d' | cut -d '"' -f 1 > /tmp/online.$clientid.tmpXM.newlist2
	cat /tmp/online.$clientid.tmpXM.newlist | sed 's/\"title\"/\n/g' | sed '1d' | cut -d '"' -f 2 | sed 's/[ ][ ]*/-/g' | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g'  | sed -e 's/\ /-/g' | sed -e 's/|/-/g'  > /tmp/online.$clientid.tmpXM.filenamelist
	cat /tmp/online.$clientid.tmpXM.newlist | sed 's/\"index\":/\n/g' | sed '1d'| cut -d ',' -f 1 > /tmp/online.$clientid.tmpXM.newlist3
	cat /tmp/online.$clientid.tmpXM.newlist2 | while read LINE
	do
		xmlytrackId=$(echo $LINE)
		adurlprefix=$urlprefix
		adurlsuffix=$urlsuffix
		tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 http://www.ximalaya.com/revision/time > /tmp/online.$clientid.tmp.XM.xmtimestamp
		xmtimestamp=$(cat /tmp/online.$clientid.tmp.XM.xmtimestamp)
		xmvvmd5=$(echo himalaya-$xmtimestamp)
		echo -n $xmvvmd5 | md5sum > /tmp/online.$clientid.tmp.XM.md5s
		cat /tmp/online.$clientid.tmp.XM.md5s | cut -d ' ' -f 1 > /tmp/online.$clientid.tmp.XM.md5ss
		xmsign1=$(cat /tmp/online.$clientid.tmp.XM.md5ss)
		head -n6 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/online.$clientid.tmp.XM.randum1
		rnum1=\($(cat /tmp/online.$clientid.tmp.XM.randum1)\)
		head -n6 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/online.$clientid.tmp.XM.randum2
		rnum2=\($(cat /tmp/online.$clientid.tmp.XM.randum2)\)
		head -n6 /dev/urandom | tr -dc "012345" | head -c3 > /tmp/online.$clientid.tmp.XM.randum3
		bnum=$(cat /tmp/online.$clientid.tmp.XM.randum3)
		date +"%s" > /tmp/online.$clientid.tmp.XM.datelst
		optimestamp=$(cat /tmp/online.$clientid.tmp.XM.datelst)
		cxmsign=${xmsign1}${rnum1}${xmtimestamp}${rnum2}${optimestamp}${bnum}
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""xm-sign": "$cxmsign"" $tmpgetaudiourl > /tmp/online.$clientid.tmpXM.xmlyhttp6
		sleep 1
		tmpaudio=$(cat /tmp/online.$clientid.tmpXM.xmlyhttp6)
		echo ${tmpaudio#*src\":\"} > /tmp/online.$clientid.tmpXM.xmlyhttp7
		tmpaudio=$(cat /tmp/online.$clientid.tmpXM.xmlyhttp7)
		echo ${tmpaudio%\",\"albumIsSample*} > /tmp/online.$clientid.tmpXM.xmlyhttp8
		audiofile=$(cat /tmp/online.$clientid.tmpXM.xmlyhttp8)
		wget-ssl --timeout=3 $audiofile -O /tmp/tmpplay-$clientid.m4a
		ffmpeg -y -i /tmp/tmpplay-$clientid.m4a -acodec libmp3lame /tmp/tmpplay-$clientid.mp3 >/dev/null 2>&1
	done
	rm /tmp/online.$clientid.tmpXM.* /tmp/online.$clientid.tmp.XM.*
}

for i in $(seq $pagenums $(expr $pagenums + 1));do
	weburl="https://www.ximalaya.com/revision/album/v1/getTracksList?albumId=$thealbumid&pageNum=$i&pageSize=1&sort=1"
	gettmpm4a
	if [ ! -f "/tmp/onlineplay/online-$clientid-$pagenums.mp3" ];then
		mv /tmp/tmpplay-$clientid.mp3 /tmp/onlineplay/online-$clientid-$pagenums.mp3
	else
		mv /tmp/tmpplay-$clientid.mp3 /tmp/onlineplay/online-$clientid-$(expr $pagenums + 1).mp3
	fi
	rm /tmp/tmpplay-$clientid.m4a
	while [ $(ls /tmp/onlineplay/online-$clientid-*.mp3 | wc -l) -gt 2 ]
	do
		sleep 5
		rm $(ls /tmp/onlineplay/online-$clientid-*.mp3 | grep -v online-$clientid-$pagenums.mp3 | grep -v online-$clientid-$(expr $pagenums + 1).mp3)
	done
done

