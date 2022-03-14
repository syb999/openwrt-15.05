#!/bin/sh

fileparam=$(echo $1 | sed 's/%3A/:/;s/%3a/:/' )
filenum=$(echo $fileparam | cut -d ':' -f 1 )
clientid=$(echo $fileparam | cut -d ':' -f 2)

rm /tmp/onlineplay/online-$clientid-$filenum.mp3

