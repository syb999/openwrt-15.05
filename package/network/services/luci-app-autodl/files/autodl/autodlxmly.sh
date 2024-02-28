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
		echo ${xmlytrackId} > /tmp/tmpXM.xmlysoundid
		rm /tmp/tmpXM.xmlyhttp
		python3 /usr/autodl/xmlyfree.py
		audiofile=$(cat /tmp/tmpXM.xmlyhttp)
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.XM.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.XM.testwget ];then
			wget-ssl -q -c $audiofile -O $paudionum.mp3
		else
			wget -q -c $audiofile -O $paudionum.mp3
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
		xmlyturenum=$(tail -n $xtmpcounthead /tmp/tmpXM.xmlyhttp2num | head -n1)
		xmlyturename=$(cat /tmp/tmpXM.filenamelist | head -n1)
		if [ "$xmlyturename" = "$paudioname" ];then
			xmlyturename=""
		fi
		if [ $xmlyturenum -le 9 ];then
			nxmlyturenum=000$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.mp3 /$paudiopath/${paudioname}${nxmlyturenum}-${xmlyturename}.mp3
		elif [ $xmlyturenum -le 99 ];then
			nnxmlyturenum=00$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.mp3 /$paudiopath/${paudioname}${nnxmlyturenum}-${xmlyturename}.mp3
		elif [ $xmlyturenum -le 999 ];then
			nnnxmlyturenum=0$xmlyturenum
			mv -f /$paudiopath/$rpaudionum.mp3 /$paudiopath/${paudioname}${nnnxmlyturenum}-${xmlyturename}.mp3
		else
			mv -f /$paudiopath/$rpaudionum.mp3 /$paudiopath/${paudioname}${xmlyturenum}-${xmlyturename}.mp3
		fi
		sed 1d -i /tmp/tmpXM.filenamelist
		tmpcounthead=$(echo `expr $tmpcounthead + 1`)
		rpaudionum=$(echo `expr $rpaudionum - 1`)
	done

	if [ ! -d "/$paudiopath/$paudioname" ]; then
		mkdir $paudioname
	fi

	mv -f *.mp3 $paudioname
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
