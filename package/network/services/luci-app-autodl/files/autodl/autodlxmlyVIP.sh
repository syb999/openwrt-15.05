#!/bin/sh

function getxmlyaudios(){
	paudioname=$(uci get autodl.@autodl[0].xmlyname)
	paudiocookie=$(uci get autodl.@autodl[0].xmlycookie)
	paudionum=99
	rpaudionum=99
	paudiopath=$(uci get autodl.@autodl[0].xmlypath)
	psleeptime=$(uci get autodl.@autodl[0].xmlysleeptime)
	tmpcounthead=1

	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 http://www.ximalaya.com/revision/time > /tmp/tmp.XMV.xmtimestamp
	xmtimestamp=$(cat /tmp/tmp.XMV.xmtimestamp)
	urlprefix="https://mpay.ximalaya.com/mobile/track/pay/"
	urlsuffix="/ts-${xmtimestamp}/?device=pc"

	if [ ! -d "/autodl" ]; then
		mkdir /autodl
		chmod 777 /autodl
		if [ ! -d "/autodl/$paudiopath" ];then
			ln -s $paudiopath /autodl
		fi
	elif [ ! -d "/autodl/$paudiopath" ];then
			ln -s $paudiopath /autodl
	fi

	cd /$paudiopath

	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $paudiourl > /tmp/tmp.XMV.xmlyhttp
	sleep 2
	xmlyhttp=$(cat /tmp/tmp.XMV.xmlyhttp)  

	for i in `echo "$xmlyhttp" | sed 's/</\n/g'`
	do  
	    echo $i >> /tmp/tmp.XMV.xmlyhttp1
	done

	cat /tmp/tmp.XMV.xmlyhttp1 | grep isPaid > /tmp/tmp.XMV.xmlyhttp2
	cat /tmp/tmp.XMV.xmlyhttp1 | grep showShareBtn > /tmp/tmp.XMV.xmlyhttp2n
	cat /tmp/tmp.XMV.xmlyhttp2n | sed 's/title/\n/g'| grep showLikeBtn | cut -d '"' -f 1 | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g' > /tmp/tmp.XMV.filenamelist
	xmlyhttp2=$(cat /tmp/tmp.XMV.xmlyhttp2)
	for i in `echo "$xmlyhttp2" | sed 's/{\"index\":/\n/g'`
	do  
	    echo $i >> /tmp/tmp.XMV.xmlyhttp3
	done

	cat /tmp/tmp.XMV.xmlyhttp3 | grep trackId > /tmp/tmp.XMV.xmlyhttp4
	cat /tmp/tmp.XMV.xmlyhttp4 | grep '^[0-9]' | cut -d ',' -f 2 | cut -d ':' -f 2 > /tmp/tmp.XMV.xmlyhttp5
	cat /tmp/tmp.XMV.xmlyhttp5 > /tmp/tmp.XMV.xmlyhttp5d

	cat /tmp/tmp.XMV.xmlyhttp5d | while read LINE
	do
		xmlytrackId=$(echo $LINE)
		adurlprefix=$urlprefix
		adurlsuffix=$urlsuffix
		tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"

		if [ ! "$paudiocookie" ];then
			curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0\ \(Linux\;\ Android\ 10\)"" -v $tmpgetaudiourl > /tmp/tmpXMVIP.xmlyhttp6
		else
			sleep $psleeptime
			xmlycookieprefix="1&_token="
			xmlycookie="${xmlycookieprefix}${paudiocookie}"
			curl -b "$xmlycookie" -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" -v $tmpgetaudiourl > /tmp/tmpXMVIP.xmlyhttp6
		fi

		xmlyfindcode=$(cat /tmp/tmpXMVIP.xmlyhttp6)
		echo ${xmlyfindcode#*ep\":\"} > /tmp/tmpXMVIP.xmlyep1
		xmlyfindepcode=$(cat /tmp/tmpXMVIP.xmlyep1)
		echo ${xmlyfindepcode%\",\"highest*} > /tmp/tmpXMVIP.xmlyep2
		xmlynewepcode=$(cat /tmp/tmpXMVIP.xmlyep2)

		echo ${xmlyfindcode#*fileId\":\"} > /tmp/tmpXMVIP.xmlypath1
		xmlyfindpathcode=$(cat /tmp/tmpXMVIP.xmlypath1)
		echo ${xmlyfindpathcode%\",\"buyKey*} > /tmp/tmpXMVIP.xmlypath2
		xmlynewpathcode=$(cat /tmp/tmpXMVIP.xmlypath2)

		echo ${xmlyfindcode#*seed\":} > /tmp/tmpXMVIP.xmlyseed1
		xmlyfindseedcode=$(cat /tmp/tmpXMVIP.xmlyseed1)
		echo ${xmlyfindseedcode%,\"fileId*} > /tmp/tmpXMVIP.xmlyseed2
		xmlynewseedcode=$(cat /tmp/tmpXMVIP.xmlyseed2)

		echo ${xmlyfindcode#*duration\":} > /tmp/tmpXMVIP.xmlyduration1
		xmlyfinddurationcode=$(cat /tmp/tmpXMVIP.xmlyduration1)
		echo ${xmlyfinddurationcode%,\"ep*} > /tmp/tmpXMVIP.xmlyduration2
		xmlynewdurationcode=$(cat /tmp/tmpXMVIP.xmlyduration2)

		epathtxtp1="var c = bt(\""
		epathtxtp2=$xmlynewepcode
		epathtxtp3="\")"
		epathtxt=${epathtxtp1}${epathtxtp2}${epathtxtp3}
		sed -i '$d' /usr/autodl/ep.js
		echo $epathtxt >> /usr/autodl/ep.js
		node /usr/autodl/ep.js > /tmp/tmpXMVIP.xmlyVIPCODE
		sleep 3

		cpathtxtp1="console.log(c("
		cpathtxtp2=$xmlynewseedcode
		cpathtxtp3=",\""
		cpathtxtp4=$xmlynewpathcode
		cpathtxtp5="\"))"
		cpathtxt=${cpathtxtp1}${cpathtxtp2}${cpathtxtp3}${cpathtxtp4}${cpathtxtp5}
		sed -i '$d' /usr/autodl/path.js
		echo $cpathtxt >> /usr/autodl/path.js
		node /usr/autodl/path.js > /tmp/tmpXMVIP.xmlyVIPPATH
		sleep 3

		cat /tmp/tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 2 > /tmp/tmpXMVIP.xmlyVIPbuykey
		xmlybuykey=$(cat /tmp/tmpXMVIP.xmlyVIPbuykey)
		cat /tmp/tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 4 > /tmp/tmpXMVIP.xmlyVIPsign
		xmlysign=$(cat /tmp/tmpXMVIP.xmlyVIPsign)
		cat /tmp/tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 6 > /tmp/tmpXMVIP.xmlyVIPtoken
		xmlytoken=$(cat /tmp/tmpXMVIP.xmlyVIPtoken)
		cat /tmp/tmpXMVIP.xmlyVIPCODE | cut -d "'" -f 8 > /tmp/tmpXMVIP.xmlyVIPtimestamp
		xmlytimestamp=$(cat /tmp/tmpXMVIP.xmlyVIPtimestamp)

		xmlyvipaudioprefix="https://audiopay.cos.tx.xmcdn.com/download/1.0.0"
		xmlyvipaudiopath=$(cat /tmp/tmpXMVIP.xmlyVIPPATH)
		xmlyvipaudiosuffixbuykey="?buy_key="
		xmlyvipaudiosuffixsign="&sign="
		xmlyvipaudiosuffixtoken="&token="
		xmlyvipaudiosuffixtimestamp="&timestamp="
		xmlyvipaudiosuffixduration="&duration="

		xmlyvipaudiorealurl=${xmlyvipaudioprefix}${xmlyvipaudiopath}${xmlyvipaudiosuffixbuykey}${xmlybuykey}${xmlyvipaudiosuffixsign}${xmlysign}${xmlyvipaudiosuffixtoken}${xmlytoken}${xmlyvipaudiosuffixtimestamp}${xmlytimestamp}${xmlyvipaudiosuffixduration}${xmlynewdurationcode}
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmpXMVIP.testwget > /dev/null 2>&1
		if [ -s /tmp/tmpXMVIP.testwget ];then
			wget-ssl -q -c $xmlyvipaudiorealurl -O $paudionum.m4a
		else
			wget -q -c $xmlyvipaudiorealurl -O $paudionum.m4a
		fi
		sleep 3
		paudionum=$(echo `expr $paudionum - 1`)
		rm /tmp/tmpXMVIP.*
	done

	cat /tmp/tmp.XMV.xmlyhttp3 | grep trackId > /tmp/tmp.XMV.xmlyhttp0num
	cat /tmp/tmp.XMV.xmlyhttp0num | grep '^[0-9]' | cut -d ',' -f 1 > /tmp/tmp.XMV.xmlyhttp1num
	sed '1!G;h;$!d' /tmp/tmp.XMV.xmlyhttp1num > /tmp/tmp.XMV.xmlyhttp2num

	cat /tmp/tmp.XMV.xmlyhttp0num | grep tag | cut -d ',' -f 5 | cut -d '"' -f 4 | sed -e 's/《//g' | sed -e 's/》//g' | sed -e 's/（/-/g' | sed -e 's/）/-/g' |  sed -e 's/？//g' | sed -e 's/?//g' | sed -e 's/|//g' | sed -e 's/\\//g' | sed -e 's/\"//g' | sed -e 's/“//g' | sed -e 's/”//g' | sed -e 's/,//g' | sed -e "s/'//g" | sed -e 's/://g' | sed -e "s/[0-9]//g" | sed -e "s/第集//g" | sed -e "s/第章//g" > /tmp/tmp.XMV.xmlynam

	ls -al | grep "^-" > /tmp/tmpXMVIP.filelist

	cat /tmp/tmpXMVIP.filelist | while read LINE
	do
		xmlyfilename=$(echo $LINE)
		xtmpcounthead=$tmpcounthead
		xmlyturenum=$(tail -n $xtmpcounthead /tmp/tmp.XMV.xmlyhttp2num | head -n 1)
		xmlyturename=$(head -n $xtmpcounthead /tmp/tmp.XMV.xmlynam | tail -n 1 )
		if [ "$xmlyturename" = "$paudioname" ];then
			xmlyturename=""
		fi
		xmlyturenamed=$(cat /tmp/tmp.XMV.filenamelist | head -n 1)
		if [ $xmlyturenum -le 9 ];then
			nxmlyturenum=000$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nxmlyturenum$xmlyturename$xmlyturenamed.m4a
		elif [ $xmlyturenum -le 99 ];then
			nnxmlyturenum=00$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nnxmlyturenum$xmlyturename$xmlyturenamed.m4a
		elif [ $xmlyturenum -le 999 ];then
			nnnxmlyturenum=0$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nnnxmlyturenum$xmlyturename$xmlyturenamed.m4a
		else
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$xmlyturenum$xmlyturename$xmlyturenamed.m4a
		fi
		sed 1d -i /tmp/tmp.XMV.filenamelist
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	done

	if [ ! -d "/$paudiopath/$paudioname" ]; then
		mkdir $paudioname
	fi

	mv -f *.m4a $paudioname
	rm /tmp/tmpXMVIP.*
	rm /tmp/tmp.XMV.*
}

if [ ! $(uci get autodl.@autodl[0].xmlygetpages) ];then
	paudiourl=$(uci get autodl.@autodl[0].xmlyurl)
	getxmlyaudios
else
	uci get autodl.@autodl[0].xmlyurl > /tmp/doxmly.seturl.tmp
	xmlypagesendcount=$(uci get autodl.@autodl[0].xmlygetpages)
	xmlypagescount=0
	if [ ! $(uci get autodl.@autodl[0].xmlyurl | cut -d "/" -f 6 | sed 's/p//') ];then
		paudiourlstartpage=1
	else
		paudiourlstartpage=$(uci get autodl.@autodl[0].xmlyurl | cut -d "/" -f 6 | sed 's/p//')
	fi
	while [ $xmlypagescount -lt $xmlypagesendcount ]
	do
		if [ $xmlypagescount -eq 0 ];then
			paudiourlstartpage=$(echo `expr $paudiourlstartpage + $xmlypagescount`)
		else
			paudiourlstartpage=$(echo `expr $paudiourlstartpage + 1`)
		fi
		sed -i "s/$(cat /tmp/doxmly.seturl.tmp | cut -d "/" -f 6)/p$paudiourlstartpage/g" /tmp/doxmly.seturl.tmp

		xmlypagescount=$(echo `expr $xmlypagescount + 1`)
		paudiourl=$(cat /tmp/doxmly.seturl.tmp)
		getxmlyaudios
	done
	rm /tmp/doxmly.seturl.tmp
fi
