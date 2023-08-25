mp = Map("automail", "Auto Mail Sender","")

mp:section(SimpleSection).template  = "automail_status"

s = mp:section(TypedSection, "automail", "", translate("An easy-to-configure mail server for sending and receiving emails"))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting"))
information = s:taboption("basic", DummyValue, "information", translate("information"))
information.description = translate("Please configure msmtp,mutt and fetchmail first")

init = s:taboption("basic", Button, "init", translate("One-click init"))
init.rmempty = true
init.inputstyle = "apply"
function init.write(self, section)
	luci.util.exec("sh /usr/automail/init.sh >/dev/null 2>&1 &")
	luci.util.exec("uci set automail.@automail[0].init_ok=ok >/dev/null 2>&1 &")
	luci.util.exec("uci commit automail >/dev/null 2>&1 &")
end
init.description = translate("After configuration, please initialize first")

init_ok = s:taboption("basic", Value, "init_ok", translate("      "))
init_ok.rmempty = true
init_ok.datatype = "string"
init_ok.default = ""

recipient = s:taboption("basic", Value, "recipient", translate("Recipient mailbox"))
recipient:depends("init_ok", "ok")
recipient.datatype = "string"
recipient.default = "??????@163.com"
recipient.rmempty = true

schedules = s:taboption("basic", Flag, "schedules", translate("Scheduled tasks"))
schedules:depends("init_ok", "ok")
schedules.default = 0

sendbuttion = s:taboption("basic", Button, "sendbuttion", translate("One-click send mail"))
sendbuttion:depends("init_ok", "ok")
sendbuttion.rmempty = true
sendbuttion.inputstyle = "apply"
function sendbuttion.write(self, section)
	luci.util.exec("sh /usr/automail/automail.sh >/dev/null 2>&1")
end

receivebutton = s:taboption("basic", Button, "receivebutton", translate("One-click receive mail"))
receivebutton:depends("init_ok", "ok")
receivebutton.rmempty = true
receivebutton.inputstyle = "apply"
function receivebutton.write(self, section)
	luci.util.exec("fetchmail -f /etc/fetchmailrc >/dev/null 2>&1 &")
end

local auto_mail = "/usr/automail/automail.sh"
local amnxfs = require "nixio.fs"
script = s:taboption("basic", TextValue, "auto_mail")
script:depends("init_ok", "ok")
script.description = translate("Mail script")
script.rows = 12
script.wrap = "off"
script.cfgvalue = function(self, section)
	return amnxfs.readfile(auto_mail) or ""
end
script.write = function(self, section, value)
	amnxfs.writefile(auto_mail, value:gsub("\r\n", "\n"))
end

s:tab("msmtp", translate("msmtp Setting"))
msmtp_host = s:taboption("msmtp", Value, "msmtp_host", translate("Mailbox host address"))
msmtp_host.datatype = "string"
msmtp_host.placeholder = "smtp.163.com"
msmtp_host.default = "smtp.163.com"
msmtp_host.rmempty = false
msmtp_host.description = translate("Use SMTP smarthost, viewed in mailbox settings")

msmtp_from = s:taboption("msmtp", Value, "msmtp_from", translate("Sender mailbox"))
msmtp_from.datatype = "string"
msmtp_from.placeholder = "??????@163.com"
msmtp_from.default = "??????@163.com"
msmtp_from.rmempty = false
msmtp_from.description = translate("Please type your mailbox username")

msmtp_user = s:taboption("msmtp", Value, "msmtp_user", translate("Mailbox username"))
msmtp_user.datatype = "string"
msmtp_user.default = "??????"
msmtp_user.rmempty = false
msmtp_user.description = translate("Please type your mailbox username")

msmtp_password = s:taboption("msmtp", Value, "msmtp_password", translate("Mailbox password"))
msmtp_password.datatype = "string"
msmtp_password.password = false
msmtp_password.default = "??????"
msmtp_password.rmempty = false
msmtp_password.description = translate("Please type your mailbox password, viewed in mailbox settings")

