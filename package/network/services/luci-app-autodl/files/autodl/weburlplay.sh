#!/bin/sh
. /usr/autodl/testplayer
urlselected=$(uci get autodl.@autodl[0].wbaudurl)

if [ ! "$testplayer" ];then
	mpg123 $urlselected || curl -L $urlselected | mpg123 -
else
	gst-play-1.0 $urlselected
fi

