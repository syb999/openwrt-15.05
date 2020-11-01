m = Map("adbrun", translate("adb server."))

s = m:section(TypedSection, "adbrun", "", translate("Assistant for automatic control android devices."))
s.anonymous = true
s.addremove = false


s:tab("basic",  translate("Base Setting"))

o = s:taboption("basic", Flag, "enabled", translate("Enable"))

 
s:tab("adbrun", translate("Details"))

local detail = "/usr/adbrun/detail"
local NXFS = require "nixio.fs"
o = s:taboption("adbrun", TextValue, "detail")
o.description = translate("init detail")
o.rows = 9
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(detail) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(detail, value:gsub("\r\n", "\n"))
end


---- connect phone1
o = s:taboption("adbrun", Button, "_connect1", translate("connect phone1"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.70.21")
end

---- connect phone2
o = s:taboption("adbrun", Button, "_connect2", translate("connect phone2"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.70.22")
end

---- connect phone3
o = s:taboption("adbrun", Button, "_connect3", translate("connect phone3"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.70.23")
end


---- control phone1
o = s:taboption("adbrun", Button, "_control1", translate("control phone1"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd1.sh >/dev/null 2>&1 &")
end

---- control phone2
o = s:taboption("adbrun", Button, "_control2", translate("control phone2"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd2.sh >/dev/null 2>&1 &")
end

---- control phone3
o = s:taboption("adbrun", Button, "_control3", translate("control phone3"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd3.sh >/dev/null 2>&1 &")
end


return m
