m = Map("freeradius2", "FREERADIUS2", translate(""))

m:section(SimpleSection).template  = "freeradius2_status"

s = m:section(TypedSection, "freeradius2")
s.addremove = false
s.anonymous = false

s:tab("basic", translate("Basic Setting"))
auth_interface=s:taboption("basic", Value, "auth_interface", translate("Authentication Interface"))
auth_interface.datatype = "network"
auth_interface.default = "br-lan"
auth_interface.rmempty = false

auth_port=s:taboption("basic", Value, "auth_port", translate("Authentication port"))
auth_port.datatype = "port"
auth_port.default = "1812"
auth_port.rmempty = false

acct_port=s:taboption("basic", Value, "acct_port", translate("Accounting port"))
acct_port.datatype = "port"
acct_port.default = "1813"
acct_port.rmempty = false

s_secret=s:taboption("basic", Value, "s_secret", translate("Server Secret"))
s_secret.datatype = "string"
s_secret.default = "testing123"
s_secret.rmempty = false

client=s:taboption("basic", Value, "client", translate("Client IP Segment"))
client.datatype = "string"
client.default = "192.168.0.0/16"
client.rmempty = false

s:tab("usersfile",  translate("Users conf"))
local users = "/etc/freeradius2/users"
local nxfs = require "nixio.fs"
o = s:taboption("usersfile", TextValue, "users")
o.description = translate("You can add new users according with the default format")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return nxfs.readfile(users) or ""
end
o.write = function(self, section, value)
	nxfs.writefile(users, value:gsub("\r\n", "\n"))
end

s:tab("run",  translate("Action"))
restartradius = s:taboption("run", Button, "_restartradius", translate("Restart Radius Server"))
restartradius.inputstyle = "apply"
function restartradius.write(self, section)
    luci.util.exec("/etc/freeradius2/initconf >/dev/null 2>&1 &")
end


return m
