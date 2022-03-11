#!/bin/sh
#1640966400（单位:秒）表示2022年1月1日00时00分00秒（shell 默认timestamps格式）
#1640966400000（单位:毫秒）表示2022年1月1日00时00分00秒（ximalaya 默认timestamps格式）
#上海动感101:53
#上海经典947:54
#上海Love Radio103.7:55
#上海第一财经:56
#上海五星体育广播:57
#上海新闻广播:58
#上海交通广播:59
#上海戏剧曲艺:60
#上海故事广播:61
#上海东方都市广播:62
#CRI环球资讯:1040
#中国之声:1065

shellts=$(expr $(date +%s)000)
radiochannel=53
curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 https://www.ximalaya.com/radio/$radiochannel | sed 's/listenBackUrl/\n/g;s/\\u0026/\&/g' | grep today | sed '1d' | cut -d ',' -f 1 | sed 's/\":\"//g;s/\"$//g' | sed '$d' > radiourllist
endts=$(cat radiourllist | cut -d '=' -f 3)
for k in $endts;do
	aaccount=1
	tmpcount=1
	if [ $shellts -ge $k ];then
		datenum=$(date +%H%M%S)
		wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.XM.testwget > /dev/null 2>&1
		if [ -s /tmp/tmp.XM.testwget ];then
			wget-ssl -q -c $(cat radiourllist | grep end=$k) -O tmpradio_$datenum.m3u8
		else
			wget -q -c $(cat radiourllist | grep end=$k) -O tmpradio_$datenum.m3u8
		fi
		downloadaac=$(cat tmpradio_$datenum.m3u8 | grep aac | sed 's/\r$//g')

		for i in $downloadaac;do
			if [ -s /tmp/tmp.XM.testwget ];then
				wget-ssl -q $i -O tmpfrag.aac
				nohup aconvert
				theurl=$(cat nohup.out | grep .mp3 | head -n 1 | sed s'/url=\"/\n/;s/\"//g' |  tail -n 1)
				wget-ssl -q $theurl -O tmpfrag.mp3
			else
				wget -q $i -O tmpfrag.aac
				nohup aconvert
				theurl=$(cat nohup.out | grep .mp3 | head -n 1 | sed s'/url=\"/\n/;s/\"//g' |  tail -n 1)
				wget-ssl -q $theurl -O tmpfrag.mp3
			fi
			if [ $aaccount -eq "400" ];then
				tmpcount=$(expr $tmpcount + 1)
				aaccount="0"
			fi
			if [ $tmpcount -lt 10 ];then
				aacnum="0${tmpcount}"
			else
				aacnum="${tmpcount}"
			fi
			cat tmpfrag.mp3 >> tmpradio_${datenum}_${aacnum}.mp3
			aaccount=$(expr $aaccount + 1)
		done
		rm tmpfrag.mp3 tmpradio_$datenum.m3u8
	fi
done
rm radiourllist
