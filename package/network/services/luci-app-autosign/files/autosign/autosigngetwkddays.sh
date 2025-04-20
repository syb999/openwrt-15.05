#!/bin/sh

autosigngettianapikeyprefix="key="
autosigngettianapikey=$(uci get autosign.@autosign[0].tianapikey)
autosigngettiandateprefix="&type=2&date="
autosigngettiandate=$(uci get autosign.@autosign[0].tianapidate)

tmpgettianapidaytype2="${autosigngettianapikeyprefix}${autosigngettianapikey}${autosigngettiandateprefix}${autosigngettiandate}"

for i in $(seq 1 12)
do
	if [ $i -lt 10 ];then
		i=0$i
		curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -d "$tmpgettianapidaytype2-$i" https://apis.tianapi.com/jiejiari/index > /tmp/atsdaydetail.tmp
	else
		curl -k -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -d "$tmpgettianapidaytype2-$i" https://apis.tianapi.com/jiejiari/index > /tmp/atsdaydetail.tmp
	fi

	sed -i 's/{\"date\":/\n/g' /tmp/atsdaydetail.tmp
	cat /tmp/atsdaydetail.tmp | sed -e 's/{\"date\":/\n/g' | sed -e '1d' > /tmp/atsdaydetail.tmptmp
	echo -e "\n" >> /tmp/atsdaydetail.tmptmp

	cat /tmp/atsdaydetail.tmptmp | while read LINE
	do
		findday=$(echo $LINE | cut -d '"' -f 2)
		echo ${LINE#*\"daycode\":} > /tmp/atsdaydetail.tmptmp.0
		cat /tmp/atsdaydetail.tmptmp.0 | cut -d "," -f 1 > /tmp/atsdaydetail.tmptmp.1
		finddaycode1=$(cat /tmp/atsdaydetail.tmptmp.1)

		if [ -n "$finddaycode1" ]; then
			if [ $finddaycode1 -eq 3 ];then
				echo " $findday" >> /tmp/worklist.atsdaydetail
			fi
		fi
	done
	rm /tmp/atsdaydetail.*
done

cat /tmp/worklist.atsdaydetail | sed -e ":a;N;s/\\n//g;ta;s/-//g" | sed -e 's/^[ \t]*//g' | sed -e 's/-//g' > /etc/autosignworklist
rm /tmp/worklist.atsdaydetail
