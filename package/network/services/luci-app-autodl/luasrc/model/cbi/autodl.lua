m = Map("autodl", translate("Autodl"))

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download m3u8 videos."))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting"))

url=s:taboption("basic", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.description = translate("URL for downloading videos")

path=s:taboption("basic", Value, "path", translate("Download Videos directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("Please enter a valid directory")

num=s:taboption("basic", Value, "num", translate("Number of Videos"))
num.datatype = "string"
num.default = "1"
num.rmempty = false
num.description = translate("Please enter a valid number")

xmlyurl=s:taboption("basic", Value, "xmlyurl", translate("Audios URL"))
xmlyurl.rmempty = true
xmlyurl.datatype = "string"
xmlyurl.description = translate("URL for downloading https://www.ximalaya.com Audios")

xmlyname=s:taboption("basic", Value, "xmlyname", translate("Audios Name"))
xmlyname.rmempty = true
xmlyname.datatype = "string"
xmlyname.description = translate("Audios from https://www.ximalaya.com")

xmlynum=s:taboption("basic", Value, "xmlynum", translate("Please enter a lastest number"))
xmlynum.datatype = "string"
xmlynum.default = "383"
xmlynum.rmempty = false
xmlynum.description = translate("Usually one URL contains 30 resources")


xmlypath=s:taboption("basic", Value, "xmlypath", translate("Download Audios directory"))
xmlypath.datatype = "string"
xmlypath.default = "/mnt/sda3/audios"
xmlypath.rmempty = false
xmlypath.description = translate("Please enter a valid directory")

url1=s:taboption("basic", Button, "url1", translate("Sync download address (save & app after sync)"))
url1.inputstyle = "apply"


s:tab("autodl1", translate("Download form https://www.dy10000.com"))
au1 = s:taboption("autodl1", Button, "_autodl1", translate("One-click download"))
au1.inputstyle = "apply"
function au1.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl1.sh &")
end

au1t = s:taboption("autodl1", Button, "_autodl1t", translate("One-click ts to mp4"))
au1t.inputstyle = "apply"
au1t.description = translate("ffmpeg needs to be installed.")
function au1t.write(self, section)
    luci.util.exec("/usr/autodl/tstomp4.sh &")
end

s:tab("autodl2", translate("Download form https://www.xgys.net"))
au2 = s:taboption("autodl2", Button, "_autodl2", translate("One-click download"))
au2.inputstyle = "apply"
function au2.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url.bk")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].num > /tmp/autodl.num")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodl2.sh &")
end

au2t = s:taboption("autodl2", Button, "_autodl2t", translate("One-click ts to mp4"))
au2t.inputstyle = "apply"
au2t.description = translate("ffmpeg needs to be installed.")
function au2t.write(self, section)
    luci.util.exec("/usr/autodl/tstomp4.sh &")
end


s:tab("audioxmly", translate("Download Audio form https://www.ximalaya.com/"))
au3 = s:taboption("audioxmly", Button, "_audioxmly", translate("One-click download"))
au3.inputstyle = "apply"
function au3.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].xmlyurl > /tmp/tmp.XM.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlyname > /tmp/tmp.XM.name")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlynum > /tmp/tmp.XM.num")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].xmlypath > /tmp/tmp.XM.path")
    luci.util.exec("sleep 1")
    luci.util.exec("/usr/autodl/autodlxmly.sh &")
end

return m

