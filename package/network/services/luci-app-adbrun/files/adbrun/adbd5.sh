#!/bin/sh

while true
do
    sleep 16
    adb -s 192.168.170.25:5555 shell input swipe 201 599 203 243
    sleep 16
    adb -s 192.168.170.25:5555 shell input swipe 206 597 205 242
done
