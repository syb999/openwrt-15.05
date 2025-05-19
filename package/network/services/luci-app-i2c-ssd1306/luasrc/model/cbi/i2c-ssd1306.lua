local m,s

m = Map("i2c-ssd1306", translate("OLED SSD1306"), translate("A LuCI app that helps you config your OLED SSD1306/1315 display"))

--m.chain("luci")
m:section(SimpleSection).template="i2c-ssd1306/status"

s = m:section(TypedSection, "i2c-ssd1306", translate(""))
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
i2c_address.default = "0x3c"
i2c_address.rmempty = false

log_file = s:option(Value, "log_file", translate("Log file"))
log_file.datatype = "string"
log_file.default = "/var/log/ssd1306.log"
log_file.rmempty = false

screen_on_time = s:option(Value, "screen_on_time", translate("loop display duration"))
screen_on_time.datatype = "uinteger"
screen_on_time.default = "15"
screen_on_time.rmempty = false

screen_off_time = s:option(Value, "screen_off_time", translate("loop screen-off duration"))
screen_off_time.datatype = "uinteger"
screen_off_time.default = "5"
screen_off_time.rmempty = false

return m
