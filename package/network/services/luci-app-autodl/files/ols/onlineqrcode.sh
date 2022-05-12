#!/bin/sh

qrfp=$(uci get autodl.@autodl[0].qrcodefilepath)
qrcodeoutputpath=$(uci get autodl.@autodl[0].qrcodeoutputpath)
olip=$(uci get autodl.@autodl[0].olip)
olp1=$(uci get autodl.@autodl[0].olp1)
olp2=$(uci get autodl.@autodl[0].olp2)

localip=$(uci get autodl.@autodl[0].qrcodeclientip)
localport=$(uci get uhttpd.main.listen_http | awk '/0.0.0.0/ {print $1}' | cut -d ':' -f 2)

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

mkdir /tmp/csm
ln -s /tmp/csm /www


cp $qrfp /tmp/csm/csm.run.csv

count=1
for t in $(seq 1 $(cat $qrfp | wc -l));do
	curl $olip:$olp1/qrccode/$(urlencode $localip)%3a$localport%3a$count
	imgcount=$(expr $count % 3)

	compname=$(cat /tmp/csm/csm.run.csv | head -n $count | tail -n 1 | awk -F ',' '{print $1}')
	qrcurl=$(cat /tmp/csm/csm.run.csv | head -n $count | tail -n 1  | awk -F ',' '{print $2}')
	localinfo=$(cat /tmp/csm/csm.run.csv | head -n $count | tail -n 1  | awk -F ',' '{print $3}')

	wget-ssl --timeout=3 $olip:$olp2/csm/tmp.csm$imgcount.png -O /tmp/tmp.csm.png
	remotepng="/tmp/tmp.csm.png"
	while [ ! -s "$remotepng" ]
	do
		sleep 3
		wget-ssl --timeout=3 $olip:$olp2/csm/tmp.csm$imgcount.png -O /tmp/tmp.csm.png
	done

	mv /tmp/tmp.csm.png $qrcodeoutputpath/$compname.png
	count=$(expr $count + 1)
done
rm  /tmp/csm/csm.run.csv

