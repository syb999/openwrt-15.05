#!/bin/sh

spath="/usr/adbrun/"
sectionname=$(echo $0 | cut -d '_' -f 2 | sed 's/^ADBRUN//')
adbclient=$(uci get adbrun.$sectionname.adbiplist)
adbcommand=$(uci get adbrun.$sectionname.adbcommandlist)

screensize=$(adb -s ${adbclient}:5555 shell wm size | cut -d ':' -f 2 | sed -e "s/ //g;s/\n//g;s/\r//g")

case $adbcommand in
	get-input-event) adbcd="get input event"
	;;
	record-tap) adbcd="record tap"
	;;
	crazy-tap) adbcd="crazy tap"
	;;
	update-preview-picture) adbcd="update preview picture"
	;;
	push-and-install-apk) adbcd="push and install apk"
	;;
	reboot-bootloader) adbcd="reboot bootloader"
	;;
	reboot-recovery) adbcd="reboot recovery"
	;;
	reboot-fastboot) adbcd="reboot fastboot"
	;;
	reboot) adbcd="reboot"
	;;
	poweroff) adbcd="shell reboot -p"
	;;
	auto-install-ADBKeyboard) adbcd="auto-install ADBKeyboard"    
	;;
	input-chinese) adbcd="input chinese"
	;;
	menu-key) adbcd="shell input keyevent 82"
	;;
	home-key) adbcd="shell input keyevent 3"
	;;
	return-key) adbcd="shell input keyevent 4"
	;;
	allow-unknown-sources) adbcd="shell settings put global install_non_market_apps 1"
	;;
	turn-offon-the-screen) adbcd="shell input keyevent 26"
	;;
	turn-on-the-screen) adbcd="shell input keyevent 224"
	;;
	increase-screen-brightness) adbcd="shell input keyevent 221"
	;;
	reduce-screen-brightness) adbcd="shell input keyevent 220"
	;;
	playstop) adbcd="shell input keyevent 85"
	;;
	playnext) adbcd="shell input keyevent 87"
	;;
	playprevious) adbcd="shell input keyevent 88"
	;;
	resume-playback) adbcd="shell input keyevent 126"
	;;
	pause-playback) adbcd="shell input keyevent 127"
	;;
	mute) adbcd="shell input keyevent 164"
	;;
	runcamera) adbcd="shell am start -n com.android.camera/.Camera"
	;;
	photograph) adbcd="shell input keyevent 27"
	;;
	screenrecord) adbcd="shell screenrecord --time-limit 30 --size ${screensize} /data/local/tmp/screenrecord.mp4"
	;;
	dlscreenrecord) adbcd="pull /data/local/tmp/screenrecord.mp4 $(uci get adbrun.@adbinit[0].adbphotopath)/screenrecord.mp4"
	;;
	runwechat) adbcd="shell am start -n com.tencent.mm/.ui.LauncherUI"
	;;
	runqq) adbcd="shell am start -n com.tencent.mobileqq/.activity.SplashActivity"
	;;
	takephoto) adbcd="scripts"
		adbsh="takephoto"
	;;
	screenshot) adbcd="scripts"
		adbsh="screenshot"
	;;
	readbook) adbcd="scripts"
		adbsh="readbook"
	;;
	kuaishou) adbcd="scripts"
		adbsh="kuaishou"
	;;
	diantaolive) adbcd="scripts"
		adbsh="diantaolive"
	;;
	autodiantao) adbcd="scripts"
		adbsh="diantao"
	;;
	autojdlite) adbcd="scripts"
		adbsh="jdlite"
	;;
	tbbbfarm) adbcd="scripts"
		adbsh="tbbbfarm"
	;;
	none) adbcd=""
	;;
esac

