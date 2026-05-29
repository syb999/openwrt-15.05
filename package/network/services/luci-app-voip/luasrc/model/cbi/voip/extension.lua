local m = Map("voip", translate("Extension Configuration"), translate("Configure internal extensions"))

local s = m:section(TypedSection, "extension", translate("Internal Extensions"))
s.addremove = true
s.template = "cbi/tblsection"
s.sortable = true

number = s:option(Value, "number", translate("Extension Number"))
number.rmempty = false
number.datatype = "uinteger"

secret = s:option(Value, "secret", translate("Password"))
secret.password = true
secret.rmempty = false

callerid = s:option(Value, "callerid", translate("Caller ID"))
callerid.rmempty = true

enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = 1

record = s:option(Flag, "record", translate("Auto Record"))
record.default = 0

function m.on_commit()
    os.execute("/etc/init.d/asterisk reload 2>/dev/null &")
end

return m
