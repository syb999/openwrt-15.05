local m = Map("voip", translate("SIP Trunk Configuration"), translate("Configure PSTN trunks with load balancing and failover"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("After saving configuration, please go to Status page, click Apply Changes, then click Restart VoIP to make settings take effect.") .. '</div>'

local s_global = m:section(NamedSection, "global", "voip", translate("VoIP Service Global Settings"))
s_global.anonymous = false

global_enabled = s_global:option(Flag, "enabled", translate("Enable VoIP Service"))
global_enabled.default = 1
global_enabled.description = translate("Master switch for VoIP service. Disable to turn off the entire VoIP system.")

auto_restart = s_global:option(Flag, "auto_restart", translate("Auto Restart"))
auto_restart.default = 1
auto_restart.description = translate("Automatically restart Asterisk when configuration changes. Disable to apply changes manually.")

default_extension = s_global:option(Value, "default_extension", translate("Default Incoming Extension"))
default_extension.default = "6001"
default_extension.datatype = "uinteger"
default_extension.placeholder = "6001"
default_extension.description = translate("Extension number that receives incoming calls from PSTN. Leave empty to ring all extensions.")

local s = m:section(TypedSection, "trunk", translate("PSTN Trunks"))
s.addremove = true
s.anonymous = false

trunk_enabled = s:option(Flag, "enabled", translate("Enable IMS Trunk"))
trunk_enabled.default = 0
trunk_enabled.description = translate("Enable/disable this PSTN trunk.")

name = s:option(Value, "name", translate("Trunk Name"))
name.rmempty = false
name.placeholder = "ct_1"
name.description = translate("Unique name to identify this trunk.")

prefix = s:option(Value, "prefix", translate("Force Prefix"))
prefix.placeholder = "9"
prefix.description = translate("Dial this prefix to force use this trunk (e.g., 9 for 9138xxxxxxx). Leave empty for automatic routing.")

server = s:option(Value, "server", translate("SIP Server"))
server.placeholder = "sh2.ctcims.cn"
server.rmempty = false
server.description = translate("SIP server domain provided by your VoIP provider.")

forward_server = s:option(Value, "forward_server", translate("Forward Server IP"))
forward_server.placeholder = "15.192.19.17"
forward_server.rmempty = false
forward_server.description = translate("Forward server IP address from China Telecom IMS.")

port = s:option(Value, "port", translate("Port"))
port.default = "5060"
port.datatype = "port"
port.description = translate("SIP signaling port (default: 5060).")

phone = s:option(Value, "phone", translate("Phone Number"))
phone.placeholder = "+8612xxxxxxxx"
phone.rmempty = false
phone.description = translate("Your PSTN phone number with country code (e.g., +8612345678901).")

password = s:option(Value, "password", translate("Password"))
password.password = true
password.rmempty = false
password.description = translate("SIP authentication password from your provider.")

nat = s:option(Flag, "nat", translate("NAT Support"))
nat.default = 1
nat.description = translate("Enable NAT traversal. Keep enabled if Asterisk is behind a router.")

srtp = s:option(Flag, "srtp", translate("SRTP Support"))
srtp.default = 0
srtp.description = translate("Enable SRTP encryption for secure calls. Only enable if your provider supports it.")

weight = s:option(Value, "weight", translate("Weight"))
weight.default = "1"
weight.datatype = "uinteger"
weight.description = translate("Higher weight = more calls routed to this trunk. Use for primary/backup setup.")

function m.on_commit()
    os.execute("/etc/init.d/asterisk reload 2>/dev/null &")
end

return m
