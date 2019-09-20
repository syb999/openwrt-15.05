#!/bin/sh

if [ -f "/tmp/ssst"  ]; then
	sum1=`md5sum /tmp/ssst |awk -F ' ' '{print $1}'`
	sum2=`md5sum /usr/sbin/ssst |awk -F ' ' '{print $1}'`

	if [ "$sum1" != "$sum2"  ]; then
		if [ "$1" = "check"  ]; then
			echo "ssst md5sum different"
		else
			#can not stop ssst here, cause it will kill itselg
			cp /tmp/ssst /usr/sbin/ssst
			chmod 777 /usr/sbin/ssst
			/etc/init.d/syncservice restart
		fi
	else
		echo "ssst md5sum newest"
	fi
else
	echo "ssst md5sum newest"
fi
