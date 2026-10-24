m = Map("dawn", translate("Client Scores"),
	translate("How DAWN scores each client against every AP that can hear it. One row per AP; the client address on the left spans all APs that heard it. The best AP per SSID is marked."))

m.pageaction = false

s = m:section(NamedSection, "__hearingmap__")

function s.render(self, sid)
	local tpl = require "luci.template"

	tpl.render_string([[
	<%
	local utl = require "luci.util"
	local status = require "luci.tools.ieee80211"
	local stat = utl.ubus("dawn", "get_hearing_map", { }) or { }

	local function band_name(freq)
		freq = tonumber(freq) or 0
		if freq >= 5925 then return "6G" end
		if freq >= 4900 then return "5G" end
		if freq > 0 then return "2.4G" end
		return "-"
	end

	local function channel(freq)
		local c = status.frequency_to_channel(tonumber(freq) or 0)
		return tostring(c or 0)
	end

	local function signal_html(sig)
		sig = tonumber(sig)
		if sig == nil or sig == 0 then return '<span class="mut">-</span>' end

		local colour = "#2e7d32"
		if sig <= -75 then colour = "#c62828"
		elseif sig <= -65 then colour = "#ef6c00" end

		return string.format('<b style="color:%s">%d</b>', colour, sig)
	end

	local function score_html(score, best)
		score = tonumber(score) or 0
		local colour = "#666"
		if score >= 100 then colour = "#2e7d32"
		elseif score >= 80 then colour = "#ef6c00"
		elseif score < 40 then colour = "#c62828" end

		local out = string.format('<b style="color:%s">%d</b>', colour, score)
		if best then
			out = out .. ' <span style="color:#1565c0;font-size:12px">*</span>'
		end
		return out
	end

	local function util_html(util)
		local pct = (tonumber(util) or 0) / 2.55
		if pct < 0 then pct = 0 elseif pct > 100 then pct = 100 end

		local colour = "#2e7d32"
		if pct >= 70 then colour = "#c62828"
		elseif pct >= 40 then colour = "#ef6c00" end

		return string.format('<span style="color:%s">%.0f%%</span>', colour, pct)
	end

	-- one block per client, one row per (ssid, ap) it was heard by
	local clients, order, nssid_seen, nssid = { }, { }, { }, 0

	for ssid, clientmap in pairs(stat) do
		if not nssid_seen[ssid] then
			nssid_seen[ssid] = true
			nssid = nssid + 1
		end

		for clientmac, aps in pairs(clientmap) do
			if type(aps) == "table" then
				local c = clients[clientmac]
				if not c then
					c = { mac = clientmac, rows = { }, seen = { } }
					clients[clientmac] = c
				end

				for apmac, v in pairs(aps) do
					local key = ssid .. "|" .. apmac
					if type(v) == "table" and tonumber(v.freq) ~= 0 and not c.seen[key] then
						c.seen[key] = true
						c.rows[#c.rows + 1] = { ssid = ssid, ap = apmac, v = v }
					end
				end
			end
		end
	end

	for mac, c in pairs(clients) do
		if #c.rows > 0 then
			order[#order + 1] = mac
		end
	end
	table.sort(order)

	for _, mac in ipairs(order) do
		local c = clients[mac]
		table.sort(c.rows, function(a, b)
			if a.ssid == b.ssid then
				return (tonumber(a.v.score) or 0) > (tonumber(b.v.score) or 0)
			end
			return a.ssid < b.ssid
		end)

		local last_ssid = nil
		for _, r in ipairs(c.rows) do
			if r.ssid ~= last_ssid then
				last_ssid, r.best = r.ssid, true
			else
				r.best = false
			end
		end
	end
	%>

	<style type="text/css">
	.dawn-hear { width:100%; border-collapse:collapse; font-size:14px; table-layout:auto; }
	.dawn-hear th { text-align:left; padding:9px 10px; border-bottom:2px solid #cfd8dc;
	                white-space:nowrap; font-weight:600; }
	.dawn-hear td { padding:9px 10px; border-top:1px solid #e3e7ea; vertical-align:middle; }
	.dawn-hear tr:hover td { background:#f5f9fc; }
	.dawn-hear td.cli { font-family:monospace; font-size:13px; white-space:nowrap;
	                    background:#eef3f8; border-right:1px solid #cfd8dc; vertical-align:top;
	                    font-weight:600; }
	.dawn-hear td.mac { font-family:monospace; font-size:13px; white-space:nowrap; }
	.dawn-hear td.num { text-align:right; white-space:nowrap; }
	.dawn-hear .mut { color:#999; }
	</style>

	<p class="cbi-section-descr">
		<%:SSIDs:%> <strong><%= nssid %></strong>
		&nbsp;&middot;&nbsp;<%:clients:%> <strong><%= #order %></strong>
		&nbsp;&middot;&nbsp;<span class="mut"><%:best AP per SSID is marked with *%></span>
	</p>

	<%
	if #order == 0 then
	%>
	<p class="cbi-section-descr" style="color:#c62828">
		<%:No scoring data yet. DAWN first has to hear a client on at least one AP.%>
	</p>
	<%
	else
	%>
	<table class="dawn-hear">
		<thead>
			<tr>
				<th><%:Client%></th>
				<th><%:SSID%></th>
				<th><%:AP%></th>
				<th><%:Band / channel%></th>
				<th><%:Signal%></th>
				<th><%:RCPI / RSNI%></th>
				<th><%:Clients / utilization%></th>
				<th><%:Score%></th>
			</tr>
		</thead>
		<tbody>
		<%
			for _, mac in ipairs(order) do
				local c = clients[mac]
				local n = #c.rows

				for idx, r in ipairs(c.rows) do
					local v = r.v
		%>
			<tr>
			<%
					if idx == 1 then
			%>
				<td class="cli" rowspan="<%= n %>"><%= mac %></td>
			<%
					end
			%>
				<td><%= r.ssid %></td>
				<td class="mac"><%= r.ap %></td>
				<td><%= band_name(v.freq) %> / <%= channel(v.freq) %></td>
				<td class="num"><%= signal_html(v.signal) %></td>
				<td class="num"><%= (tonumber(v.rcpi) and tonumber(v.rcpi) >= 0) and tonumber(v.rcpi) or "-" %> / <%= (tonumber(v.rsni) and tonumber(v.rsni) >= 0) and tonumber(v.rsni) or "-" %></td>
				<td class="num"><%= tonumber(v.num_sta) or 0 %> / <%= util_html(v.channel_utilization) %></td>
				<td class="num"><%= score_html(v.score, r.best) %></td>
			</tr>
		<%
				end
			end
		%>
		</tbody>
	</table>
	<%
	end
	%>
	]])
end

return m
