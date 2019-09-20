#!/bin/sh /etc/rc.common
# Copyright (C) 2008 OpenWrt.org

START=99

start() {
    /usr/sbin/check_wtp.sh &
}

restart() {
    killall WTP
}
