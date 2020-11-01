#!/bin/sh

while true
do
    sleep 12
    adb -s 192.168.70.23:5555 shell input swipe 386 619 411 244
    sleep 12
    adb -s 192.168.70.23:5555 shell input swipe 381 613 406 236
done
