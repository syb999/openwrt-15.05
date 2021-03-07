module("luci.controller.banmac",package.seeall)

function index()
	local page = entry({"admin", "services", "banmac"}, cbi("banmac"), _("BanMac"))
	page.dependent = true
end

