#!/bin/sh

autodlgeturl=$(cat /tmp/autodl.url)
autodlgetpath=$(cat /tmp/autodl.path)


if [ ! -d "/autodl/videos" ]; then
  mkdir /autodl
  chmod 777 /autodl
  ln -s $autodlgetpath /autodl
fi



curl $autodlgeturl | grep m3u8 > /tmp/autodldmdm.1
sleep 3
aurl=$(cat /tmp/autodldmdm.1)
echo ${aurl#*\"url\":\"} | sed 's/\\//g' > /tmp/autodldmdm.2
a2url=$(cat /tmp/autodldmdm.2)
echo ${a2url%\"\,\"url_next*} > /tmp/autodldmdm.3
a3url=$(cat /tmp/autodldmdm.3)
curl $a3url > /tmp/autodldmdm.4
sleep 3
a4url=$(tail -n 1 /tmp/autodldmdm.4)
echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/' > /tmp/autodldmdm.5
a5url=$(echo $a3url | sed 's/index.m3u8/1000k\/hls\/&/')

echo -en "$a5url\n" | python3 /usr/autodl/autodl.py

