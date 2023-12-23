--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2012 Connectify <bprodoehl@connectify.me>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
]]--

local wa = require "luci.tools.webadmin"
local ut = require "luci.util"
local nw = require "luci.model.network"
local fs = require "nixio.fs"

m = Map("netem", translate("Network Emulation"),
    translate("With Network Emulation you can simulate various network conditions."))

s = m:section(TypedSection, "interface", translate("Interfaces"))
s.addremove = true
s.anonymous = false

ifname = s:option(Value, "ifname", translate("Interface"),
                  translate("These rules will apply to OUTGOING traffic on this physical interface."))
ifname.template = "cbi/network_ifacelist"
ifname.widget = "radio"
ifname.nobridges = false
ifname.rmempty = false
ifname.network = arg[1]

e = s:option(Flag, "enabled", translate("Enable"), translate("Enable/Disable Network Emulation on this interface."))
e.rmempty = false

s:option(Flag, "delay", translate("Packet Delay"), translate("Add a delay to all outgoing packets."))
delay_ms = s:option(Value, "delay_ms", translate("Delay (ms)"), translate("The base amount of fixed delay to be added to every ougoing packet."))
delay_ms:depends({delay="1"})
delay_ms.datatype = "uinteger"
delay_var = s:option(Value, "delay_var", translate("Delay +/- Variation (ms)"), translate("The amount of variation(jitter) that can be added or removed from the base fixed delay."))
delay_var:depends({delay="1"})
delay_var.datatype = "uinteger"
delay_corr = s:option(Value, "delay_corr", translate("Delay Correlation (%)"), translate("Probability that the variation will be the same as that of the previous packet."))
delay_corr:depends({delay="1"})
delay_corr.datatype = "range(0,100)"

reordering = s:option(Flag, "reordering", translate("Packet Re-ordering"), translate("If the inter-packet gap is less than the specified Delay (ms), then packets can be reordered."))
reordering:depends({delay="1"})
reordering_immed_pct = s:option(Value, "reordering_immed_pct", translate("Immediate Delivery (%)"), translate("Probability that a packet will be delivered immediately."))
reordering_immed_pct:depends({reordering="1"})
reordering_immed_pct.datatype = "range(0,100)"
reordering_corr = s:option(Value, "reordering_corr", translate("Reordering Correlation (%)"), translate("Probability that a packet will be delayed the same as the previous packet."))
reordering_corr:depends({reordering="1"})
reordering_corr.datatype = "range(0,100)"

s:option(Flag, "loss", translate("Packet Loss"), translate("Packets can be randomly dropped."))
loss_pct = s:option(Value, "loss_pct", translate("Loss (%)"), translate("Probability that a packet will be dropped."))
loss_pct:depends({loss="1"})
loss_pct.datatype = "range(0,100)"
loss_corr = s:option(Value, "loss_corr", translate("Loss Correlation (%)"), translate("Probability that a packet will do the same thing as the previous packet.  Bursts of packet loss can be achieved with this parameter."))
loss_corr:depends({loss="1"})
loss_corr.datatype = "range(0,100)"

s:option(Flag, "duplication", translate("Packet Duplication"), translate("Packets can be randomly duplicated."))
duplication_pct = s:option(Value, "duplication_pct", translate("Duplication (%)"), translate("Probability that a packet will be duplicated."))
duplication_pct:depends({duplication="1"})
duplication_pct.datatype = "range(0,100)"

s:option(Flag, "corruption", translate("Packet Corruption"), translate("Packets can be randomly corrupted with single-bit errors."))
corruption_pct = s:option(Value, "corruption_pct", translate("Corruption (%)"), translate("Probability that a packet will be corrupted."))
corruption_pct:depends({corruption="1"})
corruption_pct.datatype = "range(0,100)"

s:option(Flag, "ratecontrol", translate("Rate Control"), translate("OUTGOING traffic can be rate-limited."))
ratecontrol_rate = s:option(Value, "ratecontrol_rate", translate("Download Speed (kbit/s)"))
ratecontrol_rate:depends({ratecontrol="1"})
ratecontrol_rate.datatype = "uinteger"

return m
