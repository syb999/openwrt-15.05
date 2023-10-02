m = Map("autodl", translate("Autodl"))

m:section(SimpleSection).template  = "autodl_status"

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download"))
s.anonymous = true
s.addremove = false

s:tab("basic2", translate("Basic Setting for Audio"))

xmlyurl=s:taboption("basic2", Value, "xmlyurl", translate("Audios URL"))
xmlyurl.rmempty = true
xmlyurl.datatype = "string"
xmlyurl.description = translate("URL for downloading https://www.ximalaya.com Audios")

xmlypagenum=s:taboption("basic2", Value, "xmlypagenum", translate("The starting page number"))
xmlypagenum.rmempty = true
xmlypagenum.datatype = "uinteger"
xmlypagenum.default = "1"

xmlymultiurl=s:taboption("basic2", Flag, "xmly_multi_pages", translate("Audios URL multi pages"))
xmlymultiurl.description = translate("Need to download multiple pages of resources")

xmlygetpages=s:taboption("basic2", Value, "xmlygetpages", translate("Number of pages to download"))
xmlygetpages:depends("xmly_multi_pages", "1")
xmlygetpages.datatype = "uinteger"
xmlygetpages.default = "0"

xmlyname=s:taboption("basic2", Value, "xmlyname", translate("Audios Name"))
xmlyname.datatype = "string"
xmlyname.placeholder = "story"
xmlyname.default = "story"
xmlyname.rmempty = false
xmlyname.description = translate("Audios from https://www.ximalaya.com")

xmlycvip = s:taboption("basic2", Flag, "wanna_get_VIP_audios", translate("Wanna get VIP audios"))
xmlycvip.description = translate("You must have VIP accout")

xmlycookie=s:taboption("basic2", Value, "xmlycookie", translate("The value with Account Cookie name: 1＆_token"))
xmlycookie:depends("wanna_get_VIP_audios", "1")
xmlycookie.datatype = "string"
xmlycookie.default = ""
xmlycookie.description = translate("Using The Cookie of VIP account to get VIP audios")

xmlysleeptime=s:taboption("basic2", Value, "xmlysleeptime", translate("Set delay time"))
xmlysleeptime:depends("wanna_get_VIP_audios", "1")
xmlysleeptime.datatype = "uinteger"
xmlysleeptime.default = "0"

xmlypath=s:taboption("basic2", Value, "xmlypath", translate("Download Audios directory"))
xmlypath.datatype = "string"
xmlypath.default = "/mnt/sda3/audios"
xmlypath.rmempty = false
xmlypath.description = translate("Please enter a valid directory")

xmlygetlist = s:taboption("basic2", Button, "xmlygetlist", translate("Get list"))
xmlygetlist.inputstyle = "apply"
xmlygetlist.description = translate("Show current audio list")
function xmlygetlist.write(self, section)
    luci.util.exec("/usr/autodl/xmlygetlist.sh >/dev/null 2>&1 &")
end

xmlyopennum = s:taboption("basic2", Flag, "select_audio_numbers", translate("Select Audio number"))
xmlyopennum.description = translate("Get list first")

xmlysenum = s:taboption("basic2", ListValue, "audio_num", translate("Select Audio"))
xmlysenum:depends("select_audio_numbers", "1")
xmlysenum.default = "null"

local xmlyplaynumf = { }
local xmlyfload = io.open("/tmp/tmp.Audioxm.list", "r")

