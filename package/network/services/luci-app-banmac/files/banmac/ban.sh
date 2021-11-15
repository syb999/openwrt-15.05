#!/bin/sh

getcmac=$(uci get banmac.@banlist[0].banlist_mac | tr 'A-Z' 'a-z')
iptables -I FORWARD -m mac --mac-source $getcmac -j DROP

for i in $(seq 0 1)
do
	for x in $(iw wlan${i} station dump | grep -i station | cut -d ' ' -f 2)
	do
		if [ $x = $getcmac ]; then
			iw dev wlan${i} station del $x
		fi
	done
done
