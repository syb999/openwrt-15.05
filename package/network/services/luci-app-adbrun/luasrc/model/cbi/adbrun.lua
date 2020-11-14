m = Map("adbrun", translate("adb server."))

s = m:section(TypedSection, "adbrun", "", translate("Assistant for automatic control android devices."))
s.anonymous = true
s.addremove = false

s:tab("adbrun", translate("Details"))

---- connect phone1
o = s:taboption("adbrun", Button, "_connect1", translate("connect phone1"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.21")
end

---- connect phone2
o = s:taboption("adbrun", Button, "_connect2", translate("connect phone2"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.22")
end

---- connect phone3
o = s:taboption("adbrun", Button, "_connect3", translate("connect phone3"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.23")
end

---- connect phone4
o = s:taboption("adbrun", Button, "_connect4", translate("connect phone4"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.24")
end

---- connect phone5
o = s:taboption("adbrun", Button, "_connect5", translate("connect phone5"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.25")
end

---- connect phone6
o = s:taboption("adbrun", Button, "_connect6", translate("connect phone6"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("adb connect 192.168.170.26")
end

---- control phone1
o = s:taboption("adbrun", Button, "_control1", translate("control phone1 video"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd1.sh >/dev/null 2>&1 &")
end

---- control phone2
o = s:taboption("adbrun", Button, "_control2", translate("control phone2 video"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd2.sh >/dev/null 2>&1 &")
end

---- control phone3
o = s:taboption("adbrun", Button, "_control3", translate("control phone3 video"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd3.sh >/dev/null 2>&1 &")
end


---- control phone4
o = s:taboption("adbrun", Button, "_control4", translate("control phone4 video"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd4.sh >/dev/null 2>&1 &")
end

---- stop phone4
o = s:taboption("adbrun", Button, "_stop4", translate("stop phone4"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd4-stop.sh >/dev/null 2>&1 &")
end

---- control phone5
o = s:taboption("adbrun", Button, "_control5", translate("control phone5 video"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd5.sh >/dev/null 2>&1 &")
end

---- stop phone5
o = s:taboption("adbrun", Button, "_stop5", translate("stop phone5"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd5-stop.sh >/dev/null 2>&1 &")
end


---- control phone6
o = s:taboption("adbrun", Button, "_control6", translate("control phone6 book"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd6.sh >/dev/null 2>&1 &")
end

---- stop phone6
o = s:taboption("adbrun", Button, "_stop6", translate("stop phone6"))
o.inputstyle = "apply"
function o.write(self, section)
    luci.util.exec("nohup /usr/adbrun/adbd6-stop.sh >/dev/null 2>&1 &")
end


s:tab("basic",  translate("Base Setting"))

o = s:taboption("basic", Flag, "enabled", translate("Enable"))

local detail = "/usr/adbrun/detail"
local NXFS = require "nixio.fs"
o = s:taboption("basic", TextValue, "detail")
o.description = translate("init detail")
o.rows = 9
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(detail) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(detail, value:gsub("\r\n", "\n"))
end


return m
