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
elif  [ ${screensize} == "1080x1920" ];then
	sizepath="1080x1920"
elif  [ ${screensize} == "1080x2280" ];then
	sizepath="1080x2280"
fi

case $adbcommand in
	turn-offon-the-screen) adbcd="shell input keyevent 26"
	;;
	turn-on-the-screen) adbcd="shell input keyevent 224"
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
	appactivity) adbcd="shell dumpsys activity activities | grep -i run"
	;;
	runxmlylite) adbcd="shell am start -n com.ximalaya.ting.lite/com.ximalaya.ting.android.host.activity.MainActivity"
	;;
	runfqxs) adbcd="shell am start -n com.dragon.read/.pages.splash.SplashActivity"
	;;
	runwechat) adbcd="shell am start -n com.tencent.mm/.ui.LauncherUI"
	;;
	runqq) adbcd="shell am start -n com.tencent.mobileqq/.activity.SplashActivity"
	;;
	runtaobao) adbcd="shell am start -n  com.taobao.taobao/com.taobao.tao.TBMainActivity"
	;;
	runtaobaolite) adbcd="shell am start -n  com.taobao.litetao/com.taobao.ltao.maintab.MainFrameActivity"
	;;
	rundiantao) adbcd="shell am start -n com.taobao.live/.home.activity.TaoLiveHomeActivity"
	;;
	runjdlite) adbcd="shell am start -n com.jd.jdlite/.MainActivity"
	;;
	takephoto) adbcd="scripts"
		adbsh="takephoto"
	;;
	pyxmlylite) adbcd="scripts"
		adbsh="pyxmlylite"
	;;
	readbook) adbcd="scripts"
		adbsh="readbook"
	;;
	kuaishou) adbcd="scripts"
		adbsh="kuaishou"
	;;
	autodiantao) adbcd="scripts"
		adbsh="diantao"
	;;
	autojdlite) adbcd="scripts"
		adbsh="jdlite"
	;;
	11diantao) adbcd="scripts"
		adbsh="11diantao"
	;;
	11taobaozc) adbcd="scripts"
		adbsh="11taobaozc"
	;;
	none) adbcd=""
	;;
esac

if [ $adbcd == "scripts" ];then
	if [ ${adbsh} ==  "takephoto" ];then
		cp ${spath}${adbsh} /tmp/${sectionname}_sh
		chmod +x /tmp/${sectionname}_sh
		sh /tmp/${sectionname}_sh
	elif [ ${adbsh} ==  "pyxmlylite" ];then
		echo ximalayalite
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ shell\ screencap\ -p\ \/data\/local\/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ pull\ \/data\/local\/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\ \/tmp\/\ >\ \/dev\/null\ 2>\&1',shell=True)/;s/dosedxrangestart/10/;s/dosedxrangeend/710/;s/dosedxrangestep/5/;s/dosedyrangestart/330/;s/dosedyrangeend/680/;s/dosedtapax/555/;s/dosedtapay/335/;s/dosedtapbx/555/;s/dosedtapby/380/;" > /tmp/${sectionname}_py
			chmod +x /tmp/${sectionname}_py
			python3 /tmp/${sectionname}_py
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/30/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/450/;s/dosedyrangeend/950/;s/dosedtapax/855/;s/dosedtapay/648/;s/dosedtapbx/855/;s/dosedtapby/690/;" > /tmp/${sectionname}_py
			chmod +x /tmp/${sectionname}_py
			python3 /tmp/${sectionname}_py
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/20/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/470/;s/dosedyrangeend/1010/;s/dosedtapax/830/;s/dosedtapay/500/;s/dosedtapbx/830/;s/dosedtapby/570/;" > /tmp/${sectionname}_py
			chmod +x /tmp/${sectionname}_py
			python3 /tmp/${sectionname}_py
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/30/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/450/;s/dosedyrangeend/950/;s/dosedtapax/855/;s/dosedtapay/648/;s/dosedtapbx/855/;s/dosedtapby/690/;" > /tmp/${sectionname}_py
			chmod +x /tmp/${sectionname}_py
			python3 /tmp/${sectionname}_py
		fi
	elif  [ ${adbsh} == "readbook" ];then
		echo fanqiexiaoshuo
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=680/;s/dosedbasey=/basey=130/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=200/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	elif  [ ${adbsh} == "kuaishou" ];then
		echo kuaishou
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=620/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=700/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	elif  [ ${adbsh} == "diantao" ];then
		echo diantao
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=515/;s/dosedbasex=/basex=605/;s/dosedbasey=/basey=586/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=850/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=860/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	elif  [ ${adbsh} == "jdlite" ];then
		echo jdlite
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=350/;s/dosedystart=/ystart=800/;s/dosedbasex=/basex=620/;s/dosedbasey=/basey=550/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1360/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=635/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11diantao" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=310/;s/dosedystart=/ystart=710/;s/dosedbasex=/basex=600/;s/dosedbasey=/basey=500/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=1705/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1190/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=1505/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=1705/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11taobaozc" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=320/;s/dosedystart=/ystart=1065/;s/dosedbasex=/basex=360/;s/dosedbasey=/basey=500/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=770/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1360/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=570/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		elif  [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=770/' > /tmp/${sectionname}_sh
			chmod +x /tmp/${sectionname}_sh
			sh /tmp/${sectionname}_sh
		fi
	fi
else
	adb -s ${adbclient}:5555 ${adbcd}
fi

