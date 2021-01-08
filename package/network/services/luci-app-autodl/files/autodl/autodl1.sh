#!/bin/sh

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '-' -f 3 | cut -d '.' -f 1)

autodlcount=1

if [ ! -d "/autodl/videos" ]; then
  mkdir /autodl
  chmod 777 /autodl
  ln -s $autodlgetpath /autodl
fi

curl $autodlgeturl | grep vod_name > /tmp/autodldmdm.0
sleep 3
avdname0=$(cat /tmp/autodldmdm.0)
echo ${avdname0%\', vod_url*} > /tmp/autodldmdm.0
avdname1=$(cat /tmp/autodldmdm.0)
echo ${avdname1#*\= \'} > /tmp/autodldmdm.0
avdname2=$(cat /tmp/autodldmdm.0)

function autodlvd(){
	aurl=$(cat /tmp/autodldmdm.1)
	echo ${aurl#*\"url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.1
	a2url=$(cat /tmp/autodldmdm.1)
	echo ${a2url%\"\,\"url_next*} > /tmp/autodldmdm.1
	a3url=$(cat /tmp/autodldmdm.1)
	curl $a3url > /tmp/autodldmdm.2
	sleep 3
	a4url=$(tail -n 1 /tmp/autodldmdm.2)
	echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/' > /tmp/autodldmdm.1
	a5url=$(echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/')
	a6url=$(echo $a5url | sed "s/index.m3u8//")
	curl $a5url | grep .ts > /tmp/autodltmp.index.m3u8

	autodlm3u8=/tmp/autodltmp.index.m3u8

	while read LINE
	do
		autodltssuffix=$(echo $LINE)
		autodltsprefix=$(echo $a6url)
		autodltsprefixurl=$autodltsprefix
		tmpautodlts="${autodltsprefixurl}${autodltssuffix}"
		wget -q -c $tmpautodlts
		cat $autodltssuffix >> $autodlgetpath/hls.ts
		rm $autodltssuffix
	done < $autodlm3u8

	autodlcount=$(echo `expr $autodlcount + 1`)
	avdnumnew=$(echo `expr $avdnum1 + 1`)
	echo $autodlgeturl | sed "s/${avdnum1}.html/${avdnumnew}.html/" > /tmp/autodl.url
}

while [ $avdnum1 -le $autodlgetnum ]
do
	autodlgeturl=$(cat /tmp/autodl.url)
	curl $autodlgeturl | grep m3u8 > /tmp/autodldmdm.1
	sleep 3
	if [ $avdnum1 -le 9 ];then
		autodlvd
		avdnum2=0$avdnum1
		mv /autodl/videos/hls.ts /autodl/videos/$avdname2第$avdnum2集.ts
	else
		autodlvd
		mv /autodl/videos/hls.ts /autodl/videos/$avdname2第$avdnum1集.ts
	fi
	avdnum1=$(echo `expr $avdnum1 + 1`)
done

rm /tmp/autodldmdm.*
rm /tmp/autodl.url
mv /tmp/autodl.url.bk /tmp/autodl.url
