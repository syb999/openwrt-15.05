local m = Map("voip", translate("Conference Bridge"), translate("Multi-party audio conferencing"))

local tip = m:section(SimpleSection)
tip.description = '<div style="background-color: #e8f4e8; border-left: 4px solid #5cb85c; padding: 10px; margin: 10px 0;">' .. translate("Create conference rooms. Users can dial the room number to join. Multiple people can speak at the same time.") .. '</div>'

local s = m:section(TypedSection, "conference", translate("Conference Rooms"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"
s.sortable = true

room_number = s:option(Value, "number", translate("Room Number"))
room_number.datatype = "string"
room_number.rmempty = false
room_number.description = translate("Conference room number (e.g., 300001)")

enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = 1

max_users = s:option(Value, "max_users", translate("Max Participants"))
max_users.datatype = "uinteger"
max_users.default = 10
max_users.description = translate("Maximum participants (0 = unlimited)")

return m
