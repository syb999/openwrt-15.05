module("luci.controller.gmediarender",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/gmediarender") then
		return
	end

	local page = entry({"admin", "services", "gmediarender"}, cbi("gmediarender"), _("gmediarender"),10)
	page.dependent = true

	entry({"admin", "services", "gmediarender", "status"}, call("gmrender_status")).leaf = true
end

function gmrender_status()
	local e = {
		running = (luci.sys.call("pidof gmediarender >/dev/null") == 0),
		gmrd = luci.sys.exec("busybox ps | grep \/usr\/share\/gmediarender\/gmrd | grep -v grep | awk '{print $1}' ")
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

