-- Copyright 2020 Wojciech Jowsa <wojciech.jowsa@gmail.com>
-- Licensed to the public under the Apache License 2.0.
--
-- Lua port of luci-proto-vxlan (IPv6 variant) for OpenWrt 15.05.

local netmod = luci.model.network
local interface = luci.model.network.interface
local proto = netmod:register_protocol("vxlan6")

function proto.get_i18n(self)
	return luci.i18n.translate("VXLANv6 (RFC7348)")
end

function proto.ifname(self)
	return "vxlan-" .. self.sid
end

function proto.opkg_package(self)
	return "vxlan"
end

function proto.is_installed(self)
	return nixio.fs.access("/lib/netifd/proto/vxlan.sh")
end

function proto.is_floating(self)
	return true
end

function proto.is_virtual(self)
	return true
end

function proto.get_interfaces(self)
	return nil
end

function proto.contains_interface(self, ifc)
	return (netmod:ifnameof(ifc) == self:ifname())
end

netmod:register_pattern_virtual("^vxlan%-%w")
