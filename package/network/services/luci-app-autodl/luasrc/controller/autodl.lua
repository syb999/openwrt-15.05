module("luci.controller.autodl",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/autodl") then
		return
	end

	local page = entry({"admin", "services", "autodl"}, cbi("autodl"), _("Autodl"),3)
	page.dependent = true
end

