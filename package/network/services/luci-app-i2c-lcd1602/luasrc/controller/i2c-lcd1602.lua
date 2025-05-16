module("luci.controller.i2c-lcd1602", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/i2c-lcd1602") then
		return
	end

	entry({"admin", "services", "i2c-lcd1602"}, alias("admin", "services", "i2c-lcd1602", "settings"),_("LCD1602"), 90).dependent = true
	entry({"admin", "services", "i2c-lcd1602", "settings"}, cbi("i2c-lcd1602"), _("Settings"), 1).leaf = true
	entry({"admin", "services", "i2c-lcd1602", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e={}
	e.running = luci.sys.call("pgrep -f /usr/sbin/i2c_lcd1602 > /dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
