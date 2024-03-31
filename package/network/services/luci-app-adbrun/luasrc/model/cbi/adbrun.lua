m = Map("adbrun", translate("ADB server"))

m:section(SimpleSection).template  = "adbrun_status"

a = m:section(TypedSection, "adbinit", "")

a:tab("adb_init", translate("init devices"))
refresh_pic = a:taboption("adb_init", Button, "refresh_pic", translate("refresh all preview pics"))
refresh_pic.rmempty = true
refresh_pic.inputstyle = "apply"
function refresh_pic.write(self, section)
	luci.util.exec("rm /tmp/*.screen.png >/dev/null 2>&1 &")
end

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
	luci.util.exec("mv /etc/hotplug.d/usb/30-adb_init /etc/30-adb_init >/dev/null 2>&1 &")
end

adbxhotplug = a:taboption("adb_init", Button, "adbxhotplug", translate("One-click resume hotplug"))
adbxhotplug.rmempty = true
adbxhotplug.inputstyle = "apply"
adbxhotplug.description = translate("After hot plug is enabled, you can continue to initialize the device using USB cable")
function adbxhotplug.write(self, section)
	luci.util.exec("mv /etc/30-adb_init /etc/hotplug.d/usb/30-adb_init >/dev/null 2>&1 &")
end

a:tab("diantaoinit_set", translate("diantao init setting"))
diantaoskip = a:taboption("diantaoinit_set", Value, "diantaoskip", translate("diantao skip step(default for 1080x1920)"))
diantaoskip.datatype = "string"
diantaoskip.default = "210"
diantaoskip.rmempty = false


diantaodayworklist = a:taboption("diantaoinit_set", Value, "diantaodayworklist", translate("diantao daytime worklist"))
diantaodayworklist.datatype = "string"
diantaodayworklist.default = "skip 60秒2次 skip 3分钟1次 5分钟2次 5分钟3次 60秒1次"
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
adbcommandlist:value("none")
adbcommandlist:value("get-input-event", translate("get input event"))
adbcommandlist:value("record-tap", translate("record tap"))
adbcommandlist:value("crazy-tap", translate("crazy tap"))
adbcommandlist:value("update-preview-picture", translate("update preview picture"))
adbcommandlist:value("push-and-install-apk", translate("push and install apk"))
adbcommandlist:value("reboot-bootloader", translate("entry bootloader mode"))
adbcommandlist:value("reboot-recovery", translate("entry recovery mode"))
adbcommandlist:value("reboot-fastboot", translate("entry fastboot mode"))
adbcommandlist:value("reboot", translate("reboot"))
adbcommandlist:value("poweroff", translate("poweroff"))
adbcommandlist:value("auto-install-ADBKeyboard", translate("auto-install ADBKeyboard"))
adbcommandlist:value("input-chinese", translate("input chinese"))
adbcommandlist:value("menu-key", translate("menu key"))
adbcommandlist:value("home-key", translate("home key"))
adbcommandlist:value("return-key", translate("return key"))
adbcommandlist:value("allow-unknown-sources", translate("Allow installation of apps from unknown sources"))
adbcommandlist:value("turn-offon-the-screen", translate("Turn off/on the screen"))
adbcommandlist:value("turn-on-the-screen", translate("Turn on screen"))
adbcommandlist:value("increase-screen-brightness", translate("Increase screen brightness"))
adbcommandlist:value("reduce-screen-brightness", translate("Reduce screen brightness"))
adbcommandlist:value("playstop", translate("Play or stop"))
adbcommandlist:value("playnext", translate("Play the next"))
adbcommandlist:value("playprevious", translate("Play the previous"))
adbcommandlist:value("resume-playback", translate("Resume playback"))
adbcommandlist:value("pause-playback", translate("Pause playback"))
adbcommandlist:value("mute", translate("Mute on/off"))
adbcommandlist:value("runcamera", translate("Run camera"))
adbcommandlist:value("photograph", translate("Take a picture"))
adbcommandlist:value("screenrecord", translate("Screen record 30s"))
adbcommandlist:value("dlscreenrecord", translate("Push screen record to openwrt"))
adbcommandlist:value("runwechat", translate("Run Wechat"))
adbcommandlist:value("runqq", translate("Run QQ"))
adbcommandlist:value("takephoto", translate("Automatically take photos"))
adbcommandlist:value("screenshot", translate("Automatically push screenshot to openwrt"))
adbcommandlist:value("readbook", translate("Automatically read book"))
adbcommandlist:value("kuaishou", translate("Automatically play kuaishou"))
adbcommandlist:value("diantaolive", translate("Automatically diantaolive"))
adbcommandlist:value("autodiantao", translate("Automatically taobao live"))
adbcommandlist:value("autojdlite", translate("Automatically jdlite"))
adbcommandlist:value("tbbbfarm", translate("Automatically taobao baba farm"))
adbcommandlist.default = "none"
adbcommandlist.rempty = true

adb_recordtime = s:taboption("adb_set", Value, "adb_recordtime", translate("recording duration"))
adb_recordtime:depends( "adbcommandlist", "record-tap" )
adb_recordtime.datatype = "uinteger"
adb_recordtime.default = "2"
adb_recordtime.rmempty = true
adb_recordtime.description = translate("in seconds")

adb_looptime = s:taboption("adb_set", Value, "adb_looptime", translate("looping times"))
adb_looptime:depends( "adbcommandlist", "crazy-tap" )
adb_looptime.datatype = "uinteger"
adb_looptime.default = "150"
adb_looptime.rmempty = true

adb_src_path = s:taboption("adb_set", Value, "adb_src_path", translate("apk path"))
adb_src_path:depends( "adbcommandlist", "push-and-install-apk" )
adb_src_path.datatype = "string"
adb_src_path.default = "/tmp/xxx.apk"
adb_src_path.rmempty = true
adb_src_path.description = translate("push to /sdcard directory")

adb_input_ch = s:taboption("adb_set", Value, "adb_input_ch", translate("input text"))                                 
adb_input_ch:depends( "adbcommandlist", "input-chinese" )                                                                
adb_input_ch.datatype = "string"                                                                           
adb_input_ch.default = "你好啊"                                                                                     
adb_input_ch.rmempty = true 
adb_input_ch.description = translate("please install ADBKeyboard.apk first")

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
	luci.util.exec("sleep 1")
	luci.util.exec("/tmp/adb_ADBRUN" ..section.. "_.sh >/dev/null 2>&1 &")
end

adbstop = s:taboption("adb_action",Button, "adbstop", translate("Stop loop script")) 
adbstop.rmempty = true
adbstop.inputstyle = "apply"
function adbstop.write(self, section)
	luci.util.exec("kill -9 $(busybox ps | grep ADBRUN" ..section.. "_ | grep -v grep | awk '{print$1}') > /dev/null 2>&1")
end

return m

