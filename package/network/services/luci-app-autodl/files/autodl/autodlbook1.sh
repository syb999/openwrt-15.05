#!/bin/sh

#http://book.zongheng.com/

uci get autodl.@autodl[0].bookurl > /tmp/autodl.bookurl
uci get autodl.@autodl[0].bookname > /tmp/autodl.bookname
uci get autodl.@autodl[0].bookpath > /tmp/autodl.bookpath

autodlbookgeturl=$(cat /tmp/autodl.bookurl)
autodlbookgetname=$(cat /tmp/autodl.bookname)
autodlbookgetpath=$(cat /tmp/autodl.bookpath)

autodlbookcount=1

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "/autodl/$autodlbookgetpath" ];then
		ln -s $autodlbookgetpath /autodl
	fi
else
	if [ ! -d "/autodl/$autodlbookgetpath" ];then
		ln -s $autodlbookgetpath /autodl
	fi
fi

cd $autodlbookgetpath

curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlbookgeturl > /tmp/autodltmp.zh.tmpbook
cat /tmp/autodltmp.zh.tmpbook | grep href= | grep title | sed 's/\"new\"//g' | cut -d '"' -f 2 > /tmp/autodl.zh.bookurllist
cat /tmp/autodltmp.zh.tmpbook | grep href= | grep title | cut -d '>' -f 2 > /tmp/autodl.zh.booknamelist

autodlbooklist=/tmp/autodl.zh.bookurllist

while read LINE
do
	autodlgetbook=$(echo $LINE)
	curl -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 $autodlgetbook | grep \<p\> | sed 's/ //g' > /tmp/autodltmp.zh.realbook
	autodlechoname=$(cat /tmp/autodl.zh.booknamelist | head -n 1 | sed 's/<\/a//g')
	if [ $autodlbookcount -le 9 ];then
		nautodlbookcount=000$autodlbookcount
		cat /tmp/autodltmp.zh.realbook | grep \<p\> | sed '$d' | sed -e 's/ //g;s/<p>//g;s/<\/p>/\r\n/g' | sed -e "1i$autodlechoname"  > $autodlbookgetname$nautodlbookcount.txt
	elif [ $autodlbookcount -le 99 ];then
		nautodlbookcount=00$autodlbookcount
		cat /tmp/autodltmp.zh.realbook | grep \<p\> | sed '$d' | sed -e 's/ //g;s/<p>//g;s/<\/p>/\r\n/g' | sed -e "1i$autodlechoname" > $autodlbookgetname$nautodlbookcount.txt
	elif [ $autodlbookcount -le 999 ];then
		nautodlbookcount=0$autodlbookcount
		cat /tmp/autodltmp.zh.realbook | grep \<p\> | sed '$d' | sed -e 's/ //g;s/<p>//g;s/<\/p>/\r\n/g' | sed -e "1i$autodlechoname" > $autodlbookgetname$nautodlbookcount.txt
	else
		cat /tmp/autodltmp.zh.realbook | grep \<p\> | sed '$d' | sed -e 's/ //g;s/<p>//g;s/<\/p>/\r\n/g' | sed -e "1i$autodlechoname" > $autodlbookgetname$autodlbookcount.txt
	fi
	sed 1d -i /tmp/autodl.zh.booknamelist
	autodlbookcount=$(expr $autodlbookcount + 1)
done < $autodlbooklist

if [ ! -d "/$autodlbookgetpath/$autodlbookgetname" ]; then
	mkdir $autodlbookgetname
fi

mv -f *.txt $autodlbookgetname

rm /tmp/autodl.*
rm /tmp/autodltmp.*
