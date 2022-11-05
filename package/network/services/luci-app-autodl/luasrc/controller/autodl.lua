module("luci.controller.autodl",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/autodl") then
		return
	end

	local page = entry({"admin", "services", "autodl"}, cbi("autodl"), _("Autodl"),3)
	page.dependent = true
	entry({"admin", "services", "autodl", "status"}, call("autodl_status")).leaf = true
end

function autodl_status()
	local e = {
		running = luci.sys.exec("busybox ps | grep \/usr\/online_server\/dexmly.py | grep -v grep | awk '{print $1}' "),
		mpg123 = luci.sys.exec("busybox ps | grep mpg123 | grep -v grep | awk '{print$6}' ")
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

