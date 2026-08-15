-- Copyright 2020 Wojciech Jowsa <wojciech.jowsa@gmail.com>
-- Licensed to the public under the Apache License 2.0.
--
-- Lua port of luci-proto-vxlan (IPv6 variant) CBI form for OpenWrt 15.05.
-- Options mirror the 21.02 JS implementation (protocol/vxlan6.js).

local map, section, net = ...

local peer6addr, ip6addr, vid, tunlink, macaddr
local mtu, ttl, tos, rxcsum, txcsum

peer6addr = section:taboption("general", Value, "peer6addr",
	translate("Remote IPv6 address"),
	translate("The IPv6 address or the fully-qualified domain name of the remote end."))
peer6addr.optional = false
peer6addr.datatype = "or(hostname,cidr6)"

ip6addr = section:taboption("general", Value, "ip6addr",
	translate("Local IPv6 address"),
	translate("The local IPv6 address over which the tunnel is created (optional)."))
ip6addr.optional = true
ip6addr.datatype = "cidr6"

vid = section:taboption("general", Value, "vid",
	translate("VXLAN network identifier"),
	translate("ID used to uniquely identify the VXLAN"))
vid.optional = true
vid.datatype = "range(1, 16777216)"

tunlink = section:taboption("general", Value, "tunlink",
	translate("Bind interface"),
	translate("Bind the tunnel to this interface (optional)."))
tunlink.optional = true

macaddr = section:taboption("general", Value, "macaddr",
	translate("Override MAC address"),
	translate("MAC address of the tunnel interface (optional)."))
macaddr.optional = true
macaddr.datatype = "macaddr"

mtu = section:taboption("advanced", Value, "mtu",
	translate("Override MTU"),
	translate("Specify an MTU (Maximum Transmission Unit) other than the default (1500 bytes)."))
mtu.optional = true
mtu.placeholder = 1500
mtu.datatype = "range(68, 9200)"

ttl = section:taboption("advanced", Value, "ttl",
	translate("Override TTL"),
	translate("Specify a TTL (Time to Live) for the encapsulating packet other than the default (64)."))
ttl.optional = true
ttl.placeholder = 64
ttl.datatype = "min(1)"

tos = section:taboption("advanced", Value, "tos",
	translate("Override TOS"),
	translate("Specify a TOS (Type of Service)."))
tos.optional = true
tos.datatype = "range(0, 255)"

rxcsum = section:taboption("advanced", Flag, "rxcsum",
	translate("Enable rx checksum"),
	translate("Enable receive checksum offload on the tunnel interface."))
rxcsum.optional = true
rxcsum.default = rxcsum.enabled

txcsum = section:taboption("advanced", Flag, "txcsum",
	translate("Enable tx checksum"),
	translate("Enable transmit checksum offload on the tunnel interface."))
txcsum.optional = true
txcsum.default = txcsum.enabled
