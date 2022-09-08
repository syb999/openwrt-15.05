#!/bin/sh
fp="$(uci get autodl.@autodl[0].docinpath)/$(uci get autodl.@autodl[0].docinname)"  
cd $fp
mkdir txt
if [ -s /tmp/allfiles.tmp ];then
	rm /tmp/allfiles.tmp
fi
for file in ${fp}/*
do  
    temp_file=`basename $file`  
    echo $temp_file >> /tmp/allfiles.tmp
done
cat /tmp/allfiles.tmp | while read LINE
do
	pngfilename=$(echo $LINE)
	convert -quality 96 $pngfilename /tmp/tmp.new.jpg
	convert /tmp/tmp.new.jpg -resample 150 /tmp/tmp.newimage.jpg
	export TESSDATA_PREFIX="/usr/share/tessdata/"
	export PATH=$PATH:$TESSDATA_PREFIX
	tesseract /tmp/tmp.newimage.jpg /tmp/tessdoc -l chi_sim --dpi 150
	cat /tmp/tessdoc.txt | sed -e '/^$/d' >> ${fp}/000full.txt
	mv /tmp/tessdoc.txt ${fp}/txt/$(echo $LINE | cut -d '.' -f 0).txt
	rm /tmp/tmp.new.jpg /tmp/tmp.newimage.jpg
done
rm /tmp/allfiles.tmp
