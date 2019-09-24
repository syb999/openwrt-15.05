module("luci.controller.firewall", package.seeall)

function index()
	entry({"admin", "network", "firewall"},
		alias("admin", "network", "firewall", "zones"),
		_("Firewall"), 60)

	entry({"admin", "network", "firewall", "zones"},
		arcombine(cbi("firewall/zones"), cbi("firewall/zone-details")),
		_("General Settings"), 10).leaf = true

	entry({"admin", "network", "firewall", "forwards"},
		arcombine(cbi("firewall/forwards"), cbi("firewall/forward-details")),
		_("Port Forwards"), 20).leaf = true

	entry({"admin", "network", "firewall", "rules"},
		arcombine(cbi("firewall/rules"), cbi("firewall/rule-details")),
		_("Traffic Rules"), 30).leaf = true

--	/* start modified by ivan 2015.7.31 remove "Custom Rules" under "Network - Firewall" */
--[[
	entry({"admin", "network", "firewall", "custom"},
		cbi("firewall/custom"),
		_("Custom Rules"), 40).leaf = true
--]]
--	/* end modified by ivan 2015.7.31 remove "Custom Rules" under "Network - Firewall" */

end
