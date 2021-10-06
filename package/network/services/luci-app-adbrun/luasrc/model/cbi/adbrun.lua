m = Map("adbrun", translate("adb server."))

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

adbcommandlist = s:taboption("adb_set", ListValue, "adbcommandlist", translate("command list"), translate("adbrun command list"))
adbcommandlist.placeholder = "none"
adbcommandlist:value("none", translate("none"))
adbcommandlist:value("turn-offon-the-screen", translate("Turn off/on the screen"))
adbcommandlist:value("turn-on-the-screen", translate("Turn on screen"))
adbcommandlist:value("playstop", translate("Play audio or stop"))
adbcommandlist:value("playnext", translate("Play the next"))
adbcommandlist:value("playprevious", translate("Play the previous"))
adbcommandlist:value("resume-playback", translate("Playback audio"))
adbcommandlist:value("pause-playback", translate("Pause audio"))
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
adbcommandlist:value("pyxmlylite", translate("Automatically get gold coins from ximalaya lite version"))
adbcommandlist:value("readbook", translate("Automatically read book"))
adbcommandlist:value("autodiantao", translate("Automatically taobao live"))
adbcommandlist.default     = "none"
adbcommandlist.rempty      = false


s:tab("adb_action", translate("Action"))

adbconnect=s:taboption("adb_action",Button,"adbconnect",translate("Connect client"))
adbconnect.rmempty = true
adbconnect.inputstyle = "apply"
function adbconnect.write(self, section)
	local adbconnectip = luci.util.exec("adb connect $(uci get adbrun."..section..".adbiplist)")
	--testconnect = luci.util.exec("adb devices | grep -i "..section)
	--if testconnect == "" then
		--luci.util.exec("logger Connection failed: Please connect the computer with USB cable. ")
		--luci.util.exec("logger Run: adb tcpip 5555 ")
	--else
		--luci.util.exec("logger Successful: "..adbconnectip)
	--end
end

adbplay=s:taboption("adb_action",Button, "adbplay", translate("Play")) 
adbplay.rmempty = true
adbplay.inputstyle = "apply"
function adbplay.write(self, section)
	luci.util.exec("cp /usr/adbrun/adbcommand.sh /tmp/adb_" ..section.. "_.sh")
	luci.util.exec("/tmp/adb_" ..section.. "_.sh")
end

adbstop=s:taboption("adb_action",Button, "adbstop", translate("Stop loop script")) 
adbstop.rmempty = true
adbstop.inputstyle = "apply"
function adbstop.write(self, section)
	luci.util.exec("kill $(ps | grep " ..section.. " | head -n 1 | grep -v grep | cut -d 'r' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | head -n 1 | grep -v grep | cut -d 'r' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | head -n 1 | grep -v grep | cut -d ' ' -f 1) > /dev/null 2>&1")
	luci.util.exec("kill $(ps | grep " ..section.. " | head -n 1 | grep -v grep | cut -d ' ' -f 1) > /dev/null 2>&1")
end

return m