if xmlyfload then
	local listnumb
	repeat
		listnumb = xmlyfload:read("*l")
		local s = listnumb
		if s then xmlyplaynumf[#xmlyplaynumf+1] = s end
	until not listnumb
	xmlyfload:close()
end

for _, v in luci.util.vspairs(xmlyplaynumf) do
    xmlysenum:value(v)
end

isydl = s:taboption("basic2", Flag, "wanna_get_ishuyin_audios", translate("Wanna get www.ishuyin.com audios"))

isyurl=s:taboption("basic2", Value, "isyurl", translate("Audios URL"))
isyurl:depends("wanna_get_ishuyin_audios", "1")
isyurl.rmempty = true
isyurl.datatype = "string"
isyurl.description = translate("URL for downloading https://www.ishuyin.com Audios")

isyname=s:taboption("basic2", Value, "isyname", translate("Audios Name"))
isyname:depends("wanna_get_ishuyin_audios", "1")
isyname.datatype = "string"
isyname.placeholder = "story"
isyname.default = "story"
isyname.rmempty = true
isyname.description = translate("Audios from https://www.ishuyin.com")

isypath=s:taboption("basic2", Value, "isypath", translate("Download Audios directory"))
isypath:depends("wanna_get_ishuyin_audios", "1")
isypath.datatype = "string"
isypath.default = "/mnt/sda3/audios"
isypath.rmempty = true
isypath.description = translate("Please enter a valid directory")

isynumber=s:taboption("basic2", Value, "isynumber", translate("Download Audios numbers"))
isynumber:depends("wanna_get_ishuyin_audios", "1")
isynumber.datatype = "uinteger"
isynumber.default = "1"
isynumber.rmempty = true
isynumber.description = translate("Please enter the total number")

kugoudl = s:taboption("basic2", Flag, "wanna_get_kugou_audios", translate("Wanna get https://www.kugou.com/ts/ audios"))

kugouurl=s:taboption("basic2", Value, "kugouurl", translate("Audios URL"))
kugouurl:depends("wanna_get_kugou_audios", "1")
kugouurl.rmempty = true
kugouurl.datatype = "string"
kugouurl.default = "https://www.kugou.com/ts/xiaoshuo/x76gwaa/"
kugouurl.description = translate("URL for downloading https://www.kugou.com/ts/ Audios")

kugouname=s:taboption("basic2", Value, "kugouname", translate("Audios Name"))
kugouname:depends("wanna_get_kugou_audios", "1")
kugouname.datatype = "string"
kugouname.placeholder = "story"
kugouname.default = "宇宙职业选手"
kugouname.rmempty = true

kugoupath=s:taboption("basic2", Value, "kugoupath", translate("Download Audios directory"))
kugoupath:depends("wanna_get_kugou_audios", "1")
kugoupath.datatype = "string"
kugoupath.default = "/mnt/sda3/audios"
kugoupath.rmempty = true
kugoupath.description = translate("Please enter a valid directory")

kugounumber=s:taboption("basic2", Value, "kugounumber", translate("Download Audios numbers"))
kugounumber:depends("wanna_get_kugou_audios", "1")
kugounumber.datatype = "uinteger"
kugounumber.default = "10"
kugounumber.rmempty = true
kugounumber.description = translate("Please enter the total number")


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


s:tab("audioxmly", translate("Download Audio from https://www.ximalaya.com"))
au3 = s:taboption("audioxmly", Button, "_audioxmly", translate("One-click download"))
au3.inputstyle = "apply"
au3.description = translate("Audios download")
function au3.write(self, section)
    luci.util.exec("/usr/autodl/autodlxmly.sh >/dev/null 2>&1 &")
end

au3v = s:taboption("audioxmly", Button, "_audioau3v", translate("One-click download freeVIP"))
au3v.inputstyle = "apply"
au3v.description = translate("node needs to be installed")
function au3v.write(self, section)
    luci.util.exec("/usr/autodl/autodlxmlyVIP.sh >/dev/null 2>&1 &")
end

au3t = s:taboption("audioxmly", Button, "_autodl3t", translate("One-click m4a to mp3"))
au3t.inputstyle = "apply"
au3t.description = translate("ffmpeg needs to be installed")
function au3t.write(self, section)
    luci.util.exec("/usr/autodl/m4atomp3.sh >/dev/null 2>&1 &")
end

au3isy = s:taboption("audioxmly", Button, "_audioisy", translate("www.ishuyin.com One-click download"))
au3isy:depends("wanna_get_ishuyin_audios", "1")
au3isy.inputstyle = "apply"
au3isy.description = translate("Audios download from https://www.ishuyin.com")
function au3isy.write(self, section)
    luci.util.exec("/usr/autodl/autodlisy.sh >/dev/null 2>&1 &")
end

au3kugou = s:taboption("audioxmly", Button, "_audiokugou", translate("https://www.kugou.com/ts/ One-click download"))
au3kugou:depends("wanna_get_kugou_audios", "1")
au3kugou.inputstyle = "apply"
au3kugou.description = translate("Audios download from https://www.kugou.com/ts/")
function au3kugou.write(self, section)
    luci.util.exec("/usr/autodl/autodlkugou.sh >/dev/null 2>&1 &")
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

oldlvip = s:taboption("online_server", Button, "_oldlvip", translate("用解码服务器下载新品限免VIP资源(本机免安装Node)"))
oldlvip:depends("ollist", "olremote")
oldlvip.inputstyle = "apply"
oldlvip.description = translate("需要特定的解码服务器支持,本机需安装urlencode")
function oldlvip.write(self, section)
    luci.util.exec("/usr/autodl/ols/xmlyonline.sh >/dev/null 2>&1 &")
end

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

s:tab("online_serverp", translate("在线解码播放"))
olalbumid = s:taboption("online_serverp", Value, "olalbumid", translate("Audios URL"))
olalbumid:depends("ollist", "olremote")
olalbumid.rmempty = true
olalbumid.datatype = "string"
olalbumid.description = translate("播放https://www.ximalaya.com音频的网址url")

olpagenums = s:taboption("online_serverp", Value, "olpagenums", translate("起始集数"))
olpagenums:depends("ollist", "olremote")
olpagenums.datatype = "string"
olpagenums.placeholder = "1"
olpagenums.default = "1"
olpagenums.description = translate("免费节目集数排序取反，最新一集定为第1集")

olpagenume = s:taboption("online_serverp", Value, "olpagenume", translate("结束页码"))
olpagenume:depends("ollist", "olremote")
olpagenume.datatype = "string"
olpagenume.placeholder = "2"
olpagenume.default = "2"
olpagenume.description = translate("每页30集")

olplayfr = s:taboption("online_serverp", Button, "_olplayfr", translate("直接在线播放喜马拉雅免费节目"))
olplayfr:depends("ollist", "olremote")
olplayfr.inputstyle = "apply"
function olplayfr.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlineplayxmf.sh >/dev/null 2>&1 &")
end

olplayvp = s:taboption("online_serverp", Button, "_olplayvp", translate("直接在线播放喜马拉雅新品限免VIP节目"))
olplayvp:depends("ollist", "olremote")
olplayvp.inputstyle = "apply"
function olplayvp.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlineplayxmv.sh >/dev/null 2>&1 &")
end


olnext = s:taboption("online_serverp", Button, "_olnext", translate("播放下一集"))
olnext:depends("ollist", "olremote")
olnext.inputstyle = "apply"
function olnext.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlinenext.sh >/dev/null 2>&1 &")
end

olstop = s:taboption("online_serverp", Button, "_olstop", translate("停止播放"))
olstop:depends("ollist", "olremote")
olstop.inputstyle = "apply"
function olstop.write(self, section)
    luci.util.exec("/usr/autodl/ols/onlinestop.sh >/dev/null 2>&1 &")
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

au3selectedplay = s:taboption("audioplaytab", Button, "_autodl3selectedplay", translate("One-click Play selected mp3(m4a aac)"))
au3selectedplay.inputstyle = "apply"
au3selectedplay.description = translate("USB sound card is needed and gst-play-1.0 or mpg123 package has been installed")
function au3selectedplay.write(self, section)
    luci.util.exec("/usr/autodl/playselectedmp3a.sh >/dev/null 2>&1 &")
end

au3play = s:taboption("audioplaytab", Button, "_autodl3play", translate("One-click Play mp3(Positive)"))
au3play.inputstyle = "apply"
au3play.description = translate("USB sound card is needed and gst-play-1.0 or mpg123 package has been installed")
function au3play.write(self, section)
    luci.util.exec("/usr/autodl/playmp3a.sh >/dev/null 2>&1 &")
end

au3stop = s:taboption("audioplaytab", Button, "_autodl3stop", translate("Stop play mp3"))
au3stop.inputstyle = "apply"
function au3stop.write(self, section)
    luci.util.exec("/usr/autodl/stopmp3.sh >/dev/null 2>&1 &")
end

au3playlastest = s:taboption("audioplaytab", Button, "_autodl3playlastest", translate("One-click Play mp3(Reverse)"))
au3playlastest.inputstyle = "apply"
au3playlastest.description = translate("USB sound card is needed and gst-play-1.0 or mpg123 package has been installed")
function au3playlastest.write(self, section)
    luci.util.exec("/usr/autodl/playlastestmp3a.sh >/dev/null 2>&1 &")
end

au3next = s:taboption("audioplaytab", Button, "_autodl3next", translate("Play Next mp3"))
au3next.inputstyle = "apply"
function au3next.write(self, section)
    luci.util.exec("/usr/autodl/playnext.sh >/dev/null 2>&1 &")
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
