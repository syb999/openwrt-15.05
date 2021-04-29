#!/bin/sh

rm /tmp/tmp.Audioxm.list

paudiopath=$(uci get autodl.@autodl[0].xmlypath)
paudioname=$(uci get autodl.@autodl[0].xmlyname)

cd /$paudiopath/$paudioname
find *.mp3 > /tmp/tmp.Audioxm.list
