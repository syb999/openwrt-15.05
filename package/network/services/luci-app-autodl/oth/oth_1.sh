#!/bin/sh

numcount=1
pppurl="https://????"
echo "A,B,C,D" > /tmp/tmget.tmp.csv.txt

function getlist(){
for i in $(seq 1 100)
do
	curl -d "" -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0\ \(Windows\ NT\ 10.0\;\ Win64\;\ x64\)"" $pppurl > /tmp/tmget.tmpget

	Qcache=$(cat /tmp/tmget.tmpget)

	echo ${Qcache#*\"title\":\"} > /tmp/tmget.tmpa1
	Qcachea1=$(cat /tmp/tmget.tmpa1)
	echo ${Qcachea1%\",\"states\"*} | sed -e 's/\\n//g' | sed -e 's/,/，/g' | sed -e 's/®/-ORO-/g' > /tmp/tmget.tmpa1

	ovtimes=$(grep -o 'optionvalue' /tmp/tmget.tmpget | wc -l)
	echo ${Qcache#*\"optionvalue\":\"} > /tmp/tmget.tmpa10
	Qcachea10=$(cat /tmp/tmget.tmpa10)
	echo ${Qcachea10%\",\"optionkey\"*} > /tmp/tmget.tmpa11

	Qcachea11=$(cat /tmp/tmget.tmpa11)
	echo " A、${Qcachea11%%\",\"optionkey\"*}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1a

	if [ $(expr $ovtimes) -eq 2 ];then
		echo " B、${Qcachea11#*\"optionvalue\":\"}" | sed -e 's/,/，/g' >> /tmp/tmget.tmpa1a
		sed -i ":a;N;s/\\n//g;ta;s/-//g" /tmp/tmget.tmpa1a
	elif [ $(expr $ovtimes) -eq 5 ];then
		echo " E、${Qcachea11##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1e
		echo ${Qcachea11%\",\"optionkey\"*} > /tmp/tmget.tmpa1listd
		Qcachea1d=$(cat /tmp/tmget.tmpa1listd)
		echo " D、${Qcachea1d##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1d
		echo ${Qcachea1d%\",\"optionkey\"*} > /tmp/tmget.tmpa1listc
		Qcachea1c=$(cat /tmp/tmget.tmpa1listc)
		echo " C、${Qcachea1c##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1c
		echo ${Qcachea1c%\",\"optionkey\"*} > /tmp/tmget.tmpa1listb
		Qcachea1c=$(cat /tmp/tmget.tmpa1listb)
		echo " B、${Qcachea1b##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1b
		echo "$(cat /tmp/tmget.tmpa1b)$(cat /tmp/tmget.tmpa1c)$(cat /tmp/tmget.tmpa1d)$(cat /tmp/tmget.tmpa1e)" >> /tmp/tmget.tmpa1a
		sed -i ":a;N;s/\\n//g;ta;s/-//g" /tmp/tmget.tmpa1a
	else
		echo " D、${Qcachea11##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1d
		echo ${Qcachea11%\",\"optionkey\"*} > /tmp/tmget.tmpa1listc
		Qcachea1c=$(cat /tmp/tmget.tmpa1listc)
		echo " C、${Qcachea1c##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1c
		echo ${Qcachea1c%\",\"optionkey\"*} > /tmp/tmget.tmpa1listb
		Qcachea1b=$(cat /tmp/tmget.tmpa1listb)
		echo " B、${Qcachea1b##*\"optionvalue\":\"}" | sed -e 's/,/，/g' > /tmp/tmget.tmpa1b
		echo "$(cat /tmp/tmget.tmpa1b)$(cat /tmp/tmget.tmpa1c)$(cat /tmp/tmget.tmpa1d)" >> /tmp/tmget.tmpa1a
		sed -i ":a;N;s/\\n//g;ta;s/-//g" /tmp/tmget.tmpa1a
	fi

	echo "$(cat /tmp/tmget.tmpa1a)" >> /tmp/tmget.tmpa1
	sed -i ":a;N;s/\\n//g;ta;s/-//g" /tmp/tmget.tmpa1

	echo ${Qcache#*\"tianalysis\":\"} > /tmp/tmget.tmpb1
	Qcacheb1=$(cat /tmp/tmget.tmpb1)
	echo ${Qcacheb1%\",\"readPdfUrl\"*} | sed -e 's/\\n//g' | sed -e 's/,/，/g' > /tmp/tmget.tmpb1

	echo "$numcount," > /tmp/tmget.000.txt
	echo "$(cat /tmp/tmget.tmpa1)," >> /tmp/tmget.000.txt
	echo " answer ," >> /tmp/tmget.000.txt
	echo $(cat /tmp/tmget.tmpb1) >> /tmp/tmget.000.txt
	sed -i ":a;N;s/\\n//g;ta;s/-//g" /tmp/tmget.000.txt
	echo $(cat /tmp/tmget.000.txt) >> /tmp/tmget.tmp.csv.txt
	numcount=$(echo `expr $numcount + 1`)
done
iconv -f utf-8 -t GB18030 /tmp/tmget.tmp.csv.txt > /root/thelist.csv
rm /tmp/tmget.*
}

for i in $(seq 1 5)
do
	getlist
	cat /root/thelist.csv >> /root/timu.csv
	rm /root/thelist.csv
done
