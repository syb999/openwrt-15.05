#/bin/sh

myFile="/tmp/acstatus"
apModeFile="/proc/sfax8_mode_info"
fit_ap=1

start_ac() {
	AC /etc/capwap &
}

while [ 1 ]
do
	result=`ps | grep AC | grep -v grep`
	if [ "$result" = "" ];then
		start_ac
		sleep 1
	else
		sleep 2
	fi
done

