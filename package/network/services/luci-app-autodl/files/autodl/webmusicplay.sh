#!/bin/sh

_musicsrc="$(uci get autodl.@autodl[0].webmusicsrc)"

if [ "${_musicsrc}" = "9ku" ];then
	musiclist="$(uci get autodl.@autodl[0].web9kulist)"
else
	musiclist="$(uci get autodl.@autodl[0].webkugoulist)"
fi

case $musiclist in
	[0-9]*) theid="$musiclist"
	;;
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

# ---- kuwo -------------------------------------------------------------------
kuwo_ids() {
	case "$1" in
		kuwo-soaring) echo 93 ;;
		kuwo-hot) echo 16 ;;
		kuwo-new) echo 17 ;;
		kuwo-shortvideo) echo 158 ;;
		kuwo-monthly) echo 79 ;;
		kuwo-cantonese) echo 182 ;;
		all) echo "93 16 17 158 79 182" ;;
	esac
}

kuwo_url() {
	curl -k -s -A "Mozilla/5.0 (Linux; Android 10)" --connect-timeout 10 -m 20 \
		"https://antiserver.kuwo.cn/anti.s?type=convert_url3&rid=MUSIC_$1&format=mp3&response=url" \
		| lua /usr/autodl/kgjson.lua kuwourl
}

kuwo_main() {
	_kwids="$(kuwo_ids "$(uci get autodl.@autodl[0].webkuwolist)")"
	if [ -z "$_kwids" ]; then
		sleep 30
		return
	fi
	for _id in $_kwids; do
		curl -k -s -A "Mozilla/5.0 (Linux; Android 10)" --connect-timeout 10 -m 30 \
			"https://kbangserver.kuwo.cn/ksong.s?from=pc&fmt=json&pn=0&rn=100&type=bang&data=content&id=${_id}&show_copyright_off=0&pcmp4=1&isbang=1" \
			| lua /usr/autodl/kgjson.lua kuwobang > /tmp/kuwo.tmp.list
		_kwtotal="$(wc -l < /tmp/kuwo.tmp.list | tr -d ' ')"
		_kwi=0
		while IFS='|' read -r _rid _kwname _kwartist _kwdur _kwpay; do
			_kwi=$((_kwi + 1))
			[ -z "$_rid" ] && continue
			case "$_kwpay" in
				''|*[!0-9]*) _kwpay=0 ;;
			esac
			# pay 0xff.... = member only, kuwo only serves an 11 second sample
			if [ $((_kwpay / 65536)) -eq 255 ]; then
				echo "$(date '+%Y-%m-%d %H:%M:%S') ${_kwname} member only, skipped" >> /tmp/webmusic_kuwo.log
				continue
			fi
			_kwurl="$(kuwo_url "$_rid")"
			if [ -n "$_kwurl" ]; then
				_kwlen="$(curl -k -s -I -A "Mozilla/5.0 (Linux; Android 10)" --connect-timeout 8 -m 15 "$_kwurl" 2>/dev/null | tr -d '\r' | sed -n 's/^[Cc]ontent-[Ll]ength: //p' | head -n1)"
				case "$_kwlen" in
					''|*[!0-9]*) _kwlen=0 ;;
				esac
				if [ "$_kwlen" -gt 0 ] && [ "$_kwlen" -lt 320000 ]; then
					echo "$(date '+%Y-%m-%d %H:%M:%S') ${_kwname} member only (preview), skipped" >> /tmp/webmusic_kuwo.log
					continue
				fi
			fi
			if [ -z "$_kwurl" ]; then
				echo "$(date '+%Y-%m-%d %H:%M:%S') ${_rid} ${_kwname} no playable url, skipped" >> /tmp/webmusic_kuwo.log
				continue
			fi
			# the luci status page and the download button read these two
			printf '%s\n' "$_kwurl" > /tmp/webmusic.tmp.url
			printf '%s\n' "${_kwname}_${_kwartist}" > /tmp/webmusic.tmp.info
			echo "$(date '+%Y-%m-%d %H:%M:%S') ${_kwi}/${_kwtotal} ${_kwname}_${_kwartist}" >> /tmp/webmusic_kuwo.log
			if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ]; then
				wget-ssl -t 5 -q -c "$_kwurl" -O "$(uci get autodl.@autodl[0].webmusicpath)/${_kwname}_${_kwartist}.mp3"
			fi
			curl -k -s "$_kwurl" --connect-timeout 5 | mpg123 --timeout 2 --no-resync -
			while [ "$(ps -w | grep mpg123 | grep -v grep | awk '{print$1}')" ]; do
				sleep 2
			done
			sleep 1
		done < /tmp/kuwo.tmp.list
	done
	rm -f /tmp/kuwo.tmp.list
}

