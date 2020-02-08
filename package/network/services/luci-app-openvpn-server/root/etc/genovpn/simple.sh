#!/bin/sh

ddns=`uci get openvpn.myvpn.ddns`
port=`uci get openvpn.myvpn.port`

cat > /tmp/my-simple.ovpn  <<EOF
client
dev tun
proto tcp-client
remote $ddns $port
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
EOF
[ -f /etc/ovpnadd.conf ] && cat /etc/ovpnadd.conf >> /tmp/my-simple.ovpn