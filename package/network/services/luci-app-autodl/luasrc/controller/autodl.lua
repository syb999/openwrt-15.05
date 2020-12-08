module("luci.controller.autodl",package.seeall)

function index()
	local page = entry({"admin", "services", "autodl"}, cbi("autodl"), _("Autodl"))
	page.dependent = true
end

