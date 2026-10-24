local m, s, o

m = Map("dawn",
	translate("DAWN Advanced"),
	translate("Everything that the basic page leaves out: ports, timers, 802.11k/802.11v details and the scoring weights. The defaults are tuned for a network of a few APs; change them only when you know what they do. All APs must use the same values."))

local function one_section(stype, title, desc)
	local sec = m:section(TypedSection, stype, title, desc)
	sec.anonymous = true
	sec.addremove = false
	return sec
end

-- ---------------------------------------------------------------------------
-- Inter-AP communication, part 2
-- ---------------------------------------------------------------------------
s = one_section("network",
	translate("1. Inter-AP communication - ports and encryption"),
	translate("Must be identical on every AP."))

o = s:option(Value, "broadcast_port", translate("UDP port"),
	translate("Default 1025. Must be the same on every AP."))
o.datatype = "port"
o.default = "1025"

o = s:option(Value, "tcp_port", translate("TCP port"),
	translate("Default 1026. Must be the same on every AP."))
o.datatype = "port"
o.default = "1026"

o = s:option(Value, "server_ip", translate("TCP peer address"),
	translate("Only used by transport mode 3: the IP address of another AP."))
o.datatype = "ip4addr"

o = s:option(Flag, "use_symm_enc", translate("Encrypt inter-AP traffic"),
	translate("Must be enabled or disabled on all APs alike."))
o.default = o.disabled

-- ---------------------------------------------------------------------------
-- hostapd
-- ---------------------------------------------------------------------------
s = one_section("hostapd",
	translate("2. hostapd interface (may differ per AP)"),
	translate("dawn talks to hostapd through the control sockets in this directory."))

o = s:option(Value, "hostapd_dir", translate("hostapd socket directory"),
	translate("Default /var/run/hostapd. Normally there is no reason to change it."))
o.default = "/var/run/hostapd"

-- ---------------------------------------------------------------------------
-- Timers
-- ---------------------------------------------------------------------------
s = one_section("times",
	translate("3. Timers"),
	translate("Values are in seconds. Keep them identical across all APs, otherwise one AP reacts faster than another and the decisions contradict each other."))

o = s:option(Value, "con_timeout", translate("Connection timeout"), translate("Default 60."))
o.datatype = "uinteger"
o.default = "60"

o = s:option(Value, "remove_client", translate("Expire client entries after"), translate("Default 15."))
o.datatype = "uinteger"

o = s:option(Value, "remove_probe", translate("Expire probe entries after"), translate("Default 30."))
o.datatype = "uinteger"

o = s:option(Value, "remove_ap", translate("Expire AP entries after"), translate("Default 460."))
o.datatype = "uinteger"

o = s:option(Value, "update_hostapd", translate("Rescan hostapd sockets every"), translate("Default 10."))
o.datatype = "uinteger"

o = s:option(Value, "update_tcp_con", translate("Refresh inter-AP connections every"), translate("Default 10."))
o.datatype = "uinteger"

o = s:option(Value, "update_chan_util", translate("Channel utilization sampling interval"), translate("Default 5."))
o.datatype = "uinteger"

o = s:option(Value, "update_beacon_reports", translate("Request 802.11k beacon reports every"),
	translate("Default 20. Only meaningful for clients that support 11k and when beacon reports are enabled. 0 disables the requests."))
o.datatype = "uinteger"

-- ---------------------------------------------------------------------------
-- Global metric
-- ---------------------------------------------------------------------------
s = m:section(NamedSection, "global", "metric",
	translate("4. Global scoring and kicking policy - details"),
	translate("Thresholds and 802.11k/802.11v details. All APs must use the same values."))

o = s:option(Value, "min_probe_count", translate("Minimum probe count"),
	translate("A client must be heard at least this many times before it takes part in the evaluation. Default 3."))
o.datatype = "uinteger"
o.default = "3"

o = s:option(Value, "max_station_diff", translate("Maximum station count difference"),
	translate("The target AP may have at most this many more clients than the current one, which keeps all clients from piling up on a single AP. Default 1."))
o.datatype = "uinteger"
o.default = "1"

o = s:option(Value, "bandwidth_threshold", translate("Active transfer threshold (Mbps)"),
	translate("A client whose current rate is above this value counts as actively transferring and is not asked to move. Do not set it to the 802.11 basic rate (6): every idle 2.4 GHz client sits exactly there and would look kickable. Default 3; 0 disables the check entirely."))
o.datatype = "uinteger"
o.default = "3"

o = s:option(Value, "chan_util_avg_period", translate("Channel utilization averaging period"),
	translate("Default 3."))
o.datatype = "uinteger"

o = s:option(Flag, "use_station_count", translate("Include the station count in the score"))
o.default = o.disabled

o = s:option(Flag, "eval_probe_req", translate("Use probe requests in the evaluation"))
o.default = o.disabled

