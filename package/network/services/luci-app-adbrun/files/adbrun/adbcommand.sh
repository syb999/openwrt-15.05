#!/bin/sh

spath="/usr/adbrun/"
sectionname=$(echo $0 | cut -d '_' -f 2)
adbclient=$(uci get adbrun.$sectionname.adbiplist)
adbcommand=$(uci get adbrun.$sectionname.adbcommandlist)

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
	runxmlylite) adbcd="shell am start -n  com.ximalaya.ting.lite/com.ximalaya.ting.android.host.activity.MainActivity"
	;;
	pyxmlylite) adbcd="scripts"
		adbsh="pyxmlylite"
	;;


	none) adbcd=""
	;;
esac

if [ $adbcd == "scripts" ];then
	cp ${spath}${adbsh} /tmp/${sectionname}_py
	python3 /tmp/${sectionname}_py
else
	adb -s ${adbclient}:5555 ${adbcd}
fi

