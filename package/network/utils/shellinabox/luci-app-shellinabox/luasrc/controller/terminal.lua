module("luci.controller.terminal", package.seeall)

function index()
	if not (luci.sys.call("pidof shellinaboxd > /dev/null") == 0) then
		return
	end
	
	entry({"admin", "system", "terminal"}, template("terminal"), _("Shellinabox Terminal"), 10).leaf = true
end
