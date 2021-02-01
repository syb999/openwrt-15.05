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

xmlyname=s:taboption("basic2", Value, "xmlyname", translate("Audios Name"))
xmlyname.datatype = "string"
xmlyname.placeholder = "story"
xmlyname.default = "story"
xmlyname.rmempty = false
xmlyname.description = translate("Audios from https://www.ximalaya.com")

xmlypath=s:taboption("basic2", Value, "xmlypath", translate("Download Audios directory"))
xmlypath.datatype = "string"
xmlypath.default = "/mnt/sda3/audios"
xmlypath.rmempty = false
xmlypath.description = translate("Please enter a valid directory")

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

---url1=s:taboption("basic", Button, "url1", translate("Sync download address (save & app after sync)"))
---url1.inputstyle = "apply"


s:tab("autodl1", translate("Download from https://www.dy10000.com"))
au1 = s:taboption("autodl1", Button, "_autodl1", translate("One-click download"))
au1.inputstyle = "apply"
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

au1t = s:taboption("autodl1", Button, "_autodl1t", translate("One-click ts to mp4"))
au1t.inputstyle = "apply"
au1t.description = translate("ffmpeg needs to be installed")
function au1t.write(self, section)
    luci.util.exec("/usr/autodl/tstomp4.sh &")
end

s:tab("autodl2", translate("Download from https://www.xgys.net"))
au2 = s:taboption("autodl2", Button, "_autodl2", translate("One-click download"))
au2.inputstyle = "apply"
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

au2t = s:taboption("autodl2", Button, "_autodl2t", translate("One-click ts to mp4"))
au2t.inputstyle = "apply"
au2t.description = translate("ffmpeg needs to be installed")
function au2t.write(self, section)
    luci.util.exec("/usr/autodl/tstomp4.sh &")
end


s:tab("audioxmly", translate("Download Audio from https://www.ximalaya.com/"))
au3 = s:taboption("audioxmly", Button, "_audioxmly", translate("One-click download"))
au3.inputstyle = "apply"
au3.description = translate("Audios download")
function au3.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].xmlyurl > /tmp/tmp.XM.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path")
    luci.util.exec("sleep 1")
    luci.util.exec("nohup /usr/autodl/autodlxmly.sh >/dev/null 2>&1 &")
end

au3v = s:taboption("audioxmly", Button, "_audioau3v", translate("One-click download freeVIP"))
au3v.inputstyle = "apply"
au3v.description = translate("node needs to be installed")
function au3v.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].xmlyurl > /tmp/tmp.XM.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path")
    luci.util.exec("sleep 1")
    luci.util.exec("nohup /usr/autodl/autodlxmlyVIP.sh >/dev/null 2>&1 &")
end

au3t = s:taboption("audioxmly", Button, "_autodl3t", translate("One-click m4a to mp3"))
au3t.inputstyle = "apply"
au3t.description = translate("ffmpeg needs to be installed")
function au3t.write(self, section)
    luci.util.exec("nohup /usr/autodl/m4atomp3.sh >/dev/null 2>&1 &")
end

au3play = s:taboption("audioxmly", Button, "_autodl3play", translate("One-click Play mp3(Positive)"))
au3play.inputstyle = "apply"
au3play.description = translate("USB sound card is needed and mpg123 package has been installed")
function au3play.write(self, section)
    luci.util.exec("/usr/autodl/playmp3.sh &")
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
    luci.util.exec("/usr/autodl/playmp3lastest.sh &")
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

s:tab("autodldocin", translate("Download from https://www.docin.com/"))
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

return m

