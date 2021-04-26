#!/bin/sh
# 一般工作日打卡计划任务

today=$(date +%Y%m%d)
holidaylist=$(cat /etc/autosignvacationlist)  

for i in $holidaylist;
do
	if [ $i != $today ]; then
		echo 1 >> /tmp/dakaswitch.tmp;	
	else
		echo 0 >> /tmp/dakaswitch.tmp;
	fi
done 
 
pd=$(cat /tmp/dakaswitch.tmp | grep 0)

if [ "$pd" == 0 ]; then
	logger 今天是$today,是休息日，停止自动打卡!
else
	logger 今天是$today,是工作日。开始自动打卡!
	sleep 3
	#curl -d "xxx" http://url 请修改我
fi

rm /tmp/dakaswitch.tmp
