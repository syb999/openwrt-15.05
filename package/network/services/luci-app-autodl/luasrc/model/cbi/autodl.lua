m = Map("autodl", translate("Autodl"))

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download m3u8 videos."))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting"))

url=s:taboption("basic", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.description = translate("下载视频的网页地址")

path=s:taboption("basic", Value, "path", translate("Directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("保存视频的地址")

url1=s:taboption("basic", Button, "url1", translate("同步下载地址(同步后先保存&应用)"))
url1.inputstyle = "apply"


s:tab("autodl1", translate("Download form https://www.dy10000.com"))
au = s:taboption("autodl1", Button, "_autodl1", translate("download"))
au.inputstyle = "apply"
function au.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 2")
    luci.util.exec("/usr/autodl/autodl1.sh &")
end

s:tab("autodl2", translate("Download form https://www.xgys.net"))
au = s:taboption("autodl2", Button, "_autodl2", translate("download"))
au.inputstyle = "apply"
function au.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 2")
    luci.util.exec("/usr/autodl/autodl2.sh &")
end

return m

