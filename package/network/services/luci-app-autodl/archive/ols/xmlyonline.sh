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

	newlistprefix="https://www.ximalaya.com/revision/album/v1/getTracksList?albumId="
	newlistpagenumprefix="&pageNum="
	newlistpagesuffix="&sort=0"
	thenewlist="${newlistprefix}${newlistalbumId}${newlistpagenumprefix}${newlistpagenum}${newlistpagesuffix}"
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $thenewlist > /tmp/tmp.XMV.newlist
	cat /tmp/tmp.XMV.newlist | sed 's/\/sound\//\n/g' | sed '1d' | cut -d '"' -f 1 > /tmp/tmp.XMV.newlist2
	cat /tmp/tmp.XMV.newlist | sed 's/\"title\"/\n/g' | sed '1d' | cut -d '"' -f 2 | sed 's/[ ][ ]*/-/g' | sed -e 's/\\/＼/g' | sed -e 's/\//／/g' | sed -e 's/</《/g' | sed -e 's/>/》/g' | sed -e 's/:/：/g' | sed -e 's/*//g' | sed -e 's/?/？/g' | sed -e 's/\"/“/g'  | sed -e 's/\ /-/g' | sed -e 's/|/-/g'  > /tmp/tmp.XMV.filenamelist
	cat /tmp/tmp.XMV.newlist | sed 's/\"index\":/\n/g' | sed '1d'| cut -d ',' -f 1 > /tmp/tmp.XMV.newlist3
	cat /tmp/tmp.XMV.newlist2 | while read LINE
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
		echo ${xmlyfindepcode%\",\"highest*} | sed 's/\//%2f/g' > /tmp/tmpXMVIP.xmlyep2
		urlencode $(cat /tmp/tmpXMVIP.xmlyep2) > /tmp/tmpXMVIP.xmlyep3
		cat /tmp/tmpXMVIP.xmlyep3 | sed 's/\//%2f/g' > /tmp/tmpXMVIP.xmlyep4
		xmlynewepcode=$(cat /tmp/tmpXMVIP.xmlyep4)

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

		olip=$(uci get autodl.@autodl[0].olip)
		olp1=$(uci get autodl.@autodl[0].olp1)
		curl -s $olip:$olp1/epcode/$xmlynewepcode > /tmp/tmpXMVIP.xmlyVIPCODE
		sleep 1
		curl -s $olip:$olp1/sdcode/$xmlynewseedcode
		sleep 1
		curl -s $olip:$olp1/phcode/$xmlynewpathcode | sed 's/\\n\"$/\"/' | cut -d '"' -f 2 > /tmp/tmpXMVIP.xmlyVIPPATH
		sleep 1

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
		wget-ssl -t 5 -w 3 -T 60 -q -c $(uci get network.lan.ipaddr) -O /tmp/tmpXMVIP.testwget > /dev/null 2>&1
		if [ -s /tmp/tmpXMVIP.testwget ];then
			wget-ssl -t 5 -w 3 -T 60 -q -c $xmlyvipaudiorealurl -O $paudionum.m4a
		else
			wget -t 5 -w 3 -T 60 -q -c $xmlyvipaudiorealurl -O $paudionum.m4a
		fi
		sleep 3
		paudionum=$(echo `expr $paudionum - 1`)
		rm /tmp/tmpXMVIP.*
	done

	sed '1!G;h;$!d' /tmp/tmp.XMV.newlist3 > /tmp/tmp.XMV.xmlyhttp2num

	ls -al | grep "^-" > /tmp/tmpXMVIP.filelist

	cat /tmp/tmpXMVIP.filelist | while read LINE
	do
		xmlyfilename=$(echo $LINE)
		xtmpcounthead=$tmpcounthead
		xmlyturenum=$(tail -n $xtmpcounthead /tmp/tmp.XMV.xmlyhttp2num | head -n 1)
		xmlyturename=$(cat /tmp/tmp.XMV.filenamelist | head -n 1)
		if [ "$xmlyturename" = "$paudioname" ];then
			xmlyturename=""
		fi
		if [ $xmlyturenum -le 9 ];then
			nxmlyturenum=000$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/${paudioname}${nxmlyturenum}-${xmlyturename}.m4a
		elif [ $xmlyturenum -le 99 ];then
			nnxmlyturenum=00$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/${paudioname}${nnxmlyturenum}-${xmlyturename}.m4a
		elif [ $xmlyturenum -le 999 ];then
			nnnxmlyturenum=0$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/${paudioname}${nnnxmlyturenum}-${xmlyturename}.m4a
		else
			mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/${paudioname}${xmlyturenum}-${xmlyturename}.m4a
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
	newlistalbumId=$(uci get autodl.@autodl[0].xmlyurl | sed "s/\/$//" | sed 's/album\//^/' | cut -d '^' -f 2)
	newlistpagenum=$(uci get autodl.@autodl[0].xmlypagenum)
	getxmlyaudios
else
	newlistalbumId=$(uci get autodl.@autodl[0].xmlyurl | sed "s/\/$//" | sed 's/album\//^/' | cut -d '^' -f 2)
	newlistpagenum=$(uci get autodl.@autodl[0].xmlypagenum)
	xmlypagesendcount=$(uci get autodl.@autodl[0].xmlygetpages)
	xmlypagescount=0
	while [ $xmlypagescount -lt $xmlypagesendcount ]
	do
		xmlypagescount=$(echo `expr $xmlypagescount + 1`)
		getxmlyaudios
		newlistpagenum=$(echo `expr $newlistpagenum + 1`)
	done
	rm /tmp/doxmly.seturl.tmp
fi
