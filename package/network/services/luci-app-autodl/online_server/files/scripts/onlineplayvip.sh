#!/bin/sh

theparam=$(echo $1 | sed 's/%3A/:/;s/%3a/:/' )
thealbumid=$(echo $theparam | cut -d ':' -f 1 )
pagenums=$(echo $theparam | cut -d ':' -f 2)

mkdir /tmp/onlineplay
ln -s /tmp/onlineplay /www

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

urlprefix="https://mpay.ximalaya.com/mobile/track/pay/"

function gettmpm4a(){
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 http://www.ximalaya.com/revision/time > /tmp/online.tmp.XMV.xmtimestamp
	xmtimestamp=$(cat /tmp/online.tmp.XMV.xmtimestamp)
	urlsuffix="/ts-${xmtimestamp}/?device=pc"

	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $weburl > /tmp/online.tmp.XMV.newlist
	cat /tmp/online.tmp.XMV.newlist | sed 's/\/sound\//\n/g' | sed '1d' | cut -d '"' -f 1 > /tmp/online.tmp.XMV.newlist2
	cat /tmp/online.tmp.XMV.newlist | sed 's/\"title\"/\n/g' | sed '1d' | cut -d '"' -f 2 | sed 's/[ ][ ]*/-/g' | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g'  | sed -e 's/\ /-/g' | sed -e 's/|/-/g'  > /tmp/online.tmp.XMV.filenamelist
	cat /tmp/online.tmp.XMV.newlist | sed 's/\"index\":/\n/g' | sed '1d'| cut -d ',' -f 1 > /tmp/online.tmp.XMV.newlist3
	cat /tmp/online.tmp.XMV.newlist2 | while read LINE
	do
		xmlytrackId=$(echo $LINE)
		adurlprefix=$urlprefix
		adurlsuffix=$urlsuffix
		tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"

		if [ ! "$paudiocookie" ];then
			curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0\ \(Linux\;\ Android\ 10\)"" -v $tmpgetaudiourl > /tmp/online.tmpXMVIP.xmlyhttp6
		else
			sleep $psleeptime
			xmlycookieprefix="1&_token="
			xmlycookie="${xmlycookieprefix}${paudiocookie}"
			curl -b "$xmlycookie" -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" -v $tmpgetaudiourl > /tmp/online.tmpXMVIP.xmlyhttp6
		fi

		xmlyfindcode=$(cat /tmp/online.tmpXMVIP.xmlyhttp6)
		echo ${xmlyfindcode#*ep\":\"} > /tmp/online.tmpXMVIP.xmlyep1
		xmlyfindepcode=$(cat /tmp/online.tmpXMVIP.xmlyep1)
		echo ${xmlyfindepcode%\",\"highest*} > /tmp/online.tmpXMVIP.xmlyep2
		xmlynewepcode=$(cat /tmp/online.tmpXMVIP.xmlyep2)

		echo ${xmlyfindcode#*fileId\":\"} > /tmp/online.tmpXMVIP.xmlypath1
		xmlyfindpathcode=$(cat /tmp/online.tmpXMVIP.xmlypath1)
		echo ${xmlyfindpathcode%\",\"buyKey*} > /tmp/online.tmpXMVIP.xmlypath2
		xmlynewpathcode=$(cat /tmp/online.tmpXMVIP.xmlypath2)

		echo ${xmlyfindcode#*seed\":} > /tmp/online.tmpXMVIP.xmlyseed1
		xmlyfindseedcode=$(cat /tmp/online.tmpXMVIP.xmlyseed1)
		echo ${xmlyfindseedcode%,\"fileId*} > /tmp/online.tmpXMVIP.xmlyseed2
		xmlynewseedcode=$(cat /tmp/online.tmpXMVIP.xmlyseed2)

		echo ${xmlyfindcode#*duration\":} > /tmp/online.tmpXMVIP.xmlyduration1
		xmlyfinddurationcode=$(cat /tmp/online.tmpXMVIP.xmlyduration1)
		echo ${xmlyfinddurationcode%,\"ep*} > /tmp/online.tmpXMVIP.xmlyduration2
		xmlynewdurationcode=$(cat /tmp/online.tmpXMVIP.xmlyduration2)

		epathtxtp1="var c = bt(\""
		epathtxtp2=$xmlynewepcode
		epathtxtp3="\")"
		epathtxt=${epathtxtp1}${epathtxtp2}${epathtxtp3}
		sed -i '$d' /usr/autodl/ep.js
		echo $epathtxt >> /usr/autodl/ep.js
		node /usr/autodl/ep.js > /tmp/online.tmpXMVIP.xmlyVIPCODE
		sleep 3

		cpathtxtp1="console.log(c("
		cpathtxtp2=$xmlynewseedcode
		cpathtxtp3=",\""
		cpathtxtp4=$xmlynewpathcode
		cpathtxtp5="\"))"
		cpathtxt=${cpathtxtp1}${cpathtxtp2}${cpathtxtp3}${cpathtxtp4}${cpathtxtp5}
		sed -i '$d' /usr/autodl/path.js
		echo $cpathtxt >> /usr/autodl/path.js
		node /usr/autodl/path.js > /tmp/online.tmpXMVIP.xmlyVIPPATH
		sleep 3

		cat /tmp/online.tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 2 > /tmp/online.tmpXMVIP.xmlyVIPbuykey
		xmlybuykey=$(cat /tmp/online.tmpXMVIP.xmlyVIPbuykey)
		cat /tmp/online.tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 4 > /tmp/online.tmpXMVIP.xmlyVIPsign
		xmlysign=$(cat /tmp/online.tmpXMVIP.xmlyVIPsign)
		cat /tmp/online.tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 6 > /tmp/online.tmpXMVIP.xmlyVIPtoken
		xmlytoken=$(cat /tmp/online.tmpXMVIP.xmlyVIPtoken)
		cat /tmp/online.tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 8 > /tmp/online.tmpXMVIP.xmlyVIPtimestamp
		xmlytimestamp=$(cat /tmp/online.tmpXMVIP.xmlyVIPtimestamp)

		xmlyvipaudioprefix="https://audiopay.cos.tx.xmcdn.com/download/1.0.0"
		xmlyvipaudiopath=$(cat /tmp/online.tmpXMVIP.xmlyVIPPATH)
		xmlyvipaudiosuffixbuykey="?buy_key="
		xmlyvipaudiosuffixsign="&sign="
		xmlyvipaudiosuffixtoken="&token="
		xmlyvipaudiosuffixtimestamp="&timestamp="
		xmlyvipaudiosuffixduration="&duration="

		xmlyvipaudiorealurl=${xmlyvipaudioprefix}${xmlyvipaudiopath}${xmlyvipaudiosuffixbuykey}${xmlybuykey}${xmlyvipaudiosuffixsign}${xmlysign}${xmlyvipaudiosuffixtoken}${xmlytoken}${xmlyvipaudiosuffixtimestamp}${xmlytimestamp}${xmlyvipaudiosuffixduration}${xmlynewdurationcode}
		wget-ssl --timeout=3 $xmlyvipaudiorealurl -O /tmp/tmpplay.m4a
		ffmpeg -y -i /tmp/tmpplay.m4a -acodec libmp3lame /tmp/tmpplay.mp3 >/dev/null 2>&1
	done
	rm /tmp/online.tmpXMVIP.* /tmp/online.tmp.XMV.*
}

for i in $(seq $pagenums $(expr $pagenums + 1));do
	weburl="https://www.ximalaya.com/revision/album/v1/getTracksList?albumId=$thealbumid&pageNum=$i&pageSize=1"
	gettmpm4a
	if [ ! -f "/tmp/onlineplay/online$pagenums.mp3" ];then
		mv /tmp/tmpplay.mp3 /tmp/onlineplay/online$pagenums.mp3
	else
		mv /tmp/tmpplay.mp3 /tmp/onlineplay/online$(expr $pagenums + 1).mp3
	fi
	rm /tmp/tmpplay.m4a
	while [ $(ls /tmp/onlineplay/*.mp3 | wc -l) -gt 2 ]
	do
		sleep 5
		rm $(ls /tmp/onlineplay/*.mp3 | grep -v online$pagenums.mp3 | grep -v online$(expr $pagenums + 1).mp3)
	done
done

