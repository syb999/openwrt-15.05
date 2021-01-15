#!/bin/sh

tspath=$(uci get autodl.@autodl[0].path > /tmp/autodl.path)
tsname=$(uci get autodl.@autodl[0].name > /tmp/autodl.name)

autodlgetpath=$(cat /tmp/autodl.path)
autodlgetname=$(cat /tmp/autodl.name)

testffmpeg=$(opkg list-installed | grep ffmpeg)

if [ ! "$testffmpeg" ];then
	echo "No ffmpeg. Stop script."
else
	cd /$autodlgetpath/$autodlgetname

	temp_v="0"
	for fileName in `find . -name "*.ts" | sort`
	do 
		tempName=${fileName#*./}
		mp4ffmpeg=$(echo $tempName)
		ffmpeg -v quiet -i $mp4ffmpeg -vcodec copy $mp4ffmpeg.mp4
		temp_v=$tempName
	done

	for tmfile in `ls | grep .mp4`
	do
		newfile=$(echo $tmfile | sed 's/.ts//g')
		mv $tmfile $newfile
	done

	rm *.ts
fi

