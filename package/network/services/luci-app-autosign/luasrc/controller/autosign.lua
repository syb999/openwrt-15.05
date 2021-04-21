module("luci.controller.autosign",package.seeall)

function index()
	local page = entry({"admin", "services", "autosign"}, cbi("autosign"), _("AutoSign"))
	page.dependent = true
end
