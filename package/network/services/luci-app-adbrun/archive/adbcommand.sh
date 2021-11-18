#!/bin/sh

spath="/usr/adbrun/"
sectionname=$(echo $0 | cut -d '_' -f 2 | sed 's/^ADBRUN//')
adbclient=$(uci get adbrun.$sectionname.adbiplist)
adbcommand=$(uci get adbrun.$sectionname.adbcommandlist)

adb connect ${adbclient}:5555
screensize=$(adb -s ${adbclient}:5555 shell wm size | cut -d ':' -f 2 | sed -e "s/ //g;s/\n//g;s/\r//g")
if [ ${screensize} == "720x1280" ];then
	sizepath="720x1280"
elif  [ ${screensize} == "720x1560" ];then
	sizepath="720x1560"
elif  [ ${screensize} == "768x1024" ];then
	sizepath="768x1024"
elif  [ ${screensize} == "1080x2244" ];then
	sizepath="1080x2244"
elif  [ ${screensize} == "1080x1920" ];then
	sizepath="1080x1920"
elif  [ ${screensize} == "1080x2280" ];then
	sizepath="1080x2280"
elif  [ ${screensize} == "1080x2340" ];then
	sizepath="1080x2340"
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
	screenshot) adbcd="scripts"
		adbsh="screenshot"
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
	tbbbfarm) adbcd="scripts"
		adbsh="tbbbfarm"
	;;
	11diantao) adbcd="scripts"
		adbsh="11diantao"
	;;
	11diantaolucky) adbcd="scripts"
		adbsh="11diantaolucky"
	;;
	11taobaozc) adbcd="scripts"
		adbsh="11taobaozc"
	;;
	11taobaomiaotang) adbcd="scripts"
		adbsh="11taobaomiaotang"
	;;
	11taobaoshaizi) adbcd="scripts"
		adbsh="11taobaoshaizi"
	;;
	none) adbcd=""
	;;
esac

