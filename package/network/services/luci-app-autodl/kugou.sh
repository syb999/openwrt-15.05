#!/bin/bash

[[ "$1" == "" ]] && echo -e "Usage: ./kugou.sh playall\n       ./kugou.sh play" && exit 1

thelist="8888 6666 59703 52144 52767 24971 31308 31310 21101 33162 33160 46910 33163 33166"

if [ "$1" == "playall" ];then
	echo -n ""
elif [ "$1" == "play" ];then
	randomnum="$(head -n 5 /dev/urandom | tr -dc '123456789' | head -c 1)"
	count=1
	for r in $thelist;do
		if [ "$randomnum" == "$count" ];then
			thelist=$r
			break
		fi
		count=$(expr $count + 1)
	done
else
	exit 1
fi

function mixsonglist() {
	rm /tmp/kugou.mixlist > /dev/null 2>&1
	for kgp in $thelist;do
		for pp in $(seq 3);do
			curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 https://www.kugou.com/yy/rank/home/1-$kgp.html?p=$pp | grep mixsong | cut -d '"' -f 2 | cut -d '"' -f 1 >> /tmp/kugou.mixlist
		done
	done
}

function showlyric() {
	loadtimemin=00
	loadtimesec=00
	starttime=0
	for ic in $(seq 1 $(cat $thetmplyric | wc -l));do
		nloadtimemin="$(cat $thetmplyric | head -n $ic | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2 | cut -d ':' -f 1)"
		nloadtimesec="$(cat $thetmplyric | head -n $ic | tail -n 1 | cut -d ']' -f 1 | cut -d '[' -f 2 | cut -d ':' -f 2 | cut -d '.' -f 1)"
		if [ "$nloadtimemin" == "$loadtimemin" ];then
			mintosec="0"
		else
			mintosec=$(expr $(expr $nloadtimemin - $loadtimemin) \* 60 + $nloadtimesec)
		fi
		if [ "$mintosec" == "0" ];then
			sleeptime=$(expr $nloadtimesec - $loadtimesec)
		else
			sleeptime=$(expr $mintosec - $loadtimesec)
		fi
		echo -ne "\r\033[31m      $(cat $thetmplyric | head -n $ic | tail -n 1 | cut -d ']' -f 2)      \033[0m\n"
		sleep $sleeptime
		loadtimemin=$nloadtimemin
		loadtimesec=$nloadtimesec
	done
	rm $thetmplyric
}

function kugouplay() {
	kghash=$(cat $thetmpfile1 | head -n 1 | cut -d '"' -f 1)
	kgname=$(echo -en "$(cat $thetmpfile1 | head -n 2 | tail -n 1 | cut -d '"' -f 1)" | sed s'/\ //g;s/-/_/g')
	kgmixid=$(cat $thetmpfile1 | head -n 3 | tail -n 1 | cut -d '}' -f 1 | cut -d ',' -f 1)
	mp3prefix="https://wwwapi.kugou.com/yy/index.php?r=play/getdata"
	mp3hash="&hash=${kghash}"
	mp3mid="&mid=cb6010e84a1298873dfe9adcf4943d33"
	mp3id="&album_audio_id=${kgmixid}"
	mp3url=${mp3prefix}${mp3hash}${mp3mid}${mp3id}
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $mp3url > $thetmpfile2
	urlinfo=$(cat $thetmpfile2)
	echo ${urlinfo#*offset:0\]} > $thetmpfile3
	thelyrictmp=$(cat $thetmpfile3)
	echo ${thelyrictmp%%\",\"author_id*} > $thetmpfile3
	echo -en "$(cat $thetmpfile3)" | grep -v "hash:" | grep -v "al:" | grep -v "sign:" | grep -v "qq:" | grep -v "total:" | grep -v "offset:" | grep -v "ar:" | grep -v "ti:" | grep -v "by:" | sed '1d' > $thetmplyric
	echo ${urlinfo#*play_url\":\"} > $thetmpurl
	themp3tmp=$(cat $thetmpurl)
	echo ${themp3tmp%%\",\"authors*} | sed 's/\\//g' > $thetmpurl
	wget -q $(cat $thetmpurl) -O /tmp/$kgname.xuoguk
	if [ $(ls -l /tmp | grep xuoguk | awk '{print $5}') -lt "2300000" ];then
		echo VIP收费歌曲，跳过
		rm /tmp/$kgname.xuoguk /tmp/kugou.lyric
	else
		mv /tmp/$kgname.xuoguk /tmp/$kgname.mp3
		while [ "$(busybox ps | grep mpg123 | grep -v grep | grep root)" != "" ];do
			sleep 2
		done
		mpg123 /tmp/$kgname.mp3 &
		sleep 3
		showlyric
		rm /tmp/$kgname.mp3
	fi
	rm /tmp/kugou.tmp.*
	sleep 1
}

thetmpfile1="/tmp/kugou.tmp.1"
thetmpfile2="/tmp/kugou.tmp.2"
thetmpfile3="/tmp/kugou.tmp.3"
thetmplyric="/tmp/kugou.lyric"
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
