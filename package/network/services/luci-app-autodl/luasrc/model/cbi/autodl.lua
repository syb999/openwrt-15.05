m = Map("autodl", translate("Autodl"))

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download m3u8 videos form https://www.dy10000.com."))
s.anonymous = true
s.addremove = false

s:tab("autodl", translate("Basic"))

url=s:taboption("autodl", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.description = translate("下载视频的网页地址")

path=s:taboption("autodl", Value, "path", translate("Directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("保存视频的地址")

url1=s:taboption("autodl", Button, "url1", translate("同步下载地址(同步后先保存&应用)"))
url1.inputstyle = "apply"


au = s:taboption("autodl", Button, "_autodl", translate("download"))
au.inputstyle = "apply"
function au.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 2")
    luci.util.exec("/usr/autodl/autodl.sh &")
end

return m

