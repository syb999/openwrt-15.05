m = Map("autodl", translate("Autodl"))

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download m3u8 videos."))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting for Video"))

url=s:taboption("basic", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.description = translate("URL for downloading videos")

path=s:taboption("basic", Value, "path", translate("Download Videos directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("Please enter a valid directory")

name=s:taboption("basic", Value, "name", translate("Videos Name"))
name.datatype = "string"
name.default = "鬼灭之刃"
name.rmempty = false
name.description = translate("Videos from dy10000.com or xgys.net")

num=s:taboption("basic", Value, "num", translate("Total number of video files"))
num.datatype = "string"
num.default = "1"
num.rmempty = false
num.description = translate("Please enter a valid number")

s:tab("basic2", translate("Basic Setting for Audio"))

xmlyurl=s:taboption("basic2", Value, "xmlyurl", translate("Audios URL"))
xmlyurl.rmempty = true
xmlyurl.datatype = "string"
xmlyurl.description = translate("URL for downloading https://www.ximalaya.com Audios")

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

xmlycookie=s:taboption("basic2", Value, "xmlycookie", translate("The value with Account Cookie name:1&_token"))
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
    luci.util.exec("/usr/autodl/xmlygetlist.sh &")
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

s:tab("basic4", translate("Basic Setting for qingbiji"))

qbjcookie=s:taboption("basic4", Value, "qbjcookie", translate("Get Cookie form URL:qingbiji.cn/myNote"))
qbjcookie.datatype = "string"
qbjcookie.default = ""
qbjcookie.description = translate("Using the Cookie to get Your Notes from https://www.qingbiji.cn")

qbjnum=s:taboption("basic4", Value, "qbjnum", translate("Number of Your Documents"))
qbjnum.datatype = "string"
qbjnum.placeholder = "1"
qbjnum.default = "1"
qbjnum.rmempty = false
qbjnum.description = translate("Enter a positive integer")

qbjpath=s:taboption("basic4", Value, "qbjpath", translate("Download documents directory"))
qbjpath.datatype = "string"
qbjpath.default = "/mnt/sda3/qbj"
qbjpath.rmempty = false
qbjpath.description = translate("Please enter a valid directory")

s:tab("basic5", translate("Basic Setting for book"))

bookurl=s:taboption("basic5", Value, "bookurl", translate("Book contents URL"))
bookurl.rmempty = true
bookurl.datatype = "string"
bookurl.description = translate("Book URL")

bookname=s:taboption("basic5", Value, "bookname", translate("The title of a book"))
bookname.datatype = "string"
bookname.placeholder = "story"
bookname.default = "story"
bookname.rmempty = false

bookpath=s:taboption("basic5", Value, "bookpath", translate("Download book directory"))
bookpath.datatype = "string"
bookpath.default = "/mnt/sda3/book"
bookpath.rmempty = false
bookpath.description = translate("Please enter a valid directory")

---url1=s:taboption("basic", Button, "url1", translate("Sync download address (save & app after sync)"))
---url1.inputstyle = "apply"

s:tab("autodl1", translate("Videos Download Page"))
au1 = s:taboption("autodl1", Button, "_autodl1", translate("One-click download"))
au1.inputstyle = "apply"
au1.description = translate("Download from https://www.dy10000.com")
function au1.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].name > /tmp/autodl.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl1.sh &")
end

au2 = s:taboption("autodl1", Button, "_autodl2", translate("One-click download"))
au2.inputstyle = "apply"
au2.description = translate("Download from https://www.xgys.net")
function au2.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].name > /tmp/autodl.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl2.sh &")
end

au5 = s:taboption("autodl1", Button, "_autodl5", translate("One-click download"))
au5.inputstyle = "apply"
au5.description = translate("Download from https://www.gclxx.com")
function au5.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].name > /tmp/autodl.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl5.sh &")
end

au6 = s:taboption("autodl1", Button, "_autodl6", translate("One-click download"))
au6.inputstyle = "apply"
au6.description = translate("Download from http://gtghy-45.cn")
function au6.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].name > /tmp/autodl.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl6.sh &")
end

au7 = s:taboption("autodl1", Button, "_autodl7", translate("One-click download"))
au7.inputstyle = "apply"
au7.description = translate("Download from https://www.ppys5.net (depends openssl)")
function au7.write(self, section)
    luci.util.exec("/usr/autodl/autodl7.sh &")
end

au8 = s:taboption("autodl1", Button, "_autodl8", translate("One-click download"))
au8.inputstyle = "apply"
au8.description = translate("Download from http://www.jingcai520.com (depends openssl)")
function au8.write(self, section)
    luci.util.exec("/usr/autodl/autodl8.sh &")
end

au1t = s:taboption("autodl1", Button, "_autodl1t", translate("One-click ts to mp4"))
au1t.inputstyle = "apply"
au1t.description = translate("ffmpeg needs to be installed")
function au1t.write(self, section)
    luci.util.exec("/usr/autodl/tstomp4.sh &")
end

s:tab("audioxmly", translate("Download Audio from https://www.ximalaya.com"))
au3 = s:taboption("audioxmly", Button, "_audioxmly", translate("One-click download"))
au3.inputstyle = "apply"
au3.description = translate("Audios download")
function au3.write(self, section)
    luci.util.exec("nohup /usr/autodl/autodlxmly.sh >/dev/null 2>&1 &")