msmtp_ready = s:taboption("msmtp", Flag, "msmtp_ready", translate("Setup ready"))
msmtp_ready.default = 0

s:tab("mutt", translate("mutt Setting"))
mutt_sendmail = s:taboption("mutt", Value, "mutt_sendmail", translate("Program path"))
mutt_sendmail.datatype = "string"
mutt_sendmail.placeholder = "/user/bin/msmtp"
mutt_sendmail.default = "/user/bin/msmtp"
mutt_sendmail.rmempty = false

mutt_use_from = s:taboption("mutt", Flag, "mutt_use_from", translate("use_from"))
mutt_use_from.default = 1

mutt_from = s:taboption("mutt", Value, "mutt_from", translate("Sender mailbox"))
mutt_from.datatype = "string"
mutt_from.placeholder = "???@163.com"
mutt_from:depends("mutt_use_from", "1")
mutt_from.rmempty = true
mutt_from.description = translate("Please type your email address")

mutt_realname = s:taboption("mutt", Value, "mutt_realname", translate("Sender's Name"))
mutt_realname.datatype = "string"
mutt_realname.placeholder = "AutoMail"
mutt_realname.default = "AutoMail"
mutt_realname:depends("mutt_use_from", "1")
mutt_realname.rmempty = true

mutt_editor = s:taboption("mutt", Value, "mutt_editor", translate("Mutt editor"))
mutt_editor.datatype = "string"
mutt_editor.placeholder = "vi"
mutt_editor.default = "vi"
mutt_editor.rmempty = true

mutt_ready = s:taboption("mutt", Flag, "mutt_ready", translate("Setup ready"))
mutt_ready.default = 0

s:tab("schedule", translate("Schedule Setting"))
defdes = s:taboption("schedule", DummyValue, "defdes", translate("Default schedule description"))
defdes:depends("schedules", "1")
defdes.description = translate("Automatically send email at 8:15 a.m. every day from Monday to Friday")

f1_list = s:taboption("schedule", ListValue, "f1_list", translate("Minutes List(F1)"))
f1_list:depends("schedules", "1")
f1_list.placeholder = "0 ~ 59"
f1_list:value("0 ~ 59")
f1_list:value("*")
f1_list.default = "0 ~ 59"
f1_list.rempty  = true

sch_f1 = s:taboption("schedule", Value, "sch_f1", translate("The Minute(F1)"))
sch_f1:depends({ schedules = "1", f1_list = "0 ~ 59" })
sch_f1.datatype = "range(0,59)"
sch_f1.placeholder = "15"
sch_f1.default = "15"
sch_f1.rmempty = true

f2_list = s:taboption("schedule", ListValue, "f2_list", translate("Hours List(F2)"))
f2_list:depends("schedules", "1")
f2_list.placeholder = "0 ~ 23"
f2_list:value("0 ~ 23")
f2_list:value("*")
f2_list.default = "0 ~ 23"
f2_list.rempty  = true

sch_f2 = s:taboption("schedule", Value, "sch_f2", translate("The Hour(F2)"))
sch_f2:depends({ schedules = "1", f2_list = "0 ~ 23" })
sch_f2.datatype = "range(0,23)"
sch_f2.placeholder = "8"
sch_f2.default = "8"
sch_f2.rmempty = true

f3_list = s:taboption("schedule", ListValue, "f3_list", translate("Days List(F3)"))
f3_list:depends("schedules", "1")
f3_list.placeholder = "*"
f3_list:value("*")
f3_list:value("1 ~ 31")
f3_list.default = "*"
f3_list.rempty  = true


sch_f3 = s:taboption("schedule", Value, "sch_f3", translate("The day of the month(F3)"))
sch_f3:depends({ schedules = "1", f3_list = "1 ~ 31" })
sch_f3.datatype = "range(1,31)"
sch_f3.placeholder = "1"
sch_f3.default = "1"
sch_f3.rmempty = true