o = s:option(Flag, "eval_auth_req", translate("Use authentication requests in the evaluation"))
o.default = o.disabled

o = s:option(Flag, "eval_assoc_req", translate("Use association requests in the evaluation"))
o.default = o.disabled

o = s:option(Value, "deny_auth_reason", translate("Status code when denying authentication"),
	translate("802.11 status code, default 1. Only used when authentication requests are evaluated."))
o.datatype = "uinteger"
o.default = "1"

o = s:option(Value, "deny_assoc_reason", translate("Reason code when denying association"),
	translate("802.11 reason code, default 17."))
o.datatype = "uinteger"
o.default = "17"

o = s:option(ListValue, "set_hostapd_nr", translate("Fill in 802.11k neighbor reports for hostapd"),
	translate("With 11k enabled, 0 leaves the client with a neighbor report that only lists its current AP. 1 lets DAWN fill in every AP of the network, which is what makes 11k roaming useful."))
o:value("0", translate("0 - do not set"))
o:value("1", translate("1 - static: all APs in this network"))
o:value("2", translate("2 - dynamic: the nearest APs seen by the client"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "disassoc_nr_length", translate("Neighbor report entries per 802.11v request"),
	translate("How many candidate APs are included in a BTM/disassoc neighbor report. 6 is the documented iOS-friendly value; longer lists cost airtime and are usually ignored by clients."))
o.datatype = "uinteger"
o.default = "6"

o = s:option(Value, "duration", translate("Deadline for the client to move (seconds)"),
	translate("Used both as the 802.11k beacon report measurement duration and as the 802.11v BSS transition timer. Must not be 0: some clients refuse a zero-length measurement and some treat a zero validity period as expired and leave the AP without a valid target."))
o.datatype = "uinteger"
o.default = "150"

o = s:option(Value, "rrm_mode", translate("Preferred 802.11k beacon report modes"),
	translate("Order string built from P (passive), A (active) and T (table), for example PAT. Only meaningful with 11k enabled."))
o.default = "PAT"

-- ---------------------------------------------------------------------------
-- Per-band scoring
-- ---------------------------------------------------------------------------
local function band_section(section_name, title, description)
	local bs = m:section(NamedSection, section_name, "metric", title, description)
	local bo

	bo = bs:option(Value, "ap_weight", translate("AP weight"),
		translate("Additional score bonus or penalty. Usually left at 0."))
	bo.datatype = "integer"

	bo = bs:option(Value, "ht_support", translate("Bonus for HT (802.11n) support"))
	bo.datatype = "integer"

	bo = bs:option(Value, "vht_support", translate("Bonus for VHT (802.11ac) support"))
	bo.datatype = "integer"

	bo = bs:option(Value, "rssi", translate("Bonus for a good signal"),
		translate("Score added while the signal is above the good signal threshold."))
	bo.datatype = "integer"

	bo = bs:option(Value, "rssi_val", translate("Good signal threshold (dBm)"),
		translate("Negative value, for example -60. Anything above it counts as good."))
	bo.datatype = "integer"

	bo = bs:option(Value, "low_rssi", translate("Penalty for a bad signal"),
		translate("Negative value, for example -15. Added to the score once the signal drops below the bad signal threshold."))
	bo.datatype = "integer"

	bo = bs:option(Value, "low_rssi_val", translate("Bad signal threshold (dBm)"),
		translate("Negative value, for example -80. Anything below it counts as bad."))
	bo.datatype = "integer"

	bo = bs:option(Value, "chan_util", translate("Bonus for an idle channel"),
		translate("Score added while channel utilization is below the good utilization threshold."))
	bo.datatype = "integer"

	bo = bs:option(Value, "chan_util_val", translate("Good channel utilization threshold"),
		translate("Scale of 0-255 where 255 means 100 percent."))
	bo.datatype = "uinteger"

	bo = bs:option(Value, "max_chan_util", translate("Penalty for a congested channel"),
		translate("Negative value. Added to the score once utilization exceeds the congestion threshold."))
	bo.datatype = "integer"

	bo = bs:option(Value, "max_chan_util_val", translate("Congested channel utilization threshold"))
	bo.datatype = "uinteger"

	bo = bs:option(Value, "rssi_center", translate("Linear RSSI scoring center (dBm)"),
		translate("Used together with the linear RSSI weight; has no effect while the weight is 0."))
	bo.datatype = "integer"

	bo = bs:option(Value, "rssi_weight", translate("Linear RSSI scoring weight"),
		translate("Score added or subtracted per dB away from the center. 0 disables linear scoring (default)."))
	bo.datatype = "integer"

	return bs
end

band_section("802_11g",
	translate("5. 2.4 GHz scoring - details"),
	translate("802.11g/n band. The initial score is set on the basic page."))

band_section("802_11a",
	translate("6. 5 GHz scoring - details"),
	translate("802.11a/n/ac band. The initial score is set on the basic page."))

return m
