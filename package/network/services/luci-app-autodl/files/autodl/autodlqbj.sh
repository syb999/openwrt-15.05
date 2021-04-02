#!/bin/sh

autodlqbjgetpath=$(cat /tmp/autodlqbj.path)
autodlqbjgetnum=$(cat /tmp/autodlqbj.num)
autodlqbjcookie=$(cat /tmp/autodlqbj.cookie)

if [ ! -d "/autodl" ]; then
	mkdir /autodl
	chmod 777 /autodl
	if [ ! -d "$autodlqbjgetpath" ];then
		mkdir $autodlqbjgetpath
		ln -s $autodlqbjgetpath /autodl
	fi
elif [ ! -d "$autodlqbjgetpath" ];then
	mkdir $autodlqbjgetpath
	ln -s $autodlqbjgetpath /autodl
elif [ ! -d "/autodl/$autodlqbjgetpath" ];then
	ln -s $autodlqbjgetpath /autodl
fi

cd $autodlqbjgetpath

if [ ! -d "$autodlqbjgetpath/tmpnote" ]; then
	mkdir $autodlqbjgetpath/tmpnote
fi
if [ ! -d "$autodlqbjgetpath/mynote" ]; then
	mkdir $autodlqbjgetpath/mynote
fi

qnumber=0
qcurlpage=1
fixfilescount=1

getmo=$(expr $autodlqbjgetnum % 20)
if [ $getmo -eq 0 ];then
	getcount=$(expr $autodlqbjgetnum / 20)
else
	getcount=$(expr $autodlqbjgetnum / 20 + 1)
fi

echo 0 > $autodlqbjgetpath/qbjtmp.latestRevisionlist

while [ $qcurlpage -le $getcount ]
do
	getnewlatestRevision=$(cat $autodlqbjgetpath/qbjtmp.latestRevisionlist | tail -n 1)
	tmpqbjurlpprefix="https://www.qingbiji.cn/getPersonalNotes?latestRevision="
	tmpqbjurlpsuffix="&page_size=20&summary_length=150"
	tmpgetqbjfullurl="${tmpqbjurlpprefix}${getnewlatestRevision}${tmpqbjurlpsuffix}"
	curl -b "$autodlqbjcookie" -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -v $tmpgetqbjfullurl > $autodlqbjgetpath/qbjtmp.qbj$qcurlpage

	sed 's/\"latestRevision\":/\n/g' $autodlqbjgetpath/qbjtmp.qbj$qcurlpage > $autodlqbjgetpath/qbjtmp.newlatestRevision$qcurlpage
	cat $autodlqbjgetpath/qbjtmp.newlatestRevision$qcurlpage >> $autodlqbjgetpath/qbjtmp.qbjfulllist
	cat $autodlqbjgetpath/qbjtmp.newlatestRevision$qcurlpage | tail -n 1 | cut -d ' ' -f 2 | cut -d ',' -f 1 >> $autodlqbjgetpath/qbjtmp.latestRevisionlist

	qcurlpage=$(echo `expr $qcurlpage + 1`)
done

cat $autodlqbjgetpath/qbjtmp.qbjfulllist | while read LINE
do
	qaurl=$(echo $LINE)
	echo ${qaurl%%\, \"source*} > $autodlqbjgetpath/qbjtmp.newqbj.1
	qa2url=$(cat $autodlqbjgetpath/qbjtmp.newqbj.1)
	echo ${qa2url#*noteId\":\ } > $autodlqbjgetpath/qbjtmp.newqbj.2
	notenumber=$(cat $autodlqbjgetpath/qbjtmp.newqbj.2)
	qprefixurl="https://www.qingbiji.cn/showNote/"
	tmpqlist="${qprefixurl}${notenumber}"
	curl -b "$autodlqbjcookie" -s --retry 3 --retry-delay 2 --connect-timeout 10 -m 20 -v $tmpqlist > $autodlqbjgetpath/qbjtmp.note$qnumber

	rdnote=$(cat $autodlqbjgetpath/qbjtmp.note$qnumber)
	echo ${rdnote#*noteContent} > $autodlqbjgetpath/tmpnote/note$qnumber
	sed -e 's/&lt;br\/&gt;/\n/g;s/&lt;\/p&gt;&lt;/\n/g;s/&lt;\/p&gt;/\n/g;s/\" value=\"&lt;html&gt;&lt;body&gt;&lt;p&gt;//g;s/\" value=\"&lt;p&gt;/\n/g;s/&lt;br \/&gt;/\n/g;s/\" value=\"&lt;html&gt;&lt;body&gt;//g;s/&lt;br \/&gt;//g;s/\\n/\n/g;s/&amp;lt;//g;s/&amp;gt;//g;s/&amp;nbsp;//g' $autodlqbjgetpath/tmpnote/note$qnumber > $autodlqbjgetpath/mynote/note$qnumber

	sed -i '/^$/d' $autodlqbjgetpath/mynote/note$qnumber
	sed -i '$d' $autodlqbjgetpath/mynote/note$qnumber

	cat $autodlqbjgetpath/qbjtmp.newqbj.2 >> $autodlqbjgetpath/qbjtmp.fullnoteID
	qnumber=$(echo `expr $qnumber + 1`)
done
rm $autodlqbjgetpath/qbjtmp.note0
rm $autodlqbjgetpath/mynote/note0
rm $autodlqbjgetpath/tmpnote/note0

# rename filename
if [ ! -d "$autodlqbjgetpath/note" ]; then
	mkdir $autodlqbjgetpath/note
fi

qrealfilenumber=$(ls $autodlqbjgetpath/mynote -l | grep "^-" | wc -l)
qgetfilenumber=$(echo $qrealfilenumber)
while [ $fixfilescount -le $qrealfilenumber ]
do
	if [ $qgetfilenumber -le 9 ];then
		nqgetfilenumber=00$qgetfilenumber
		cp $autodlqbjgetpath/mynote/note$fixfilescount $autodlqbjgetpath/note/note$nqgetfilenumber.txt
	elif [ $qgetfilenumber -le 99 ];then
		nnqgetfilenumber=0$qgetfilenumber
		cp $autodlqbjgetpath/mynote/note$fixfilescount $autodlqbjgetpath/note/note$nnqgetfilenumber.txt
	elif [ $qgetfilenumber -le 999 ];then
		cp $autodlqbjgetpath/mynote/note$fixfilescount $autodlqbjgetpath/note/note$qgetfilenumber.txt
	fi
	qgetfilenumber=$(echo `expr $qgetfilenumber - 1`)
	fixfilescount=$(echo `expr $fixfilescount + 1`)
done

rm -rf $autodlqbjgetpath/mynote
rm -rf $autodlqbjgetpath/tmpnote
rm $autodlqbjgetpath/qbjtmp.*

