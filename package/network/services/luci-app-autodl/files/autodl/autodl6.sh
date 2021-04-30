#!/bin/sh

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '/' -f 12 | cut -d '.' -f 1)

autodlcount=1

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
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep link_pre > /tmp/autodldmdm.0
	sleep 3
	aurl=$(cat /tmp/autodldmdm.0)
	echo ${aurl%\",\"url_next*} > /tmp/autodldmdm.1
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url#*url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.1
	a3url=$(cat /tmp/autodldmdm.1)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a3url > /tmp/autodldmdm.2
	sleep 3
	a4urlprefix=$(cat /tmp/autodldmdm.2 | grep redirecturl | cut -d '"' -f 2)
	a4urlsuffix=$(cat /tmp/autodldmdm.2 | grep "url\"" | cut -d '"' -f 4)
	a4url="${a4urlprefix}${a4urlsuffix}"
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a4url | grep .ts > /tmp/autodltmp.index.m3u8

	autodlm3u8=/tmp/autodltmp.index.m3u8

	while read LINE
	do
		autodltssuffix=$(echo $LINE)
		autodltsprefix=$(echo $a4urlprefix)
		autodltsprefixurl=$autodltsprefix
		tmpautodlts="${autodltsprefixurl}${autodltssuffix}"
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.autodl.testwget ];then
			wget-ssl --timeout=35 -q -c $tmpautodlts -O $autodlgetpath/tmphls.ts
		else
			wget --timeout=35 -q -c $tmpautodlts -O $autodlgetpath/tmphls.ts
		fi
		rm /tmp/tmp.autodl.testwget
		cat tmphls.ts >> $autodlgetpath/hls.ts
		rm $autodlgetpath/tmphls.ts
	done < $autodlm3u8

	autodlcount=$(echo `expr $autodlcount + 1`)
	avdnumnew=$(echo `expr $avdnum1 + 1`)
	echo $autodlgeturl | sed "s/${avdnum1}.html/${avdnumnew}.html/" > /tmp/autodl.url
}

while [ $avdnum1 -le $autodlgetnum ]
do
	if [ $avdnum1 -lt 9 ];then
		autodlvd
		avdnum2=00$avdnumx1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnum2集.ts
	elif [ $avdnum1 -lt 99 ];then
		autodlvd
		avdnum3=0$avdnumx1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnum3集.ts
	else
		autodlvd
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$autodlgetname第$avdnumx1集.ts
	fi
	avdnum1=$(echo `expr $avdnum1 + 1`)
	avdnumx1=$(echo `expr $avdnumx1 + 1`)
done

if [ ! -d "/$autodlgetpath/$autodlgetname" ]; then
mkdir $autodlgetname
fi

mv -f *.ts $autodlgetname

rm /tmp/autodldmdm.*
rm /tmp/autodl.url
mv -f /tmp/autodl.url.bk /tmp/autodl.url
