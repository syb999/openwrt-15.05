#!/bin/sh

paudiourl=$(uci get autodl.@autodl[0].isyurl)
paudioname=$(uci get autodl.@autodl[0].isyname)
paudiopath=$(uci get autodl.@autodl[0].isypath)
paudionumber=$(uci get autodl.@autodl[0].isynumber)

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$paudiopath" ];then
		ln -s $paudiopath /autodl
	fi
elif [ ! -d "/autodl/$paudiopath" ];then
		ln -s $paudiopath /autodl
fi

cd /$paudiopath

urlprefix=https://mp3.aikeu.com/
urlid="$(echo $paudiourl | cut -d "-" -f 3 | cut -d "." -f 1)/"

indexstart=1
indexend=$paudionumber

if [ ! -d "/$paudiopath/$paudioname" ]; then
	mkdir $paudioname
fi

while [ $indexstart -le $indexend ]
do
	url=${urlprefix}${urlid}${indexstart}.mp3
	wget-ssl -q -c $(uci get network.lan.ipaddr) -O /tmp/tmp.XM.testwget > /dev/null 2>&1
	if [ -s /tmp/tmp.XM.testwget ];then
		wget-ssl -q -c $url -O $indexstart.mp3
	else
		wget -q -c $url -O $indexstart.mp3
	fi

	if [ $indexstart -le 9 ];then
		nindexstart=000$indexstart
		mv -f /$paudiopath/$indexstart.mp3 /$paudiopath/$paudioname/$nindexstart.mp3
	elif [ $indexstart -le 99 ];then
		nnindexstart=00$indexstart
		mv -f /$paudiopath/$indexstart.mp3 /$paudiopath/$paudioname/$nnindexstart.mp3
	elif [ $indexstart -le 999 ];then
		nnnindexstart=0$indexstart
		mv -f /$paudiopath/$indexstart.mp3 /$paudiopath/$paudioname/$nnnindexstart.mp3
	else
		mv -f /$paudiopath/$indexstart.mp3 /$paudiopath/$paudioname/$indexstart.mp3
	fi
	indexstart=$(echo `expr $indexstart + 1`)
	rm /tmp/tmp.XM.testwget
done
