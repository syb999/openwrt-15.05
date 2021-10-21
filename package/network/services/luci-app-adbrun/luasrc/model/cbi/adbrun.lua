m = Map("adbrun", translate("ADB server"))

a = m:section(TypedSection, "adbinit", "")

adbinit = a:option(Button, "_adbinit", translate("One-click initialize devices"))
adbinit.rmempty = true
adbinit.inputstyle = "apply"
adbinit.description = translate("Please use USB cable to connect openwrt router and Android device(multi devices support)")
function adbinit.write(self, section)
	luci.util.exec("/usr/adbrun/adbinit.sh >/dev/null 2>&1 &")
end

adbphotopath=a:option(Value, "adbphotopath", translate("Photos directory"))
adbphotopath.datatype = "string"
adbphotopath.default = "/tmp"
adbphotopath.rmempty = false
adbphotopath.description = translate("Please enter a valid directory")


s = m:section(TypedSection, "adbrun", "", translate("Assistant for automatic control android devices."))

s:tab("adb_set", translate("Basic setting"))

s.anonymous = false
s.addremove = true

adbiplist=s:taboption("adb_set",Value, "adbiplist", translate("IP address")) 
adbiplist.rmempty = true
adbiplist.datatype = "ipaddr"
luci.sys.net.ipv4_hints(function(ip, name)
	adbiplist:value(ip, "%s (%s)" %{ ip, name })
end)

adbcommandlist = s:taboption("adb_set", ListValue, "adbcommandlist", translate("Command list"), translate("adbrun command list"))
adbcommandlist.placeholder = "none"
adbcommandlist:value("none", translate("none"))
adbcommandlist:value("turn-offon-the-screen", translate("Turn off/on the screen"))
adbcommandlist:value("turn-on-the-screen", translate("Turn on screen"))
adbcommandlist:value("playstop", translate("Play or stop"))
adbcommandlist:value("playnext", translate("Play the next"))
adbcommandlist:value("playprevious", translate("Play the previous"))
adbcommandlist:value("resume-playback", translate("Resume playback"))
adbcommandlist:value("pause-playback", translate("Pause playback"))
adbcommandlist:value("mute", translate("Mute on/off"))
adbcommandlist:value("runcamera", translate("Run camera"))
adbcommandlist:value("photograph", translate("Take a picture"))
adbcommandlist:value("appactivity", translate("Get running APP"))
adbcommandlist:value("runwechat", translate("Run Wechat"))
adbcommandlist:value("runqq", translate("Run QQ"))
adbcommandlist:value("runtaobao", translate("Run taobao"))
adbcommandlist:value("runtaobaolite", translate("Run taobao lite version"))
adbcommandlist:value("rundiantao", translate("Run taobao live"))
adbcommandlist:value("runjdlite", translate("Run JD lite version"))
adbcommandlist:value("runfqxs", translate("Run fanqie xiaoshuo"))
adbcommandlist:value("runxmlylite", translate("Run ximalaya lite version"))
adbcommandlist:value("takephoto", translate("Automatically take photos"))
adbcommandlist:value("pyxmlylite", translate("Automatically get gold coins from ximalaya lite version"))
adbcommandlist:value("readbook", translate("Automatically read book"))
adbcommandlist:value("kuaishou", translate("Automatically play kuaishou"))
adbcommandlist:value("autodiantao", translate("Automatically taobao live"))
adbcommandlist:value("autojdlite", translate("Automatically jdlite"))
adbcommandlist:value("11diantao", translate("Automatically 11.11 taobao live"))
adbcommandlist:value("11diantaolucky", translate("Automatically 11.11 taobao live lucky event"))
adbcommandlist:value("11taobaozc", translate("Automatically 11.11 taobao zhongcaoji"))
adbcommandlist:value("11taobaomiaotang", translate("Automatically 11.11 taobao miaotang event"))
adbcommandlist.default     = "none"
adbcommandlist.rempty      = false


s:tab("adb_action", translate("Action"))

adbconnect=s:taboption("adb_action",Button,"adbconnect",translate("Connect client"))
adbconnect.rmempty = true
adbconnect.inputstyle = "apply"
function adbconnect.write(self, section)
	luci.util.exec("adb connect $(uci get adbrun."..section..".adbiplist) >/dev/null 2>&1 &")
end

adbplay=s:taboption("adb_action",Button, "adbplay", translate("Play")) 
adbplay.rmempty = true
adbplay.inputstyle = "apply"
function adbplay.write(self, section)
	luci.util.exec("cp /usr/adbrun/adbcommand.sh /tmp/adb_" ..section.. "_.sh >/dev/null 2>&1 &")
	luci.util.exec("/tmp/adb_" ..section.. "_.sh >/dev/null 2>&1 &")
end

adbstop=s:taboption("adb_action",Button, "adbstop", translate("Stop loop script")) 
adbstop.rmempty = true
adbstop.inputstyle = "apply"
function adbstop.write(self, section)
	luci.util.exec("kill $(ps | grep " ..section.. " | grep -v grep | head -n 1 | cut -d 'r' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | grep -v grep | head -n 1 | cut -d 'r' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | grep -v grep | head -n 1 | cut -d ' ' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | grep -v grep | head -n 1 | cut -d ' ' -f 1) > /dev/null 2>&1")
end

return m

