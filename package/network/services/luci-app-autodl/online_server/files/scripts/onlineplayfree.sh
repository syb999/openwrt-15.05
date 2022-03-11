#!/bin/sh

theparam=$(echo $1 | sed 's/%3A/:/;s/%3a/:/' )
thealbumid=$(echo $theparam | cut -d ':' -f 1 )
pagenums=$(echo $theparam | cut -d ':' -f 2)
pagenume=$(echo $theparam | cut -d ':' -f 3)
kcount=1

mkdir /tmp/onlineplay
ln -s /tmp/onlineplay /www

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

urlprefix="https://www.ximalaya.com/revision/play/v1/audio?id="
urlsuffix="&ptype=1"

function gettmpm4a() {
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $weburl > /tmp/online.tmpXM.newlist
	cat /tmp/online.tmpXM.newlist | sed 's/\/sound\//\n/g' | sed '1d' | cut -d '"' -f 1 > /tmp/online.tmpXM.newlist2
	cat /tmp/online.tmpXM.newlist | sed 's/\"title\"/\n/g' | sed '1d' | cut -d '"' -f 2 | sed 's/[ ][ ]*/-/g' | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g'  | sed -e 's/\ /-/g' | sed -e 's/|/-/g'  > /tmp/online.tmpXM.filenamelist
	cat /tmp/online.tmpXM.newlist | sed 's/\"index\":/\n/g' | sed '1d'| cut -d ',' -f 1 > /tmp/online.tmpXM.newlist3
	cat /tmp/online.tmpXM.newlist2 | while read LINE
	do
		xmlytrackId=$(echo $LINE)
		adurlprefix=$urlprefix
		adurlsuffix=$urlsuffix
		tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 http://www.ximalaya.com/revision/time > /tmp/online.tmp.XM.xmtimestamp
		xmtimestamp=$(cat /tmp/online.tmp.XM.xmtimestamp)
		xmvvmd5=$(echo himalaya-$xmtimestamp)
		echo -n $xmvvmd5 | md5sum > /tmp/online.tmp.XM.md5s
		cat /tmp/online.tmp.XM.md5s | cut -d ' ' -f 1 > /tmp/online.tmp.XM.md5ss
		xmsign1=$(cat /tmp/online.tmp.XM.md5ss)
		head -n 128 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/online.tmp.XM.randum1
		rnum1=\($(cat /tmp/online.tmp.XM.randum1)\)
		head -n 128 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/online.tmp.XM.randum2
		rnum2=\($(cat /tmp/online.tmp.XM.randum2)\)
		head -n 128 /dev/urandom | tr -dc "012345" | head -c3 > /tmp/online.tmp.XM.randum3
		bnum=$(cat /tmp/online.tmp.XM.randum3)
		date +"%s" > /tmp/online.tmp.XM.datelst
		optimestamp=$(cat /tmp/online.tmp.XM.datelst)
		cxmsign=${xmsign1}${rnum1}${xmtimestamp}${rnum2}${optimestamp}${bnum}
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""xm-sign": "$cxmsign"" $tmpgetaudiourl > /tmp/online.tmpXM.xmlyhttp6
		sleep 1
		tmpaudio=$(cat /tmp/online.tmpXM.xmlyhttp6)
		echo ${tmpaudio#*src\":\"} > /tmp/online.tmpXM.xmlyhttp7
		tmpaudio=$(cat /tmp/online.tmpXM.xmlyhttp7)
		echo ${tmpaudio%\",\"albumIsSample*} > /tmp/online.tmpXM.xmlyhttp8
		audiofile=$(cat /tmp/online.tmpXM.xmlyhttp8)
		wget-ssl --timeout=3 $audiofile -O /tmp/tmpplay.m4a
		ffmpeg -y -i /tmp/tmpplay.m4a -acodec libmp3lame /tmp/tmpplay.mp3 >/dev/null 2>&1
	done
	rm /tmp/online.tmpXM.*
}

for i in $(seq $pagenums $pagenume);do
	weburl="https://www.ximalaya.com/revision/album/v1/getTracksList?albumId=$thealbumid&pageNum=$i&pageSize=1&sort=1"
	gettmpm4a
	mv /tmp/tmpplay.mp3 /tmp/onlineplay/online$kcount.mp3
	rm /tmp/tmpplay.m4a
	kcount=$(expr $kcount + 1)
	if [ $kcount -eq 4 ];then
		kcount=1
	fi
	while [ $(ls /tmp/onlineplay/*.mp3 | wc -l) -gt 3 ]
	do
		sleep 5
	done
done

