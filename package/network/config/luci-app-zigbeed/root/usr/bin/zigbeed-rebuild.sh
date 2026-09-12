#!/bin/sh
# zigbeed-rebuild.sh v6 - manual rebuild of the coordinator network (via DeviceHub)
#
# usage: sh /usr/bin/zigbeed-rebuild.sh
#
# v6 (2026-09-12) fixes the two reasons a *successful* rebuild was reported as
# failure (and retried 3x = destructive churn):
#   1. coor_ok required the response to contain no "[FF][FF][FF]" run, but a real
#      kA frame carries a long FF region (unused slots) after the parameters ->
#      every successful build looked like an "empty network".
#      Now the kA frame itself is parsed with awk: panid (2 bytes after the
#      F2 03 marker, little endian) must not be FF FF and the channel byte
#      (marker + 41) must not be FF.
#   2. [6/6] depended on /tmp/rtoken (tmpfs -> gone after reboot -> the whole
#      check was skipped and CH stayed "?" = always FAIL), and ran it in
#      background + kill (truncated output).
#      Now [6/6] starts zigbeed and polls /tmp/zigbeed_status.json until a
#      fresh status (ts advanced) reports a valid channel 11..26.
#   Also: rtoken is looked up in /usr/bin first (persistent), /tmp second,
#   and "zigbeed -cmd" is only the last resort (it needs the free serial lock,
#   i.e. it works only while the daemon is stopped - which is the case here).

LOG=/tmp/zigbeed_rebuild.log
DEVHUB=/usr/bin/DeviceHub
COORINFO=/etc/IoT/CoorInfo.json
ZCMD=/usr/bin/zigbeed
RTK=""
[ -x /usr/bin/rtoken ] && RTK=/usr/bin/rtoken
[ -x /tmp/rtoken ] && RTK=/tmp/rtoken

LOCK=/tmp/zigbeed_rebuild.lock
# atomic lock (mkdir): only one rebuild can run at a time
if ! mkdir $LOCK 2>/dev/null; then
    echo "another rebuild is running, exit" | tee $LOG
    exit 2
fi
trap "rmdir $LOCK 2>/dev/null" EXIT INT TERM

# read one command from the coordinator.
# "zigbeed -cmd" is the primary path: it waits long enough to collect the full
# multi-segment reply (the kA frame arrives in a later segment) and it works
# here because the daemon is stopped at this point (the lock is free).
# rtoken (raw tool, no lock) is only a fallback when installed.
coor_read() {   # $1 = AT command, $2 = output file
    : > "$2"
    if [ -n "$RTK" ]; then
        # rtoken -s: read the full window (the kA frame can arrive ~10s into a
        # session; a 3s read misses it and makes a good network look empty)
        "$RTK" -s 12 "$1" > "$2" 2>&1
    else
        # zigbeed -cmd is the fallback (works while the daemon is stopped)
        $ZCMD -cmd "$1" > "$2" 2>&1
    fi
    if [ ! -s "$2" ] && [ -n "$RTK" ]; then
        "$RTK" -s 12 "$1" > "$2" 2>&1
    fi
}

# network presence check with one retry: a single read can miss the kA frame
# (the coordinator pushes it asynchronously), and a false "no network" would
# start a needless, destructive rebuild.
net_check() {   # $1 = output file ; 0 = real network present
    coor_read "AT+RTOKEN" "$1"
    net_ok "$1" && return 0
    sleep 5
    coor_read "AT+RTOKEN" "$1"
    net_ok "$1" && return 0
    return 1
}

# 0 = response holds a kA frame with real parameters (not FF FF / FF channel).
# Rendering is the rtoken/"zigbeed -cmd" one: printable bytes as-is, others as
# [XX]; printable bytes count as "not FF" by construction.
net_ok() {   # $1 = response file
    [ -s "$1" ] || return 1
    awk '
        {
            line = $0; n = 0; i = 1
            while (i <= length(line)) {
                if (substr(line, i, 1) == "[") {
                    t = substr(line, i+1, 2)
                    if (t ~ /^[0-9A-F][0-9A-F]$/ && substr(line, i+3, 1) == "]") {
                        n++; b[n] = t; i += 4; continue
                    }
                }
                n++; b[n] = "P"; i++      # printable byte, never FF
            }
            for (k = 1; k + 41 <= n; k++) {
                if (b[k] == "F2" && b[k+1] == "03") {
                    if ((b[k+15] != "FF" || b[k+16] != "FF") && b[k+41] != "FF")
                        got = 1
                }
            }
        }
        END { if (got) exit 0; exit 1 }
    ' "$1"
}

