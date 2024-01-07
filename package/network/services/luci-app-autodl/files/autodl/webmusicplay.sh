#!/bin/sh

_musicsrc="$(uci get autodl.@autodl[0].webmusicsrc)"

if [ "${_musicsrc}" = "9ku" ];then
	musiclist="$(uci get autodl.@autodl[0].web9kulist)"
else
	musiclist="$(uci get autodl.@autodl[0].webkugoulist)"
fi

case $musiclist in
	9ku-top500) theid="music/t_m_hits.htm"
	;;
	9ku-wangluo) theid="wangluo/"
	;;
	9ku-laoge) theid="laoge/"
	;;
	9ku-yingwen) theid="yingwen/"
	;;
	9ku-chaqu) theid="laoge/chaqu.htm"
	;;
	9ku-ktv) theid="zhuanji/75.htm"
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
		if [ "${_musicsrc}" = "9ku" ];then
			theid="music/t_m_hits.htm wangluo/ laoge/ yingwen/ laoge/chaqu.htm zhuanji/75.htm"
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

function ku9_get_times() {
	_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "class=\"songName" | wc -l)
	if [ ${_num} = 0 ];then
		_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "target=_1" | wc -l)
	fi
	if [ ${_num} = 0 ];then
		_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "target=\"_blank" | wc -l)
	fi
}

function ku9_gen_num() {
	head -n6 /dev/urandom | tr -dc "0-$1" | head -c1
}

function ku9_split_num() {
	for i in $(seq 1 ${_length});do
		if [ ${i} -eq 1 ];then
			ku9_gen_num $(echo ${_num} | cut -c1)  > /tmp/split_num.tmp.mpt_$i
		elif [ ${i} -eq 2 ];then
			if [ "$(cat /tmp/split_num.tmp.mpt_1 | grep 0)" != "" ];then
				ku9_gen_num 9 > /tmp/split_num.tmp.mpt_$i
			else
				echo ${_num} | cut -c${i} > /tmp/split_num.tmp.mpt_$i
			fi
		else
			if [ "$(echo $(cat /tmp/split_num.tmp.mpt_1)$(cat /tmp/split_num.tmp.mpt_2))" = "$(echo ${_num} | cut -c1,2)" ];then
				echo ${_num} | cut -c${i} > /tmp/split_num.tmp.mpt_$i
			else
				ku9_gen_num 9 > /tmp/split_num.tmp.mpt_$i
			fi
		fi
	done
}

function ku9_gen_id() {
	ku9_split_num
	for n in $(seq 1 ${_length});do
		_new="$(cat /tmp/split_num.tmp.mpt_$n)"
		_target="${_target}${_new}"
	done

	_target=$(expr ${_target} + 0)
	rm /tmp/split_num.tmp.mpt_*
}

function ku9_geturl() {
	ku9_gen_id
	if [ ${the_a} == "zhuanji/75.htm" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "target=_1" | head -n${_target} | tail -n1 | cut -d '"' -f2 | cut -d '/' -f3)"
	elif [ ${the_a} == "wangluo/" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "target=\"_blank" | head -n${_target} | tail -n1 | cut -d '"' -f22 | cut -d '/' -f3)"
	elif [ ${the_a} == "yingwen/" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "songName" | head -n${_target} | tail -n1 | cut -d '"' -f14 | cut -d '/' -f3)"
	else
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "class=\"songName" | head -n${_target} | tail -n1 | cut -d '"' -f4 | cut -d '/' -f3)"
	fi
	theurl="${theprefix}${thesuffix}"
	real_id="$(curl -k -s $theurl | grep "Mp3下载" | cut -d '"' -f2 | grep mp3)"
	real_title="$(curl -k -s $theurl | grep "Mp3下载" | grep mp3 | cut -d '>' -f2| sed "s/Mp3下载//" | cut -d '<' -f1 | sed 's/ /_/g' )"
}

function mixsonglist_9ku() {
	_num=""
	_target=""
	real_id=""
	theprefix="https://www.9ku.com/down/"
	_random=$(head -n6 /dev/urandom | tr -dc "1-6" | head -c1)

	if [ "$(uci get autodl.@autodl[0].web9kulist)" = "all" ];then
		xcount=1
		for a in ${theid};do
			the_a=${a}
			if [ ${xcount} -eq ${_random} ];then
				break
			else
				xcount=$(expr $xcount + 1)
			fi
		done
	else
		the_a=${theid}
	fi

	ku9_get_times
	_length=${#_num}

	while [ "$real_id" == "" ];do
		ku9_geturl
		_target=""
	done
}

function ku9_play() {
	if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
		wget-ssl -t 5 -q -c "https://music.jsbaidu.com${real_id}" -O $(uci get autodl.@autodl[0].webmusicpath)/${real_title}.mp3
	fi
	curl -s "https://music.jsbaidu.com${real_id}" --connect-timeout 5  | mpg123 --timeout 2 --no-resync -
}

function ku9_main() {
	for a in ${theid};do
		mixsonglist_9ku
		ku9_play
	done
}

function mixsonglist_kugou() {
	rm /tmp/kugou.mixlist > /dev/null 2>&1
	for kgp in $theid;do
		for pp in $(seq 1 5);do
			curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 https://www.kugou.com/yy/rank/home/1-$kgp.html?p=$pp | grep mixsong | cut -d '"' -f 2 | cut -d '"' -f 1 >> /tmp/kugou.mixlist
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
	curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mp3url > $thetmpfile2
	urlinfo=$(cat $thetmpfile2)
	echo ${urlinfo#*play_url\":\"} > $thetmpurl
	themp3tmp=$(cat $thetmpurl)
	echo ${themp3tmp%%\",\"authors*} | sed 's/\\//g' > $thetmpurl
	if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
		wget-ssl -t 5 -q -c $(cat $thetmpurl) -O $(uci get autodl.@autodl[0].webmusicpath)/$(cat $thetmpinfo).mp3
	fi
	curl -k -s $(cat $thetmpurl) --connect-timeout 5 | mpg123 --timeout 2 --no-resync -
	while [ "$(ps -w | grep mpg123 | grep -v grep | awk '{print$1}')" ];do
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
		curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mixsongurl | grep hash | sed 's/\"hash\":\"/\n/;s/\"audio_name\":\"/\n/;s/\"mixsongid\":/\n/' | sed '1d' > $thetmpfile1
		curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mixsongurl | grep "<title>" | cut -d '<' -f2 | cut -d ">" -f2 | cut -d '_' -f1,2 | sed 's/ /_/g' > $thetmpinfo
		kugouplay
	done
	rm /tmp/kugou.*
}

thetmpurl="/tmp/webmusic.tmp.url"
thetmpinfo="/tmp/webmusic.tmp.info"
while true;do
	test_dir
	if [ "${_musicsrc}" = "9ku" ];then
		ku9_main
	else
		kugou_main
	fi
done
