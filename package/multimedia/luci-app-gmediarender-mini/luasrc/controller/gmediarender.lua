module("luci.controller.gmediarender",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/gmediarender") then
		return
	end

	local page = entry({"admin", "services", "gmediarender"}, cbi("gmediarender"), _("gmediarender"),10)
	page.dependent = true
end

