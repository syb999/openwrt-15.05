local m = Map("voip", translate("Record Settings"), translate("Configure recording parameters"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 10px 0;">' .. translate("After saving configuration, please go to Status page, click Apply Changes, then click Restart VoIP to make settings take effect.") .. '</div>'

local s = m:section(TypedSection, "record", translate("Recording Settings"))
s.anonymous = true

enabled = s:option(Flag, "enabled", translate("Enable Recording"))
enabled.default = 0

record_dir = s:option(Value, "dir", translate("Recording Directory"))
record_dir.default = "/tmp/voip_records"
record_dir.rmempty = true

record_format = s:option(ListValue, "format", translate("Recording Format"))
record_format:value("gsm", translate("GSM: Space-saving, approximately 0.1MB per minute"))
record_format:value("wav", translate("WAV: Good compatibility, approximately 0.5MB per minute"))
record_format.default = "gsm"

auto_clean = s:option(Value, "auto_clean", translate("Auto Clean Days"))
auto_clean.datatype = "uinteger"
auto_clean.default = 30
auto_clean.rmempty = true

function m.on_commit()
    os.execute("/etc/init.d/asterisk reload 2>/dev/null &")
end

return m