if [ "$adbcd" == "scripts" ];then
	if [ ${adbsh} ==  "takephoto" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_.sh
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} ==  "screenshot" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_.sh
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "readbook" ];then
		echo fanqiexiaoshuo
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=680/;s/dosedbasey=/basey=130/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=680/;s/dosedbasey=/basey=157/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=754/;s/dosedbasey=/basey=130/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=200/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=395/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2400" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=395/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "kuaishou" ];then
		echo kuaishou
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=620/;s/dosedbasecx=/basecx=655/;s/dosedbasecy=/basecy=145/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=655/;s/dosedbasecy=/basecy=175/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=428/;s/dosedbasey=/basey=620/;s/dosedbasecx=/basecx=727/;s/dosedbasecy=/basecy=145/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=700/;s/dosedbasecx=/basecx=780/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=845/;s/dosedbasecx=/basecx=1075/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2400" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=845/;s/dosedbasecx=/basecx=1075/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "diantaolive" ];then
		echo diantaolive
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=620/;s/dosedbasecx=/basecx=655/;s/dosedbasecy=/basecy=145/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=655/;s/dosedbasecy=/basecy=175/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=428/;s/dosedbasey=/basey=620/;s/dosedbasecx=/basecx=727/;s/dosedbasecy=/basecy=145/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=700/;s/dosedbasecx=/basecx=780/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=845/;s/dosedbasecx=/basecx=1075/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2400" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=845/;s/dosedbasecx=/basecx=1075/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "diantao" ];then
		echo diantao
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=515/;s/dosedbasex=/basex=605/;s/dosedbasey=/basey=586/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=623/;s/dosedbasex=/basex=605/;s/dosedbasey=/basey=709/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=399/;s/dosedystart=/ystart=515/;s/dosedbasex=/basex=700/;s/dosedbasey=/basey=770/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=850/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=1160/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1145/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1155/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2400" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1145/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1350/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "jdlite" ];then
		echo jdlite
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=350/;s/dosedystart=/ystart=800/;s/dosedbasex=/basex=620/;s/dosedbasey=/basey=550/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=350/;s/dosedystart=/ystart=968/;s/dosedbasex=/basex=620/;s/dosedbasey=/basey=665/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=388/;s/dosedystart=/ystart=800/;s/dosedbasex=/basex=688/;s/dosedbasey=/basey=550/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1360/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=635/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1655/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=930/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2400" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1655/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=860/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} == "tbbbfarm" ];then
		echo tbbbfarm
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1000/;s/dosedbasex=/basex=600/;s/dosedbasey=/basey=570/;s/dosedysetp1=/ysetp1=125/;s/dosedentbbx=/entbbx=500/;s/dosedentbby=/entbby=300/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "768x1024" ];then
			echo "unsupport now"
		elif [ ${screensize} == "800x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=333/;s/dosedystart=/ystart=1000/;s/dosedbasex=/basex=666/;s/dosedbasey=/basey=570/;s/dosedysetp1=/ysetp1=125/;s/dosedentbbx=/entbbx=555/;s/dosedentbby=/entbby=300/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1200/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=680/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=460/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1000/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=480/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=260/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1200/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=680/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=460/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1295/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=775/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=555/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=.*/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	fi
elif [ "$adbcd" == "get input event" ];then
	adb -s ${adbclient}:5555 shell getevent -l | grep -v add | grep -v name | awk '{print$1}' | cut -d ':' -f1 > /tmp/${adbclient}.getevent &
	while true;do
		if [ ! -z "$(cat "/tmp/${adbclient}.getevent" | grep input)" ];then
			kill -9 $(busybox ps | grep "${adbclient}:5555 shell getevent" | grep -v grep | awk '{print$1}')
			break
		fi
	done
	adb -s ${adbclient}:5555 shell touch "/sdcard/event$(cat /tmp/${adbclient}.getevent | tail -n1 | sed 's/.*[^0-9]//')"
elif [ "$adbcd" == "record tap" ];then
	theevent=$(cat /tmp/${adbclient}.getevent | tail -n1)
	sleep 2
	adb -s ${adbclient}:5555 shell dd if=${theevent} of=/sdcard/recordtap &
	sleep $(uci get adbrun.$sectionname.adb_recordtime)
	kill -9 $(busybox ps | grep "if=${theevent}" | grep -v grep | awk '{print$1}')
elif [ "$adbcd" == "crazy tap" ];then
	cat /usr/adbrun/input/crazytap.sh | sed "s/\/event/\/event$(cat /tmp/${adbclient}.getevent | tail -n1 | sed 's/.*[^0-9]//')/" > /tmp/crazytap.sh
	sed -i "s/_looptime=/_looptime=$(uci get adbrun.$sectionname.adb_looptime)/" /tmp/crazytap.sh
	adb -s ${adbclient}:5555 push /tmp/crazytap.sh /sdcard/
	if [ -z "$(adb -s ${adbclient}:5555 shell cat /sdcard/recordtap | grep -v "No such file")" ];then
		adb -s ${adbclient}:5555 push /usr/adbrun/input/recordtap /sdcard/
	fi
	adb -s ${adbclient}:5555 shell sh /sdcard/crazytap.sh
elif [ "$adbcd" == "update preview picture" ];then
	rm /tmp/${adbclient}.png
elif [ "$adbcd" == "push and install apk" ];then
	adb -s ${adbclient}:5555 shell mkdir -p /data/local/tmp/
	adb -s ${adbclient}:5555 push "$(uci get adbrun.$sectionname.adb_src_path)" /data/local/tmp/
	sleep 5
	adb -s ${adbclient}:5555 shell pm install "/data/local/tmp/$(basename $(uci get adbrun.$sectionname.adb_src_path))"
	sleep 5
	adb -s ${adbclient}:5555 shell rm "/data/local/tmp/$(basename $(uci get adbrun.$sectionname.adb_src_path))"
elif [ "$adbcd" == "input chinese" ];then                                                                    
        ch_text="$(uci get adbrun.$sectionname.adb_input_ch)"                                                 
        adb -s ${adbclient}:5555 shell ime enable com.android.adbkeyboard/.AdbIME                             
        adb -s ${adbclient}:5555 shell ime set com.android.adbkeyboard/.AdbIME                                
        adb -s ${adbclient}:5555 shell am broadcast -a ADB_INPUT_TEXT --es msg "$ch_text"                     
        adb -s ${adbclient}:5555 shell ime set "$(adb -s ${adbclient}:5555 shell ime list -a | grep mId | grep -v adbkeyboard | head -n1 | awk '{print$1}' | cut -d '=' -f2)"
elif [ "$adbcd" == "auto-install ADBKeyboard" ];then 
	wget https://raw.githubusercontent.com/syb999/android-apk/master/ADBKeyboard.apk -O /tmp/xxx.apk
	sleep 5
	adb -s ${adbclient}:5555 push /tmp/xxx.apk /sdcard/
	sleep 5
	adb -s ${adbclient}:5555 shell pm install /sdcard/xxx.apk
else
	adb -s ${adbclient}:5555 ${adbcd} &
	if [ -n "$(echo "$adbcd" | grep reboot)" ];then
		while [ -n "$(adb devices | grep ${adbclient}:5555)" ];do
			sleep 1
			adb disconnect ${adbclient}
			kill -9 $(busybox ps |grep ${adbclient}:5555 | grep -v grep | awk '{print$1}') >/dev/null 2>&1
		done
	fi
fi
