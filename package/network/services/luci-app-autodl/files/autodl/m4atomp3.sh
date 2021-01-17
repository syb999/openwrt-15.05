#!/bin/sh

m4apath=$(uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path)
m4aname=$(uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name)

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

testffmpeg=$(opkg list-installed | grep ffmpeg)

if [ ! "$testffmpeg" ];then
	echo "No ffmpeg. Stop script."
else
	ffmpeg -encoders | grep mp3 > /tmp/tmpfind.libmp3
	xfindlibmp3lame=$(cat /tmp/tmpfind.libmp3 | grep lame)
	xfindlibmp3shine=$(cat /tmp/tmpfind.libmp3 | grep shine)
fi

if [ ! "$testffmpeg" ];then
	echo "No ffmpeg. Stop script."
elif [ "$xfindlibmp3lame" = "" ];then
	if [ "$xfindlibmp3shine" != "" ];then
		cd /$paudiopath/$paudioname

		temp_a="0"
		for fileNamea in `find . -name "*.m4a" | sort`
		do 
			tempNamea=${fileNamea#*./}
			mp3ffmpeg=$(echo $tempNamea)
			ffmpeg -v quiet -i $mp3ffmpeg -acodec mp3 $mp3ffmpeg.mp3
			temp_a=$tempNamea
		done

		for tmfilea in `ls | grep .mp3`
		do
			newfilea=$(echo $tmfilea | sed 's/.m4a//g')
			mv $tmfilea $newfilea
		done

		rm *.m4a
		rm /tmp/tmpfind.libmp3
	else
		echo "No ffmpeg mp3 encoders. Stop script."
	fi
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
	rm /tmp/tmpfind.libmp3
fi

