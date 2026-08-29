-- luci-app-vxlan settings
local m, s, o
local sys = require "luci.sys"

m = Map("vxlan_link", translate("VXLAN WiFi Networking"),
	translate("Extend layer-2 network over a wireless backhaul + VXLAN tunnels. Supports MT7628/MT7688 (mt76x8), " ..
		"AR7240/7241/7242/AR9331/9341/9342/9344/QCA9531/9533/9556/9558/9561/9563/TP9343 (ar71xx), RT3052/5350/MT7620/MT7621 (ramips), arm and " ..
		"x86 platforms. The server (AP) provides the wireless AP and tunnel egress; the client (STA) connects and bridges STB/terminals. " ..
		"After saving, click 'Apply Network Config' on the Status page to take effect (restarts network)."))

s = m:section(NamedSection, "settings", "settings", translate("Basic Settings"))
s.addremove = false
s.anonymous = false

s:tab("general", translate("General"))
s:tab("backhaul", translate("Wireless Backhaul"))
s:tab("lan", translate("Subnets & Routes"))
s:tab("iptv", translate("IPTV (Telecom)"))
s:tab("voip", translate("VoIP Network"))
s:tab("advanced", translate("Advanced"))

-- ---------------- general ----------------
o = s:taboption("general", Flag, "enabled", translate("Enable"),
	translate("Install hotplug hooks at boot and start tunnel self-healing (does not reconfigure the network)"))
o.default = "0"
o.rmempty = false

o = s:taboption("general", ListValue, "role", translate("Role"),
	translate("server = transmitter (AP, connects to ONT/upstream); client = receiver (STA, connects STB)"))
o:value("server", translate("Server / Transmitter (A)"))
o:value("client", translate("Client / Receiver (B)"))
o.default = "server"
o.rmempty = false

o = s:taboption("general", ListValue, "provider", translate("Provider Mode"),
	translate("telecom = VLAN single-line multiplexing + private routes + mcast-to-ucast; unicom = plain L2 extension (single tunnel)"))
o:value("telecom", translate("Telecom (VLAN mux + private routes)"))
o:value("unicom", translate("Unicom (plain L2 extension)"))
o.default = "telecom"
o.rmempty = false

o = s:taboption("general", ListValue, "region", translate("Region"),
	translate("Shanghai uses tested telecom/unicom private-network profiles; other regions have unknown private networks, " ..
		"fall back to the Shanghai-Unicom DHCP profile (no VLAN bridge/private routes) - untested."))
o:value("shanghai", translate("Shanghai (telecom/unicom, tested)"))
o:value("other", translate("Other regions (Unicom DHCP profile, untested)"))
o.default = "shanghai"
o.rmempty = false

-- ---------------- backhaul ----------------
o = s:taboption("backhaul", ListValue, "radio", translate("Wireless Device"),
	translate("Radio used by the backhaul (radio1 on dual-band devices). Leave empty to auto-detect."))
o:value("radio0", "radio0 (2.4G)")
o:value("radio1", "radio1 (5G, requires hardware support)")
o.rmempty = true

o = s:taboption("backhaul", Value, "ssid", translate("Backhaul SSID"),
	translate("Must match on both ends"))
o.default = "link"
o.rmempty = false

o = s:taboption("backhaul", Value, "key", translate("Backhaul Password"),
	translate("WPA2-PSK, at least 8 chars, must match on both ends"))
o.password = true
o.default = "EnjoyLink2026"
o.rmempty = false

o = s:taboption("backhaul", Value, "backhaul_ip", translate("Local Backhaul IP"),
	translate("Underlay address. Server: 172.16.9.1, client: 172.16.9.2"))
o.datatype = "ip4addr"
o.default = "172.16.9.1"
o.rmempty = false

o = s:taboption("backhaul", Value, "peer_ips", translate("Peer Backhaul IP (one or more)"),
	translate("Space-separated peer underlay addresses, same subnet as local. One peer = one IP, " ..
		"multiple peers = multiple IPs (e.g. 172.16.9.2 172.16.9.3 172.16.9.4). " ..
		"Multi-peer is server-only: creates a dedicated VXLAN tunnel per peer bridged into br-lan/br-iptv/br-voip; " ..
		"offline peers do not affect the server (tunnels are managed directly by the script, not netifd)."))
