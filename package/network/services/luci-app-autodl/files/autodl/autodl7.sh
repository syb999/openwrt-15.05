#!/bin/sh

uci get autodl.@autodl[0].url > /tmp/autodl.url
uci get autodl.@autodl[0].path > /tmp/autodl.path
uci get autodl.@autodl[0].name > /tmp/autodl.name
uci get autodl.@autodl[0].num > /tmp/autodl.num

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)
autodlgetnum=$(cat /tmp/autodl.num)

avdnum0=$(uci get autodl.@autodl[0].url)
avdnum1=$(echo $avdnum0 | cut -d '-' -f 3)

autodlcount=1
aescount=0

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$autodlgetpath" ];then
		ln -s $autodlgetpath /autodl
	fi
else
	if [ ! -d "/autodl/$autodlgetpath" ];then
		ln -s $autodlgetpath /autodl
	fi
fi

cd /$autodlgetpath

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgeturl | grep "\/upload\/" | cut -d '"' -f 4 > /tmp/autodldmdm.0
avdname0=$(cat /tmp/autodldmdm.0)
advnameurlprefix="https://www.ppys5.net"
avdname0url="${advnameurlprefix}${avdname0}"
curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $avdname0url | cut -d "'" -f 14 > /tmp/autodldmdm.1
cat /tmp/autodldmdm.1 | sed 's/m3u8/m3u8\n/g' | sed '$d' > /tmp/autodldmdm.avdurlfulllist

function autodlvd(){
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $avdname1url > /tmp/autodldmdm.2
	if [ -s /tmp/autodldmdm.2 ];then
		avdname2=$(cat /tmp/autodldmdm.2 | grep m3u8)
		avdname2m=$(cat /tmp/autodldmdm.2p)
		avdname2url="https://${avdname2m}${avdname2}"
		curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $avdname2url | grep 'ts' > /tmp/autodltmp.index.m3u8
		hlsaeskey=$(curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $(cat /tmp/autodltmp.index.m3u8 | head -n 1 | cut -d '"' -f 2) > /tmp/autodldmdm.aeskey)
		strkey=$(hexdump -v -e '16/1 "%02x"' /tmp/autodldmdm.aeskey)
		sed 1d -i /tmp/autodltmp.index.m3u8
		autodlm3u8="/tmp/autodltmp.index.m3u8"

		while read LINE
		do
			autodlts=$(echo $LINE)
			wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.autodl.testwget > /dev/null 2>&1
			if [ -s /tmp/tmp.autodl.testwget ];then
				wget-ssl --timeout=35 -q -c $autodlts -O $autodlgetpath/aestmphls.ts
			else
				wget --timeout=35 -q -c $autodlt s-O $autodlgetpath/aestmphls.ts
			fi
			rm /tmp/tmp.autodl.testwget
			openssl aes-128-cbc -d -in aestmphls.ts -out tmphls.ts -nosalt -iv $(printf '%032x' $aescount) -K $strkey 
			cat tmphls.ts >> $autodlgetpath/hls.ts
			rm $autodlgetpath/aestmphls.ts
			rm $autodlgetpath/tmphls.ts
			aescount=$(expr $aescount + 1)
		done < $autodlm3u8
		autodlcount=$(expr $autodlcount + 1)
		avdnum1=$(echo `expr $avdnum1 + 1`)
	fi
	rm /tmp/autodldmdm.2
	sed 1d -i /tmp/autodldmdm.avdurlfulllist
}


while [ $avdnum1 -le $autodlgetnum ]
do
	avdname1=$(cat /tmp/autodldmdm.avdurlfulllist | head -n 1 )
	echo ${avdname1##*https} > /tmp/autodldmdm.11
	sed -e 's/%3A%2F%2F/:\/\//;s/%2F/\//g;s/%3A/:/g' -i /tmp/autodldmdm.11
	cat /tmp/autodldmdm.11 | cut -d '/' -f 3 > /tmp/autodldmdm.2p
	sed -i 's/:\/\//https:\/\//' -i /tmp/autodldmdm.11
	avdname1url=$(cat /tmp/autodldmdm.11)

	if [ $avdnum1 -le 9 ];then
		autodlvd
		avdnum2=00$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum2集.ts
	elif [ $avdnum1 -le 99 ];then
		autodlvd
		avdnum3=0$avdnum1
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum3集.ts
	else
		autodlvd
		mv -f $autodlgetpath/hls.ts $autodlgetpath/$avdname2第$avdnum1集.ts
	fi
done

if [ ! -d "/$autodlgetpath/$autodlgetname" ]; then
mkdir $autodlgetname
fi

mv -f *.ts $autodlgetname

rm /tmp/autodldmdm.*
rm /tmp/autodl.url
