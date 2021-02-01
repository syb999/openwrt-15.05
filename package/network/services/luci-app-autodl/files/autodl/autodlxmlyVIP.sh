#!/bin/sh

rm /tmp/tmpXMVIP.*
rm /tmp/tmp.XMV.*

paudiourl=$(cat /tmp/tmp.XM.url)
paudioname=$(cat /tmp/tmp.XM.name)
paudionum=99
rpaudionum=99
paudiopath=$(cat /tmp/tmp.XM.path)
tmpcounthead=1

urlprefix="https://mpay.ximalaya.com/mobile/track/pay/"
urlsuffix="/?device=pc"

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
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" -v $tmpgetaudiourl > /tmp/tmpXMVIP.xmlyhttp6

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

	cat /tmp/tmpXMVIP.xmlyVIPCODE | head -n 1 | cut -d "'" -f 2 > /tmp/tmpXMVIP.xmlyVIPbuykey
	xmlybuykey=$(cat /tmp/tmpXMVIP.xmlyVIPbuykey)
	cat /tmp/tmpXMVIP.xmlyVIPCODE | head -n 2 | tail -n 1 | cut -d "'" -f 2 > /tmp/tmpXMVIP.xmlyVIPsign
	xmlysign=$(cat /tmp/tmpXMVIP.xmlyVIPsign)
	cat /tmp/tmpXMVIP.xmlyVIPCODE | head -n 3 | tail -n 1 | cut -d "'" -f 2 > /tmp/tmpXMVIP.xmlyVIPtoken
	xmlytoken=$(cat /tmp/tmpXMVIP.xmlyVIPtoken)
	cat /tmp/tmpXMVIP.xmlyVIPCODE | head -n 4 | tail -n 1 | cut -d "'" -f 2 > /tmp/tmpXMVIP.xmlyVIPtimestamp
	xmlytimestamp=$(cat /tmp/tmpXMVIP.xmlyVIPtimestamp)

	xmlyvipaudioprefix="https://audiopay.cos.tx.xmcdn.com/download/1.0.0"
	xmlyvipaudiopath=$(cat /tmp/tmpXMVIP.xmlyVIPPATH)
	xmlyvipaudiosuffixbuykey="?buy_key="
	xmlyvipaudiosuffixsign="&sign="
	xmlyvipaudiosuffixtoken="&token="
	xmlyvipaudiosuffixtimestamp="&timestamp="
	xmlyvipaudiosuffixduration="&duration="

	xmlyvipaudiorealurl=${xmlyvipaudioprefix}${xmlyvipaudiopath}${xmlyvipaudiosuffixbuykey}${xmlybuykey}${xmlyvipaudiosuffixsign}${xmlysign}${xmlyvipaudiosuffixtoken}${xmlytoken}${xmlyvipaudiosuffixtimestamp}${xmlytimestamp}${xmlyvipaudiosuffixduration}${xmlynewdurationcode}
	wget-ssl -q -c $xmlyvipaudiorealurl -O $paudionum.m4a
	sleep 3
	paudionum=$(echo `expr $paudionum - 1`)
	rm /tmp/tmpXMVIP.*
done

cat /tmp/tmp.XMV.xmlyhttp3 | grep trackId > /tmp/tmp.XMV.xmlyhttp0num
cat /tmp/tmp.XMV.xmlyhttp0num | grep '^[0-9]' | cut -d ',' -f 1 > /tmp/tmp.XMV.xmlyhttp1num
sed '1!G;h;$!d' /tmp/tmp.XMV.xmlyhttp1num > /tmp/tmp.XMV.xmlyhttp2num

ls -al | grep "^-" > /tmp/tmpXMVIP.filelist

cat /tmp/tmpXMVIP.filelist | while read LINE
do
	xmlyfilename=$(echo $LINE)
	xtmpcounthead=$tmpcounthead
	xmlyturenum=$(tail -n $xtmpcounthead /tmp/tmp.XMV.xmlyhttp2num | head -n 1)
	if [ $xmlyturenum -le 9 ];then
		nxmlyturenum=000$xmlyturenum
		mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nxmlyturenum.m4a
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	elif [ $xmlyturenum -le 99 ];then
		nnxmlyturenum=00$xmlyturenum
		mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nnxmlyturenum.m4a
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	elif [ $xmlyturenum -le 999 ];then
		nnnxmlyturenum=0$xmlyturenum
		mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$nnnxmlyturenum.m4a
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	else
		mv -f /$paudiopath/$rpaudionum.m4a /$paudiopath/$paudioname$xmlyturenum.m4a
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	fi
done

if [ ! -d "/$paudiopath/$paudioname" ]; then
mkdir $paudioname
fi

mv -f *.m4a $paudioname

rm /tmp/tmpXMVIP.*
rm /tmp/tmp.XMV.*