end

au3v = s:taboption("audioxmly", Button, "_audioau3v", translate("One-click download freeVIP"))
au3v.inputstyle = "apply"
au3v.description = translate("node needs to be installed")
function au3v.write(self, section)
    luci.util.exec("nohup /usr/autodl/autodlxmlyVIP.sh >/dev/null 2>&1 &")
end

au3t = s:taboption("audioxmly", Button, "_autodl3t", translate("One-click m4a to mp3"))
au3t.inputstyle = "apply"
au3t.description = translate("ffmpeg needs to be installed")
function au3t.write(self, section)
    luci.util.exec("nohup /usr/autodl/m4atomp3.sh >/dev/null 2>&1 &")
end

au3selectedplay = s:taboption("audioxmly", Button, "_autodl3selectedplay", translate("One-click Play selected mp3"))
au3selectedplay.inputstyle = "apply"
au3selectedplay.description = translate("USB sound card is needed and mpg123 package has been installed")
function au3selectedplay.write(self, section)
    luci.util.exec("/usr/autodl/playselectedmp3a.sh &")
end

au3play = s:taboption("audioxmly", Button, "_autodl3play", translate("One-click Play mp3(Positive)"))
au3play.inputstyle = "apply"
au3play.description = translate("USB sound card is needed and mpg123 package has been installed")
function au3play.write(self, section)
    luci.util.exec("/usr/autodl/playmp3a.sh &")
end

au3stop = s:taboption("audioxmly", Button, "_autodl3stop", translate("Stop play mp3"))
au3stop.inputstyle = "apply"
function au3stop.write(self, section)
    luci.util.exec("/usr/autodl/stopmp3.sh &")
end

au3playlastest = s:taboption("audioxmly", Button, "_autodl3playlastest", translate("One-click Play mp3(Reverse)"))
au3playlastest.inputstyle = "apply"
au3playlastest.description = translate("USB sound card is needed and mpg123 package has been installed")
function au3playlastest.write(self, section)
    luci.util.exec("/usr/autodl/playlastestmp3a.sh &")
end

au3next = s:taboption("audioxmly", Button, "_autodl3next", translate("Play Next mp3"))
au3next.inputstyle = "apply"
function au3next.write(self, section)
    luci.util.exec("/usr/autodl/playnext.sh &")
end

au3vup = s:taboption("audioxmly", Button, "_autodl3vup", translate("Volume Up"))
au3vup.inputstyle = "apply"
au3vup.description = translate("alsa-utils needs to be installed")
function au3vup.write(self, section)
    luci.util.exec("nohup /usr/autodl/volumeup.sh >/dev/null 2>&1 &")
end

au3vdown = s:taboption("audioxmly", Button, "_autodl3vdown", translate("Volume Down"))
au3vdown.inputstyle = "apply"
au3vdown.description = translate("alsa-utils needs to be installed")
function au3vdown.write(self, section)
    luci.util.exec("nohup /usr/autodl/volumedown.sh >/dev/null 2>&1 &")
end

au3isy = s:taboption("audioxmly", Button, "_audioisy", translate("www.ishuyin.com One-click download"))
au3isy:depends("wanna_get_ishuyin_audios", "1")
au3isy.inputstyle = "apply"
au3isy.description = translate("Audios download from https://www.ishuyin.com")
function au3isy.write(self, section)
    luci.util.exec("nohup /usr/autodl/autodlisy.sh >/dev/null 2>&1 &")
end

s:tab("autodldocin", translate("Download from https://www.docin.com"))
au4 = s:taboption("autodldocin", Button, "_autodldocin", translate("One-click download documents"))
au4.inputstyle = "apply"
au4.description = translate("docin.com documents download")
function au4.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].docinurl > /tmp/autodldocin.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].docinpage > /tmp/autodldocin.page")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].docinname > /tmp/autodldocin.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].docinpath > /tmp/autodldocin.path")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/docin.sh &")
end

s:tab("autodlqbj", translate("Download from https://www.qingbiji.cn"))
qbj1 = s:taboption("autodlqbj", Button, "_autodlqbj", translate("One-click download notes"))
qbj1.inputstyle = "apply"
qbj1.description = translate("download qingbiji.cn notes ")
function qbj1.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].qbjcookie > /tmp/autodlqbj.cookie")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].qbjnum > /tmp/autodlqbj.num")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].qbjpath > /tmp/autodlqbj.path")
    luci.util.exec("sleep 1")
    luci.util.exec("nohup /usr/autodl/autodlqbj.sh >/dev/null 2>&1 &")
end

s:tab("autodlbook", translate("Books Download Page"))
bk1 = s:taboption("autodlbook", Button, "_autodlbook", translate("One-click download book"))
bk1.inputstyle = "apply"
bk1.description = translate("Download a book from http://book.zongheng.com")
function bk1.write(self, section)
    luci.util.exec("/usr/autodl/autodlbook1.sh &")
end

bk2 = s:taboption("autodlbook", Button, "_autodlbook2", translate("One-click download book"))
bk2.inputstyle = "apply"
bk2.description = translate("Download a book from https://www.biquge5200.cc")
function bk2.write(self, section)
    luci.util.exec("/usr/autodl/autodlbook2.sh &")
end

return m

