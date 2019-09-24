#!/bin/sh /etc/rc.common
# Copyright (C) 2008 OpenWrt.org

START=96
USE_PROCD=1

DEVICE_CONFIG_FILE=/etc/config/capwap_devices

start_service() {
    if [ ! -f $DEVICE_CONFIG_FILE ]; then
        touch $DEVICE_CONFIG_FILE
    fi
    local lan_ip=`uci get network.lan.ipaddr`
    echo $lan_ip > /var/run/ac_ipaddr.conf
    procd_open_instance "AC"
    procd_set_param command /usr/sbin/AC
    procd_set_param respawn
    procd_set_param file /etc/config/network
    procd_close_instance
}

reload_service()
{
    local old_ip=`cat /var/run/ac_ipaddr.conf`
    local new_ip=`uci get network.lan.ipaddr`
    if [ "$old_ip" != "$new_ip" ]; then
        /etc/init.d/ac_server restart
    fi
}