o.placeholder = "172.16.9.2 172.16.9.3"
o.datatype = "string"
o.rmempty = false

o = s:taboption("backhaul", Value, "backhaul_mask", translate("Backhaul Netmask"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "255.255.255.0"

o = s:taboption("backhaul", Value, "vni_inet", translate("Internet Tunnel VNI"),
	translate("Must match on both ends"))
o.datatype = "uinteger"
o.default = "100"
o.rmempty = false

o = s:taboption("backhaul", Value, "vni_iptv", translate("IPTV Tunnel VNI"),
	translate("Telecom only, must match on both ends. Client N automatically uses VNI+N-1"))
o.datatype = "uinteger"
o.default = "200"
o.rmempty = true
o:depends("provider", "telecom")

-- ---------------- lan ----------------
o = s:taboption("lan", Value, "wan_if", translate("Uplink Interface"),
	translate("Server's uplink to ONT/upstream. Leave empty to auto-detect the device's current wan interface"))
o.default = "eth0"
o:depends("role", "server")

o = s:taboption("lan", Value, "lan_if", translate("LAN Physical Sub-Interface"),
	translate("Physical member of br-lan. Leave empty to auto-detect the device's current lan interface"))
o.default = "eth0.1"
o:depends("role", "server")

o = s:taboption("lan", Value, "lan_ip", translate("Local LAN IP"),
	translate("Server: 192.168.3.1 recommended; client must use a different subnet, e.g. 192.168.4.1"))
o.datatype = "ip4addr"
o.default = "192.168.3.1"
o.rmempty = false

o = s:taboption("lan", Value, "lan_mask", translate("LAN Netmask"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "255.255.255.0"

o = s:taboption("lan", Value, "gw_ip", translate("Default Gateway (server LAN IP)"),
	translate("Client-only: points to the server's br-lan address, reachable through the tunnel"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "192.168.3.1"
o:depends("role", "client")

o = s:taboption("lan", Value, "peer_lan_subnet", translate("Peer LAN Subnet"),
	translate("Server: client subnet (return route); client: server subnet"))
o.datatype = "ip4addr"
o.default = "192.168.4.0"
o.rmempty = false

o = s:taboption("lan", Value, "peer_lan_mask", translate("Peer LAN Netmask"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "255.255.255.0"

o = s:taboption("lan", Value, "lan_mac", translate("br-lan MAC"),
	translate("Client recommended: same-batch boards share the factory MAC and collide. Empty = don't change"))
o.datatype = "macaddr"
o.rmempty = true
o.placeholder = "00:7e:56:00:36:88"
o:depends("role", "client")

o = s:taboption("lan", Value, "iptv_mac", translate("br-iptv MAC"),
	translate("Client telecom recommended, avoids collision with server br-iptv. Empty = don't change"))
o.datatype = "macaddr"
o.rmempty = true
o.placeholder = "00:7e:56:00:36:89"
o:depends("role", "client")

-- ---------------- iptv ----------------
o = s:taboption("iptv", Value, "iptv_vid", translate("IPTV VLAN ID"),
	translate("Must match on both ends; Shanghai Telecom uses 85"))
o.datatype = "range(1,4094)"
o.rmempty = true
o.default = "85"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "iptv_hostname", translate("IPTV DHCP Hostname"),
	translate("Checked by some carriers; leave empty to not send"))
o.default = "zte"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "iptv_gateway", translate("Private Gateway"),
	translate("Next-hop for private routes; leave empty to skip private routes"))
o.datatype = "ip4addr"
o.rmempty = true
o.placeholder = "30.170.0.1"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "iptv_routes", translate("IPTV Walled-Garden Routes"),
	translate("Carrier service subnets inside the IPTV plane that DHCP does NOT deliver " ..
		"(DNS e.g. 10.192.0.0/16, etc). Space-separated, max 3, routed via the " ..
		"DHCP-assigned IPTV gateway. Auto-detected on renumber."))
o.placeholder = "10.192.0.0/16"
o.datatype = "string"
o.rmempty = true
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "epg_host", translate("EPG Server"),
	translate("Single address, routed /32 via private network"))
o.datatype = "ip4addr"
o.rmempty = true
o.placeholder = "218.83.165.67"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "lb_subnets", translate("Lookback Server Subnets"),
	translate("Space-separated, max 3, can use a.b.c.0/24"))
o.placeholder = "124.75.26.0/24 124.75.27.0/24"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "hb_host", translate("Heartbeat Server"),
	translate("Single address, routed /32 via private network"))
o.datatype = "ip4addr"
o.rmempty = true
o.placeholder = "124.75.22.211"
o:depends("provider", "telecom")

o = s:taboption("iptv", Flag, "msd_enable", translate("Enable msd_lite multicast-to-unicast"),
	translate("Applies in client telecom mode; requires msd_lite installed"))
o.default = "1"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "msd_port", translate("msd_lite Port"),
	translate("Play URL like http://<local-ip>:<port>/udp/<mcast-addr>:<port>"))
o.datatype = "port"
o.rmempty = true
o.default = "7088"
o:depends("provider", "telecom")

o = s:taboption("iptv", Value, "option125", translate("DHCP option 125"),
	translate("ONT identifier (vendor class) sent to the STB, format 125,00:00:... " ..
		"Empty = options 125/15/28 are not sent at all. Capture packets from your own ONT to get it"))
o.placeholder = "125,00:00:00:00:1D:01:06:..."

-- ---------------- voip ----------------
o = s:taboption("voip", Flag, "voip_enable", translate("Enable VoIP Network"),
	translate("Shanghai Telecom VoIP uses VLAN46 private network. Dedicated vxlan_voip tunnel + br-voip bridge, " ..
		"not shared with other tunnels. DHCP yields 28.132.57.x/17, gateway 28.132.127.254 (HSRP)."))
o.default = "0"
o.rmempty = false
o:depends("provider", "telecom")

o = s:taboption("voip", Value, "voip_vid", translate("VoIP VLAN ID"),
	translate("Shanghai Telecom uses 46 (verified)"))
o.datatype = "range(1,4094)"
o.rmempty = true
o.default = "46"
o:depends("provider", "telecom")

o = s:taboption("voip", Value, "voip_vni", translate("VoIP Tunnel VNI"),
	translate("VNI of the dedicated vxlan_voip tunnel, must match on both ends. Default 300"))
o.datatype = "uinteger"
o.rmempty = true
o.default = "300"
o:depends("provider", "telecom")

o = s:taboption("voip", Value, "voip_gateway", translate("VoIP Private Gateway"),
	translate("Shanghai Telecom: 28.132.127.254 (Cisco HSRP virtual gateway, ICMP blocked)"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "28.132.127.254"
o:depends("provider", "telecom")

o = s:taboption("voip", Value, "voip_subnets", translate("VoIP Private Subnets"),
	translate("Space-separated, max 3. Shanghai Telecom: 28.132.0.0/17"))
o.placeholder = "28.132.0.0/17"
o.default = "28.132.0.0/17"
o:depends("provider", "telecom")

o = s:taboption("voip", Value, "voip_routes", translate("VoIP Walled-Garden Routes"),
	translate("Carrier service subnets inside the VoIP plane that DHCP does NOT deliver " ..
		"(DNS/softswitch, e.g. 15.192.0.0/16). Space-separated, max 3, routed via the " ..
		"DHCP-assigned VoIP gateway. Auto-detected on renumber."))
o.placeholder = "15.192.0.0/16"
o.datatype = "string"
o.rmempty = true
o:depends("provider", "telecom")

-- ---------------- advanced ----------------
o = s:taboption("advanced", Value, "dns1", translate("Upstream DNS 1"),
	translate("Prevents DNS pollution from IPTV-provided DNS"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "223.5.5.5"

o = s:taboption("advanced", Value, "dns2", translate("Upstream DNS 2"))
o.datatype = "ip4addr"
o.rmempty = true
o.default = "114.114.114.114"

o = s:taboption("advanced", Flag, "selfheal", translate("Tunnel Self-Heal"),
	translate("Client waits for wifi after boot, verifies tunnel, auto-rebuilds on failure"))
o.default = "1"
o.rmempty = false

o = s:taboption("advanced", Flag, "force_soc", translate("Force Run on Unrecognized SoC"),
	translate("DANGER: normally auto-detects mt76x8 (MT7628/MT7688), ar71xx (AR7240/7241/7242/AR9331/9341/9342/9344/QCA9531/9533/9556/9558/9561/9563/TP9343), " ..
		"ramips (RT3052/5350/MT7620/MT7621), arm, x86. Enable only if platform detection fails and you verified hardware compatibility"))
o.default = "0"
o.rmempty = false

o = s:taboption("advanced", ListValue, "switch_mode", translate("Switch Mode"),
	translate("auto/software 8021q = default for all platforms; wireless mesh doesn't depend on board port layout (arm/x86 use pure software VLAN). " ..
		"Multi-port boards may pick hw (hardware VLAN/swconfig) to use the switch chip"))
o:value("auto", translate("Auto (software 8021q, recommended)"))
o:value("hw", translate("Hardware VLAN (swconfig, multi-port boards)"))
o:value("sw", translate("Software 8021q"))
o.default = "auto"

o = s:taboption("advanced", Value, "sw_dev", translate("Switch Device (multi-port platforms)"),
	translate("Switch device name for ar71xx/ramips hardware VLAN, usually switch0"))
o.default = "switch0"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "sw_cpu_port", translate("CPU Port"),
	translate("Switch-to-CPU port number, commonly 6 (AR9341/MT7620/MT7621) or 5"))
o.datatype = "range(0,9)"
o.default = "6"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "sw_lan_ports", translate("LAN Ports"),
	translate("Space-separated LAN port numbers (VLAN1 members, untagged), e.g. 0 1 2 3"))
o.placeholder = "0 1 2 3"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "sw_wan_port", translate("WAN Port (hardware VLAN)"),
	translate("Port connected to the ONT internet (VLAN2 member, untagged). Fill on ramips multi-port routers " ..
		"to auto-create the WAN VLAN and use eth0.<wan_vlan> as uplink; ar71xx standalone WAN (eth1) can leave empty"))
o.placeholder = "4"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "wan_vlan", translate("WAN VLAN ID"),
	translate("VLAN ID of the WAN port, default 2"))
o.datatype = "range(1,4094)"
o.default = "2"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "sw_iptv_port", translate("IPTV Port"),
	translate("Port connected to the ONT IPTV (VLAN85 member, untagged)"))
o.placeholder = "4"
o.rmempty = true
	o:depends("switch_mode", "hw")

o = s:taboption("advanced", Value, "sw_voip_port", translate("VoIP Port"),
	translate("Port connected to VoIP terminals (VLAN46 member, untagged); empty = no VoIP VLAN"))
o.placeholder = ""
o.rmempty = true
	o:depends("switch_mode", "hw")

-- Save must be fast: only (re)install hotplug hooks in the background so the
-- LuCI page returns immediately. vxlan devices are rebuilt only by 'apply'
-- and at boot (init.d start); never on save - deleting tunnels here would
-- stall the page AND drop live tunnels for no reason. selfheal reads uci
-- live on every loop, so a running watchdog picks up new settings on its own.
function m.on_after_commit(self)
	local en = self:get("settings", "enabled") or "0"
	if en == "1" then
		sys.call("/etc/init.d/vxlan-link enable >/dev/null 2>&1")
		sys.call("/usr/bin/vxlan-link hotplug >/dev/null 2>&1 &")
	else
		sys.call("/etc/init.d/vxlan-link stop >/dev/null 2>&1")
		sys.call("/etc/init.d/vxlan-link disable >/dev/null 2>&1")
	end
end

return m