echo "[1/6] stop zigbeed + DeviceHub..." | tee $LOG
killall zigbeed DeviceHub 2>/dev/null
sleep 3
killall zigbeed 2>/dev/null
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
sleep 1

# Keep-alive protection: coordinator answers AT+VER *and* has a real network
# (kA frame with real parameters) = nothing lost -> refuse to rebuild.
# Coordinator alive but no real kA = network gone (firmware cleanup) -> rebuild.
rm -f /tmp/coor_pre.txt
coor_read "AT+VER" /tmp/coor_pre.txt
if grep -q "REXENSE" /tmp/coor_pre.txt 2>/dev/null; then
    echo "coordinator alive (AT+VER ok), checking network..." | tee -a $LOG
    if net_check /tmp/coor_pre2.txt; then
        echo "network present (real kA frame), nothing to rebuild!" | tee -a $LOG
        echo "restarting zigbeed..." | tee -a $LOG
        rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
        /etc/init.d/zigbeed start 2>/dev/null
        exit 0
    fi
    echo "coordinator alive but no real kA -> rebuild needed" | tee -a $LOG
else
    echo "no AT+VER response (coordinator silent/cold), continue rebuild..." | tee -a $LOG
fi

ATTEMPT=0
SUCCESS=0
while [ $ATTEMPT -lt 3 ] && [ $SUCCESS -eq 0 ]; do
    ATTEMPT=$((ATTEMPT + 1))
    # No GPIO36 reset before DeviceHub: a reset leaves the coordinator in a
    # state where DeviceHub does not form a network (tested) - clear CoorInfo
    # and let DeviceHub build.
    echo "[2/6] attempt ${ATTEMPT}: start DeviceHub (no GPIO reset)..." | tee -a $LOG
    echo "[3/6] clear CoorInfo + DeviceHub, wait 120s for forming..." | tee -a $LOG
    [ -f $COORINFO ] && cp $COORINFO ${COORINFO}.bak
    echo "{}" > $COORINFO
    LD_LIBRARY_PATH=/usr/lib/devicehub $DEVHUB > /tmp/devicehub_rebuild.log 2>&1 &
    DH_PID=$!
    sleep 120

    echo "[4/6] stop DeviceHub..." | tee -a $LOG
    killall DeviceHub 2>/dev/null
    kill $DH_PID 2>/dev/null
    sleep 3

    if net_check /tmp/coor_rsp.txt; then
        echo "  -> attempt ${ATTEMPT} OK: network formed" | tee -a $LOG
        SUCCESS=1
    else
        echo "  -> attempt ${ATTEMPT} FAILED: no real kA frame" | tee -a $LOG
    fi
done

echo "[6/6] start zigbeed + verify via status.json..." | tee -a $LOG
killall zigbeed 2>/dev/null
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
sleep 1

# Remember the old timestamp: a stale status.json must not count as success
TS0=0
if [ -f /tmp/zigbeed_status.json ]; then
    TS0=`sed -n 's/.*"ts": *\([0-9][0-9]*\).*/\1/p' /tmp/zigbeed_status.json | head -1`
    [ -z "$TS0" ] && TS0=0
fi

/etc/init.d/zigbeed start 2>/dev/null

CH=""
TRY=0
while [ $TRY -lt 12 ]; do
    sleep 15
    if [ -f /tmp/zigbeed_status.json ]; then
        TS=`sed -n 's/.*"ts": *\([0-9][0-9]*\).*/\1/p' /tmp/zigbeed_status.json | head -1`
        CV=`sed -n 's/.*"channel": *"\([^"]*\)".*/\1/p' /tmp/zigbeed_status.json | head -1`
        if [ -n "$TS" ] && [ "$TS" -gt "$TS0" ]; then
            case "$CV" in
                1[1-9]|2[0-6]) CH="$CV"; break ;;
            esac
        fi
    fi
    TRY=$((TRY + 1))
done

echo "  status: channel=${CH:-none} (waited $((TRY * 15))s after start)" | tee -a $LOG
if [ -n "$CH" ]; then
    echo "OK: coordinator network up, channel $CH" | tee -a $LOG
    exit 0
fi
echo "FAIL: zigbeed reports no channel (DeviceHub attempts: $ATTEMPT, success: $SUCCESS)" | tee -a $LOG
exit 1
