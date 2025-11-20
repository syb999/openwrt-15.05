module("luci.controller.squeezelite", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/squeezelite") then
        return
    end
    
    entry({"admin", "services", "squeezelite"}, cbi("squeezelite"), _("Squeezelite"), 60).dependent = true

    entry({"admin", "services", "squeezelite", "status"}, call("status")).leaf = true
end


function status()
	local e = {}
	e.running = luci.sys.call("pgrep squeezelite >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
