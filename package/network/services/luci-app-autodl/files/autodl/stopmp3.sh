#!/bin/sh

ps | grep playmp3.sh | grep -v grep > /tmp/tmpmp3124.tmp
cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmp2
astopmp3=$(cat /tmp/tmpmp3124.tmp2)
kill $astopmp3 > /dev/null 2>&1

ps | grep playmp3lastest.sh | grep -v grep > /tmp/tmpmp3124.tmpx
cat /tmp/tmpmp3124.tmpx | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmpx2
xastopmp3=$(cat /tmp/tmpmp3124.tmpx2)
kill $xastopmp3 > /dev/null 2>&1

ps | grep playmp3.sh | grep -v grep > /tmp/tmpmp3124.tmp
cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmp2
astopmp3=$(cat /tmp/tmpmp3124.tmp2)
kill $astopmp3 > /dev/null 2>&1

ps | grep playmp3lastest.sh | grep -v grep > /tmp/tmpmp3124.tmpx
cat /tmp/tmpmp3124.tmpx | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmpx2
xastopmp3=$(cat /tmp/tmpmp3124.tmpx2)
kill $xastopmp3 > /dev/null 2>&1

pidof mpg123 > /tmp/tmpmpg123.tmp
runmpg123=$(cat /tmp/tmpmpg123.tmp)
kill $runmpg123 > /dev/null 2>&1

rm /tmp/tmpmpg123.*
rm /tmp/tmpmp3124.*