test_dir() {
	if [ ! -d "$(uci get autodl.@autodl[0].webmusicpath)" ]; then
		mkdir -p "$(uci get autodl.@autodl[0].webmusicpath)"
		chmod 777 "$(uci get autodl.@autodl[0].webmusicpath)"
	fi
}

ku9_get_times() {
	_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "class=\"songName" | wc -l)
	if [ ${_num} = 0 ];then
		_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "target=_1" | wc -l)
	fi
	if [ ${_num} = 0 ];then
		_num=$(curl -k -s "https://www.9ku.com/${the_a}" | grep "target=\"_blank" | wc -l)
	fi
}

ku9_gen_num() {
	head -n6 /dev/urandom | tr -dc "0-$1" | head -c1
}

ku9_split_num() {
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

ku9_gen_id() {
	ku9_split_num
	for n in $(seq 1 ${_length});do
		_new="$(cat /tmp/split_num.tmp.mpt_$n)"
		_target="${_target}${_new}"
	done

	_target=$(expr ${_target} + 0)
	rm /tmp/split_num.tmp.mpt_*
}

ku9_geturl() {
	ku9_gen_id
	if [ ${the_a} = "zhuanji/75.htm" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "target=_1" | head -n${_target} | tail -n1 | cut -d '"' -f2 | cut -d '/' -f3)"
	elif [ ${the_a} = "wangluo/" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "target=\"_blank" | head -n${_target} | tail -n1 | cut -d '"' -f22 | cut -d '/' -f3)"
	elif [ ${the_a} = "yingwen/" ];then
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "songName" | head -n${_target} | tail -n1 | cut -d '"' -f14 | cut -d '/' -f3)"
	else
		thesuffix="$(curl -k -s https://www.9ku.com/${the_a} | grep "class=\"songName" | head -n${_target} | tail -n1 | cut -d '"' -f4 | cut -d '/' -f3)"
	fi
	theurl="${theprefix}${thesuffix}"
	real_id="$(curl -k -s $theurl | grep "Mp3下载" | cut -d '"' -f2 | grep mp3)"
	real_title="$(curl -k -s $theurl | grep "Mp3下载" | grep mp3 | cut -d '>' -f2| sed "s/Mp3下载//" | cut -d '<' -f1 | sed 's/ /_/g' )"
}

mixsonglist_9ku() {
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

	while [ "$real_id" = "" ];do
		ku9_geturl
		_target=""
	done
}

ku9_play() {
	# current source url: shown by the luci status page, used by the download button
	echo "https://music.jsbaidu.com${real_id}" > $thetmpurl
	if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
		wget-ssl -t 5 -q -c "https://music.jsbaidu.com${real_id}" -O $(uci get autodl.@autodl[0].webmusicpath)/${real_title}.mp3
	fi
	curl -s "https://music.jsbaidu.com${real_id}" --connect-timeout 5  | mpg123 --timeout 2 --no-resync -
}

ku9_main() {
	for a in ${theid};do
		mixsonglist_9ku
		ku9_play
	done
}

mixsonglist_kugou() {
	rm /tmp/kugou.mixlist > /dev/null 2>&1
	for kgp in $theid;do
		for pp in $(seq 1 5);do
			curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 https://www.kugou.com/yy/rank/home/1-$kgp.html?p=$pp | grep mixsong | cut -d '"' -f 2 | cut -d '"' -f 1 >> /tmp/kugou.mixlist
		done
	done
}

# stdin filter: kugou escapes every slash in the urls it returns
kugou_url_decode() {
	sed 's/\\//g'
}

