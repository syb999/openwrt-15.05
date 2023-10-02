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
	local mpg123 = luci.sys.exec("ps -w | grep mpg123 | grep -v grep | head -n1 | awk '{print$6}' ")
	if not mpg123 or string.match(mpg123, "timeout") or string.match(mpg123, "-") then
		mpg123 = luci.sys.exec("ps -w | grep curl | grep -v grep | head -n1 | awk '{print$7}' ")
	end

	local e = {
		running = luci.sys.exec("ps -w | grep \/usr\/online_server\/dexmly.py | grep -v grep | awk '{print$1}' "),
		mpg123 = mpg123
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
