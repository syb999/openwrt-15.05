local m, s, o

m = Map("dawn",
	translate("DAWN - decentralized WiFi roaming controller"),
	translate("Only the settings that actually matter for roaming between several APs are shown here. Ports, timers, scoring weights and the rest live under DAWN Advanced. The shipped defaults are already tuned for a handful of APs."))

local function one_section(stype, title, desc)
	local sec = m:section(TypedSection, stype, title, desc)
	sec.anonymous = true
	sec.addremove = false
	return sec
end

-- ---------------------------------------------------------------------------
-- 1. Inter-AP communication (must be identical on every AP)
-- ---------------------------------------------------------------------------
s = one_section("network",
	translate("1. Inter-AP communication (identical on every AP)"),
	translate("DAWN instances use these settings to discover each other and to exchange client information. If any of them differs between APs, the packets still arrive but cannot be decoded - the APs appear to see each other while nothing works."))

o = s:option(ListValue, "network_option", translate("Transport"),
	translate("2 (TCP with uMDNS discovery) is the right choice for several APs. 0/1 use UDP broadcast/multicast, 3 needs a manually configured peer."))
o:value("0", translate("0 - UDP broadcast"))
o:value("1", translate("1 - UDP multicast"))
o:value("2", translate("2 - TCP with uMDNS discovery (default)"))
o:value("3", translate("3 - TCP with manually configured peer"))
o.default = "2"
o.rmempty = false

o = s:option(Value, "broadcast_ip", translate("Broadcast/multicast address"),
	translate("Only used by transport modes 0 and 1, and it must be the broadcast address of your LAN (for example 192.168.2.255). Ignored by modes 2 and 3."))
o.datatype = "ip4addr"

o = s:option(Value, "shared_key", translate("Shared key"),
	translate("Must be exactly the same on every AP. A mismatch means packets are received but cannot be decrypted."))
o.rmempty = false

o = s:option(Value, "iv", translate("Initialization vector (IV)"),
	translate("Must be exactly the same on every AP."))
o.rmempty = false

-- ---------------------------------------------------------------------------
-- 2. Roaming behaviour
-- ---------------------------------------------------------------------------
s = m:section(NamedSection, "global", "metric",
	translate("2. Roaming behaviour (identical on every AP)"),
	translate("DAWN scores every client/AP pair and asks a client to move when the score difference exceeds the threshold. 802.11v BTM only is the least disruptive way to steer; forced disconnects should stay off on a healthy network."))

o = s:option(ListValue, "kicking", translate("Kicking method"),
	translate("This is a bit mask, not a plain switch: 1 = force disconnect, 2 = send an 802.11v BTM request, 3 = both. The default only asks."))
o:value("0", translate("0 - do not kick (score only)"))
o:value("1", translate("1 - force disconnect (deauth/disassoc)"))
o:value("2", translate("2 - 802.11v BTM request"))
o:value("3", translate("3 - BTM and disconnect (default)"))
o.default = "2"
o.rmempty = false

o = s:option(Value, "kicking_threshold", translate("Kicking score threshold"),
	translate("The target AP must score this much higher before a client is moved. 35 keeps clients in place inside the coverage area and only moves them when the current AP is clearly worse."))
o.datatype = "uinteger"
o.default = "35"

o = s:option(Value, "min_number_to_kick", translate("Consecutive evaluations before kicking"),
	translate("Debounce counter: the client must look like it should move this many evaluation cycles in a row. Default 6."))
o.datatype = "uinteger"
o.default = "6"

-- ---------------------------------------------------------------------------
-- 3. Band preference
-- ---------------------------------------------------------------------------
s = m:section(NamedSection, "802_11g", "metric",
	translate("3. 2.4 GHz preference"),
	translate("Starting score for the 2.4 GHz band. A lower value keeps clients on 5 GHz for as long as possible."))

o = s:option(Value, "initial_score", translate("Initial score"))
o.datatype = "integer"
o.default = "75"

s = m:section(NamedSection, "802_11a", "metric",
	translate("4. 5 GHz preference"),
	translate("Starting score for the 5 GHz band. 5 GHz carries the load, so it starts higher."))

o = s:option(Value, "initial_score", translate("Initial score"))
o.datatype = "integer"
o.default = "100"

-- ---------------------------------------------------------------------------
-- 5. Refresh / logging
-- ---------------------------------------------------------------------------
s = one_section("times",
	translate("5. Refresh interval"),
	translate("How often DAWN re-reads the client lists. Shorter reacts faster, longer costs less CPU."))

o = s:option(Value, "update_client", translate("Client information refresh interval"),
	translate("Default 15 seconds for a network of a few APs."))
o.datatype = "uinteger"
o.default = "15"

s = one_section("local",
	translate("6. Local options (may differ per AP)"),
	translate("Only affect the local dawn process."))

o = s:option(ListValue, "loglevel", translate("Log level"),
	translate("0 prints errors and warnings only (default, recommended). Raise it to 1 or 2 while debugging; 3 logs every internal step and should not be left enabled."))
o:value("0", translate("0 - errors and warnings (default)"))
o:value("1", translate("1 - informational"))
o:value("2", translate("2 - trace"))
o:value("3", translate("3 - full debug (very verbose)"))
o.default = "0"
o.rmempty = false

return m
