#!/bin/sh

function msmtp_conf() {
	echo -e "account default\nhost $(uci get automail.@automail[0].msmtp_host)\ntls off\nfrom $(uci get automail.@automail[0].msmtp_from)\nauth login\nuser $(uci get automail.@automail[0].msmtp_user)\npassword $(uci get automail.@automail[0].msmtp_password)\nsyslog LOG_MAIL\nlogfile /tmp/msmtp.log\n" > /etc/msmtprc
}

function mutt_conf() {
	echo -e "set sendmail=\"/usr/bin/msmtp\"\nset use_from=yes\nset from=\"$(uci get automail.@automail[0].mutt_from)\"\nset realname=\"$(uci get automail.@automail[0].mutt_realname)\"\nset editor=\"vi\"\n" > /etc/Muttrc
}

if [ -f "/etc/msmtprc" ];then
	mv /etc/msmtprc /etc/msmtprc.backup
fi

if [ -f "/etc/Muttrc" ];then
	mv /etc/Muttrc /etc/Muttrc.backup
fi

if [ ! -f "/etc/msmtprc" ];then
	msmtp_conf
fi

if [ ! -f "/etc/Muttrc" ];then
	mutt_conf
fi

/etc/init.d/automail enable
/etc/init.d/automail start

