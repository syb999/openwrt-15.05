module("luci.controller.dawn", package.seeall)

function index()
    entry({ "admin", "network", "dawn" }, firstchild(), "DAWN", 60).dependent = false
    entry({ "admin", "network", "dawn", "configure_daemon" }, cbi("dawn/dawn_config"),
          translate("DAWN Settings"), 1)
    entry({ "admin", "network", "dawn", "advanced" }, cbi("dawn/dawn_advanced"),
          translate("DAWN Advanced"), 2)
    entry({ "admin", "network", "dawn", "wireless_baseline" }, cbi("dawn/dawn_wireless"),
          translate("Wireless Baseline"), 3)
    entry({ "admin", "network", "dawn", "view_aps" }, cbi("dawn/dawn_aps"),
          translate("Peer APs"), 4)
    entry({ "admin", "network", "dawn", "view_network" }, cbi("dawn/dawn_network"),
          translate("Network Overview"), 5)
    entry({ "admin", "network", "dawn", "view_hearing_map" }, cbi("dawn/dawn_hearing_map"),
          translate("Client Scores"), 6)
end
