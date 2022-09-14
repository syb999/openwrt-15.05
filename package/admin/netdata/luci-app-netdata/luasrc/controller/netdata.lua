module("luci.controller.netdata", package.seeall)

function index()
  entry({"admin", "status", "netdata"}, template("netdata"), _("Netdata Status"), 99)
end

