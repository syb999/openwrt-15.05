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

	temp_v="0"
	for fileName in `find . -name "*.m4a" | sort`
	do 
		tempName=${fileName#*./}
		mp3ffmpeg=$(echo $tempName)
		ffmpeg -v quiet -i $mp3ffmpeg -acodec libmp3lame $mp3ffmpeg.mp3
		temp_v=$tempName
	done

	for tmfile in `ls | grep .mp3`
	do
		newfile=$(echo $tmfile | sed 's/.m4a//g')
		mv $tmfile $newfile
	done

	rm *.m4a
fi

