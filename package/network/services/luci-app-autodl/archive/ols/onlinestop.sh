#!/bin/sh
olip=$(uci get autodl.@autodl[0].olip)
olp1=$(uci get autodl.@autodl[0].olp1)

kill -9 $(busybox ps | grep "onlineplayxm" | grep -v grep | cut -d 'r' -f 1)
thekn=$(busybox ps | grep mpg123 | grep -v grep | awk '{print $6}' | cut -d 'e' -f 2 | cut -d '.' -f 1)
kill -9 $(busybox ps | grep "mpg123" | grep -v grep | cut -d 'r' -f 1)
rm /tmp/online*.mp3 /tmp/pidfind.onlineplay /tmp/filecount.onlineplay
curl -s $olip:$olp1/playrm/$thekn
sleep 5
curl -s $olip:$olp1/playrm/$(expr $thekn + 1)
sleep 5
curl -s $olip:$olp1/playrm/$(expr $thekn - 1)
sleep 5
curl -s $olip:$olp1/playrm/$(expr $thekn + 2)