# the legacy wwwapi play/getdata endpoint is retired: it now always answers
# err_code 30020 with no play_url at all, so every track ended up silent.
# the mobile api below still hands out a play_url for songs free to stream.
kugou_geturl_mobile() {
	kgmhash="${1:-${kghash}}"
	kgplayurl=""
	kganswer="$(curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -A "Mozilla/5.0 (Linux; Android 10)" "https://m.kugou.com/app/i/getSongInfo.php?cmd=playInfo&hash=${kgmhash}")"
	kgplayurl="$(echo "${kganswer}" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p' | kugou_url_decode)"
	# raw answer of the last lookup, for troubleshooting on the device
	echo "${kganswer}" > $thetmpfile2
}

# same song data, different host: used when the mobile api stops answering json
kugou_geturl_cdn() {
	kgplayurl=""
	command -v md5sum > /dev/null 2>&1 || return 1
	kghashlow="$(echo "${kghash}" | tr 'A-Z' 'a-z')"
	kgkey="$(printf '%s' "${kghashlow}kgcloudv2" | md5sum | cut -d ' ' -f 1)"
	kganswer="$(curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -A "Mozilla/5.0 (Linux; Android 10)" "https://trackercdn.kugou.com/i/v2/?appid=1005&pid=2&cmd=25&behavior=play&hash=${kghashlow}&key=${kgkey}")"
	kgplayurl="$(echo "${kganswer}" | sed -n 's/.*"url":\["\([^"]*\)".*/\1/p' | kugou_url_decode)"
}

# most chart entries are pay only (privilege 10) and kugou returns an empty url
# for them: search the same song name and stream the first free version instead
kugou_geturl_search() {
	kgplayurl=""
	kgkeyword="$(urlencode "$(echo "$(cat $thetmpinfo)" | sed 's/_/ /g')")"
	kganswer="$(curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -A "Mozilla/5.0 (Linux; Android 10)" "https://mobilecdn.kugou.com/api/v3/search/song?format=json&keyword=${kgkeyword}&page=1&pagesize=20")"
	for ghash in $(echo "${kganswer}" | sed 's/"hash":"/\n/g' | tail -n +2 | cut -d '"' -f 1 | head -n 10);do
		kugou_geturl_mobile ${ghash}
		if [ -n "${kgplayurl}" ];then
			return 0
		fi
	done
	kgplayurl=""
	return 1
}

kugouplay() {
	kghash=$(cat $thetmpfile1 | head -n 1 | cut -d '"' -f 1)
	kugou_geturl_mobile
	case "${kganswer}" in
		*'"errcode"'*) ;;
		*) kugou_geturl_cdn ;;
	esac
	if [ -z "${kgplayurl}" ];then
		kugou_geturl_search
	fi
	if [ -z "${kgplayurl}" ];then
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${kghash} no playable url, skipped" >> /tmp/webmusic_kugou.log
		rm /tmp/kugou.tmp.*
		return 1
	fi
	# still needed by the "Download current music" button in the web ui
	echo "${kgplayurl}" > $thetmpurl
	if [ "$(uci get autodl.@autodl[0].webmusic_dl_mode)" = "automatic-download" ];then
		wget-ssl -t 5 -q -c "${kgplayurl}" -O $(uci get autodl.@autodl[0].webmusicpath)/$(cat $thetmpinfo).mp3
	fi
	curl -k -s "${kgplayurl}" --connect-timeout 5 | mpg123 --timeout 2 --no-resync -
	while [ "$(ps -w | grep mpg123 | grep -v grep | awk '{print$1}')" ];do
		sleep 2
	done
	rm /tmp/kugou.tmp.*
	sleep 1
}

kugou_main() {
	thetmpfile1="/tmp/kugou.tmp.1"
	thetmpfile2="/tmp/kugou.tmp.2"
	rm /tmp/webmusic_kugou.log > /dev/null 2>&1
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
	# kugou answers errcode 1002 when it is queried too often: stay quiet during
	# the cooldown instead of hammering it and keeping the block alive.
	# this is a kugou only limit, the other sources must not be held back.
	if [ "${_musicsrc}" != "kuwo" ] && [ -s /tmp/kgweb.throttle ]; then
		_t="$(head -n1 /tmp/kgweb.throttle 2>/dev/null)"
		case "$_t" in
			[0-9]*)
				if [ $(( $(date +%s) - _t )) -lt 90 ]; then
					sleep 20
					continue
				fi
				;;
		esac
	fi
	if [ "${_musicsrc}" = "kuwo" ];then
		kuwo_main
	elif [ "${_musicsrc}" = "9ku" ];then
		ku9_main
	else
		kugou_main
	fi
done
