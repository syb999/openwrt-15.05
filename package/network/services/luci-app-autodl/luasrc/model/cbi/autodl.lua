m = Map("autodl", translate("Autodl"))

m:section(SimpleSection).template  = "autodl_status"

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download"))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting for Video"))

url=s:taboption("basic", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.placeholder = "https://www.qdm88.com/dongman/1548.html"
url.default = "https://www.qdm88.com/dongman/1548.html"
url.description = translate("require: pip install pycryptodome")

path=s:taboption("basic", Value, "path", translate("Download Videos directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("Please enter a valid directory")

name=s:taboption("basic", Value, "name", translate("Videos Name"))
name.datatype = "string"
name.default = "凡人修仙传"
name.rmempty = false
name.description = translate("Videos from www.qdm88.com")

startnum=s:taboption("basic", Value, "startnum", translate("Start number of video files"))
startnum.datatype = "string"
startnum.default = "1"
startnum.rmempty = false
startnum.description = translate("Please enter a valid number")

endnum=s:taboption("basic", Value, "endnum", translate("End number of video files"))
endnum.datatype = "string"
endnum.default = "1"
endnum.rmempty = false
endnum.description = translate("Please enter a valid number")


s:tab("basic3", translate("Basic Setting for docin"))

docinurl=s:taboption("basic3", Value, "docinurl", translate("docin.com doc URL"))
docinurl.rmempty = true
docinurl.datatype = "string"
docinurl.description = translate("URL for downloading https://docin.com documents")

docinpage=s:taboption("basic3", Value, "docinpage", translate("Document total pages"))
docinpage.datatype = "string"
docinpage.placeholder = "1"
docinpage.default = "1"
docinpage.rmempty = false
docinpage.description = translate("Documents from https://docin.com")

docinname=s:taboption("basic3", Value, "docinname", translate("Document Name"))
docinname.datatype = "string"
docinname.placeholder = "story"
docinname.default = "story"
docinname.rmempty = false
docinname.description = translate("Documents from https://docin.com")

docinpath=s:taboption("basic3", Value, "docinpath", translate("Download documents directory"))
docinpath.datatype = "string"
docinpath.default = "/mnt/sda3/docs"
docinpath.rmempty = false
docinpath.description = translate("Please enter a valid directory")


s:tab("autodl1", translate("Videos Download Page"))
au1 = s:taboption("autodl1", Button, "_autodl1", translate("One-click download"))
au1.inputstyle = "apply"
au1.description = translate("Download from https://www.qdm88.com")
function au1.write(self, section)
    luci.util.exec("/usr/autodl/qdm88.sh >/dev/null 2>&1 &")
end

s:tab("online_server", translate("在线解码服务"))
ollist=s:taboption("online_server", ListValue, "ollist", translate("在线解码服务"))
ollist:value("olremote", translate("使用在线解码服务"))
ollist:value("ollocal", translate("提供在线解码服务"))
ollist.default     = "olremote"
ollist.rempty      = false

olslef=s:taboption("online_server", Button, "olslef", translate("运行解码服务"))
olslef:depends("ollist", "ollocal")
olslef.inputstyle = "apply"
olslef.description = translate("提供解码服务，需要安装好fastapi和uvicorn")
function olslef.write(self, section)
    luci.util.exec("python3 /usr/online_server/dexmly.py >/dev/null 2>&1 &")
end

olip = s:taboption("online_server", Value, "olip", translate("在线解码服务器"))
olip:depends("ollist", "olremote")
olip.datatype = "string"
olip.placeholder = "http://192.168.7.7"
olip.default = "http://192.168.7.7"
olip.description = translate("请输入服务器ip地址")

olp1 = s:taboption("online_server", Value, "olp1", translate("解码服务端口"))
olp1:depends("ollist", "olremote")
olp1.datatype = "string"
olp1.placeholder = "7777"
olp1.default = "7777"
olp1.description = translate("请输入解码服务端口号")

olp2 = s:taboption("online_server", Value, "olp2", translate("web服务端口"))
olp2:depends("ollist", "olremote")
olp2.datatype = "string"
olp2.placeholder = "80"
olp2.default = "80"
olp2.description = translate("请输入web服务端口号")

olm4amp3 = s:taboption("online_server", Button, "_olm4amp3", translate("m4a在线转码mp3"))
olm4amp3:depends("ollist", "olremote")
olm4amp3.inputstyle = "apply"
function olm4amp3.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlinemp3.sh >/dev/null 2>&1 &")
end

s:tab("online_serveqr", translate("在线生成二维码图片"))
qrcodeclientip= s:taboption("online_serveqr", Value, "qrcodeclientip", translate("wan ip"))
qrcodeclientip:depends("ollist", "olremote")
qrcodeclientip.datatype = "string"
qrcodeclientip.default = "http://192.168.1.1"
qrcodeclientip.description = translate("本机wan口ip(请自行确保http服务端口已做映射)")

qrcodefilepath = s:taboption("online_serveqr", Value, "qrcodefilepath", translate("File Path"))
qrcodefilepath:depends("ollist", "olremote")
qrcodefilepath.datatype = "string"
qrcodefilepath.default = "/tmp/file.csv"
qrcodefilepath.description = translate("二维码URL数据表文件路径（文件内容格式(支持多行)：名字,url,信息）")

qrcodeoutputpath = s:taboption("online_serveqr", Value, "qrcodeoutputpath", translate("Output Directory"))
qrcodeoutputpath:depends("ollist", "olremote")
qrcodeoutputpath.datatype = "string"
qrcodeoutputpath.default = "/tmp"
qrcodeoutputpath.description = translate("文件输出目录")

qrcodemake = s:taboption("online_serveqr", Button, "qrcodemake", translate("批量在线生成二维码图片"))
qrcodemake:depends("ollist", "olremote")
qrcodemake.inputstyle = "apply"
function qrcodemake.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlineqrcode.sh >/dev/null 2>&1 &")
end

s:tab("autodldocin", translate("Download from https://www.docin.com"))

au4 = s:taboption("autodldocin", Button, "_autodldocin", translate("One-click download documents"))
au4.inputstyle = "apply"
au4.description = translate("docin.com documents download")
function au4.write(self, section)
    luci.util.exec("/usr/autodl/docin.sh >/dev/null 2>&1 &")
end

au4txt = s:taboption("autodldocin", Button, "_autodldocintxt", translate("One-click convert to TXT"))
au4txt.inputstyle = "apply"
au4txt.description = translate("docin.com documents convert to TXT(depends imagemagick & tesseract)")
function au4txt.write(self, section)
    luci.util.exec("/usr/autodl/docintotxt.sh >/dev/null 2>&1 &")
end


s:tab("audioplaytab", translate("Audio playback menu"))
byebyegst = s:taboption("audioplaytab", Button, "byebyegst", translate("One-click discard gst-play-1.0"))
byebyegst.inputstyle = "apply"
byebyegst.description = translate("Not suitable for MIPS routers")
function byebyegst.write(self, section)
    luci.util.exec("sed -i 's/gst-play-1.0/gstplaybroken/' /usr/autodl/testplayer >/dev/null 2>&1 &")
end

hellogst = s:taboption("audioplaytab", Button, "hellogst", translate("One-click reuse gst-play-1.0"))
hellogst.inputstyle = "apply"
function hellogst.write(self, section)
    luci.util.exec("sed -i 's/gstplaybroken/gst-play-1.0/' /usr/autodl/testplayer >/dev/null 2>&1 &")
end

au3vup = s:taboption("audioplaytab", Button, "_autodl3vup", translate("Volume Up"))
au3vup.inputstyle = "apply"
au3vup.description = translate("alsa-utils needs to be installed")
function au3vup.write(self, section)
    luci.util.exec("/usr/autodl/volumeup.sh >/dev/null 2>&1 &")
end

au3vdown = s:taboption("audioplaytab", Button, "_autodl3vdown", translate("Volume Down"))
au3vdown.inputstyle = "apply"
au3vdown.description = translate("alsa-utils needs to be installed")
function au3vdown.write(self, section)
    luci.util.exec("/usr/autodl/volumedown.sh >/dev/null 2>&1 &")
end

au3usesnd1 = s:taboption("audioplaytab", Button, "_au3usesnd1", translate("Use the second sound card"))
au3usesnd1.inputstyle = "apply"
au3usesnd1.description = translate("alsa-utils needs to be installed")
function au3usesnd1.write(self, section)
    luci.util.exec("/usr/autodl/usesoundcard1.sh >/dev/null 2>&1 &")
end

au3usesnd0 = s:taboption("audioplaytab", Button, "_au3usesnd0", translate("Use default sound card"))
au3usesnd0.inputstyle = "apply"
au3usesnd0.description = translate("alsa-utils needs to be installed")
function au3usesnd0.write(self, section)
    luci.util.exec("/usr/autodl/usesoundcard0.sh >/dev/null 2>&1 &")
end


s:tab("webradiotab", translate("Network radio"))

local aweburllist = "/usr/autodl/audurllist"
local AUDNXFS = require "nixio.fs"
audweburl = s:taboption("webradiotab", TextValue, "aweburllist")
audweburl.rows = 6
audweburl.wrap = "on"
audweburl.cfgvalue = function(self, section)
	return AUDNXFS.readfile(aweburllist) or ""
end
audweburl.write = function(self, section, value)
	AUDNXFS.writefile(aweburllist, value:gsub("\r\n", "\n"))
end

webaudioselc = s:taboption("webradiotab", ListValue, "wbaudurl", translate("Select radio URL"))
webaudioselc.default = "null"

local webplayselcurl = { }
local webplayload = io.open("/usr/autodl/audurllist", "r")

if webplayload then
	local listaudurl
	repeat
		listaudurl = webplayload:read("*l")
		local s = listaudurl
		if s then webplayselcurl[#webplayselcurl+1] = s end
	until not listaudurl
	webplayload:close()
end

for _, v in luci.util.vspairs(webplayselcurl) do
    webaudioselc:value(v)
end

webaudioplay = s:taboption("webradiotab", Button, "webaudioplay", translate("PLAY"))
webaudioplay.rmempty = true
webaudioplay.inputstyle = "apply"
function webaudioplay.write(self, section)
    luci.util.exec("/usr/autodl/weburlplay.sh >/dev/null 2>&1 &")
end

webaudiostop = s:taboption("webradiotab", Button, "_webaudiostop", translate("STOP"))
webaudiostop.inputstyle = "apply"
function webaudiostop.write(self, section)
    luci.util.exec("/usr/autodl/stopmp3.sh >/dev/null 2>&1 &")
end

webaudiovup = s:taboption("webradiotab", Button, "_webaudiovup", translate("Volume Up"))
webaudiovup.inputstyle = "apply"
webaudiovup.description = translate("alsa-utils needs to be installed")
function webaudiovup.write(self, section)
    luci.util.exec("/usr/autodl/volumeup.sh >/dev/null 2>&1 &")
end

webaudiovdown = s:taboption("webradiotab", Button, "_webaudiovdown", translate("Volume Down"))
webaudiovdown.inputstyle = "apply"
webaudiovdown.description = translate("alsa-utils needs to be installed")
function webaudiovdown.write(self, section)
    luci.util.exec("/usr/autodl/volumedown.sh >/dev/null 2>&1 &")
end

s:tab("webmusictab", translate("Network Music"))
webmusicsrc = s:taboption("webmusictab", ListValue, "webmusicsrc", translate("Music list"))
webmusicsrc.placeholder = "9ku"
webmusicsrc:value("9ku", translate("9ku"))
webmusicsrc:value("kugou", translate("kugou"))
webmusicsrc.default = "kugou"
webmusicsrc.rempty = true

web9kulist = s:taboption("webmusictab", ListValue, "web9kulist", translate("Music list"))
web9kulist:depends("webmusicsrc", "9ku")
web9kulist.placeholder = "none"
web9kulist:value("none")
web9kulist:value("9ku-top500", translate("9ku top 500"))
web9kulist:value("9ku-wangluo", translate("9ku net music"))
web9kulist:value("9ku-laoge", translate("9ku old music"))
web9kulist:value("9ku-yingwen", translate("9ku english music"))
web9kulist:value("9ku-chaqu", translate("9ku movie music"))
web9kulist:value("9ku-ktv", translate("9ku ktv music"))
web9kulist:value("all", translate("all"))
web9kulist.default = "none"
web9kulist.rempty = true

webkugoulist = s:taboption("webmusictab", ListValue, "webkugoulist", translate("Music list"))
webkugoulist:depends("webmusicsrc", "kugou")
webkugoulist.placeholder = "none"
webkugoulist:value("none")
webkugoulist:value("hummingbird-pop-music-chart", translate("hummingbird pop music chart"))
webkugoulist:value("tiktok-hot-song-chart", translate("tiktok hot song chart"))
webkugoulist:value("kwai-hot-song-chart", translate("kwai hot song chart"))
webkugoulist:value("western-golden-melody-chart", translate("western golden melody chart"))
webkugoulist:value("kugou-top500", translate("kugou top500"))
webkugoulist:value("acg-new-song-chart", translate("acg new song chart"))
webkugoulist:value("mainland-song-chart", translate("mainland song chart"))
webkugoulist:value("hongkong-song-chart", translate("hongkong song chart"))
webkugoulist:value("japanese-song-chart", translate("japanese song chart"))
webkugoulist:value("acg-new-song-chart", translate("acg new song chart"))
webkugoulist:value("billboard-chart", translate("billboard chart"))
webkugoulist:value("all", translate("all"))
webkugoulist.default = "none"
webkugoulist.rempty = true

webmusicplay = s:taboption("webmusictab", Button, "webmusicplay", translate("PLAY"))
webmusicplay.rmempty = true
webmusicplay.inputstyle = "apply"
function webmusicplay.write(self, section)
    luci.util.exec("/usr/autodl/webmusicplay.sh >/dev/null 2>&1 &")
end

webmusicstop = s:taboption("webmusictab", Button, "webmusicstop", translate("STOP"))         
webmusicstop.inputstyle = "apply"
function webmusicstop.write(self, section)
    luci.util.exec("kill -9 $(ps -w | grep webmusicplay.sh | grep -v grep | awk '{print$1}') >/dev/null 2>&1 &")
    luci.util.exec("kill -9 $(ps -w | grep mpg123 | grep -v grep | awk '{print$1}') >/dev/null 2>&1 &")
end

webmusicnext = s:taboption("webmusictab", Button, "webmusicnext", translate("Next Song"))         
webmusicnext.inputstyle = "apply"
function webmusicnext.write(self, section)
    luci.util.exec("kill -9 $(ps -w | grep mpg123 | grep -v grep | awk '{print$1}') >/dev/null 2>&1 &")
end

webmusicpath = s:taboption("webmusictab", Value, "webmusicpath", translate("Download Audios directory"))
webmusicpath.datatype = "string"
webmusicpath.default = "/mnt/sda3/webmusic"
webmusicpath.rmempty = true
webmusicpath.description = translate("Please enter a valid directory")

webmusic_dl_mode = s:taboption("webmusictab", ListValue, "webmusic_dl_mode", translate("Download mode"))
webmusic_dl_mode.placeholder = "manual-download"
webmusic_dl_mode:value("manual-download", translate("manual download"))
webmusic_dl_mode:value("automatic-download", translate("automatic download while playing"))
webmusic_dl_mode.default = "manual-download"
webmusic_dl_mode.rempty = true

webmusicdownload = s:taboption("webmusictab", Button, "webmusicdownload", translate("Download current music"))          
webmusicdownload:depends("webmusic_dl_mode", "manual-download")
webmusicdownload.rmempty = true
webmusicdownload.inputstyle = "apply"
function webmusicdownload.write(self, section)
    luci.util.exec("wget-ssl -t 5 -q -c $(cat /tmp/webmusic.tmp.url) -O $(uci get autodl.@autodl[0].webmusicpath)/$(cat /tmp/webmusic.tmp.info).mp3 >/dev/null 2>&1 &")
end
                                                                                              
s:tab("eventradiotab", translate("Background Music of Event"))
eventname1=s:taboption("eventradiotab", Value, "eventname1", translate("FileName1"))
eventname1.datatype = "string"
eventname1.default = "/tmp/1.mp3"
eventname1.rmempty = false

eventaudio1 = s:taboption("eventradiotab", Button, "eventaudio1", translate("Play FileName1"))
eventaudio1.inputstyle = "apply"
function eventaudio1.write(self, section)
    luci.util.exec("mpg123 \"$(uci get autodl.@autodl[0].eventname1)\" >/dev/null 2>&1 &")
end

eventname2=s:taboption("eventradiotab", Value, "eventname2", translate("FileName2"))
eventname2.datatype = "string"
eventname2.default = "/tmp/2.mp3"
eventname2.rmempty = false

eventaudio2 = s:taboption("eventradiotab", Button, "eventaudio2", translate("Play FileName2"))
eventaudio2.inputstyle = "apply"
function eventaudio2.write(self, section)
    luci.util.exec("mpg123 \"$(uci get autodl.@autodl[0].eventname2)\" >/dev/null 2>&1 &")
end

eventname3=s:taboption("eventradiotab", Value, "eventname3", translate("FileName3"))
eventname3.datatype = "string"
eventname3.default = "/tmp/3.mp3"
eventname3.rmempty = false

eventaudio3 = s:taboption("eventradiotab", Button, "eventaudio3", translate("Play FileName3"))
eventaudio3.inputstyle = "apply"
function eventaudio3.write(self, section)
    luci.util.exec("mpg123 \"$(uci get autodl.@autodl[0].eventname3)\" >/dev/null 2>&1 &")
end

eventaudiostop = s:taboption("eventradiotab", Button, "eventaudiostop", translate("STOP"))
eventaudiostop.inputstyle = "apply"
function eventaudiostop.write(self, section)
    luci.util.exec("/usr/autodl/stopmp3.sh >/dev/null 2>&1 &")
end


return m
