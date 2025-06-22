#!/bin/sh

autodlgetpath="$(uci get autodl.@autodl[0].path)"
autodlgetname="$(uci get autodl.@autodl[0].name)"
autodlstartnum="$(uci get autodl.@autodl[0].startnum)"
autodlendnum="$(uci get autodl.@autodl[0].endnum)"

if [ ! -d "$autodlgetpath/$autodlgetname" ]; then
	mkdir -p "$autodlgetpath/$autodlgetname"
	chmod 777 -R "$autodlgetpath/$autodlgetname"
fi

v_url="$(uci get autodl.@autodl[0].url)"
v_num="$(basename ${v_url} | cut -d '.' -f1 | cut -d '-' -f1)"

start_num="$(uci get autodl.@autodl[0].startnum)"
end_num="$(uci get autodl.@autodl[0].endnum)"

for i in $(seq ${start_num} ${end_num});do
	base_url="https://www.qdm88.com/dongmanplay/${v_num}-1-${i}.html"

	d_prefix="https://danmu.yhdmjx.com/m3u8.php?url="
	d_url="$(curl -s --retry 3 --retry-delay 3 --connect-timeout 10 -m 20 ${base_url} | grep "\"url\"" | sed '1d' | awk -F 'url' '{print$2}' | cut -d '"' -f3)"

	d_mix="${d_prefix}${d_url}"
	d_content="$(curl -s --retry 3 --retry-delay 3 --connect-timeout 10 -m 20 ${d_mix} > /tmp/qqq_content.tmp)"

	bt_token="$(cat /tmp/qqq_content.tmp | grep bt_token | cut -d '"' -f2)"
	bt_url="$(cat /tmp/qqq_content.tmp | grep getVideoInfo | cut -d '"' -f4)"

	decrypto_url="$(python3 /usr/autodl/qdm88.py -e "${bt_url}" -i "${bt_token}")"
	if [ "$i" -lt 10 ];then
		num_v=00$i
	elif [ "$i" -lt 100 ];then
		num_v=0$i
	else
		num_v=$i
	fi

	p_prefix="$(echo ${decrypto_url} | awk -F'/' '{OFS="/"; $NF=""; sub("/$",""); print}')"

	wget-ssl -q $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
	if [ -s /tmp/tmp.autodl.testwget ];then
		WGET=$(which wget-ssl)
	else
		WGET=$(which wget)
	fi

	$WGET --timeout=25 -q "${decrypto_url}" -O "$autodlgetpath/$autodlgetname/tmp.autodl.xm3u8"

	if [ -z "$(file $autodlgetpath/$autodlgetname/tmp.autodl.xm3u8 | grep MP4)" ];then
		p_suffix="$(cat /tmp/tmp.autodl.xm3u8 | grep m3u8)"

		p_middle="$(echo ${p_suffix} | awk -F'/' '{OFS="/"; $NF=""; print}')"
		new_url="${p_prefix}/${p_suffix}"
		$WGET --timeout=25 -q "${new_url}" -O "$autodlgetpath/$autodlgetname/tmp.autodl.xm3u8"

		for i in $(cat "$autodlgetpath/$autodlgetname/tmp.autodl.xm3u8" | grep ts);do
			ts_url="${p_prefix}/${p_middle}${i}"
			$WGET --timeout=25 -q "${ts_url}" -O "/tmp/tmp.autodl.fragts"
			cat /tmp/tmp.autodl.fragts >> "$autodlgetpath/$autodlgetname/第${num_v}集.ts"
		done

		FFMPEG=$(which ffmpeg)
		$FFMPEG -i "$autodlgetpath/$autodlgetname/第${num_v}集.ts" "$autodlgetpath/$autodlgetname/第${num_v}集.mp4"

		rm "$autodlgetpath/$autodlgetname/tmp.autodl.xm3u8"
		rm /tmp/tmp.autodl.*
	else
		mv "$autodlgetpath/$autodlgetname/tmp.autodl.xm3u8" "$autodlgetpath/$autodlgetname/第${num_v}集.mp4"
	fi
done

