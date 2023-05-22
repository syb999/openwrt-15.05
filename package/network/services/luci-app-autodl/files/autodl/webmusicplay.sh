#!/bin/sh

_musicsrc="$(uci get autodl.@autodl[0].webmusicsrc)"

if [ "${_musicsrc}" = "kuwo" ];then
	musiclist="$(uci get autodl.@autodl[0].webkuwolist)"
else
	musiclist="$(uci get autodl.@autodl[0].webkugoulist)"
fi

case $musiclist in
	kuwo-soaring-chart) theid="93"
	;;
	kuwo-new-song-chart) theid="17"
	;;
	kuwo-hot-song-chart) theid="16"
	;;
	kuwo-tiktok-hot-song-chart) theid="158"
	;;
	DJ-list-chart) theid="176"
	;;
	member-chart) theid="145"
	;;
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
	all) 
		if [ "${_musicsrc}" = "kuwo" ];then
			theid="93 17 16 158 176 145"
		else
			theid="59703 52144 52767 33166 8888 33162 31308 31313 31312 4681"
		fi
	;;
	none) exit 0
	;;
esac

function test_dir() {
	if [ ! -d "$(uci get autodl.@autodl[0].webmusicpath)" ]; then
		mkdir -p "$(uci get autodl.@autodl[0].webmusicpath)"
		chmod 777 "$(uci get autodl.@autodl[0].webmusicpath)"
	fi
}

function kuwo_get_token(){
	url="https://kuwo.cn/"
	curl -s -c /tmp/kuwo.cookie.tmp $url >/dev/null 2>&1
	thetoken="$(cat /tmp/kuwo.cookie.tmp | grep kw_token | awk '{print$7}')"
}

function mixsonglist_kuwo() {
	rm /tmp/kuwo.list.tmp.2 >/dev/null 2>&1
	for p in $(seq 1 5);do
		url="https://kuwo.cn/api/www/bang/bang/musicList?pn=${p}&rn=20&bangId=${a}"
		curl -s -H ""Accept":"application/json"" -H ""Cookie":"kw_token=${thetoken}"" -H ""csrf":"${thetoken}"" -H ""Referer":"https://kuwo.cn/rankList"" -H ""User-Agent":"Mozilla/5.0"" $url > /tmp/kuwo.list.tmp
		cat /tmp/kuwo.list.tmp | sed "s/musicrid\":\"/\n/g" | grep MUSIC_  >> /tmp/kuwo.list.tmp.2
		rm /tmp/kuwo.list.tmp
	done
}

function kuwoplay() {
	_id_list="$(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f1 | cut -d '_' -f2)"
	_singer_list="$(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f13)"
	url="https://bd.kuwo.cn/api/v1/www/music/playUrl?type=url_3&mid="
	for i in $(seq 1 $(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f73 | wc -l));do
		if [ "$(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f73 | head -n$i | tail -n1)" = "artistid" ];then
			_song="$(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f93 | head -n$i | tail -n1)"
		else
			_song="$(cat /tmp/kuwo.list.tmp.2 | cut -d '"' -f97 | head -n$i | tail -n1)"
		fi
		_id="$(echo ${_id_list} | cut -d ' ' -f$i)"
		_singer="$(echo ${_singer_list} | cut -d ' ' -f$i)"
		curl -s -H ""Cookie":"kw_token=${thetoken}"" "${url}${_id}" | cut -d '"' -f20 > $thetmpurl
		echo "${_singer}-${_song}" | sed 's/ //g' > $thetmpinfo
		if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
			wget-ssl -t 5 -q -c $(cat $thetmpurl) -O $(uci get autodl.@autodl[0].webmusicpath)/$(cat $thetmpinfo).mp3
		fi
		curl $(cat $thetmpurl) | mpg123 -
	done
}

function kuwo_main() {
	kuwo_get_token
	for a in ${theid};do
		mixsonglist_kuwo
		kuwoplay
	done
}

function mixsonglist_kugou() {
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
	if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
		wget-ssl -t 5 -q -c $(cat $thetmpurl) -O $(uci get autodl.@autodl[0].webmusicpath)/$(cat $thetmpinfo).mp3
	fi
	curl $(cat $thetmpurl) | mpg123 -
	while [ "$(busybox ps | grep mpg123 | grep -v grep | awk '{print$1}')" ];do
		sleep 2
	done
	rm /tmp/kugou.tmp.*
	sleep 1
}

function kugou_main() {
	thetmpfile1="/tmp/kugou.tmp.1"
	thetmpfile2="/tmp/kugou.tmp.2"
	mixsonglist_kugou
	for mu in $(seq 1 $(cat /tmp/kugou.mixlist | wc -l));do
		mixsongurl=$(cat /tmp/kugou.mixlist | head -n $mu |  tail -n 1)
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mixsongurl | grep hash | sed 's/\"hash\":\"/\n/;s/\"audio_name\":\"/\n/;s/\"mixsongid\":/\n/' | sed '1d' > $thetmpfile1
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mixsongurl | grep "<title>" | cut -d '<' -f2 | cut -d ">" -f2 | cut -d '_' -f1,2 > $thetmpinfo
		kugouplay
	done
	rm /tmp/kugou.*
}

thetmpurl="/tmp/webmusic.tmp.url"
thetmpinfo="/tmp/webmusic.tmp.info"
while true;do
	test_dir
	if [ "${_musicsrc}" = "kuwo" ];then
		kuwo_main
	else
		kugou_main
	fi
done
