#!/bin/sh

rm /tmp/tmp.Audioxm.list

uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path
uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name

paudiopath=$(cat /tmp/tmp.XM.path)
paudioname=$(cat /tmp/tmp.XM.name)

cd /$paudiopath/$paudioname
find *.mp3 > /tmp/tmp.Audioxm.list

