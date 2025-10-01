#!/bin/sh
# 周末工作日打卡计划任务

function ones_digit() {
	head -n3 /dev/urandom | tr -dc "123456789" | head -c1
}

function tens_digit() {
	head -n3 /dev/urandom | tr -dc "123456789" | head -c2
}

function test_addday() {
	if [ "$(date +%A)" = "Saturday" ];then
		if [ ! -z "$(cat /etc/autosignworklist | sed 's/\ /\n/g' | grep ${today})" ];then
			addday="on"
		fi
	elif [ "$(date +%A)" = "Sunday" ];then
		if [ ! -z "$(cat /etc/autosignworklist | sed 's/\ /\n/g' | grep ${today})" ];then
			addday="on"
		fi
	fi
}

function sync_year() {
	ping -c1 -W 1 223.5.5.5 >/dev/null 2>&1

	if [ $? -eq 0 ];then
		ntpd -q -p ntp.aliyun.com
		sleep 3 
	fi

	sign_year="$(uci get autosign.@autosign[0].tianapidate)"
	real_year="$(date +%Y)"

	if [ "${sign_year}" = "${real_year}" ];then
		echo pass
	else
		uci set autosign.@autosign[0].tianapidate=${real_year}
		uci commit autosign
	fi
}

sync_year

today=$(date +%Y%m%d)
worklist=$(cat /etc/autosignworklist)  
D31="1231"
addday="off"

test_addday

if [ "${D31}" = "$(date +%m%d)" ];then
	new_year=$(expr $(date +%Y) + 1)
	uci set autosign.@autosign[0].tianapidate=${new_year}
	uci commit autosign

	ping -c1 -W 1 223.5.5.5 >/dev/null 2>&1

	if [ $? -eq 0 ];then
		/usr/autosign/autosigngetdays.sh
		sleep 10
		/usr/autosign/autosigngetwkddays.sh
		sleep 12
	fi

	if [ "${addday}" = "on" ];then
		sed -i "s/^/${today} /" /etc/autosignworklist
	fi
fi

if [ ! -z "$(logread | grep "time disparity of")" ];then
	/etc/init.d/log restart
	logger -t luci-app-autosign " Invalid time detected. Refresh log. "
	/usr/autosign/autosigngetdays.sh
	sleep 10
	/usr/autosign/autosigngetwkddays.sh
	sleep 12
	exit 0
fi

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
	sleep $(ones_digit)

	#curl -d "xxx" http://url 请修改我
fi

rm /tmp/dakawkdswitch.tmp
