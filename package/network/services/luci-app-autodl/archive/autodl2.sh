#!/bin/sh

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '-' -f 3 | cut -d '.' -f 1)

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

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep data-name > /tmp/autodldmdm.0
sleep 3
avdname0=$(cat /tmp/autodldmdm.0)
echo ${avdname0%\" data-link*} > /tmp/autodldmdm.0
avdname1=$(cat /tmp/autodldmdm.0)
echo ${avdname1#*data-name\=\"} > /tmp/autodldmdm.0
avdname2=$(cat /tmp/autodldmdm.0)

avdnumx1=$(echo `expr $avdnum1 + 1`)

function autodlvd(){
	aurl=$(cat /tmp/autodldmdm.1)
	echo ${aurl#*now=\"} > /tmp/autodldmdm.1
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url%\"\;var pn*} > /tmp/autodldmdm.1
	a3url=$(cat /tmp/autodldmdm.1)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a3url > /tmp/autodldmdm.2
	sleep 3
	a4url=$(tail -n 1 /tmp/autodldmdm.2)
	a4urlp1=$(echo $a4url | cut -d '/' -f 1 )
	echo $a3url | sed "s/index.m3u8/$a4urlp1\/hls\/&/" > /tmp/autodldmdm.3
	a5url=$(cat /tmp/autodldmdm.3)
	a6url=$(echo $a5url | sed "s/index.m3u8//")
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $a5url | grep .ts > /tmp/autodltmp.index.m3u8

	autodlm3u8=/tmp/autodltmp.index.m3u8

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

while [ $avdnum1 -lt $autodlgetnum ]
do
	autodlgeturl=$(cat /tmp/autodl.url)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep m3u8 > /tmp/autodldmdm.1
	sleep 3
	if [ $avdnum1 -lt 9 ];then
		autodlvd
		avdnum2=00$avdnumx1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum2集.ts
	elif [ $avdnum1 -lt 99 ];then
		autodlvd
		avdnum3=0$avdnumx1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum3集.ts
	else
		autodlvd
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnumx1集.ts
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
