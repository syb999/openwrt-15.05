#!/bin/sh

spath="/usr/adbrun/"
sectionname=$(echo $0 | cut -d '_' -f 2)
adbclient=$(uci get adbrun.$sectionname.adbiplist)
adbcommand=$(uci get adbrun.$sectionname.adbcommandlist)

adb connect ${adbclient}:5555
screensize=$(adb -s ${adbclient}:5555 shell wm size | cut -d ':' -f 2 | sed -e "s/ //g;s/\n//g;s/\r//g")
if [ ${screensize} == "720x1280" ];then
	sizepath="720x1280"
elif  [ ${screensize} == "1080x2244" ];then
	sizepath="1080x2244"
fi

case $adbcommand in
	turn-offon-the-screen) adbcd="shell input keyevent 26"
	;;
	turn-on-the-screen) adbcd="shell input keyevent 224"
	;;
	playback) adbcd="shell input keyevent 126"
	;;
	pause-playback) adbcd="shell input keyevent 127"
	;;
	mute) adbcd="shell input keyevent 164"
	;;
	appactivity) adbcd="shell dumpsys activity activities | grep -i run"
	;;
	runxmlylite) adbcd="shell am start -n com.ximalaya.ting.lite/com.ximalaya.ting.android.host.activity.MainActivity"
	;;
	pyxmlylite) adbcd="scripts"
		adbsh="pyxmlylite"
	;;
	none) adbcd=""
	;;
esac

if [ $adbcd == "scripts" ];then
	cp ${spath}${sizepath}/${adbsh} /tmp/${sectionname}_py
	python3 /tmp/${sectionname}_py
else
	adb -s ${adbclient}:5555 ${adbcd}
fi

