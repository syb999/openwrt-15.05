m = Map("dawn", translate("Network Overview"),
	translate("What DAWN sees on every radio: the APs taking part in the network and the clients attached to each of them. Signal values are dBm, closer to 0 is better."))

m.pageaction = false

s = m:section(NamedSection, "__networkoverview__")

function s.render(self, sid)
	local tpl = require "luci.template"

	tpl.render_string([[
	<%
	local utl = require "luci.util"
	local status = require "luci.tools.ieee80211"
	local stat = utl.ubus("dawn", "get_network", { }) or { }

	-- libubox renders u8 0/1 as JSON true/false, so accept both shapes
	local function is_local(d)
		local v = d["local"]
		return v == true or tonumber(v) == 1 or v == "true"
	end

	local ssids = { }
	local n_ap, n_client = 0, 0

	for ssid, macs in pairs(stat) do
		ssids[#ssids + 1] = ssid
		for mac, data in pairs(macs) do
			if type(data) == "table" and data.freq ~= nil then
				n_ap = n_ap + 1
				for clientmac, clientvals in pairs(data) do
					if type(clientvals) == "table" then
						n_client = n_client + 1
					end
				end
			end
		end
	end

	table.sort(ssids)

	local function band_name(freq)
		freq = tonumber(freq) or 0
		if freq >= 5925 then return "6 GHz" end
		if freq >= 4900 then return "5 GHz" end
		if freq > 0 then return "2.4 GHz" end
		return "-"
	end

	local function channel(freq)
		local c = status.frequency_to_channel(tonumber(freq) or 0)
		return string.format("%d", c or 0)
	end

	local function signal_html(sig)
		sig = tonumber(sig)
		if sig == nil or sig == 0 then return '<span style="color:#9e9e9e">-</span>' end

		local colour = "#2e7d32"
		if sig <= -75 then colour = "#c62828"
		elseif sig <= -65 then colour = "#ef6c00" end

		return string.format('<strong style="color:%s">%d</strong> <small>dBm</small>', colour, sig)
	end

	local function util_bar(util)
		local pct = (tonumber(util) or 0) / 2.55
		if pct < 0 then pct = 0 end
		if pct > 100 then pct = 100 end

		local colour = "#2e7d32"
		if pct >= 70 then colour = "#c62828"
		elseif pct >= 40 then colour = "#ef6c00" end

		return string.format(
			'<div style="background:#e0e0e0;border-radius:4px;height:9px;width:80px;display:inline-block;vertical-align:middle">' ..
			'<div style="background:%s;height:9px;width:%.0f%%;border-radius:4px"></div></div> <span class="dawn-muted">%.0f%%</span>',
			colour, pct, pct)
	end

	local function badge(text, colour)
		return string.format(
			'<span class="dawn-badge" style="background:%s">%s</span>',
			colour, text)
	end
	%>

	<style type="text/css">
		#cbi-dawn { font-size: 14px; }
		#cbi-dawn table.dawn-tbl { width: 100%; border-collapse: collapse; font-size: 14px; line-height: 1.5; margin: 10px 0 18px; }
		#cbi-dawn table.dawn-tbl th { text-align: left; font-weight: bold; padding: 10px 14px; border-bottom: 2px solid #ddd; white-space: nowrap; }
		#cbi-dawn table.dawn-tbl td { padding: 10px 14px; border-bottom: 1px solid #eee; vertical-align: top; }
		#cbi-dawn table.dawn-tbl tbody tr:hover td { background: #f6f6f6; }
		#cbi-dawn .dawn-mono { font-family: monospace; font-size: 13px; }
		#cbi-dawn .dawn-muted { color: #777; font-size: 12px; }
		#cbi-dawn .dawn-badge { display: inline-block; padding: 1px 7px; border-radius: 3px; color: #fff; font-size: 12px; line-height: 18px; }
		#cbi-dawn .dawn-bar { background: #e0e0e0; border-radius: 4px; height: 10px; width: 90px; display: inline-block; vertical-align: middle; }
		#cbi-dawn .dawn-bar > div { height: 10px; border-radius: 4px; }
	</style>

	<p class="cbi-section-descr">
		<%:SSIDs:%> <strong><%= #ssids %></strong>
		&nbsp;&middot;&nbsp;<%:APs:%> <strong><%= n_ap %></strong>
		&nbsp;&middot;&nbsp;<%:clients:%> <strong><%= n_client %></strong>
	</p>

	<%
	if #ssids == 0 then
	%>
	<p class="cbi-section-descr" style="color:#c62828">
		<%:DAWN has not learned any AP yet. If this stays empty, dawn is not receiving hostapd data or the APs cannot reach each other.%>
	</p>
	<%
	else
		for _, ssid in ipairs(ssids) do
			local macs = stat[ssid]
			local aps = { }
			for mac, data in pairs(macs) do
				if type(data) == "table" and data.freq ~= nil then
					aps[#aps + 1] = { mac = mac, data = data }
				end
			end
			table.sort(aps, function(a, b)
				return (tonumber(a.data.freq) or 0) < (tonumber(b.data.freq) or 0)
			end)
	%>
	<div class="cbi-section">
		<h3><%:SSID%>: <%= ssid %></h3>
		<table class="dawn-tbl">
			<thead>
				<tr>
					<th><%:AP%></th>
					<th><%:Client%></th>
					<th><%:Band / channel%></th>
					<th><%:Signal%></th>
					<th><%:Capabilities%></th>
				</tr>
			</thead>
			<tbody>
			<%
			for _, ap in ipairs(aps) do
				local d = ap.data
				local local_ap = is_local(d)
				local first = true

				local clients = { }
				for clientmac, clientvals in pairs(d) do
					if type(clientvals) == "table" then
						clients[#clients + 1] = { mac = clientmac, vals = clientvals }
					end
				end
				table.sort(clients, function(a, b) return a.mac < b.mac end)

				local ap_cell = string.format(
					'<div><strong>%s</strong> %s</div>' ..
					'<div class="dawn-mono dawn-muted">%s</div>' ..
					'<div class="dawn-muted">%s &middot; %s</div>',
					(d.hostname ~= nil and d.hostname ~= "") and d.hostname or "-",
					local_ap and badge(translate("local"), "#1565c0") or "",
					ap.mac,
					(d.iface ~= nil and d.iface ~= "") and d.iface or "-",
					util_bar(d.channel_utilization))

				if #clients == 0 then
			%>
				<tr>
					<td><%= ap_cell %></td>
					<td colspan="4" style="color:#9e9e9e"><%:no clients%></td>
				</tr>
			<%
				else
					for _, c in ipairs(clients) do
						local v = c.vals
						local caps = { }
						if tonumber(v.ht) == 1 then caps[#caps + 1] = "HT" end
						if tonumber(v.vht) == 1 then caps[#caps + 1] = "VHT" end
			%>
				<tr>
					<td><%= first and ap_cell or "" %></td>
					<td class="dawn-mono"><%= c.mac %></td>
					<td><%= band_name(d.freq) %> / <%= channel(d.freq) %></td>
					<td><%= signal_html(v.signal) %></td>
					<td><%= (#caps > 0) and table.concat(caps, " / ") or "-" %></td>
				</tr>
			<%
						first = false
					end
				end
			end
			%>
			</tbody>
		</table>
	</div>
	<%
		end
	end
	%>
	]])
end

return m
