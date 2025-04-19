#!/bin/sh

paudiourl=$(uci get autodl.@autodl[0].kugouurl)
paudioname=$(uci get autodl.@autodl[0].kugouname)
paudiopath=$(uci get autodl.@autodl[0].kugoupath)
paudionumber=$(uci get autodl.@autodl[0].kugounumber)

function kugoudownload() {
	if [ "$(echo $paudiourl | grep ".html")" == "" ];then
		curl -s $paudiourl > /tmp/kgtmp.tmp.index
		count=1
	else
		thesuffix="$(echo $paudiourl | cut -d '/' -f $(expr $(echo $paudiourl | grep -o "/" | wc -l) + 1))"
		paudiourl=$(echo $paudiourl | sed "s/${thesuffix}//")
		curl -s $paudiourl > /tmp/kgtmp.tmp.index
		thepagenum="$(echo $thesuffix | sed 's/p//g;s/\.html//;')"
		count="$(expr $thepagenum \* 20 - 19)"
	fi

	totalnum=$(cat /tmp/kgtmp.tmp.index | grep pageTotal | cut -d '"' -f 2)
	totalpage=$(expr $totalnum / 20)

	for p in $(seq 1 $totalpage);do
		if [ "$p" == "$(expr $count / 20 + 1)" ];then
			pageurl="$paudiourl/p$p.html"
			curl -s $pageurl | grep "data-encode_album_audio_id" | cut -d '"' -f10 > /tmp/kgtmp.tmp.audioid
		else
			pageurl="${paudiourl}p${thepagenum}.html"
			paudionumber=$(expr $count + $paudionumber)
			curl -s $pageurl | grep "data-encode_album_audio_id" | cut -d '"' -f10 > /tmp/kgtmp.tmp.audioid
		fi

		for i in $(cat /tmp/kgtmp.tmp.audioid);do
			audioname=$(curl -s $pageurl | grep "$i.html" | cut -d '>' -f3 | cut -d '<' -f1 | sed 's/ //g;s/:/∶/g;s/*/※/g;s/?/？/g;s/</《/g;s/>/》/g;s/\"/“/g;s/|/|/g;s/(/（/g;s/)/）/g')

			if [ $count -lt 10 ];then
				audionum="000$count"
			elif [ $count -lt 100 ];then
				audionum="00$count"
			elif [ $count -lt 1000 ];then
				audionum="0$count"
			else
				audionum="$count"
			fi

			urlprefix="https://wwwapi.kugou.com/yy/index.php?r=play/getdata&appid=1014&dfid=2UIjAE434hQg2auA6h3lClRK&mid=9243ba2d8b19c29dcf007af9105dd478&platid=4&from=111&encode_album_audio_id="
			theurl="${urlprefix}${i}"		
			curl --cookie "$thecookie" $theurl > /tmp/kgtmp.tmp.url
			audiourl=$(cat /tmp/kgtmp.tmp.url | sed 's/play_backup_url\":\"/\n/;s/\\//g' | tail -n1 | cut -d '"' -f1)
			wget $audiourl -O /$paudiopath/$paudioname/$audionum-$audioname.mp3

			count=$(expr $count + 1)
			if [ $count -gt $paudionumber ];then
				break 2
			fi
		done
	done
}

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$paudiopath" ];then
		ln -s $paudiopath /autodl
	fi
elif [ ! -d "/autodl/$paudiopath" ];then
		ln -s $paudiopath /autodl
fi

cd /$paudiopath

if [ ! -d "/$paudiopath/$paudioname" ]; then
	mkdir $paudioname
fi

thecookie="kgmid=9243ba2d8b19c29dcf007af9105dd4"

kugoudownload

rm /tmp/kgtmp.tmp.*

