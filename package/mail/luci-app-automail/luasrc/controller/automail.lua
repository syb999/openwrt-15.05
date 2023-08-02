module("luci.controller.automail",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/automail") then
		return
	end

	local page = entry({"admin", "services", "automail"}, cbi("automail"), _("Automail"),9)
	page.dependent = true

	entry({"admin", "services", "automail", "status"}, call("automail_status")).leaf = true
end

function automail_status()
	local mailtest
	if not nixio.fs.access("/tmp/msmtp.log") then
		mailtest = nil	
	else
		mailtest = luci.sys.exec("cat /tmp/msmtp.log | grep -v EX_NO | tail -n 1 | cut -d '=' -f1 2>/dev/null ")
	end

	local e = {
		mailtest = mailtest
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

