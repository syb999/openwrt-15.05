module("luci.controller.adbrun",package.seeall)

function index()
	local page = entry({"admin", "services", "adbrun"}, cbi("adbrun"), _("adbrun"))
	page.dependent = true
end
