local uci = require "luci.model.uci".cursor()

module("luci.controller.freeradius2",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/freeradius2") then
		return
	end

	local page = entry({"admin", "services", "freeradius2"}, cbi("freeradius2"), _("FREERADIUS2"),3)
	page.dependent = true

	entry({"admin", "services", "freeradius2", "status"}, call("freeradius2_status")).leaf = true
end

function freeradius2_status()
	local e = {
		running = luci.sys.call("pgrep radiusd >/dev/null") == 0,
		interface = luci.sys.exec("busybox ps | grep radiusd | grep -v grep | awk '{print$7}'"),
		port = luci.sys.exec("busybox ps | grep radiusd | grep -v grep | awk '{print$9}' | cut -d ',' -f1 ")
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

