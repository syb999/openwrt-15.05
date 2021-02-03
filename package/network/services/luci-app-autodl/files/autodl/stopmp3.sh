#!/bin/sh

ps | grep mp3a.sh | grep -v grep > /tmp/tmpmp3124.tmp
cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 1 | head -n 1 > /tmp/tmpmp3124.tmp2
astopmp3=$(cat /tmp/tmpmp3124.tmp2)
if [ "$astopmp3" = "" ];then
	cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 2 | head -n 1 > /tmp/tmpmp3124.tmp3
	astopmp3k=$(cat /tmp/tmpmp3124.tmp3)
	kill $astopmp3k > /dev/null 2>&1
else
	kill $astopmp3 > /dev/null 2>&1
fi

ps | grep mp3a.sh | grep -v grep > /tmp/tmpmp3124.tmpx
cat /tmp/tmpmp3124.tmpx | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmpx2
xastopmp3=$(cat /tmp/tmpmp3124.tmpx2)

if [ "$xastopmp3" = "" ];then
	cat /tmp/tmpmp3124.tmpx | cut -d ' ' -f 2 > /tmp/tmpmp3124.tmpx3
	xastopmp3k=$(cat /tmp/tmpmp3124.tmpx3)
	kill $xastopmp3k > /dev/null 2>&1
else
	kill $xastopmp3 > /dev/null 2>&1
fi

pidof mpg123 > /tmp/tmpmpg123.tmp
runmpg123=$(cat /tmp/tmpmpg123.tmp)
kill $runmpg123 > /dev/null 2>&1

rm /tmp/tmpmpg123.*
rm /tmp/tmpmp3124.*

