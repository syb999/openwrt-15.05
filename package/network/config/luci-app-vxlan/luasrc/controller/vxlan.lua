-- luci-app-vxlan controller
module("luci.controller.vxlan", package.seeall)

local sys = require "luci.sys"
local http = require "luci.http"

function index()
	if not nixio.fs.access("/etc/config/vxlan_link") then
		return
	end

	local page = entry({"admin", "network", "vxlan"}, alias("admin", "network", "vxlan", "status"), _("VXLAN WiFi Networking"), 60)
	page.dependent = false

	entry({"admin", "network", "vxlan", "status"}, template("vxlan/status"), _("Status"), 10).leaf = true
	entry({"admin", "network", "vxlan", "settings"}, cbi("vxlan_link"), _("Settings"), 20).leaf = true
	entry({"admin", "network", "vxlan", "log"}, template("vxlan/log"), _("Log"), 30).leaf = true

	entry({"admin", "network", "vxlan", "act_status"}, call("act_status")).leaf = true
	entry({"admin", "network", "vxlan", "act_apply"}, call("act_apply")).leaf = true
	entry({"admin", "network", "vxlan", "act_fw"}, call("act_fw")).leaf = true
	entry({"admin", "network", "vxlan", "act_log"}, call("act_log")).leaf = true
end

function act_status()
	local out = sys.exec("/usr/bin/vxlan-link status 2>&1") or ""
	http.prepare_content("text/plain; charset=utf-8")
	http.write(out)
end

-- Applying restarts the network, so the script backgrounds itself; we return
-- immediately instead of waiting for the HTTP request to be cut off.
function act_apply()
	sys.call("/usr/bin/vxlan-link apply >/dev/null 2>&1 &")
	http.prepare_content("text/plain; charset=utf-8")
	http.write("apply started")
end

-- Firewall only: safe to run synchronously, it does not restart the network.
function act_fw()
	local out = sys.exec("/usr/bin/vxlan-link fw 2>&1") or ""
	http.prepare_content("text/plain; charset=utf-8")
	http.write(out)
	http.write("\n\n" .. (sys.exec("/usr/bin/vxlan-link status 2>&1 | grep -E '^(fw_|bridge_nf)'") or ""))
end

function act_log()
	local out = sys.exec("tail -60 /tmp/vxlan-link.log 2>/dev/null") or ""
	if out == "" then
		out = "(log empty)"
	end
	http.prepare_content("text/plain; charset=utf-8")
	http.write(out)
end
