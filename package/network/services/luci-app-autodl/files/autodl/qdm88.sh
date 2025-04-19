#!/bin/sh

autodlgetpath="$(uci get autodl.@autodl[0].path)"
autodlgetname="$(uci get autodl.@autodl[0].name)"
autodlstartnum="$(uci get autodl.@autodl[0].startnum)"
autodlendnum="$(uci get autodl.@autodl[0].endnum)"

if [ ! -d "$autodlgetpath/$autodlgetname" ]; then
	mkdir -p "$autodlgetpath/$autodlgetname"
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
		num_v=0$i
	else
		num_v=$i
	fi

	wget-ssl -q $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
	if [ -s /tmp/tmp.autodl.testwget ];then
		wget-ssl --timeout=25 -q "${decrypto_url}" -O "$autodlgetpath/$autodlgetname/第${num_v}集.mp4"
	else
		wget --timeout=25 -q "${decrypto_url}" -O "$autodlgetpath/$autodlgetname/第${num_v}集.mp4"
	fi

done

