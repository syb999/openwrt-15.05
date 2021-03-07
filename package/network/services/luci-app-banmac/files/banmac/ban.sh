#!/bin/sh

getcmac=$(uci get banmac.@banlist[0].banlist_mac)

iptables -I FORWARD -m mac --mac-source $getcmac -j DROP

