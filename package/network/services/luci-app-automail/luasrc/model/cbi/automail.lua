mp = Map("automail", "Auto Mail Sender","")

mp:section(SimpleSection).template  = "automail_status"

s = mp:section(TypedSection, "automail", "", translate("An easy config mailsender server"))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting"))
information = s:taboption("basic", DummyValue, "information", translate("information"))
information.description = translate("Please configure msmtp and mutt first")

recipient = s:taboption("basic", Value, "recipient", translate("Recipient mailbox"))
recipient:depends({ msmtp_ready = "1", mutt_ready = "1" })
recipient.datatype = "string"
recipient.default = "??????@163.com"
recipient.rmempty = true

init = s:taboption("basic", Button, "init", translate("One-click init"))
init.rmempty = true
init.inputstyle = "apply"
function init.write(self, section)
	luci.util.exec("/usr/automail/init.sh >/dev/null 2>&1 &")
end
init.description = translate("After configuration, please initialize first")

senderbuttion = s:taboption("basic", Button, "senderbuttion", translate("One-click send mail"))
senderbuttion.rmempty = true
senderbuttion.inputstyle = "apply"
function senderbuttion.write(self, section)
	luci.util.exec("/usr/automail/automail.sh >/dev/null 2>&1 &")
end

local auto_mail = "/usr/automail/automail.sh"
local amnxfs = require "nixio.fs"
script = s:taboption("basic", TextValue, "auto_mail")
script:depends({ msmtp_ready = "1", mutt_ready = "1" })
script.description = translate("Mail script")
script.rows = 20
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
mutt_realname.placeholder = "My_Openwrt"
mutt_realname.default = "My_Openwrt"
mutt_realname:depends("mutt_use_from", "1")
mutt_realname.rmempty = true

mutt_editor = s:taboption("mutt", Value, "mutt_editor", translate("Mutt editor"))
mutt_editor.datatype = "string"
mutt_editor.placeholder = "vi"
mutt_editor.default = "vi"
mutt_editor.rmempty = true

mutt_ready = s:taboption("mutt", Flag, "mutt_ready", translate("Setup ready"))
mutt_ready.default = 0

return mp
