#!/bin/sh
# zigbeed-pair.sh - open a Zigbee pairing window and accept a new device
#
# Why DeviceHub: the coordinator only completes a join while an authorized host
# session exists (the vendor DeviceHub's). zigbeed's own {"Duration":N} window
# is accepted by the coordinator but joins do not complete without that session
# - measured 2026-09-12 on 157.
#
# usage: sh /usr/bin/zigbeed-pair.sh [seconds] [skip_network_check]
#   seconds            window length, default 120
#   skip_network_check 1 = caller already verified the network (saves ~50s:
#                      without it the script would stop/start zigbeed just to
#                      check the kA frame and then stop it again)

LOG=/tmp/zigbeed_pair.log
EVENTS=/tmp/zigbeed_pair_events.log
STATE=/tmp/zigbeed_pair_state        # machine readable state for the LuCI page
SEC=${1:-60}
SKIPNET=${2:-0}
DEVHUB=/usr/bin/DeviceHub
LOCK=/tmp/zigbeed_pair.lock

if ! mkdir $LOCK 2>/dev/null; then
    echo "another pairing window is already running" | tee $LOG
    exit 2
fi
trap "rmdir $LOCK 2>/dev/null" EXIT INT TERM

echo "state=starting remaining=-1 updated=$(date +%s)" > $STATE
echo "[pair] $(date +%H:%M:%S) start, window=${SEC}s, skip_net_check=${SKIPNET}" | tee $LOG

# 1) the device needs an existing network (only checked when the caller asks)
if [ "$SKIPNET" = "1" ]; then
    echo "[pair] $(date +%H:%M:%S) network check skipped (caller says it is up)" | tee -a $LOG
else
    echo "[pair] $(date +%H:%M:%S) ensuring coordinator network..." | tee -a $LOG
    sh /usr/bin/zigbeed-rebuild.sh >> $LOG 2>&1
fi

# 2) DeviceHub owns the serial while the join window is open
echo "[pair] $(date +%H:%M:%S) stopping zigbeed, starting DeviceHub..." | tee -a $LOG
killall zigbeed 2>/dev/null
sleep 1
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid
LD_LIBRARY_PATH=/usr/lib/devicehub $DEVHUB > /tmp/devicehub_pair.log 2>&1 &
sleep 12

echo "state=window remaining=${SEC} updated=$(date +%s)" > $STATE
echo "[pair] $(date +%H:%M:%S) JOIN WINDOW OPEN (${SEC}s) - put the device in pairing mode now" | tee -a $LOG
ubus call devicehub allowjoin '{"sqno":1,"scanflag":1,"deviceSN":""}' >> $LOG 2>&1

# watch for join events while the window is open; close early once a device
# shows up so the gateway comes back as soon as possible
: > $EVENTS
i=0
joined=0
while [ $i -lt $SEC ]; do
    logread 2>/dev/null \
        | grep -iE "gem_device_join_cb|gem_device_state_cb.*state=\{" \
        | grep -v "1047C9FEFF65112C" \
        | sed 's/.*DeviceHub\[[0-9]*\]: *//; s/\x1b\[[0-9;]*m//g' | tail -5 >> $EVENTS
    if grep -q "gem_device_join_cb" $EVENTS 2>/dev/null; then
        joined=1
        break
    fi
    echo "state=window remaining=$((SEC - i)) updated=$(date +%s)" > $STATE
    sleep 5
    i=$((i + 5))
done
if [ $joined = 1 ]; then
    echo "[pair] $(date +%H:%M:%S) device joined - closing the window early" | tee -a $LOG
fi
echo "state=handover remaining=0 updated=$(date +%s)" > $STATE
sort -u $EVENTS > ${EVENTS}.u 2>/dev/null && mv ${EVENTS}.u $EVENTS
if [ -s $EVENTS ]; then
    echo "[pair] $(date +%H:%M:%S) device events seen:" | tee -a $LOG
    sort -u $EVENTS | head -10 >> $LOG
    # the vendor decoder already knows the live state: write it back so the page
    # is correct immediately (device frames only arrive on the next event)
    sort -u $EVENTS | grep -o 'address=[0-9A-F]\{16\}[^}]*state={"Alarm":"[01]"[^}]*}' | tail -20 | while read -r line; do
        addr=$(echo "$line" | sed -n 's/.*address=\([0-9A-F]\{16\}\).*/\1/p')
        alarm=$(echo "$line" | sed -n 's/.*"Alarm":"\([01]\)".*/\1/p')
        tamper=$(echo "$line" | sed -n 's/.*"Tamper":"\([01]\)".*/\1/p')
        [ -n "$addr" ] || continue
        key=$(echo "$addr" | sed 's/\(..\)/\1:/g; s/:$//')
        st=$(( alarm + tamper * 4 ))
        if grep -q "^$key " /etc/zigbeed/known_devices.conf 2>/dev/null; then
            awk -v k="$key" -v s="$st" -v t="$(date +%s)" 'BEGIN{OFS=" "} $1==k{$3=s;$4=t} {print}' \
                /etc/zigbeed/known_devices.conf > /tmp/zigbeed_kd.tmp \
                && mv /tmp/zigbeed_kd.tmp /etc/zigbeed/known_devices.conf
            echo "[pair] state written back: $key -> $st (alarm=$alarm tamper=$tamper)" | tee -a $LOG
        fi
    done
else
    echo "[pair] $(date +%H:%M:%S) no device events (the device did not report)" | tee -a $LOG
fi

# 3) close the window and hand the serial back to zigbeed
echo "[pair] $(date +%H:%M:%S) closing window, starting zigbeed..." | tee -a $LOG
killall DeviceHub 2>/dev/null
sleep 2
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid
/etc/init.d/zigbeed start 2>/dev/null
sleep 12

echo "[pair] $(date +%H:%M:%S) known devices:" | tee -a $LOG
cat /etc/zigbeed/known_devices.conf >> $LOG 2>/dev/null
echo "state=done remaining=0 updated=$(date +%s)" > $STATE
echo "[pair] $(date +%H:%M:%S) done - the device list refreshes on the next poll (~1 min)" | tee -a $LOG
