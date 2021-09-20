#!/bin/sh

docinurl=$(uci get autodl.@autodl[0].docinurl)
docintotalpage=$(uci get autodl.@autodl[0].docinpage)
docinname=$(uci get autodl.@autodl[0].docinname)
pdocinpath=$(uci get autodl.@autodl[0].docinpath)
docindlpage=1

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$pdocinpath" ];then
		ln -s $pdocinpath /autodl
	fi
elif [ ! -d "/autodl/$pdocinpath" ];then
		ln -s $pdocinpath /autodl
fi

cd /$pdocinpath

docgeturlprefix="https://docimg1.docin.com/docinpic.jsp?file="
docgeturlmiddle="&width=1000&pageno="
docgeturlsuffix="&sid="

echo $docinurl | cut -d '-' -f 2 > /tmp/tmp.docin.file0
cat /tmp/tmp.docin.file0 | cut -d '.' -f 1 > /tmp/tmp.docin.file1

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -H ""user-agent": "Mozilla/5.0"" $docinurl > /tmp/tmp.docin.docinurl
cat /tmp/tmp.docin.docinurl | grep flash_param_hzq > /tmp/tmp.docin.sid0
cat /tmp/tmp.docin.sid0 | cut -d '"' -f 2 > /tmp/tmp.docin.sid1


while [ $docindlpage -le $docintotalpage ]
do
	docinfile=$(cat /tmp/tmp.docin.file1)
	docinsid=$(cat /tmp/tmp.docin.sid1)
	docinautodlpng="${docgeturlprefix}${docinfile}${docgeturlmiddle}${docindlpage}${docgeturlsuffix}${docinsid}"
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 --output - $docinautodlpng > docin.png
	if [ $docintotalpage -le 9 ];then
		mv docin.png $docindlpage.png
	elif [ $docintotalpage -le 99 ];then
		if [ $docindlpage -le 9 ];then
			ndocindlpage=0$docindlpage
			mv docin.png $ndocindlpage.png
		else
			mv docin.png $docindlpage.png	
		fi	
	else
		if [ $docindlpage -le 9 ];then
			ndocindlpage=00$docindlpage
			mv docin.png $ndocindlpage.png
		elif [ $docindlpage -le 99 ];then
			ndocindlpage=0$docindlpage
			mv docin.png $ndocindlpage.png
		else
			mv docin.png $docindlpage.png
		fi
	fi
	docindlpage=$(echo `expr $docindlpage + 1`)
done

if [ ! -d "/$pdocinpath/$docinname" ]; then
mkdir $docinname
fi

mv -f *.png $docinname
