m = Map("autosign", translate("AutoSign"))

s = m:section(TypedSection, "autosign", "", translate("Assistant for automatic Sign in."))
s.anonymous = true
s.addremove = false

s:tab("autosign", translate("Basic"))

tianapikey=s:taboption("autosign", Value, "tianapikey", translate("API KEY"))
tianapikey.datatype = "string"
tianapikey.placeholder = "please enter your api key"
tianapikey.description = translate("tianapi vacation days key(from https://www.tianapi.com/apiview/139)")

tianapidate=s:taboption("autosign", Value, "tianapidate", translate("date"))
tianapidate.datatype = "string"
tianapidate.default="2025"
tianapidate.description = translate("What year's vacation days")

workhour=s:taboption("autosign", Value, "workhour", translate("hour"))
workhour.datatype = "string"
workhour.default="7"
workhour.description = translate("Set the time for work(hour)")

workminute=s:taboption("autosign", Value, "workminute", translate("minute"))
workminute.datatype = "string"
workminute.default="59"
workminute.description = translate("Set the time for work(minute)")

gooffworkhour=s:taboption("autosign", Value, "gooffworkhour", translate("hour"))
gooffworkhour.datatype = "string"
gooffworkhour.default="17"
gooffworkhour.description = translate("Set the time for go off work(hour)")

gooffworkminute=s:taboption("autosign", Value, "gooffworkminute", translate("minute"))
gooffworkminute.datatype = "string"
gooffworkminute.default="15"
gooffworkminute.description = translate("Set the time for go off work(minute)")

workweek=s:taboption("autosign", Value, "workweek", translate("days"))
workweek.datatype = "string"
workweek.default="1-5"
workweek.description = translate("Set weekly sign-in days")

workwkd=s:taboption("autosign", Value, "workwkd", translate("weekend days"))
workwkd.datatype = "string"
workwkd.default="6,0"
workwkd.description = translate("Set weekly sign-in weekend days")

s:tab("vacationlist",  translate("vacation days"))

getvacationlist = s:taboption("vacationlist", Button, "getvacationlist", translate("one-click get vacation list"))
getvacationlist.inputstyle = "apply"
function getvacationlist.write(self, section)
    luci.util.exec("sh /usr/autosign/autosigngetdays.sh &")
end

local vddetails = "/etc/autosignvacationlist"
local VDNXFS = require "nixio.fs"
o = s:taboption("vacationlist", TextValue, "vddetails")
o.rows = 3
o.wrap = "off"
o.cfgvalue = function(self, section)
	return VDNXFS.readfile(vddetails) or ""
end
o.write = function(self, section, value)
	VDNXFS.writefile(vddetails, value:gsub("\r\n", "\n"))
end

getworklist = s:taboption("vacationlist", Button, "getworklist", translate("Get weekend work list"))
getworklist.inputstyle = "apply"
function getworklist.write(self, section)
    luci.util.exec("sh /usr/autosign/autosigngetwkddays.sh &")
end

local vdwkddetails = "/etc/autosignworklist"
local VDWKDNXFS = require "nixio.fs"
o = s:taboption("vacationlist", TextValue, "vdwkddetails")
o.rows = 3
o.wrap = "off"
o.cfgvalue = function(self, section)
	return VDWKDNXFS.readfile(vdwkddetails) or ""
end
o.write = function(self, section, value)
	VDWKDNXFS.writefile(vdwkddetails, value:gsub("\r\n", "\n"))
end


s:tab("forsignin", translate("Sign in"))
ocrunsign = s:taboption("forsignin", Button, "ocrunsign", translate("Onc-Click set autosign"))
ocrunsign.inputstyle = "apply"
function ocrunsign.write(self, section)
    luci.util.exec("sh /usr/autosign/autosigntocrontab.sh")
end

local autosignrun = "/usr/autosign/autosignrun.sh"
local RSNXFS = require "nixio.fs"
o = s:taboption("forsignin", TextValue, "autosignrun")
o.rows = 20
o.wrap = "off"
o.cfgvalue = function(self, section)
	return RSNXFS.readfile(autosignrun) or ""
end
o.write = function(self, section, value)
	RSNXFS.writefile(autosignrun, value:gsub("\r\n", "\n"))
end

local autosignwkdrun = "/usr/autosign/autosignwkdrun.sh"
local RSWKDNXFS = require "nixio.fs"
o = s:taboption("forsignin", TextValue, "autosignwkdrun")
o.rows = 20
o.wrap = "off"
o.cfgvalue = function(self, section)
	return RSWKDNXFS.readfile(autosignwkdrun) or ""
end
o.write = function(self, section, value)
	RSWKDNXFS.writefile(autosignwkdrun, value:gsub("\r\n", "\n"))
end


return m