f4_list = s:taboption("schedule", ListValue, "f4_list", translate("Months List(F4)"))
f4_list:depends("schedules", "1")
f4_list.placeholder = "*"
f4_list:value("*")
f4_list:value("1 ~ 12")
f4_list.default = "*"
f4_list.rempty  = true

sch_f4 = s:taboption("schedule", Value, "sch_f4", translate("The Month(F4)"))
sch_f4:depends({ schedules = "1", f4_list = "1 ~ 12" })
sch_f4.datatype = "range(1,12)"
sch_f4.placeholder = "1"
sch_f4.default = "1"
sch_f4.rmempty = true

f5_list = s:taboption("schedule", ListValue, "f5_list", translate("The Days of the week(F5)"))
f5_list:depends("schedules", "1")
f5_list.placeholder = "1-5"
f5_list:value("*")
f5_list:value("1-5", translate("Monday to Friday"))
f5_list:value("6,0", translate("Weekend"))
f5_list.default = "1-5"
f5_list.rempty  = true

s:tab("fetchmail", translate("fetchmail setting"))
fetchmail_info = s:taboption("fetchmail", DummyValue, "fetchmail_info", translate("information"))
fetchmail_info.description = translate("Fetchmail is a Open-source software used to download e-mail from a remote mail server")

fetchmail_info2 = s:taboption("fetchmail", DummyValue, "fetchmail2_info", translate("information"))
fetchmail_info2.description = translate("Please check the email in the/var/spool/mail directory")

fetchmail_maillist = s:taboption("fetchmail", ListValue, "fetchmail_maillist", translate("Email Server List"))
fetchmail_maillist.placeholder = "mail.163.com"
fetchmail_maillist:value("mail.163.com", translate("Email 163"))
fetchmail_maillist:value("mail.qq.com", translate("Email QQ"))
fetchmail_maillist.default = "mail.163.com"
fetchmail_maillist.rempty  = true

fetchmail_infoqq = s:taboption("fetchmail", DummyValue, "fetchmail_infoqq", translate("information"))
fetchmail_infoqq:depends("fetchmail_maillist", "mail.qq.com")
fetchmail_infoqq.description = translate("Please login to mail.qq.com first to set an authorization code")

fetchmail_protocollist = s:taboption("fetchmail", ListValue, "fetchmail_protocollist", translate("email protocol"))
fetchmail_protocollist.placeholder = "pop3"
fetchmail_protocollist:value("pop3")
fetchmail_protocollist.default = "pop3"
fetchmail_protocollist.rempty  = true

fetchmail_user = s:taboption("fetchmail", Value, "fetchmail_user", translate("Mailbox username"))
fetchmail_user.datatype = "string"
fetchmail_user.default = "??????"
fetchmail_user.rmempty = false
fetchmail_user.description = translate("Please type your mailbox username")

fetchmail_password = s:taboption("fetchmail", Value, "fetchmail_password", translate("Mailbox password"))
fetchmail_password.datatype = "string"
fetchmail_password.password = false
fetchmail_password.default = "??????"
fetchmail_password.rmempty = false
fetchmail_password.description = translate("Please type your mailbox password, viewed in mailbox settings")

fetchmail_highrisk = s:taboption("fetchmail", Flag, "fetchmail_highrisk", translate("High risk setting"))
fetchmail_highrisk.rmempty = true

fetchmail_nokeep = s:taboption("fetchmail", Flag, "fetchmail_nokeep", translate("After downloading the email, the original email on the server will be deleted"))
fetchmail_nokeep:depends("fetchmail_highrisk", "1")
fetchmail_nokeep.rmempty = true
fetchmail_nokeep.default = 0

fetchmail_limit = s:taboption("fetchmail", Value, "fetchmail_limit", translate("Limit the data size of messages"))
fetchmail_limit.datatype = "uinteger"
fetchmail_limit.default = 30720
fetchmail_limit.rmempty = false
fetchmail_limit.description = translate("The default value of 30720, means that every email larger than 30KB will not be downloaded")

fetchmail_ready = s:taboption("fetchmail", Flag, "fetchmail_ready", translate("Setup ready"))
fetchmail_ready.default = 0

return mp
