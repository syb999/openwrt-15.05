#!/bin/sh

epathtxtp1="var c = bt(\""
epathtxtp2=$(echo $1)
#epathtxtp2=$(echo $1 | sed 's/%2b/+/g;s/%3d/=/g;s/%2f/\//g;s/%5c/\\/g;s/%3f/?/g;s/%2a/*/g')
epathtxtp3="\")"
epathtxt=${epathtxtp1}${epathtxtp2}${epathtxtp3}
sed -i '$d' /usr/autodl/ep.js
echo $epathtxt >> /usr/autodl/ep.js

echo $(node /usr/autodl/ep.js)
