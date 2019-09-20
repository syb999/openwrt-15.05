#!/bin/sh
. /lib/functions.sh
. /usr/share/libubox/jshn.sh

purl_check() {
	rm -rf /tmp/updatelist.bin
	/usr/bin/pctl_upgrade
	if [ ! -f "/tmp/updatelist.bin" ]; then
		#echo "updatelist.bin not exist!!!" > /dev/ttyS0
		return
	fi
	json_load_file "/tmp/updatelist.bin"
	echo "++++update url success!" > dev/ttyS0
	json_get_var code2 "code"
	echo "code2=$code2"
	if [ "x$code2" == "x0" ]; then
		json_select data
		json_get_vars action updateAt province
		echo "++++update action=$action!" > dev/ttyS0
		if [ "x$action" == "x1" -o "x$action" == "x2" ]; then
			tscfg -u /tmp/updatelist.bin
			checksum=`md5sum /etc/config/sf-ts-cfg.bin.tar.gz | awk '{print $1}'`
			uci set tsconfig.tsrecord.checksum="$checksum"
			echo "++++++++++++update=$updateAt" > /dev/ttyS0
			uci commit tsconfig
			[ -f "/etc/config/sf-ts-cfg.bin.tar.gz" ] && {
				tscfg -i
			}
		fi
		json_select ..
	fi
	json_select ..
	rm /tmp/updatelist.bin
}

timewait=$1
if [ "x$timewait" != "x" ]; then
	sleep $timewait
fi

purl_check
