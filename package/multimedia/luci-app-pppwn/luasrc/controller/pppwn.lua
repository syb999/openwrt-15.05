module("luci.controller.pppwn", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/pppwn") then
		return
	end
	local page = entry({"admin", "services", "pppwn"}, cbi("pppwn"), _("PS4 PPP PWN"), 80)
	page.dependent = true

	entry({"admin", "services", "pppwn", "status"}, call("status")).leaf = true
end

function status()
	local e = {}
	e.running = luci.sys.call("pgrep pppwn >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
