#!/bin/sh

m4apath=$(uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path)
m4aname=$(uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name)

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

testffmpeg=$(opkg list-installed | grep ffmpeg)

if [ ! "$testffmpeg" ];then
	echo "No ffmpeg. Stop script."
else
	cd /$paudiopath/$paudioname

	temp_a="0"
	for fileNamea in `find . -name "*.m4a" | sort`
	do 
		tempNamea=${fileNamea#*./}
		mp3ffmpeg=$(echo $tempNamea)
		ffmpeg -v quiet -i $mp3ffmpeg -acodec libmp3lame $mp3ffmpeg.mp3
		temp_a=$tempNamea
	done

	for tmfilea in `ls | grep .mp3`
	do
		newfilea=$(echo $tmfilea | sed 's/.m4a//g')
		mv $tmfilea $newfilea
	done

	rm *.m4a
fi

