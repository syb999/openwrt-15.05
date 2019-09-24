#!/bin/sh

cat /sys/kernel/debug/npu_counts > /tmp/dailyData.txt
for _dev in /sys/class/ieee80211/*; do
    [ -e "$_dev" ] || continue
    dev="${_dev##*/}"
    band=`cat /sys/kernel/debug/ieee80211/$dev/rwnx/band_type`
    echo "band======$band" >> /tmp/dailyData.txt
    cat /sys/kernel/debug/ieee80211/$dev/rwnx/error_dump >> /tmp/dailyData.txt
    cat /sys/kernel/debug/ieee80211/$dev/rwnx/skb_alloc_fail >> /tmp/dailyData.txt
    cat /sys/kernel/debug/ieee80211/$dev/rwnx/recovery_hb >> /tmp/dailyData.txt
done
