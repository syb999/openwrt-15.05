m = Map("gmediarender", translate("gmediarender server"))

m:section(SimpleSection).template  = "gmrender_status"

s = m:section(TypedSection, "gmediarender", "")

s:tab("gmrender_set", translate("Basic setting"))
gmrenderbindiflist = s:taboption("gmrender_set", ListValue, "gmrenderbindiflist", translate("Binding interface list"))
gmrenderbindiflist.placeholder = "lan"
gmrenderbindiflist:value("lan", translate("lan"))
gmrenderbindiflist:value("wan", translate("wan"))
gmrenderbindiflist:value("other", translate("other"))
gmrenderbindiflist.default = "lan"
gmrenderbindiflist.rempty = false

gmrenderotherif = s:taboption("gmrender_set", Value, "gmrenderotherif", translate("Other interface"))
gmrenderotherif:depends("gmrenderbindiflist", "other")
gmrenderotherif.rmempty = true
gmrenderotherif.datatype = "string"
gmrenderotherif.description = translate("Please type interface name")

gmrendersuffix = s:taboption("gmrender_set", Value, "gmrendersuffix", translate("gmediarender friendly-name suffix"))
gmrendersuffix.datatype = "string"
gmrendersuffix.placeholder = "hello"
gmrendersuffix.default = "hello"
gmrendersuffix.rmempty = false

gmrenderextra=s:taboption("gmrender_set", Flag, "gmrenderextra", translate("Wanna download while Playing"))

gmrenderdir = s:taboption("gmrender_set", Value, "gmrenderdir", translate("Download directory"))
gmrenderdir:depends("gmrenderextra", "1")
gmrenderdir.datatype = "string"
gmrenderdir.default = "/tmp"
gmrenderdir.placeholder = "/tmp"
gmrenderdir.rmempty = true
gmrenderdir.description = translate("Please enter a valid directory")

gmrenderlog = s:taboption("gmrender_set", Value, "gmrenderlog", translate("Log file"))
gmrenderlog:depends("gmrenderextra", "1")
gmrenderlog.datatype = "string"
gmrenderlog.default = "gmrender.tmp.log"
gmrenderlog.placeholder = "gmrender.tmp.log"
gmrenderlog.rmempty = true
gmrenderlog.description = translate("Please type log file's name")

s:tab("gmrender_init", translate("Action"))
gmrenderinit = s:taboption("gmrender_init", Button, "gmrenderinit", translate("One-click initialize gmediarender"))
gmrenderinit.rmempty = true
gmrenderinit.inputstyle = "apply"
function gmrenderinit.write(self, section)
	luci.util.exec("/etc/init.d/gmediarender restart >/dev/null 2>&1 &")
	luci.util.exec("kill -9 $(busybox ps | grep \"gmediarender/gmrd\" | grep -v grep | awk '{print$1}') >/dev/null 2>&1 &")
end

gmrenderdownload = s:taboption("gmrender_init", Button, "gmrenderdownload", translate("One-click download while Playing"))
gmrenderdownload:depends("gmrenderextra", "1")
gmrenderdownload.rmempty = true
gmrenderdownload.inputstyle = "apply"
gmrenderdownload.description = translate("Support v.qq.com,iqiyi.com,bilibili.com,youku.com,music...")
function gmrenderdownload.write(self, section)
	luci.util.exec("/usr/share/gmediarender/gmrd >/dev/null 2>&1 &")
end

gmrenderbilibilimp4 = s:taboption("gmrender_init", Button, "gmrenderbilibilimp4", translate("One-click flv to mp4"))
gmrenderbilibilimp4:depends("gmrenderextra", "1")
gmrenderbilibilimp4.inputstyle = "apply"
gmrenderbilibilimp4.description = translate("ffmpeg needs to be installed(only for bilibili)")
function gmrenderbilibilimp4.write(self, section)
    luci.util.exec("/usr/share/gmediarender/flvtomp4 >/dev/null 2>&1 &")
end

gmrendertsmp4 = s:taboption("gmrender_init", Button, "gmrendertsmp4", translate("One-click ts to mp4"))
gmrendertsmp4:depends("gmrenderextra", "1")
gmrendertsmp4.inputstyle = "apply"
gmrendertsmp4.description = translate("ffmpeg needs to be installed")
function gmrendertsmp4.write(self, section)
    luci.util.exec("/usr/share/gmediarender/tstomp4 >/dev/null 2>&1 &")
end

gmrenderm4amp3 = s:taboption("gmrender_init", Button, "gmrenderm4amp3", translate("One-click m4a to mp3"))
gmrenderm4amp3:depends("gmrenderextra", "1")
gmrenderm4amp3.inputstyle = "apply"
gmrenderm4amp3.description = translate("ffmpeg needs to be installed")
function gmrenderm4amp3.write(self, section)
    luci.util.exec("/usr/share/gmediarender/m4atomp3 >/dev/null 2>&1 &")
end

return m

