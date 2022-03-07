#!/bin/sh

cpathtxtp1="console.log(c("
cpathtxtp2="$(cat /tmp/sdcode.tmp)"
cpathtxtp3=",\""
cpathtxtp4="$(echo $1)"
cpathtxtp5="\"))"
cpathtxt=${cpathtxtp1}${cpathtxtp2}${cpathtxtp3}${cpathtxtp4}${cpathtxtp5}
sed -i '$d' /usr/autodl/path.js
echo $cpathtxt >> /usr/autodl/path.js

echo $(node /usr/autodl/path.js)
