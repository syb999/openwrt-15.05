#!/bin/sh

setup_channel(){

#set 24g channel

        channel_24g=$(($1 % 11))

                [ "$channel_24g" -eq 0 ] && channel_24g=1

                uci set wireless.radio0.channel="$channel_24g"

                ch_5g=36

        case "$(($1 % 4))" in

                1) ch_5g=48;;

                2) ch_5g=64;;

                3) ch_5g=149;;

                0) ch_5g=36;;

                esac

#set 5g channel

                        uci set wireless.radio1.channel="$ch_5g"

}


init_ap(){
				rm /etc/config/wireless
                /sbin/wifi detect > /etc/config/wireless

                hostssid="wifi-test-$1"

                                uci add wireless wifi-iface                     #......ap......

                                uci set wireless.@wifi-iface[2].ifname=wlan2
                                uci set wireless.@wifi-iface[2].device=radio0   #......radion0......
                                uci set wireless.@wifi-iface[2].network=lan
                                uci set wireless.@wifi-iface[2].mode=ap      #ap
                                uci set wireless.@wifi-iface[2].ssid="$hostssid-1"    #AP ssid
                                uci set wireless.@wifi-iface[2].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[2].key=12345678
#				uci set wireless.@wifi-iface[2].macaddr=`echo -n 10:16:88; dd bs=1 count=3 if=/dev/random 2>/dev/null | hexdump -v -e '/1 ":%02X"'`

                                uci add wireless wifi-iface                     #......ap......
                                uci set wireless.@wifi-iface[3].ifname=wlan3
                                uci set wireless.@wifi-iface[3].device=radio0   #......radion0......
                                uci set wireless.@wifi-iface[3].network=lan
                                uci set wireless.@wifi-iface[3].mode=ap      #ap
                                uci set wireless.@wifi-iface[3].ssid="$hostssid-2"    #AP ssid
                                uci set wireless.@wifi-iface[3].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[3].key=12345678

                                uci add wireless wifi-iface                     #......ap......
                                uci set wireless.@wifi-iface[4].ifname=wlan4
                                uci set wireless.@wifi-iface[4].device=radio0   #......radion0......
                                uci set wireless.@wifi-iface[4].network=lan
                                uci set wireless.@wifi-iface[4].mode=ap     #ap
                                uci set wireless.@wifi-iface[4].ssid="$hostssid-3"    #AP ssid
                                uci set wireless.@wifi-iface[4].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[4].key=12345678

                                uci add wireless wifi-iface                     #......ap......
                                uci set wireless.@wifi-iface[5].ifname=wlan5
                                uci set wireless.@wifi-iface[5].device=radio1   #......radion0......
                                uci set wireless.@wifi-iface[5].network=lan
                                uci set wireless.@wifi-iface[5].mode=ap     #ap
                                uci set wireless.@wifi-iface[5].ssid="$hostssid-4"    #AP ssid
                                uci set wireless.@wifi-iface[5].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[5].key=12345678

                                uci add wireless wifi-iface                     #......ap......
                                uci set wireless.@wifi-iface[6].ifname=wlan6
                                uci set wireless.@wifi-iface[6].device=radio1   #......radion0......
                                uci set wireless.@wifi-iface[6].network=lan
                                uci set wireless.@wifi-iface[6].mode=ap     #ap
                                uci set wireless.@wifi-iface[6].ssid="$hostssid-5"    #AP ssid
                                uci set wireless.@wifi-iface[6].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[6].key=12345678

                                uci add wireless wifi-iface                     #......ap......
                                uci set wireless.@wifi-iface[7].ifname=wlan7
                                uci set wireless.@wifi-iface[7].device=radio1   #......radion0......
                                uci set wireless.@wifi-iface[7].network=lan
                                uci set wireless.@wifi-iface[7].mode=ap     #ap
                                uci set wireless.@wifi-iface[7].ssid="$hostssid-6"    #AP ssid
                                uci set wireless.@wifi-iface[7].encryption="psk2+ccmp" #............
                                uci set wireless.@wifi-iface[7].key=12345678


}

commit_wireless()
{
        uci commit wireless
}

sync_wifi_down()
{
	echo "wifi down--1">dev/ttyS0
	/sbin/wifi down
	counter=20
	while [ $counter -gt 0 ]; do
		counter=$(($counter - 1))
		num=`ifconfig | grep wlan | wc -l`
		if  [ $num -eq 0 ]; then
			break
		fi
		sleep 1
	done
	sleep 1
	echo "wifi down--2">dev/ttyS0
}

/etc/init.d/subservice stop
/etc/init.d/syncservice stop
#set recovery env
for _dev in /sys/class/ieee80211/*; do
	[ -e "$_dev" ] || continue
	dev="${_dev##*/}"
	echo 1 > /sys/kernel/debug/ieee80211/$dev/rwnx/recovery_enable
done

timer=1000000
while [ $timer -gt 0 ]; do
        timer=$(($timer - 1))
        init_ap $1
        commit_wireless
		ubus call network reload
		sleep 2
		sync_wifi_down
		echo "wifi up++">dev/ttyS0
		/sbin/wifi up
        counter=30
        cost=0
        num=0
        while [ $counter -gt 0 ]; do
                counter=$(($counter - 1))
                num=`ifconfig | grep wlan | wc -l`
                if  [ $num -eq 8 ]; then
                        break
                fi
                sleep 1
                cost=$(($cost + 1))
        done
        if  [ $num -ne 8 ]; then
                echo "########################test fail########################">/dev/ttyS0
                echo "wifi interface num1 is $num">/dev/ttyS0
                echo "################################################">/dev/ttyS0
                break
        fi
        echo "wait wifi link up0 $cost seconds!">/dev/ttyS0
		rm /etc/config/wireless
        /sbin/wifi detect > /etc/config/wireless
        commit_wireless
		sleep 2
		ubus call network reload
		sync_wifi_down
		echo "wifi up++">dev/ttyS0
		/sbin/wifi up
        num=0
        cost=0
        counter=20
        while [ $counter -gt 0 ]; do
                counter=$(($counter - 1))
                num=`ifconfig | grep wlan | wc -l`
                if  [ $num -eq 2 ]; then
                        break
                fi
                sleep 1
                cost=$(($cost + 1))
        done
        if  [ $num -ne 2 ]; then
                echo "########################test fail########################">/dev/ttyS0
                echo "wifi interface num2 is $num">/dev/ttyS0
                echo "################################################">/dev/ttyS0
                break
        fi
        echo "wait wifi link up1 $cost seconds!">/dev/ttyS0
done
