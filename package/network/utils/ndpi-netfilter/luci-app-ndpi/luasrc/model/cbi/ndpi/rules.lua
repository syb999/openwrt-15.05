local fs = require "nixio.fs"

local function protos()
	local list = {}
	local f = io.open("/proc/net/xt_ndpi/proto", "r")

	if f then
		for line in f:lines() do
			if line:sub(1, 1) ~= "#" then
				local idx, mark, name = line:match("^(%x+)%s+(%S+)%s+(%S+)")
				if name and name:sub(1, 9) ~= "badproto_" and mark:sub(1, 7) ~= "disable" then
					list[#list + 1] = name
				end
			end
		end
		f:close()
	end

	return list
end

m = Map("ndpi", translate("Rules"),
	translate("A preset rule expands into one iptables rule per domain or protocol. --host is a substring match, so bilivideo.com also matches upos-sz-mirrorcos.bilivideo.com"))

r = m:section(TypedSection, "rule", translate("Rules"))
r.anonymous = true
r.addremove = true
r.template = "cbi/tblsection"

ren = r:option(Flag, "enabled", translate("Enable"))
ren.default = "1"
ren.rmempty = false

rm = r:option(ListValue, "match", translate("Match type"))
rm:value("group", translate("Preset"))
rm:value("proto", translate("Application"))
rm:value("host", translate("Custom domain"))
rm.default = "group"
rm.rmempty = false

rg = r:option(ListValue, "group", translate("Preset"))
local seen = {}
local function addpreset(x)
	local n = x[".name"]
	if n and not seen[n] then
		seen[n] = true
		rg:value(n, translate(x.title or n))
	end
end
m.uci:foreach("ndpi", "group", addpreset)
m.uci:foreach("ndpi", "site", addpreset)
rg:depends("match", "group")

rp = r:option(DynamicList, "proto", translate("Application"))
rp.cast = "string"
rp.placeholder = translate("e.g. BitTorrent")
local pl = protos()
local i
for i = 1, #pl do
	rp:value(pl[i])
end
rp:depends("match", "proto")

rh = r:option(DynamicList, "host", translate("Domain"))
rh.placeholder = translate("e.g. bilivideo.com")
rh:depends("match", "host")

rc = r:option(ListValue, "chain", translate("Hook"))
rc:value("prerouting", translate("PREROUTING (forwarded traffic)"))
rc:value("output", translate("OUTPUT (local traffic)"))
rc:value("postrouting", translate("POSTROUTING"))
rc.default = "prerouting"

ra = r:option(ListValue, "action", translate("Action"))
ra:value("mark", translate("Set mark"))
ra:value("drop", translate("Drop"))
ra.default = "mark"

rv = r:option(Value, "value", translate("Mark value"))
rv.default = "0x10"
rv:depends("action", "mark")

function m.on_commit(map)
	luci.sys.call("/etc/init.d/ndpi reload >/dev/null 2>&1")
end

return m
