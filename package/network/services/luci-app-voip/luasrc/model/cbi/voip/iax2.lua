local m = Map("voip", translate("IAX2 Trunk"), translate("Configure IAX2 trunks for multi-Asterisk interconnection"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("IAX2 trunks allow multiple Asterisk servers to interconnect. Each trunk represents a remote Asterisk server. Use dial prefix to route calls to the target server (e.g., prefix 81 means dial 816001 to reach extension 6001 on remote server).") .. '</div>'

local global = m:section(TypedSection, "iax2", translate("IAX2 Global Settings"))
global.anonymous = true

bindport = global:option(Value, "bindport", translate("Bind Port"))
bindport.default = "4569"
bindport.datatype = "port"

bindaddr = global:option(Value, "bindaddr", translate("Bind Address"))
bindaddr.default = "0.0.0.0"
bindaddr.description = translate("0.0.0.0 for all interfaces, or specific IP address")

local s = m:section(TypedSection, "iax2_trunk", translate("IAX2 Trunks"))
s.addremove = true
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = 1

name = s:option(Value, "name", translate("Trunk Name"))
name.rmempty = false

host = s:option(Value, "host", translate("Remote Host/IP"))
host.rmempty = false

port = s:option(Value, "port", translate("Port"))
port.default = "4569"
port.datatype = "port"

secret = s:option(Value, "secret", translate("Secret"))
secret.password = true
secret.rmempty = false

dial_prefix = s:option(Value, "dial_prefix", translate("Dial Prefix"))
dial_prefix.rmempty = false

context = s:option(Value, "context", translate("Context"))
context.default = "from_iax"

qualify = s:option(Flag, "qualify", translate("Qualify"))
qualify.default = 1

return m
