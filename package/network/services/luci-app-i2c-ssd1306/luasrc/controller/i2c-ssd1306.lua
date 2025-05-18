module("luci.controller.i2c-ssd1306", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/i2c-ssd1306") then
		return
	end

	entry({"admin", "services", "i2c-ssd1306"}, alias("admin", "services", "i2c-ssd1306", "settings"),_("OLED SSD1306"), 90).dependent = true
	entry({"admin", "services", "i2c-ssd1306", "settings"}, cbi("i2c-ssd1306"), _("Settings"), 1).leaf = true
	entry({"admin", "services", "i2c-ssd1306", "status"}, call("act_status")).leaf = true
end

function act_status()
	local e={}
	e.running = luci.sys.call("pgrep -f /usr/sbin/i2c_ssd1306 > /dev/null")==0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
