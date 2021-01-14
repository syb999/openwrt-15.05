#!/bin/sh

ps | grep playmp3.sh | grep -v grep > /tmp/tmpmp3124.tmp
cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmp2

astopmp3=$(cat /tmp/tmpmp3124.tmp2)
kill $astopmp3

ps | grep playmp3.sh | grep -v grep > /tmp/tmpmp3124.tmp
cat /tmp/tmpmp3124.tmp | cut -d ' ' -f 1 > /tmp/tmpmp3124.tmp2

astopmp3=$(cat /tmp/tmpmp3124.tmp2)
kill $astopmp3

ps | grep mpg123 | grep -v grep > /tmp/tmpmpg123.tmp
cat /tmp/tmpmpg123.tmp | cut -d ' ' -f 1 > /tmp/tmpmpg123.tmp2

runmpg123=$(cat /tmp/tmpmpg123.tmp2)
kill $runmpg123

rm /tmp/tmpmpg123.*
rm /tmp/tmpmp3124.*

