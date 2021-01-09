#!/bin/sh

paudiourl=$(cat /tmp/tmp.XM.url)
paudioname=$(cat /tmp/tmp.XM.name)
paudionum=$(cat /tmp/tmp.XM.num)
paudiopath=$(cat /tmp/tmp.XM.path)

urlprefix="https://www.ximalaya.com/revision/play/v1/audio?id="
urlsuffix="&ptype=1"

if [ ! -d "/autodl/audios" ]; then
  mkdir /autodl
  chmod 777 /autodl
  ln -s $paudiopath /autodl
fi

cd /$paudiopath

curl -H ""user-agent": "Mozilla/5.0"" $paudiourl > /tmp/tmpXM.xmlyhttp

xmlyhttp=$(cat /tmp/tmpXM.xmlyhttp)  

for i in `echo "$xmlyhttp" | sed 's/</\n/g'`
do  
    echo $i >> /tmp/tmpXM.xmlyhttp1
done

cat /tmp/tmpXM.xmlyhttp1 | grep isPaid > /tmp/tmpXM.xmlyhttp2

xmlyhttp2=$(cat /tmp/tmpXM.xmlyhttp2)
for i in `echo "$xmlyhttp2" | sed 's/{\"index\":/\n/g'`
do  
    echo $i >> /tmp/tmpXM.xmlyhttp3
done

cat /tmp/tmpXM.xmlyhttp3 | grep '^[0-9]' | cut -d ',' -f 2 | cut -d ':' -f 2 > /tmp/tmpXM.xmlyhttp4
sort -u /tmp/tmpXM.xmlyhttp4 > /tmp/tmpXM.xmlyhttp5
sed '1!G;h;$!d' /tmp/tmpXM.xmlyhttp5 > /tmp/tmpXM.xmlyhttp5d

cat /tmp/tmpXM.xmlyhttp5d | while read LINE
do
	xmlytrackId=$(echo $LINE)
	adurlprefix=$urlprefix
	adurlsuffix=$urlsuffix
	tmpgetaudiourl="${adurlprefix}${xmlytrackId}${adurlsuffix}"
	curl -v $tmpgetaudiourl > /tmp/tmpXM.xmlyhttp6
	tmpaudio=$(cat /tmp/tmpXM.xmlyhttp6)
	echo ${tmpaudio#*src\":\"} > /tmp/tmpXM.xmlyhttp7
	tmpaudio=$(cat /tmp/tmpXM.xmlyhttp7)
	echo ${tmpaudio%\",\"albumIsSample*} > /tmp/tmpXM.xmlyhttp7
	audiofile=$(cat /tmp/tmpXM.xmlyhttp7)
	if [ $paudionum -le 9 ];then
		wget-ssl -q -c $audiofile -O $paudioname0$paudionum.m4a
		sleep 3
		paudionum=$(echo `expr $paudionum - 1`)
	else
		wget-ssl -q -c $audiofile -O $paudioname$paudionum.m4a
		sleep 3
		paudionum=$(echo `expr $paudionum - 1`)
	fi
done

mkdir $paudioname
mv *.m4a $paudioname

rm /tmp/tmpXM.*

