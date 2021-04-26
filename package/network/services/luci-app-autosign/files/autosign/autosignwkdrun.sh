#!/bin/sh
# 周末工作日打卡计划任务

today=$(date +%Y%m%d)
worklist=$(cat /etc/autosignworklist)  

for i in $worklist;
do
	if [ $i != $today ]; then
		echo 1 >> /tmp/dakawkdswitch.tmp;	
	else
		echo 0 >> /tmp/dakawkdswitch.tmp;
	fi
done 
 
wkdpd=$(cat /tmp/dakawkdswitch.tmp | grep 0)

if [ "$wkdpd" == 0 ]; then
	logger 今天是$today,是工作日。开始自动打卡!
	sleep 5
	#curl -d "xxx" http://url 请修改我
fi

rm /tmp/dakawkdswitch.tmp
