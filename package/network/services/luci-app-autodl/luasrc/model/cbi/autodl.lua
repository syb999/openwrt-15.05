m = Map("autodl", translate("Autodl"))

s = m:section(TypedSection, "autodl", "", translate("Assistant for automatic download m3u8 videos."))
s.anonymous = true
s.addremove = false

s:tab("basic", translate("Basic Setting"))

url=s:taboption("basic", Value, "url", translate("Video URL"))
url.rmempty = true
url.datatype = "string"
url.description = translate("URL for downloading videos")

path=s:taboption("basic", Value, "path", translate("Download directory"))
path.datatype = "string"
path.default = "/mnt/sda3/videos"
path.rmempty = false
path.description = translate("Please enter a valid directory")

url1=s:taboption("basic", Button, "url1", translate("Sync download address (save & app after sync)"))
url1.inputstyle = "apply"


s:tab("autodl1", translate("Download form https://www.dy10000.com"))
au1 = s:taboption("autodl1", Button, "_autodl1", translate("One-click download"))
au1.inputstyle = "apply"
function au1.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 2")
    luci.util.exec("/usr/autodl/autodl1.sh &")
end

s:tab("autodl2", translate("Download form https://www.xgys.net"))
au2 = s:taboption("autodl2", Button, "_autodl2", translate("One-click download"))
au2.inputstyle = "apply"
function au2.write(self, section)
    luci.util.exec("uci get autodl.@autodl[0].url > /tmp/autodl.url")
    luci.util.exec("sleep 1")
    luci.util.exec("uci get autodl.@autodl[0].path > /tmp/autodl.path")
    luci.util.exec("sleep 2")
    luci.util.exec("/usr/autodl/autodl2.sh &")
end

return m

