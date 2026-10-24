module("luci.controller.ndpi", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ndpi") then
		return
	end

	local page = entry({"admin", "network", "ndpi"}, firstchild(), "nDPI", 65)
	page.dependent = false

	entry({"admin", "network", "ndpi", "status"}, template("ndpi/status"), _("Identification"), 10)
	entry({"admin", "network", "ndpi", "rules"}, cbi("ndpi/rules"), _("Rules"), 20)
	entry({"admin", "network", "ndpi", "presets"}, cbi("ndpi/presets"), _("Presets"), 30)
	entry({"admin", "network", "ndpi", "settings"}, cbi("ndpi/settings"), _("Settings"), 40)
	entry({"admin", "network", "ndpi", "groups"}, call("action_groups")).leaf = true
	entry({"admin", "network", "ndpi", "flows"}, call("action_flows")).leaf = true
	entry({"admin", "network", "ndpi", "protos"}, call("action_protos")).leaf = true
end

local function read_protos()
	local list = {}
	local f = io.open("/proc/net/xt_ndpi/proto", "r")
	if not f then
		return list
	end

	local idx, mark, name
	for line in f:lines() do
		if line:sub(1, 1) ~= "#" then
			idx, mark, name = line:match("^(%x+)%s+(%S+)%s+(%S+)")
			if name and name:sub(1, 9) ~= "badproto_" and mark:sub(1, 7) ~= "disable" then
				list[#list + 1] = name
			end
		end
	end
	f:close()
	table.sort(list)
	return list
end

function action_protos()
	local list = read_protos()
	local out = {}
	local i

	for i = 1, #list do
		out[#out + 1] = { proto = list[i] }
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({ protos = out })
end

-- rules + hit counters. iptables-save -c is the only reliable way to get counters
-- (iptables -S never prints them); packets counted before fast-classifier offloads
function action_groups()
	local uci = require "luci.model.uci".cursor()
	local dom2group = {}
	local proto2group = {}
	local rows = {}

	uci:foreach("ndpi", "group", function(g)
		local n = g[".name"]
		local d = g.domain
		local p = g.proto

		if type(d) == "table" then
			local _, v
			for _, v in ipairs(d) do
				dom2group[string.lower(v)] = n
			end
		elseif type(d) == "string" and #d > 0 then
			dom2group[string.lower(d)] = n
		end

		if type(p) == "table" then
			local _, v
			for _, v in ipairs(p) do
				proto2group[string.lower(v)] = n
			end
		elseif type(p) == "string" and #p > 0 then
			proto2group[string.lower(p)] = n
		end
	end)

	local txt = luci.sys.exec("/usr/sbin/iptables-save -c -t mangle 2>/dev/null") or ""

	for line in txt:gmatch("[^\n]+") do
		local pk, by, chain, rest = line:match("^%[(%d+):(%d+)%] %-A (NDPI_%u+) (.*)$")

		if chain then
			local host = rest:match("%-%-host (%S+)")
			local proto = rest:match("%-%-proto (%S+)")
			local what, grp = nil, ""

			if host then
				what = host
				grp = dom2group[host:lower()] or ""
			elseif proto then
				what = "proto:" .. proto
				grp = proto2group[proto:lower()] or ""
			elseif rest:find("%-%-all") then
				what = "proto:all"
			end

			if what then
				rows[#rows + 1] = {
					match  = what,
					group  = grp,
					chain  = chain,
					action = rest:match("%-j DROP") and "drop" or "mark",
					pkts   = tonumber(pk) or 0,
					bytes  = tonumber(by) or 0
				}
			end
		end
	end

	table.sort(rows, function(a, b) return a.pkts > b.pkts end)

	local diag = {
		module = nixio.fs.access("/sys/module/xt_ndpi") and 1 or 0,
		proc   = nixio.fs.access("/proc/net/xt_ndpi") and 1 or 0,
		save   = nixio.fs.access("/usr/sbin/iptables-save") and 1 or 0,
		rules  = #rows,
		log    = luci.sys.exec("logread 2>/dev/null | grep -i ndpi | tail -n 8") or ""
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json({ rows = rows, diag = diag })
end

function action_flows()
	local acc = {}
	local total = 0
	local f = io.open("/proc/net/xt_ndpi/flows", "r")

	if f then
		for line in f:lines() do
			local ts1, ts2, fam, l4, sip, sport, dip, dport, up, down, pk_s, pk_d =
				line:match("^(%d+) (%d+) ([46]) (%d+) (%S+) (%d+) (%S+) (%d+) (%d+) (%d+) (%d+) (%d+)")

			if ts1 then
				local proto = line:match(" P=([%w%._%-]+)") or "UNKNOWN"
				local a = acc[proto]

				if not a then
					a = { flows = 0, up = 0, down = 0, pk = 0 }
					acc[proto] = a
				end

				a.flows = a.flows + 1
				a.up    = a.up + tonumber(up)
				a.down  = a.down + tonumber(down)
				a.pk    = a.pk + tonumber(pk_s) + tonumber(pk_d)
				total   = total + 1
			end
		end
		f:close()
	end

	local out = {}
	for proto, a in pairs(acc) do
		out[#out + 1] = {
			proto = proto,
			flows = a.flows,
			up    = a.up,
			down  = a.down,
			pk    = a.pk
		}
	end

	table.sort(out, function(x, y) return (x.up + x.down) > (y.up + y.down) end)

	local flow_param = "?"
	local p = io.open("/sys/module/xt_ndpi/parameters/ndpi_enable_flow", "r")
	if p then
		flow_param = p:read("*l") or "?"
		p:close()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({ total = total, flow_enable = flow_param, flows = out })
end
