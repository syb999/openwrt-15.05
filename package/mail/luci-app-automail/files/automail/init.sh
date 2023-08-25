#!/bin/sh

function msmtp_conf() {
	echo -e "account default\nhost $(uci get automail.@automail[0].msmtp_host)\ntls off\nfrom $(uci get automail.@automail[0].msmtp_from)\nauth login\nuser $(uci get automail.@automail[0].msmtp_user)\npassword $(uci get automail.@automail[0].msmtp_password)\n#syslog LOG_MAIL\nlogfile /tmp/msmtp.log\n" > /etc/msmtprc
}

function mutt_conf() {
	echo -e "set sendmail=\"/usr/bin/msmtp\"\nset use_from=yes\nset from=\"$(uci get automail.@automail[0].mutt_from)\"\nset realname=\"$(uci get automail.@automail[0].mutt_realname)\"\nset editor=\"vi\"\nset charset=\"utf-8\"\nset send_charset=\"utf-8\"\n" > /etc/Muttrc
}

function fetchmail_conf() {
	F_pollset=""
	F_limit=""
	if [ "$(uci get automail.@automail[0].fetchmail_maillist)" = "mail.163.com" ];then
		if [ "$(uci get automail.@automail[0].fetchmail_protocollist)" = "pop3" ];then
			F_pollset="pop.163.com"
		fi
	elif [ "$(uci get automail.@automail[0].fetchmail_maillist)" = "mail.qq.com" ];then
		if [ "$(uci get automail.@automail[0].fetchmail_protocollist)" = "pop3" ];then
			F_pollset="pop.qq.com"
		fi
	fi
	if [ "$(uci get automail.@automail[0].fetchmail_highrisk 2>&1)" = "1" ];then
		F_keep="no keep"
	else
		F_keep="keep"
	fi
	if [ "$(uci get automail.@automail[0].fetchmail_limit)" != "" ];then
		F_limit="limit $(uci get automail.@automail[0].fetchmail_limit)"
	fi
	echo -e "poll ${F_pollset}\nprotocol $(uci get automail.@automail[0].fetchmail_protocollist)\nuser \"$(uci get automail.@automail[0].fetchmail_user)\"\npassword \"$(uci get automail.@automail[0].fetchmail_password)\"\nsslproto \"\"\n${F_keep}\n\nmda \"/usr/bin/process_mail\"\n${F_limit}\n" > /etc/fetchmailrc

}

if [ -f "/etc/msmtprc" ];then
	mv -f /etc/msmtprc /etc/msmtprc.backup
fi

if [ -f "/etc/Muttrc" ];then
	mv -f /etc/Muttrc /etc/Muttrc.backup
fi

if [ -f "/etc/fetchmailrc" ];then
	mv -f /etc/fetchmailrc /etc/fetchmailrc.backup
fi

msmtp_conf
mutt_conf
fetchmail_conf
chmod 0700 /etc/fetchmailrc

/etc/init.d/automail enable
/etc/init.d/automail start

