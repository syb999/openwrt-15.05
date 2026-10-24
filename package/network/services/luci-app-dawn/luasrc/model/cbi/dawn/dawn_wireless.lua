m = Map("dawn", translate("Wireless Baseline"),
	translate("Sets the same SSID, encryption and key on every AP interface and enables 802.11k/802.11v there, so a node that was configured by hand cannot break roaming for the whole network. Existing values are shown first; only AP interfaces are touched."))

m.pageaction = false

s = m:section(NamedSection, "__wireless_baseline__")

function s.render(self, sid)
	local tpl  = require "luci.template"
	local http = require "luci.http"
	local uci  = require "luci.model.uci".cursor()
	local util = require "luci.util"

	local function load_ifaces()
		local list = { }
		uci:foreach("wireless", "wifi-iface", function(sec)
			if sec.mode == "ap" then
				list[#list + 1] = sec
			end
		end)
		return list
	end

	local ifaces = load_ifaces()

	local notice, notice_kind = nil, ""

	local cur_ssid = ifaces[1] and ifaces[1].ssid or ""
	local cur_enc  = ifaces[1] and ifaces[1].encryption or "psk2"
	local cur_k    = ifaces[1] and (ifaces[1].ieee80211k == "1")
	local cur_v    = ifaces[1] and (ifaces[1].ieee80211v == "1")

	if http.formvalue("b_apply") then
		local ssid = http.formvalue("b_ssid") or ""
		local enc  = http.formvalue("b_enc") or "psk2"
		local key  = http.formvalue("b_key") or ""
		local k    = http.formvalue("b_k") and "1" or "0"
		local v    = http.formvalue("b_v") and "1" or "0"

		if #ifaces == 0 then
			notice, notice_kind = translate("No AP interface found in /etc/config/wireless - nothing was changed."), "err"
		elseif ssid == "" or #ssid > 32 then
			notice, notice_kind = translate("The SSID must not be empty and at most 32 bytes long."), "err"
		elseif key ~= "" and (#key < 8 or #key > 63) then
			notice, notice_kind = translate("A WPA2 key must be between 8 and 63 characters long."), "err"
		else
			local names = { }
			for _, sec in ipairs(ifaces) do
				names[#names + 1] = sec[".name"]
			end

			for _, name in ipairs(names) do
				uci:set("wireless", name, "ssid", ssid)
				uci:set("wireless", name, "encryption", enc)
				if key ~= "" then
					uci:set("wireless", name, "key", key)
				end
				uci:set("wireless", name, "ieee80211k", k)
				uci:set("wireless", name, "ieee80211v", v)
				uci:set("wireless", name, "bss_transition", v)
			end

			uci:commit("wireless")

			local msg = string.format(translate("Updated %d AP interface(s) in /etc/config/wireless."), #names)

			if http.formvalue("b_reload") then
				require("luci.sys").call("/sbin/wifi reload >/dev/null 2>&1 &")
				msg = msg .. " " .. translate("Wireless is reloading now, clients will disconnect briefly.")
			else
				msg = msg .. " " .. translate("Run 'wifi reload' (or reboot) for it to take effect.")
			end

			notice, notice_kind = msg, "ok"
			cur_ssid, cur_enc, cur_k, cur_v = ssid, enc, (k == "1"), (v == "1")

			-- re-read so the table below shows the values that were just committed
			uci = require("luci.model.uci").cursor()
			ifaces = load_ifaces()
		end
	end

	local function esc(v)
		return util.pcdata(tostring(v or ""))
	end

	local function badge(text, colour)
		return string.format(
			'<span class="dawn-badge" style="background:%s">%s</span>',
			colour, text)
	end

	-- Map radioX -> band, and collect the SSIDs that *peer* APs use per band.
	-- Comparing every interface against one SSID is wrong on networks that use
	-- a separate SSID per band, so the state column compares this AP's SSID in
	-- a band with the SSIDs the peer APs announce in the same band.
	iface_band = { }
	do
		local uci2 = require("luci.model.uci").cursor()
		uci2:foreach("wireless", "wifi-device", function(d)
			local hm = tostring(d.hwmode or "")
			iface_band[d[".name"]] = (hm:find("11a") or hm:find("ac")) and "5" or "2"
		end)
	end

	peer_ssids = { ["2"] = { }, ["5"] = { } }
	do
		local net = util.ubus("dawn", "get_network", { }) or { }
		for pssid, aps in pairs(net) do
			if type(aps) == "table" then
				for _, v in pairs(aps) do
					if type(v) == "table" and tonumber(v.freq) then
						local b = (tonumber(v.freq) >= 4900) and "5" or "2"
						if v["local"] ~= true then
							peer_ssids[b][pssid] = (peer_ssids[b][pssid] or 0) + 1
						end
					end
				end
			end
		end
	end

	function state_of(sec)
		if sec.disabled == "1" then
			return translate("disabled"), "#9e9e9e", ""
		end
		if sec.ssid == nil or sec.ssid == "" then
			return translate("no SSID"), "#c62828", ""
		end
		if sec.ieee80211k ~= "1" or sec.ieee80211v ~= "1" then
			return translate("11k/v off"), "#ef6c00", translate("Turn both on so clients and DAWN have neighbour data.")
		end
		if sec.key == nil or sec.key == "" then
			return translate("no key"), "#c62828", ""
		end

		local band = iface_band[sec.device] or "2"
		local peers = peer_ssids[band]
		local other, total = { }, 0

		for pssid, cnt in pairs(peers) do
			total = total + cnt
			if pssid ~= sec.ssid then
				other[#other + 1] = pssid
			end
		end

		if total == 0 then
			return translate("no peer AP seen"), "#9e9e9e",
				translate("DAWN has not discovered any other AP in this band yet.")
		end

		if #other > 0 then
			return translate("differs from peers"), "#c62828", table.concat(other, ", ")
		end

		return translate("consistent with peers"), "#2e7d32", ""
	end

	local notice_html = ""
	if notice then
		local colour = (notice_kind == "err") and "#c62828" or "#2e7d32"
		notice_html = string.format('<p class="cbi-section-descr" style="color:%s"><strong>%s</strong></p>',
			colour, esc(notice))
	end

	-- The template runs in its own environment, so hand the values over explicitly.
	tpl.render_string([[
	<%= notice_html %>

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

	<table class="dawn-tbl">
		<thead>
			<tr>
				<th><%:Radio%></th>
				<th><%:Section%></th>
				<th><%:SSID%></th>
				<th><%:Encryption%></th>
				<th><%:Key set%></th>
				<th><%:802.11k%></th>
				<th><%:802.11v%></th>
				<th><%:State%></th>
			</tr>
		</thead>
		<tbody>
		<%
		if #ifaces == 0 then
		%>

			<tr>
				<td colspan="8" style="color:#c62828">
					<%:No AP interface found in /etc/config/wireless.%>
				</td>
			</tr>
		<%
		else
			for _, sec in ipairs(ifaces) do
		%>
			<tr>
				<td><%= esc(sec.device or "-") %></td>
				<td class="dawn-mono"><%= esc(sec[".name"]) %></td>
				<td><%= esc(sec.ssid or "-") %></td>
				<td><%= esc(sec.encryption or "-") %></td>
				<td><%= (sec.key ~= nil and sec.key ~= "") and translate("yes") or translate("no") %></td>
				<td><%= (sec.ieee80211k == "1") and translate("on") or translate("off") %></td>
				<td><%= (sec.ieee80211v == "1") and translate("on") or translate("off") %></td>
				<td>
					<%
						local st, col, det = state_of(sec)
					%>
					<%= badge(st, col) %>
					<% if det ~= "" then %>
						<br /><span class="dawn-muted"><%= esc(det) %></span>
					<% end %>
				</td>
			</tr>
		<%
			end
		end
		%>
		</tbody>
	</table>

	<div class="cbi-section">
		<h3><%:Apply to all AP interfaces%></h3>

		<div class="cbi-value">
			<label class="cbi-value-title" for="b_ssid"><%:SSID%></label>
			<div class="cbi-value-field">
				<input type="text" id="b_ssid" name="b_ssid" maxlength="32" value="<%= esc(cur_ssid) %>" />
			</div>
		</div>

		<div class="cbi-value">
			<label class="cbi-value-title" for="b_enc"><%:Encryption%></label>
			<div class="cbi-value-field">
				<select id="b_enc" name="b_enc">
					<option value="psk2"<% if cur_enc ~= "psk2+tkip+ccmp" then %> selected="selected"<% end %>>
						<%:WPA2-PSK (AES/CCMP) - recommended%>
					</option>
					<option value="psk2+tkip+ccmp"<% if cur_enc == "psk2+tkip+ccmp" then %> selected="selected"<% end %>>
						<%:WPA2-PSK (TKIP+CCMP, legacy clients)%>
					</option>
				</select>
			</div>
		</div>

		<div class="cbi-value">
			<label class="cbi-value-title" for="b_key"><%:Wireless key%></label>
			<div class="cbi-value-field">
				<input type="password" id="b_key" name="b_key" maxlength="63" autocomplete="new-password" />
				<div class="cbi-value-description"><%:8-63 characters. Leave empty to keep the current key.%></div>
			</div>
		</div>

		<div class="cbi-value">
			<label class="cbi-value-title"><%:Roaming helpers%></label>
			<div class="cbi-value-field">
				<label>
					<input type="checkbox" name="b_k" value="1"<% if cur_k then %> checked="checked"<% end %> />
					<%:Enable 802.11k on every AP interface%>
				</label>
				<br />
				<label>
					<input type="checkbox" name="b_v" value="1"<% if cur_v then %> checked="checked"<% end %> />
					<%:Enable 802.11v (BSS transition) on every AP interface%>
				</label>
			</div>
		</div>

		<div class="cbi-value">
			<label class="cbi-value-title"><%:Apply now%></label>
			<div class="cbi-value-field">
				<label>
					<input type="checkbox" name="b_reload" value="1" />
					<%:Reload wireless immediately (clients disconnect briefly)%>
				</label>
				<br />
				<input type="submit" name="b_apply" value="<%:Write configuration%>" class="cbi-button cbi-button-apply" />
			</div>
		</div>

		<p class="cbi-section-descr" style="color:#c62828">
			<%:This overwrites the SSID, encryption and key on every AP interface of this device. Make sure all other APs get the same values, otherwise DAWN clients will not roam between them.%>
		</p>
	</div>
	]], {
		notice_html = notice_html,
		ifaces      = ifaces,
		cur_ssid    = cur_ssid,
		cur_enc     = cur_enc,
		cur_k       = cur_k,
		cur_v       = cur_v,
		esc         = esc,
		badge       = badge,
		state_of    = state_of,
	})
end

return m
