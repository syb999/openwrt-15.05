-- Zigbee gateway settings (CBI)
-- uci: zigbeed.options (config 'options')
m = Map("zigbeed", translate("Zigbee Gateway"), translate("Independent Zigbee gateway daemon for MT7688 boards (EFR32MG1B coordinator). Reads real network parameters from the coordinator; keep channel/PAN/key empty unless you need to force a specific network."))

-- ============ General settings ============
s = m:section(NamedSection, "options", "options", translate("Gateway Settings"))
s.addremove = false
s.anonymous = true

-- Enable switch (binds /etc/init.d/zigbeed)
en = s:option(Flag, "enabled", translate("Enable gateway"))
en.rmempty = false
en.default = "1"
function en.write(self, section, value)
	Flag.write(self, section, value)
	local e = value and "1" or "0"
	if e == "1" then
		luci.util.exec("/etc/init.d/zigbeed enable >/dev/null 2>&1")
		luci.util.exec("/etc/init.d/zigbeed start >/dev/null 2>&1 &")
	else
		luci.util.exec("/etc/init.d/zigbeed stop >/dev/null 2>&1")
		luci.util.exec("/etc/init.d/zigbeed disable >/dev/null 2>&1")
		luci.util.exec("killall zigbeed 2>/dev/null")
	end
end

-- Serial port
dev = s:option(Value, "device", translate("Serial device"))
dev.rmempty = false
dev.default = "/dev/ttyS1"

-- Baud rate
bd = s:option(Value, "baud", translate("Baud rate"))
bd.rmempty = false
bd.default = "115200"

-- Poll interval
poll = s:option(Value, "poll_interval", translate("Poll interval (seconds)"))
poll.rmempty = false
poll.default = "30"
poll.datatype = "uinteger"

-- ============ Network parameters (optional) ============
ns = m:section(NamedSection, "options", "options", translate("Network Parameters (optional)"))
ns.addremove = false
ns.anonymous = true

ch = ns:option(Value, "channel", translate("Zigbee channel (11-26)"))
ch.rmempty = true
ch.description = translate("Leave empty to read from coordinator. Real value is shown on Status page.")

pan = ns:option(Value, "panid", translate("PAN ID"))
pan.rmempty = true
pan.description = translate("Leave empty to read from coordinator.")

extpan = ns:option(Value, "extpanid", translate("Extended PAN ID"))
extpan.rmempty = true
extpan.description = translate("Leave empty to read from coordinator.")

key = ns:option(Value, "network_key", translate("Network key"))
key.rmempty = true
key.description = translate("Leave empty to read from coordinator (per-device factory value).")

-- ============ MQTT bridge ============
ms = m:section(NamedSection, "options", "options", translate("MQTT Bridge"))
ms.addremove = false
ms.anonymous = true

mq = ms:option(Flag, "mqtt", translate("Enable MQTT bridge"))
mq.rmempty = false
mq.default = "1"
mq.description = translate("Bridge to local mosquitto (127.0.0.1:1883). Subscribe zigbee2mqtt/+/set, publish zigbee2mqtt/<device>.")

-- ============ Actions ============
as = m:section(NamedSection, "options", "options", translate("Actions"))
as.addremove = false
as.anonymous = true

-- Rebuild network button
rb = as:option(Button, "_rebuild", translate("Rebuild coordinator network"))
rb.rmempty = true
rb.inputstyle = "apply"
rb.description = translate("Fixes lost coordinator parameters (channel/PAN become '?'). Uses vendor DeviceHub to reform the network, then switches back to zigbeed. Channel and PAN ID will change after rebuild.")
function rb.write(self, section)
	local out = luci.util.exec("sh /usr/bin/zigbeed-rebuild.sh 2>&1")
	luci.http.prepare_content("text/plain")
	luci.http.write(out or "done")
end

return m
