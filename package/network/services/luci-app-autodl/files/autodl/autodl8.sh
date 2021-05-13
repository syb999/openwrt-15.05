#!/bin/sh

uci get autodl.@autodl[0].url > /tmp/autodl.url
uci get autodl.@autodl[0].path > /tmp/autodl.path
uci get autodl.@autodl[0].name > /tmp/autodl.name
uci get autodl.@autodl[0].num > /tmp/autodl.num

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum1=$(uci get autodl.@autodl[0].url | cut -d '-' -f 3 | cut -d '.' -f 1)

autodlcount=1
aescount=0

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$autodlgetpath" ];then
		ln -s $autodlgetpath /autodl
	fi
else
	if [ ! -d "/autodl/$autodlgetpath" ];then
		ln -s $autodlgetpath /autodl
	fi
fi

cd /$autodlgetpath

function autodlvd(){
	a3url=$(cat /tmp/autodldmdm.2)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a3url | grep m3u8 > /tmp/autodldmdm.3
	a3xurl=$(cat /tmp/autodldmdm.2 | cut -d '/' -f 3 )
	a3yurl=$(cat /tmp/autodldmdm.3)
	a4url="https://${a3xurl}${a3yurl}"
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a4url | grep 'ts' > /tmp/autodltmp.index.m3u8
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $(cat /tmp/autodltmp.index.m3u8 | head -n 1 | cut -d '"' -f 2) > /tmp/autodldmdm.aeskey
	strkey=$(hexdump -v -e '16/1 "%02x"' /tmp/autodldmdm.aeskey)
	sed 1d -i /tmp/autodltmp.index.m3u8
	autodlm3u8="/tmp/autodltmp.index.m3u8"

	while read LINE
	do
		autodlts=$(echo $LINE)
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.autodl.testwget ];then
			wget-ssl --timeout=35 -q -c $autodlts -O $autodlgetpath/aestmphls.ts
		else
			wget --timeout=35 -q -c $autodlts -O $autodlgetpath/aestmphls.ts
		fi
		rm /tmp/tmp.autodl.testwget > /dev/null 2>&1
		openssl aes-128-cbc -d -in aestmphls.ts -out tmphls.ts -nosalt -iv $(printf '%032x' $aescount) -K $strkey 
		cat tmphls.ts >> $autodlgetpath/hls.ts
		rm $autodlgetpath/aestmphls.ts > /dev/null 2>&1
		rm $autodlgetpath/tmphls.ts > /dev/null 2>&1
		aescount=$(expr $aescount + 1)
	done < $autodlm3u8
	autodlcount=$(expr $autodlcount + 1)
}

while [ $avdnum1 -le $autodlgetnum ]
do
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl > /tmp/autodldmdm.0
	aurl=$(cat /tmp/autodldmdm.0)
	echo ${aurl#*\"link_pre\":\"\",\"url\":\"} > /tmp/autodldmdm.1
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url%\",\"url_next\"*} | sed 's/\\//g' > /tmp/autodldmdm.2
	if [ $avdnum1 -le 9 ];then
		autodlvd
		avdnum2=00$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnum2集.ts
	elif [ $avdnum1 -le 99 ];then
		autodlvd
		avdnum3=0$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnum3集.ts
	else
		autodlvd
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnum1集.ts
	fi
	avdnum1=$(echo `expr $avdnum1 + 1`)
done

if [ ! -d "/$autodlgetpath/$autodlgetname" ]; then
	mkdir $autodlgetname
fi

mv -f *.ts $autodlgetname

rm /tmp/autodldmdm.*
rm /tmp/autodl.*
