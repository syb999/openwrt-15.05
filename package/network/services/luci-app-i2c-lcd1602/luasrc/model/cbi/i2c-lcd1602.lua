local m,s

m = Map("i2c-lcd1602", translate("LCD1602"), translate("A LuCI app that helps you config your LCD1602 display"))

--m.chain("luci")
m:section(SimpleSection).template="i2c-lcd1602/status"

s = m:section(TypedSection, "i2c-lcd1602", translate(""))
s.anonymous=true
s.addremove=false

enabled = s:option(Flag, "enabled", translate("Enabled"))
enabled.default = 0
enabled.rmempty = false

i2c_bus = s:option(Value, "i2c_bus", translate("I2C Bus"))
i2c_bus.datatype = "string"
i2c_bus.default = "/dev/i2c-0"
i2c_bus.rmempty = false

i2c_address = s:option(Value, "i2c_address", translate("I2C address"))
i2c_address.datatype = "string"
i2c_address.default = "0x27"
i2c_address.rmempty = false

log_file = s:option(Value, "log_file", translate("Log file"))
log_file.datatype = "string"
log_file.default = "/var/log/lcd1602.log"
log_file.rmempty = false

return m
