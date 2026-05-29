local m = Map("voip", translate("Record Settings"), translate("Configure recording parameters"))

local s = m:section(TypedSection, "record", translate("Recording Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable Recording"))
enabled.default = 0

record_dir = s:option(Value, "dir", translate("Recording Directory"))
record_dir.default = "/tmp/voip_records"
record_dir.rmempty = true

auto_clean = s:option(Value, "auto_clean", translate("Auto Clean Days"))
auto_clean.datatype = "uinteger"
auto_clean.default = 30
auto_clean.rmempty = true

function m.on_commit()
    os.execute("/etc/init.d/asterisk reload 2>/dev/null &")
end

return m
