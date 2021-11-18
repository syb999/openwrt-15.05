m = Map("adbrun", translate("ADB server"))

a = m:section(TypedSection, "adbinit", "")

a:tab("adb_init", translate("init devices"))
adbinit = a:taboption("adb_init", Button, "_adbinit", translate("One-click initialize devices"))
adbinit.rmempty = true
adbinit.inputstyle = "apply"
adbinit.description = translate("Please use USB cable to connect openwrt router and Android device(multi devices support)")
function adbinit.write(self, section)
	luci.util.exec("/usr/adbrun/adbinit.sh >/dev/null 2>&1 &")
end

adbstophotplug = a:taboption("adb_init", Button, "adbstophotplug", translate("One-click disable hotplug"))
adbstophotplug.rmempty = true
adbstophotplug.inputstyle = "apply"
adbstophotplug.description = translate("Suitable for connecting to openwrt through USB cable for a long time")
function adbstophotplug.write(self, section)
	luci.util.exec("mv /etc/hotplug.d/usb/30-adb_init /tmp/30-adb_init >/dev/null 2>&1 &")
end

adbxhotplug = a:taboption("adb_init", Button, "adbxhotplug", translate("One-click resume hotplug"))
adbxhotplug.rmempty = true
adbxhotplug.inputstyle = "apply"
adbxhotplug.description = translate("After hot plug is enabled, you can continue to initialize the device using USB cable")
function adbxhotplug.write(self, section)
	luci.util.exec("mv /tmp/30-adb_init /etc/hotplug.d/usb/30-adb_init >/dev/null 2>&1 &")
end

a:tab("diantaod11init_set", translate("d11event diantao init setting"))
diantaodayworklistd11 = a:taboption("diantaod11init_set", Value, "diantaodayworklistd11", translate("d11event-diantao daytime worklist"))
diantaodayworklistd11.datatype = "string"
diantaodayworklistd11.default = "30秒10次 60秒10次 3分钟10次 30秒10次 60秒10次 30秒1次"
diantaodayworklistd11.rmempty = false
diantaodayworklistd11.description = translate("格式:X秒 X分钟")

diantaonightworklistd11 = a:taboption("diantaod11init_set", Value, "diantaonightworklistd11", translate("d11event-diantao night worklist"))
diantaonightworklistd11.datatype = "string"
diantaonightworklistd11.default = "60秒3次 3分钟5次 30秒10次 60秒10次 3分钟10次 30秒10次 60秒10次"
diantaonightworklistd11.rmempty = false

diantaoluckyworklistd11=a:taboption("diantaod11init_set", Value, "diantaoluckyworklistd11", translate("d11event-diantao lucky worklist"))
diantaoluckyworklistd11.datatype = "string"
diantaoluckyworklistd11.default = "60秒20次 30秒20次 3分钟20次 60秒10次 3分钟8次 30秒3次"
diantaoluckyworklistd11.rmempty = false

a:tab("diantaoinit_set", translate("diantao init setting"))
diantaodayworklist = a:taboption("diantaoinit_set", Value, "diantaodayworklist", translate("diantao daytime worklist"))
diantaodayworklist.datatype = "string"
diantaodayworklist.default = "30秒20次 60秒20次 60秒3次 3分钟1次 30秒1次 30秒1次 5分钟1次 8分钟1次 30秒1次"
diantaodayworklist.rmempty = false

diantaonightworklist=a:taboption("diantaoinit_set", Value, "diantaonightworklist", translate("diantao night worklist"))
diantaonightworklist.datatype = "string"
diantaonightworklist.default = "30秒20次 60秒20次 60秒3次 3分钟1次 30秒1次 30秒1次 5分钟1次 8分钟1次 30秒1次"
diantaonightworklist.rmempty = false

a:tab("photoinit_set", translate("photo init setting"))
adbphotopath = a:taboption("photoinit_set", Value, "adbphotopath", translate("Photos directory"))
adbphotopath.datatype = "string"
adbphotopath.default = "/tmp"
adbphotopath.rmempty = false
adbphotopath.description = translate("Please enter a valid directory")

s = m:section(TypedSection, "adbrun", "", translate("Assistant for automatic control android devices."))

s:tab("adb_set", translate("Basic setting"))

s.anonymous = false
s.addremove = true

adbiplist = s:taboption("adb_set",Value, "adbiplist", translate("IP address")) 
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
adbcommandlist:value("screenshot", translate("Automatically push screenshot to openwrt"))
adbcommandlist:value("pyxmlylite", translate("Automatically get gold coins from ximalaya lite version"))
adbcommandlist:value("readbook", translate("Automatically read book"))
adbcommandlist:value("kuaishou", translate("Automatically play kuaishou"))
adbcommandlist:value("autodiantao", translate("Automatically taobao live"))
adbcommandlist:value("autojdlite", translate("Automatically jdlite"))
adbcommandlist:value("tbbbfarm", translate("Automatically taobao baba farm"))
adbcommandlist:value("11diantao", translate("Automatically 11.11 taobao live"))
adbcommandlist:value("11diantaolucky", translate("Automatically 11.11 taobao live lucky event"))
adbcommandlist:value("11taobaozc", translate("Automatically 11.11 taobao zhongcaoji"))
adbcommandlist:value("11taobaomiaotang", translate("Automatically 11.11 taobao miaotang event"))
adbcommandlist:value("11taobaoshaizi", translate("Automatically 11.11 taobao miaotang event-touzi"))
adbcommandlist.default     = "none"
adbcommandlist.rempty      = false


s:tab("adb_action", translate("Action"))

adbdisconnect = s:taboption("adb_action",Button,"adbdisconnect",translate("Disconnect the current client"))
adbdisconnect.rmempty = true
adbdisconnect.inputstyle = "apply"
function adbdisconnect.write(self, section)
	luci.util.exec("adb disconnect $(uci get adbrun."..section..".adbiplist) >/dev/null 2>&1 &")
end

adbconnect = s:taboption("adb_action",Button,"adbconnect",translate("Connect the current client"))
adbconnect.rmempty = true
adbconnect.inputstyle = "apply"
function adbconnect.write(self, section)
	luci.util.exec("adb connect $(uci get adbrun."..section..".adbiplist) >/dev/null 2>&1 &")
end

adbplay = s:taboption("adb_action",Button, "adbplay", translate("Play")) 
adbplay.rmempty = true
adbplay.inputstyle = "apply"
function adbplay.write(self, section)
	luci.util.exec("cp /usr/adbrun/adbcommand.sh /tmp/adb_ADBRUN" ..section.. "_.sh >/dev/null 2>&1 &")
	luci.util.exec("/tmp/adb_ADBRUN" ..section.. "_.sh >/dev/null 2>&1 &")
end

adbstop = s:taboption("adb_action",Button, "adbstop", translate("Stop loop script")) 
adbstop.rmempty = true
adbstop.inputstyle = "apply"
function adbstop.write(self, section)
	luci.util.exec("kill $(ps | grep ADBRUN" ..section.. "_ | grep -v grep | head -n 1 | cut -d 'r' -f 1) > /dev/null 2>&1")
end

return m

