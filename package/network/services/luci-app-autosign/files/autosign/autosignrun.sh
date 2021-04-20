#!/bin/sh

today=$(date +%Y%m%d)
holidaylist=$(cat /etc/autosignvacationlist)  

for i in $holidaylist;
do
	if [ $i != $today ]; then
		echo 1 >> /usr/autosign/dakaswitch;	
	else
		echo 0 >> /usr/autosign/dakaswitch;
	fi
done 
 
pd=$(cat /usr/autosign/dakaswitch | grep 0)

if [ "$pd" == 0 ]; then
	logger 今天是休息日，停止打卡!
else
	logger 今天是工作日，开始打卡!
	sleep 7
	#curl -d "xxx" http://url
fi

rm /usr/autosign/dakaswitch

