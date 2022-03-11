#!/bin/sh

urlprefix="https://www.ximalaya.com/revision/play/v1/audio?id="
urlsuffix="&ptype=1"
albumidlist="8125936 11676889 8424399 4904372 5411224 47885599 246622"

function gettmpm4a() {
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $weburl > /tmp/tmpXM.newlist
	cat /tmp/tmpXM.newlist | sed 's/\/sound\//\n/g' | sed '1d' | cut -d '"' -f 1 > /tmp/tmpXM.newlist2
	cat /tmp/tmpXM.newlist | sed 's/\"title\"/\n/g' | sed '1d' | cut -d '"' -f 2 | sed 's/[ ][ ]*/-/g' | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g'  | sed -e 's/\ /-/g' | sed -e 's/|/-/g'  > /tmp/tmpXM.filenamelist
	cat /tmp/tmpXM.newlist | sed 's/\"index\":/\n/g' | sed '1d'| cut -d ',' -f 1 > /tmp/tmpXM.newlist3
	cat /tmp/tmpXM.newlist2 | while read LINE
	do
		xmlytrackId=$(echo $LINE)
		adurlprefix=$urlprefix
		adurlsuffix=$urlsuffix
		tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 http://www.ximalaya.com/revision/time > /tmp/tmp.XM.xmtimestamp
		xmtimestamp=$(cat /tmp/tmp.XM.xmtimestamp)
		xmvvmd5=$(echo himalaya-$xmtimestamp)
		echo -n $xmvvmd5 | md5sum > /tmp/tmp.XM.md5s
		cat /tmp/tmp.XM.md5s | cut -d ' ' -f 1 > /tmp/tmp.XM.md5ss
		xmsign1=$(cat /tmp/tmp.XM.md5ss)
		head -n 128 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/tmp.XM.randum1
		rnum1=\($(cat /tmp/tmp.XM.randum1)\)
		head -n 128 /dev/urandom | tr -dc "123456789" | head -c2 > /tmp/tmp.XM.randum2
		rnum2=\($(cat /tmp/tmp.XM.randum2)\)
		head -n 128 /dev/urandom | tr -dc "012345" | head -c3 > /tmp/tmp.XM.randum3
		bnum=$(cat /tmp/tmp.XM.randum3)
		date +"%s" > /tmp/tmp.XM.datelst
		optimestamp=$(cat /tmp/tmp.XM.datelst)
		cxmsign=${xmsign1}${rnum1}${xmtimestamp}${rnum2}${optimestamp}${bnum}
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""xm-sign": "$cxmsign"" $tmpgetaudiourl > /tmp/tmpXM.xmlyhttp6
		sleep 1
		tmpaudio=$(cat /tmp/tmpXM.xmlyhttp6)
		echo ${tmpaudio#*src\":\"} > /tmp/tmpXM.xmlyhttp7
		tmpaudio=$(cat /tmp/tmpXM.xmlyhttp7)
		echo ${tmpaudio%\",\"albumIsSample*} > /tmp/tmpXM.xmlyhttp7
		audiofile=$(cat /tmp/tmpXM.xmlyhttp7)
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.XM.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.XM.testwget ];then
			wget-ssl -q -c $audiofile -O tmpplay_$(date +%H%M%S).m4a
		else
			wget -q -c $audiofile -O tmpplay_$(date +%H%M%S).m4a
		fi
		sleep 3
		rm /tmp/tmp.XM.*
	done
	rm /tmp/tmpXM.*
}



for i in $albumidlist;do
	weburl="https://www.ximalaya.com/revision/album/v1/getTracksList?albumId=$i&pageNum=1&pageSize=1&sort=1"
	gettmpm4a
done

