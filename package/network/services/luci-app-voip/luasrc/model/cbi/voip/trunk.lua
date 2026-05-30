local m = Map("voip", translate("SIP Trunk Configuration"), translate("Configure China Telecom IMS SIP trunk connection"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("After saving configuration, please go to Status page, click Apply Changes, then click Restart VoIP to make settings take effect.") .. '</div>'

local s = m:section(TypedSection, "global", translate("VoIP Service Global Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable VoIP Service"))
enabled.default = 0

auto_restart = s:option(Flag, "auto_restart", translate("Auto Restart"))
auto_restart.default = 1

local s2 = m:section(TypedSection, "trunk", translate("China Telecom IMS Trunk"))
s2.anonymous = true

trunk_enabled = s2:option(Flag, "enabled", translate("Enable IMS Trunk"))
trunk_enabled.default = 0

server = s2:option(Value, "server", translate("SIP Server"))
server.placeholder = "sh2.ctcims.cn"

forward_server = s2:option(Value, "forward_server", translate("Forward Server IP"))
forward_server.placeholder = "192.168.1.100"

port = s2:option(Value, "port", translate("Port"))
port.default = "5060"
port.datatype = "port"

phone = s2:option(Value, "phone", translate("Phone Number"))
phone.placeholder = "+86XXXXXXXXXX"

password = s2:option(Value, "password", translate("Password"))
password.password = true

nat = s2:option(Flag, "nat", translate("NAT Support"))
nat.default = 1

srtp = s2:option(Flag, "srtp", translate("SRTP Support"))
srtp.default = 0
srtp.description = translate("Enable SRTP encryption for secure calls")

default_extension = s2:option(Value, "default_extension", translate("Default Incoming Extension"))
default_extension.description = translate("Extension number that receives incoming calls from PSTN (leave empty to ring all extensions)")
default_extension.default = "6001"
default_extension.datatype = "uinteger"
default_extension.placeholder = "6001"

function m.on_commit()
    os.execute("/etc/init.d/asterisk reload 2>/dev/null &")
end

return m