if [ $adbcd == "scripts" ];then
	if [ ${adbsh} ==  "takephoto" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_sh
		chmod +x /tmp/ADBRUN${sectionname}_sh
		exec sh /tmp/ADBRUN${sectionname}_sh
	elif [ ${adbsh} ==  "screenshot" ];then
		cp ${spath}${adbsh} /tmp/ADBRUN${sectionname}_sh
		chmod +x /tmp/ADBRUN${sectionname}_sh
		exec sh /tmp/ADBRUN${sectionname}_sh
	elif [ ${adbsh} ==  "pyxmlylite" ];then
		echo ximalayalite
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ shell\ screencap\ -p\ \/data\/local\/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ pull\ \/data\/local\/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\ \/tmp\/\ >\ \/dev\/null\ 2>\&1',shell=True)/;s/dosedxrangestart/10/;s/dosedxrangeend/710/;s/dosedxrangestep/5/;s/dosedyrangestart/330/;s/dosedyrangeend/680/;s/dosedtapax/555/;s/dosedtapay/335/;s/dosedtapbx/555/;s/dosedtapby/380/;" > /tmp/ADBRUN${sectionname}_py
			chmod +x /tmp/ADBRUN${sectionname}_py
			exec python3 /tmp/ADBRUN${sectionname}_py
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/30/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/450/;s/dosedyrangeend/950/;s/dosedtapax/855/;s/dosedtapay/648/;s/dosedtapbx/855/;s/dosedtapby/690/;" > /tmp/ADBRUN${sectionname}_py
			chmod +x /tmp/ADBRUN${sectionname}_py
			exec python3 /tmp/ADBRUN${sectionname}_py
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/20/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/470/;s/dosedyrangeend/1010/;s/dosedtapax/830/;s/dosedtapay/500/;s/dosedtapbx/830/;s/dosedtapby/570/;" > /tmp/ADBRUN${sectionname}_py
			chmod +x /tmp/ADBRUN${sectionname}_py
			exec python3 /tmp/ADBRUN${sectionname}_py
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed -e "s/while\ True:/while\ True:\n\tsubprocess.call(r\'adb\ -s\ \$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\'):5555\ exec-out\ screencap\ -p\ >\ \/tmp\/sc\$(uci\ get\ adbrun.\'+sectionname+\'.\'+currentclient+\').jpg\',shell=True)/;s/dosedxrangestart/30/;s/dosedxrangeend/1070/;s/dosedxrangestep/10/;s/dosedyrangestart/450/;s/dosedyrangeend/950/;s/dosedtapax/855/;s/dosedtapay/648/;s/dosedtapbx/855/;s/dosedtapby/690/;" > /tmp/ADBRUN${sectionname}_py
			chmod +x /tmp/ADBRUN${sectionname}_py
			exec python3 /tmp/ADBRUN${sectionname}_py
		elif [ ${screensize} == "1080x2340" ];then
			echo "unsupport now"
		fi
	elif  [ ${adbsh} == "readbook" ];then
		echo fanqiexiaoshuo
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=680/;s/dosedbasey=/basey=130/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=200/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=300/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=1030/;s/dosedbasey=/basey=395/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "kuaishou" ];then
		echo kuaishou
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=386/;s/dosedbasey=/basey=620/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=700/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=750/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=586/;s/dosedbasey=/basey=845/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "diantao" ];then
		echo diantao
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=515/;s/dosedbasex=/basex=605/;s/dosedbasey=/basey=586/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=850/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=860/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1050/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1060/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=835/;s/dosedystart=/ystart=1145/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=1155/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "jdlite" ];then
		echo jdlite
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=350/;s/dosedystart=/ystart=800/;s/dosedbasex=/basex=620/;s/dosedbasey=/basey=550/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1360/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=635/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=835/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=530/;s/dosedystart=/ystart=1655/;s/dosedbasex=/basex=950/;s/dosedbasey=/basey=930/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "tbbbfarm" ];then
		echo tbbbfarm
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1000/;s/dosedbasex=/basex=600/;s/dosedbasey=/basey=570/;s/dosedysetp1=/ysetp1=125/;s/dosedentbbx=/entbbx=500/;s/dosedentbby=/entbby=300/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "768x1024" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1200/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=680/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=460/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1000/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=480/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=260/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1200/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=680/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=460/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=300/;s/dosedystart=/ystart=1295/;s/dosedbasex=/basex=910/;s/dosedbasey=/basey=775/;s/dosedysetp1=/ysetp1=185/;s/dosedentbbx=/entbbx=550/;s/dosedentbby=/entbby=555/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11diantao" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=310/;s/dosedystart=/ystart=710/;s/dosedbasex=/basex=600/;s/dosedbasey=/basey=500/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=755/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1190/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=555/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=755/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1485/;s/dosedbasex=/basex=900/;s/dosedbasey=/basey=850/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11diantaolucky" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=310/;s/dosedystart=/ystart=710/;s/dosedbasex=/basex=635/;s/dosedbasey=/basey=1000/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=945/;s/dosedbasey=/basey=1520/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1190/;s/dosedbasex=/basex=945/;s/dosedbasey=/basey=1320/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1390/;s/dosedbasex=/basex=945/;s/dosedbasey=/basey=1520/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=518/;s/dosedystart=/ystart=1485/;s/dosedbasex=/basex=945/;s/dosedbasey=/basey=1615/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11taobaozc" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=320/;s/dosedystart=/ystart=1065/;s/dosedbasex=/basex=360/;s/dosedbasey=/basey=500/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			echo "unsupport now"
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=770/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1360/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=570/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1560/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=770/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedxstart=/xstart=360/;s/dosedystart=/ystart=1655/;s/dosedbasex=/basex=550/;s/dosedbasey=/basey=865/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11taobaomiaotang" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=600/;s/dosedbasey=/basey=775/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=600/;s/dosedbasey=/basey=950/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=900/;s/dosedbasey=/basey=1350/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=900/;s/dosedbasey=/basey=1150/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=900/;s/dosedbasey=/basey=1350/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=900/;s/dosedbasey=/basey=1445/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	elif  [ ${adbsh} == "11taobaoshaizi" ];then
		echo "shuang11"
		if [ ${screensize} == "720x1280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=360/;s/dosedbasey=/basey=1118/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "720x1560" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=360/;s/dosedbasey=/basey=1168/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2244" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=535/;s/dosedbasey=/basey=1780/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x1920" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=535/;s/dosedbasey=/basey=1580/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2280" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=535/;s/dosedbasey=/basey=1780/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		elif [ ${screensize} == "1080x2340" ];then
			cat ${spath}${adbsh} | sed 's/dosedbasex=/basex=535/;s/dosedbasey=/basey=1875/' > /tmp/ADBRUN${sectionname}_sh
			chmod +x /tmp/ADBRUN${sectionname}_sh
			exec sh /tmp/ADBRUN${sectionname}_sh
		fi
	fi
else
	adb -s ${adbclient}:5555 ${adbcd}
fi

