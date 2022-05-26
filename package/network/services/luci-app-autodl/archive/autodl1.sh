#!/bin/sh

uci get autodl.@autodl[0].url > /tmp/autodl.url
autodlgetpath="$(uci get autodl.@autodl[0].path)"
autodlgetname="$(uci get autodl.@autodl[0].name)"
autodlgetnum="$(uci get autodl.@autodl[0].num)"

avdnum=1
avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '-' -f 3 | cut -d '.' -f 1)

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

cd $autodlgetpath
avdname2=$(uci get autodl.@autodl[0].name)

function autodlvd(){
	aurl=$(cat /tmp/autodldmdm.1)
	echo ${aurl#*link_pre\":\"\",\"url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.1
	if [ $(cat /tmp/autodldmdm.1 | cut -d ' ' -f 1 ) == "<!DOCTYPE" ];then
		burl=$(cat /tmp/autodldmdm.1)
		echo ${burl#*html\",\"url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.1
	fi
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url%%\",\"url_next\"*} > /tmp/autodldmdm.1
	a3url=$(cat /tmp/autodldmdm.1)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a3url > /tmp/autodldmdm.2
	cat /tmp/autodldmdm.1 | sed 's/index.m3u8/1000kb\/hls\/&/' > /tmp/autodldmdm.3
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $(cat /tmp/autodldmdm.3) | grep .ts | sed 's/ad.hjyedu88.com//g' > /tmp/autodltmp.index.m3u8

	if [ -s /tmp/autodltmp.index.m3u8 ];then
		hlsaeskey=$(curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $(cat /tmp/autodltmp.index.m3u8 | head -n 1 | cut -d '"' -f 2) > /tmp/autodldmdm.aeskey)
		strkey=$(hexdump -v -e '16/1 "%02x"' /tmp/autodldmdm.aeskey)
		sed 1d -i /tmp/autodltmp.index.m3u8
		autodlm3u8="/tmp/autodltmp.index.m3u8"
		autodlcount=1
		aescount=0

		while read LINE
		do
			autodlts=$(echo $LINE)
			wget-ssl -q $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
			if [ -s /tmp/tmp.autodl.testwget ];then
				wget-ssl --timeout=5 -q $autodlts -O $autodlgetpath/aestmphls.ts
			else
				wget --timeout=5 -q $autodlts -O $autodlgetpath/aestmphls.ts
			fi
			rm /tmp/tmp.autodl.testwget > /dev/null 2>&1
			openssl aes-128-cbc -d -in aestmphls.ts -out tmphls.ts -nosalt -iv $(printf '%032x' $aescount) -K $strkey 
			cat tmphls.ts >> $autodlgetpath/hls.ts
			rm $autodlgetpath/aestmphls.ts
			rm $autodlgetpath/tmphls.ts
			aescount=$(expr $aescount + 1)
		done < $autodlm3u8
	fi

	autodlcount="$(expr $autodlcount + 1)"
	avdnumnew="$(expr $avdnum1 + 1)"
	sed -i "s/${avdnum1}.html/${avdnumnew}.html/" /tmp/autodl.url
}

while [ $avdnum -le $autodlgetnum ]
do
	autodlgeturl=$(cat /tmp/autodl.url)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep m3u8 > /tmp/autodldmdm.1
	if [ $avdnum1 -le 9 ];then
		autodlvd
		avdnum2=00$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum2集.ts
	elif [ $avdnum1 -le 99 ];then
		autodlvd
		avdnum3=0$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum3集.ts
	else
		autodlvd
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum1集.ts
	fi
	avdnum1=$(expr $avdnum1 + 1)
	avdnum=$(expr $avdnum + 1)
done

if [ ! -d "$autodlgetpath/$autodlgetname" ]; then
	mkdir -p $autodlgetpath/$autodlgetname
fi

mv -f *.ts $autodlgetpath/$autodlgetname
rm /tmp/autodldmdm.* /tmp/autodl.url /tmp/autodltmp.index.m3u8
