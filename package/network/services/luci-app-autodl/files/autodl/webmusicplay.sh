#!/bin/sh

musiclist="$(uci get autodl.@autodl[0].webmusiclist)"
case $musiclist in
	hummingbird-pop-music-chart) theid="59703"
	;;
	tiktok-hot-song-chart) theid="52144"
	;;
	kwai-hot-song-chart) theid="52767"
	;;
	western-golden-melody-chart) theid="33166"
	;;
	kugou-top500) theid="8888"
	;;
	acg-new-song-chart) theid="33162"
	;;
	mainland-song-chart) theid="31308"
	;;
	hongkong-song-chart) theid="31313"
	;;
	japanese-song-chart) theid="31312"
	;;
	billboard-chart) theid="4681"
	;;
	all) theid="59703 52144 52767 33166 8888 33162 31308 31313 31312 4681"
	;;
	none) exit 0
	;;
esac

function mixsonglist() {
	rm /tmp/kugou.mixlist > /dev/null 2>&1
	for kgp in $theid;do
		for pp in $(seq 1 5);do
			curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 https://www.kugou.com/yy/rank/home/1-$kgp.html?p=$pp | grep mixsong | cut -d '"' -f 2 | cut -d '"' -f 1 >> /tmp/kugou.mixlist
		done
	done
}

function kugouplay() {
	kghash=$(cat $thetmpfile1 | head -n 1 | cut -d '"' -f 1)
	kgname=$(echo -en "$(cat $thetmpfile1 | head -n 2 | tail -n 1 | cut -d '"' -f 1)" | sed s'/\ //g;s/-/_/g')
	kgmixid=$(cat $thetmpfile1 | head -n 3 | tail -n 1 | cut -d '}' -f 1 | cut -d ',' -f 1)
	mp3prefix="https://wwwapi.kugou.com/yy/index.php?r=play/getdata"
	mp3hash="&hash=${kghash}"
	mp3mid="&mid=bbb9daa22b64526961d305894db7ebb3"
	mp3id="&album_audio_id=${kgmixid}"
	mp3url=${mp3prefix}${mp3hash}${mp3mid}${mp3id}
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mp3url > $thetmpfile2
	urlinfo=$(cat $thetmpfile2)
	echo ${urlinfo#*play_url\":\"} > $thetmpurl
	themp3tmp=$(cat $thetmpurl)
	echo ${themp3tmp%%\",\"authors*} | sed 's/\\//g' > $thetmpurl
	curl $(cat $thetmpurl) | mpg123 -
	while [ "$(busybox ps | grep mpg123 | grep -v grep | awk '{print$1}')" ];do
		sleep 2
	done
	rm /tmp/kugou.tmp.*
	sleep 1
}

thetmpfile1="/tmp/kugou.tmp.1"
thetmpfile2="/tmp/kugou.tmp.2"
thetmpurl="/tmp/kugou.tmp.url"

while true;do
	mixsonglist
	for mu in $(seq 1 $(cat /tmp/kugou.mixlist | wc -l));do
		mixsongurl=$(cat /tmp/kugou.mixlist | head -n $mu |  tail -n 1)
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mixsongurl | grep hash | sed 's/\"hash\":\"/\n/;s/\"audio_name\":\"/\n/;s/\"mixsongid\":/\n/' | sed '1d' > $thetmpfile1
		kugouplay
	done
	rm /tmp/kugou.*
done
