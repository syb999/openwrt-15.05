module("luci.controller.wifi-disconnect", package.seeall)

function index()
	
	entry({"admin", "system", "wifi-disconnect"}, template("wifi-disconnect"), _("wifi-disconnect-low-signal"), 10).leaf = true
end
