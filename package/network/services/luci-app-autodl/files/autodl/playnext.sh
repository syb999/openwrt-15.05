#!/bin/sh

ps | grep mpg123 | grep -v grep > /tmp/tmpmpg123.tmp
cat /tmp/tmpmpg123.tmp | cut -d ' ' -f 1 > /tmp/tmpmpg123.tmp2

runmpg123=$(cat /tmp/tmpmpg123.tmp2)
kill $runmpg123

rm /tmp/tmpmpg123.*

