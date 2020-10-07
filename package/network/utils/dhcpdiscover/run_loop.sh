#!/bin/sh

INTERFACES="wlan0 eth0"
OUTPUT_PATH="./proms"
LOOP_DELAY=60

mkdir -p "$OUTPUT_PATH"

while true; do
    for dev in $INTERFACES; do
        echo "checking $dev"
        ./dhcpdiscover -p -i "$dev" > "$OUTPUT_PATH/${dev}.prom" &
    done
    sleep "$LOOP_DELAY"
done
