#!/bin/sh

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '_' -f 3 | cut -d '.' -f 1)

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

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep vod_name | sed -e 's/flag/\n/g' -e 's/data-type/\n/g' > /tmp/autodldmdm.01
sleep 3
avdname0=$(cat /tmp/autodldmdm.01)
echo ${avdname0%\', vod_url*} > /tmp/autodldmdm.0
avdname1=$(cat /tmp/autodldmdm.0)
echo ${avdname1#*\= \'} > /tmp/autodldmdm.0
avdname2=$(cat /tmp/autodldmdm.0)

function autodlvd(){
	cat /tmp/autodldmdm.01 | head -n 2 | tail -n 1  > /tmp/autodldmdm.011
	aurl=$(cat /tmp/autodldmdm.011)
	echo ${aurl#*\"url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.1
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url%\"\,\"url_next*} > /tmp/autodldmdm.1
	a3url=$(cat /tmp/autodldmdm.1)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a3url > /tmp/autodldmdm.2
	sleep 3
	a4url=$(tail -n 1 /tmp/autodldmdm.2)
	echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/' > /tmp/autodldmdm.1
	a5url=$(echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/')
	a6url=$(echo $a5url | sed "s/index.m3u8//")
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a5url | grep .ts > /tmp/autodltmp.index.m3u8

	autodlm3u8="/tmp/autodltmp.index.m3u8"

	while read LINE
	do
		autodltssuffix=$(echo $LINE)
		autodltsprefix=$(echo $a6url)
		autodltsprefixurl=$autodltsprefix
		tmpautodlts="${autodltsprefixurl}${autodltssuffix}"
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.autodl.testwget ];then
			wget-ssl --timeout=35 -q -c $tmpautodlts
		else
			wget --timeout=35 -q -c $tmpautodlts
		fi
		rm /tmp/tmp.autodl.testwget
		cat $autodltssuffix >> $autodlgetpath/hls.ts
		rm $autodltssuffix
	done < $autodlm3u8

	autodlcount=$(echo `expr $autodlcount + 1`)
	avdnumnew=$(echo `expr $avdnum1 + 1`)
	echo $autodlgeturl | sed "s/${avdnum1}.html/${avdnumnew}.html/" > /tmp/autodl.url
}

while [ $avdnum1 -le $autodlgetnum ]
do
	if [ $avdnum1 -le 9 ];then
		autodlvd
		avdnum2=00$avdnum1
		mv -f /autodl/videos/hls.ts /autodl/videos/$avdname2第$avdnum2集.ts
	elif [ $avdnum1 -le 99 ];then
		autodlvd
		avdnum3=0$avdnum1
		mv -f /autodl/videos/hls.ts /autodl/videos/$avdname2第$avdnum3集.ts
	else
		autodlvd
		mv -f /autodl/videos/hls.ts /autodl/videos/$avdname2第$avdnum1集.ts
	fi
	avdnum1=$(echo `expr $avdnum1 + 1`)
done

if [ ! -d "/$autodlgetpath/$autodlgetname" ]; then
mkdir $autodlgetname
fi

mv -f *.ts $autodlgetname

rm /tmp/autodldmdm.*
rm /tmp/autodl.url
mv -f /tmp/autodl.url.bk /tmp/autodl.url
