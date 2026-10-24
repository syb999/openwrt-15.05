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

m = Map("ndpi", translate("Presets"),
	translate("A preset bundles domains and/or nDPI protocols. Rules point at a preset, so one preset change updates every rule using it. Domains are matched as substrings: write bilivideo.com, no scheme and no wildcards"))

p = m:section(TypedSection, "group", translate("Presets"))
p.anonymous = false
p.addremove = true
p.template = "cbi/tblsection"

pd = p:option(DynamicList, "domain", translate("Domain"))
pd.placeholder = translate("e.g. bilivideo.com")

pp = p:option(DynamicList, "proto", translate("Protocol"))
pp.placeholder = translate("e.g. SIP")
local pl = protos()
local i
for i = 1, #pl do
	pp:value(pl[i])
end

function m.on_commit(map)
	luci.sys.call("/etc/init.d/ndpi reload >/dev/null 2>&1")
end

return m
