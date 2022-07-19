#!/bin/sh

spath="/usr/adbrun/"
sectionname=$(echo $0 | cut -d '_' -f 2 | sed 's/^ADBRUN//')
adbclient=$(uci get adbrun.$sectionname.adbiplist)
adbcommand=$(uci get adbrun.$sectionname.adbcommandlist)

adb connect ${adbclient}:5555
screensize=$(adb -s ${adbclient}:5555 shell wm size | cut -d ':' -f 2 | sed -e "s/ //g;s/\n//g;s/\r//g")

case $adbcommand in
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

if [ $adbcd == "scripts" ];then
	if [ ${adbsh} ==  "takephoto" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_.sh
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif [ ${adbsh} ==  "screenshot" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_.sh
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
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
		fi
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
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
		fi
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
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
		fi
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
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
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=850/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=860/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/;s/dosedbasecx=/basecx=980/;s/dosedbasecy=/basecy=220/' > /tmp/ADBRUN${sectionname}_.sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1145/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1155/' > /tmp/ADBRUN${sectionname}_.sh
		fi
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	elif  [ ${adbsh} == "jdlite" ];then
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
		fi
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
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
		sed -i "s/starttime=/starttime=$(date +%s)/" /tmp/ADBRUN${sectionname}_.sh
		chmod +x /tmp/ADBRUN${sectionname}_.sh
		exec sh /tmp/ADBRUN${sectionname}_.sh
	fi
else
	adb -s ${adbclient}:5555 ${adbcd}
fi

