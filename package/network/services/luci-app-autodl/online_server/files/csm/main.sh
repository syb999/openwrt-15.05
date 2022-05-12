#!/bin/bash

clientinfo=$(echo $1 | sed 's/%3a/:/' | sed 's/%2e/./g' )
echo $clientinfo > /tmp/csm.run.newget
remoteip=$(echo $clientinfo | cut -d ':' -f 1)
remoteport=$(echo $clientinfo | cut -d ':' -f 2)
remoteline=$(echo $clientinfo | cut -d ':' -f 3)
imgcount=$(expr $remoteline % 3)

mkdir /tmp/csm
ln -s /tmp/csm /www

wgetfile="/usr/bin/wget-ssl"
if [ ! -f "$wgetfile" ];then
	ln -s /usr/bin/wget /usr/bin/wget-ssl
fi

if [ "$remoteline" -eq 1 ];then
	rm /tmp/csm/csm.run.csv > /dev/null 2>&1
fi

remotefile="/tmp/csm/csm.run.csv"
while [ ! -s "$remotefile" ]
do
	sleep 5
	wget-ssl --timeout=3 -q $remoteip:$remoteport/csm/csm.run.csv -O /tmp/csm/csm.run.csv
done

compname=$(cat /tmp/csm/csm.run.csv | head -n $remoteline | tail -n 1 | awk -F ',' '{print $1}')
qrcurl=$(cat /tmp/csm/csm.run.csv | head -n $remoteline | tail -n 1 | awk -F ',' '{print $2}')
localinfo=$(cat /tmp/csm/csm.run.csv | head -n $remoteline | tail -n 1 | awk -F ',' '{print $3}')

echo $compname,$qrcurl,$localinfo

echo "$compname,$qrcurl,$localinfo" > /tmp/csm.run.pythonread

thedistrict="One"
thestreettown="Two"

echo -e "$(echo $compname)\n$thedistrict/$thestreettown/\n$(echo $localinfo)" > /tmp/csm.run.text

bash /usr/online_server/csm/wenzi.sh
sleep 2

python3 /usr/online_server/csm/mergeimg.py

sleep 3

mv /tmp/csm.run.output.png /tmp/csm/tmp.csm$imgcount.png
rm /tmp/csm.run.* > /dev/null 2>&1

