m = Map("dawn", translate("Peer APs"),
	translate("Every AP that this DAWN instance currently knows about, including the ones running on other nodes. If only the local APs show up here, the inter-AP transport or the shared key is wrong."))

m.pageaction = false

s = m:section(NamedSection, "__peeraps__")

function s.render(self, sid)
	local tpl = require "luci.template"

	tpl.render_string([[
	<%
	local utl = require "luci.util"
	local stat = utl.ubus("dawn", "get_network", { }) or { }

	local aps = { }
	local nlocal, nremote = 0, 0

	-- libubox renders u8 0/1 as JSON true/false, so accept both shapes
	local function is_local(d)
		local v = d["local"]
		return v == true or tonumber(v) == 1 or v == "true"
	end

	for ssid, macs in pairs(stat) do
		for mac, data in pairs(macs) do
			if type(data) == "table" and data.freq ~= nil then
				aps[#aps + 1] = { ssid = ssid, mac = mac, data = data }
				if is_local(data) then
					nlocal = nlocal + 1
				else
					nremote = nremote + 1
				end
			end
		end
	end

	table.sort(aps, function(a, b)
		if a.ssid == b.ssid then
			return (tonumber(a.data.freq) or 0) < (tonumber(b.data.freq) or 0)
		end
		return a.ssid < b.ssid
	end)

	local function band_name(freq)
		freq = tonumber(freq) or 0
		if freq >= 5925 then return "6 GHz" end
		if freq >= 4900 then return "5 GHz" end
		if freq > 0 then return "2.4 GHz" end
		return "-"
	end

	local function util_bar(util)
		local pct = (tonumber(util) or 0) / 2.55
		if pct < 0 then pct = 0 end
		if pct > 100 then pct = 100 end

		local colour = "#2e7d32"
		if pct >= 70 then colour = "#c62828"
		elseif pct >= 40 then colour = "#ef6c00" end

		return string.format(
			'<div style="background:#e0e0e0;border-radius:4px;height:9px;width:90px;display:inline-block;vertical-align:middle">' ..
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
		<%:APs known to DAWN:%>
		<strong><%= nlocal + nremote %></strong>
		&nbsp;&middot;&nbsp;<%:local:%> <strong><%= nlocal %></strong>
		&nbsp;&middot;&nbsp;<%:remote:%> <strong><%= nremote %></strong>
	</p>

	<table class="dawn-tbl">
		<thead>
			<tr>
				<th><%:SSID%></th>
				<th><%:Node%></th>
				<th><%:Interface%></th>
				<th><%:BSSID%></th>
				<th><%:Band%></th>
				<th><%:Channel%></th>
				<th><%:Clients%></th>
				<th><%:Channel utilization%></th>
				<th><%:Capabilities%></th>
				<th><%:Neighbor report%></th>
			</tr>
		</thead>
		<tbody>
		<%
		if #aps == 0 then
		%>
			<tr>
				<td colspan="10" style="color:#c62828">
					<%:No APs known yet. Check that dawn is running and that the inter-AP transport settings match on every AP.%>
				</td>
			</tr>
		<%
		else
			for _, ap in ipairs(aps) do
				local d = ap.data
				local local_ap = is_local(d)
				local caps = { }
				if tonumber(d.ht_support) == 1 then caps[#caps + 1] = "HT" end
				if tonumber(d.vht_support) == 1 then caps[#caps + 1] = "VHT" end
				local nr = tostring(d.neighbor_report or "")
		%>
			<tr>
				<td><%= ap.ssid %></td>
				<td>
					<%= (d.hostname ~= nil and d.hostname ~= "") and d.hostname or "-" %>
					<% if local_ap then %><%= badge(translate("local"), "#1565c0") %><% end %>
				</td>
				<td><%= (d.iface ~= nil and d.iface ~= "") and d.iface or "-" %></td>
				<td class="dawn-mono"><%= ap.mac %></td>
				<td><%= band_name(d.freq) %></td>
				<td><%= tonumber(d.channel) or 0 %></td>
				<td><%= tonumber(d.num_sta) or 0 %></td>
				<td><%= util_bar(d.channel_utilization) %></td>
				<td><%= (#caps > 0) and table.concat(caps, " / ") or "-" %></td>
				<td>
					<% if #nr > 0 then %>
						<%= badge(string.format("%d B", #nr), "#2e7d32") %>
					<% else %>
						<%= badge(translate("none"), "#9e9e9e") %>
					<% end %>
				</td>
			</tr>
		<%
			end
		end
		%>
		</tbody>
	</table>
	]])
end

return m
