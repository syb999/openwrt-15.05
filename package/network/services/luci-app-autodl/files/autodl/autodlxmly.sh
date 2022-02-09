#!/bin/sh

function getxmlyaudios(){
	paudioname=$(uci get autodl.@autodl[0].xmlyname)
	paudionum=99
	rpaudionum=99
	paudiopath=$(uci get autodl.@autodl[0].xmlypath)
	tmpcounthead=1

	urlprefix="https://www.ximalaya.com/revision/play/v1/audio?id="
	urlsuffix="&ptype=1"

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
	newlistpagesuffix="&sort=1"
	thenewlist="${newlistprefix}${newlistalbumId}${newlistpagenumprefix}${newlistpagenum}${newlistpagesuffix}"
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $thenewlist > /tmp/tmpXM.newlist
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
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""xm-sign": "$cxmsign"" -v $tmpgetaudiourl > /tmp/tmpXM.xmlyhttp6
		sleep 1
		tmpaudio=$(cat /tmp/tmpXM.xmlyhttp6)
		echo ${tmpaudio#*src\":\"} > /tmp/tmpXM.xmlyhttp7
		tmpaudio=$(cat /tmp/tmpXM.xmlyhttp7)
		echo ${tmpaudio%\",\"albumIsSample*} > /tmp/tmpXM.xmlyhttp7
		audiofile=$(cat /tmp/tmpXM.xmlyhttp7)
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.XM.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.XM.testwget ];then
			wget-ssl -q -c $audiofile -O $paudionum.m4a
		else
			wget -q -c $audiofile -O $paudionum.m4a
		fi
		sleep 3
		paudionum=$(echo `expr $paudionum - 1`)
		rm /tmp/tmp.XM.*
	done

	sed '1!G;h;$!d' /tmp/tmpXM.newlist3 > /tmp/tmpXM.xmlyhttp2num

	ls -al | grep "^-" > /tmp/tmpXM.filelist

	cat /tmp/tmpXM.filelist | while read LINE
	do
		xtmpcounthead=$tmpcounthead
		xmlyturenum=$(tail -n $xtmpcounthead /tmp/tmpXM.xmlyhttp2num | head -n 1)
		xmlyturename=$(cat /tmp/tmpXM.filenamelist | head -n 1)
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
		sed 1d -i /tmp/tmpXM.filenamelist
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	done

	if [ ! -d "/$paudiopath/$paudioname" ]; then
		mkdir $paudioname
	fi

	mv -f *.m4a $paudioname
	rm /tmp/tmpXM.*
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
