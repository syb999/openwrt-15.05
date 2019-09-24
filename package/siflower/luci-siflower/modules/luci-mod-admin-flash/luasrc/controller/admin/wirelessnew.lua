--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/7
-- Time: 14:42
-- To change this template use File | Settings | File Templates.
--
--
local SAVE_MODE = 0
local NORMAL_MODE = 1
local PERFORMANCE_MODE = 2

local SAVE_MODE_TXPOWER = 5
local NORMAL_MODE_TXPOWER = 10
local PERFORMANCE_MODE_TXPOWER = 20

module("luci.controller.admin.wirelessnew", package.seeall)
local nw = require "luci.model.network"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local sysutil = require "luci.siwifi.sf_sysutil"
local json = require("luci.json")
local util = require("luci.util")
local sysutil = require("luci.siwifi.sf_sysutil")

function index()
    entry({"admin", "wirelessnew"}, firstchild(), _("无线设置"), 61).logo = "wireless";
    entry({"admin", "wirelessnew", "owner"}, template("new_siwifi/wireless_settings/owner") , _("主人网络"), 1);
    entry({"admin", "wirelessnew", "visitor"}, template("new_siwifi/wireless_settings/visitor") , _("访客网络"), 2);
    entry({"admin", "wirelessnew", "wds"}, template("new_siwifi/wireless_settings/wds") , _("WDS无线桥接"), 3);
    entry({"admin", "wirelessnew", "wifi_scan"}, call("wifi_scan")).leaf = true;
    entry({"admin", "wirelessnew", "wifi_connect"}, call("wifi_connect")).leaf = true;
    entry({"admin", "wirelessnew", "wds_enable"}, call("wds_enable")).leaf = true;
    entry({"admin", "wirelessnew", "wds_disable"}, call("wds_disable")).leaf = true;
    entry({"admin", "wirelessnew", "get_wds_info"}, call("get_wds_info")).leaf = true;
    entry({"admin", "wirelessnew", "get_wifi_iface"}, call("get_wifi_iface")).leaf = true;
    entry({"admin", "wirelessnew", "set_wifi_iface"}, call("set_wifi_iface")).leaf = true;
    entry({"admin", "wirelessnew", "get_customer_wifi_iface"}, call("get_customer_wifi_iface")).leaf = true;
    entry({"admin", "wirelessnew", "set_customer_wifi_iface"}, call("set_customer_wifi_iface")).leaf = true;

end

--将table转化为字符串，用于打印
function myprint(params)
    if type(params) ~= "table" then
        return tostring(params)
    end
    local rv = "\n{\n"
    for k, v in pairs(params) do
        iface = rv..tostring(k)..":"..myprint(v)..",\n"
    end
    return string.sub(iface,0,string.len(rv)-2).."\n}\n";
end

function get_wifi_iface()
	local ifaces = {}
	local wifis = sysutil.sf_wifinetworks()
	local network = require("luci.model.network").init()

	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)
		wifinet = network:get_wifinet(dev.device..".network1")
		ifaces[#ifaces+1] = {}
		ifaces[#ifaces]["band"]     = wifidev:get("band")
		ifaces[#ifaces]["enable"]     = wifinet:get("disabled") == nil and true or false
		ifaces[#ifaces]["ssid"]       = wifinet:get("ssid")

		if tonumber(wifidev:get("txpower")) == SAVE_MODE_TXPOWER then
			ifaces[#ifaces]["signal"] = SAVE_MODE
		elseif tonumber(wifidev:get("txpower")) == NORMAL_MODE_TXPOWER then
			ifaces[#ifaces]["signal"] = NORMAL_MODE
		else
			ifaces[#ifaces]["signal"] = PERFORMANCE_MODE
		end

		if( wifinet:get("encryption") == "open") then
			ifaces[#ifaces]["open"] = true
		else
			ifaces[#ifaces]["open"] = false
			ifaces[#ifaces]["key"]   = wifinet:get("key")
		end

		ifaces[#ifaces]["htmode"]     = wifidev:get("htmode")
		ifaces[#ifaces]["hwmode"]     = wifidev:get("hwmode")

		ifaces[#ifaces]["channel"]    = wifidev:get("channel")
		if (wifinet:get("isolate") and wifinet:get("isolate") == "1" ) then
			ifaces[#ifaces]["apartheid"]  = true
		else
			ifaces[#ifaces]["apartheid"]  = false
		end
		if (wifinet:get("hidden") and wifinet:get("hidden") == "1") then
			ifaces[#ifaces]["broadcast"]  = false
		else
			ifaces[#ifaces]["broadcast"]  = true
		end
	end

	local result = {
		code = 0,
		msg = "OK",
		ifaces = ifaces
	}
	nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

--ifaces
function set_wifi_iface_local(ifaces)
	local network = require("luci.model.network").init()
	local device_name
	local wifis = sysutil.sf_wifinetworks()

	for i=1,#ifaces do
		for i, dev in pairs(wifis) do
			wifidev = network:get_wifidev(dev.device)
			wifinet = network:get_wifinet(dev.device..".network1")
			if wifidev:get("band") == ifaces[i]["band"]  then
				wifidev:set("channel", ifaces[i]["channel"])
				wifidev:set("htmode", ifaces[i]["bandwidth"])
				wifinet:set("ssid", ifaces[i]["ssid"])
				wifidev:set("hwmode", ifaces[i]["mode"])
				if ifaces[i]["mode"] == "11b" and wifidev:get("band") == "2.4G" then
					wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["mode"] == "11g" and wifidev:get("band") == "2.4G" then
					wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["mode"] == "11n" and wifidev:get("band") == "2.4G" then
					wifidev:set("hwmode", "11g")
					wifidev:set("ht_coex", 1)
				elseif ifaces[i]["mode"] == "11a" and wifidev:get("band") == "5G" then
					wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["mode"] == "11n" and wifidev:get("band") == "5G" then
					wifidev:set("hwmode", "11a")
					wifidev:set("ht_coex", 1)
				elseif ifaces[i]["mode"] == "11ac" and wifidev:get("band") == "5G" then
					wifidev:set("hwmode", "11a")
					wifidev:set("ht_coex", nil)
				end

				if ifaces[i]["open"] == true then
					wifinet:set("encryption", "open")
				else
					wifinet:set("encryption", "psk2+ccmp")
					wifinet:set("key", ifaces[i]["key"])
				end
				if ifaces[i]["enable"] == true then
					wifinet:set("disabled",  nil );
					wifidev:set("radio", "1")
				else
					wifinet:set("disabled",  "1");
					wifidev:set("radio", "0")
				end

				if ifaces[i]["signal"] == SAVE_MODE then
					wifidev:set("txpower", SAVE_MODE_TXPOWER)
				elseif ifaces[i]["signal"] == NORMAL_MODE then
					wifidev:set("txpower", NORMAL_MODE_TXPOWER)
				elseif ifaces[i]["signal"] == PERFORMANCE_MODE then
					wifidev:set("txpower", PERFORMANCE_MODE_TXPOWER)
				end
				if ifaces[i]["broadcast"] then
					wifinet:set("hidden","0")
				else
					wifinet:set("hidden","1")
				end
				if ifaces[i]["apartheid"] then
					wifinet:set("isolate","1")
				else
					wifinet:set("isolate","0")
				end
			end
		end
	end
	--nixio.syslog("crit", myprint(ifaces))
	local changes = network:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		nixio.syslog("crit","apply changes")
		network:save("wireless")
		network:commit("wireless")
		sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
	end
end
function set_wifi_iface()

	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	set_wifi_iface_local(arg_list_table["ifaces"])

	local result = {
		code = 0,
		msg = "OK"
	}
	--输出log所需变量
	local ifaces=arg_list_table["ifaces"]
	local wifi_5gssid
	local wifi_24gssid
	for i=1,#ifaces do
		if ifaces[i]["band"]=="2.4G" then
			wifi_24gssid=ifaces[i]["ssid"]
		elseif ifaces[i]["band"]=="5G" then
			wifi_5gssid=ifaces[i]["ssid"]
		end
	end
	sysutil.sflog("INFO","wifi iface configure changed!2.4G ssid:%s 5G ssid:%s"%{wifi_24gssid,wifi_5gssid})--输出log
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_customer_wifi_iface()
	local network = require("luci.model.network").init()
	local wifis = sysutil.sf_wifinetworks()
	local ifaces = {}
	local allifaces = {}
	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)
		wifinet = network:get_wifinet(dev.device..".network2")
		if wifinet then
			if wifinet:get("disabled") == "0" or wifinet:get("disabled") == nil then
				ifaces["enable"] = true
			else
				ifaces["enable"] = false
			end
			ifaces["ssid"] = wifinet:get("ssid")
			if( wifinet:get("encryption") == "open") then
				ifaces["open"] = true
			else
				ifaces["open"] = false
				ifaces["key"] = wifinet:get("key")
			end

			if( wifinet:get("network") == "lan") then
				ifaces["localaccess"] = true
			else
				ifaces["localaccess"] = false
			end
			ifaces["band"] = wifidev:get("band")
			ifaces["limitupload"] = tonumber(wifinet:get("limitupload") or 0) --上行速率上限 0表示不限速
			ifaces["limitdownload"] = tonumber(wifinet:get("limitdownload") or 0) --下行速率上限 0表示不限速
			ifaces["limittime"] = wifinet:get("limittime") or false --是否限制时间
			ifaces["limittimetype"] = tonumber(wifinet:get("limittimetype") or 0) --限制类型 0：限制剩余时间， 1：周期性限制时间
			ifaces["remainingtime"] = tonumber(wifinet:get("remainingtime") or 0) --8小时之后关闭访客网络
			-- use cornd
			ifaces["periodicaltime"] = wifinet:get("periodicaltime") or ""

			allifaces[#allifaces + 1] = {}
			allifaces[#allifaces] = ifaces
			ifaces = {}
		end
	end
	local result = {
		code = 0,
		msg = "OK",
		ifaces = allifaces
	}
	nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_customer_wifi_iface()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local ifaces = arg_list_table["ifaces"]
	local wifis = sysutil.sf_wifinetworks()

	for j, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)
		wifinet = network:get_wifinet(dev.device..".network2")
		for i=1,#ifaces do
			if wifidev:get("band") == ifaces[i]["band"] then
				if ifaces[i]["enable"] == true then
					wifinet:set("disabled", "0")
				else
					wifinet:set("disabled", "1")
				end
				wifinet:set("ssid", ifaces[i]["ssid"])
				if(ifaces[i]["open"] == true) then
					wifinet:set("encryption", "open")
				else
					wifinet:set("encryption", "psk2+ccmp")
					wifinet:set("key", ifaces[i]["key"] )
				end

				if( ifaces[i]["localaccess"]) then
					wifinet:set("network", "lan")
				else
					wifinet:set("network", "guest")
				end
				if( ifaces[i]['limitupload']) then
					wifinet:set("limitupload", ifaces[i]['limitupload'])
				end
				if( ifaces[i]['limitdownload']) then
					wifinet:set("limitdownload", ifaces[i]['limitdownload'])
				end
				if( ifaces[i]['limittime']) then
					wifinet:set("limittime", ifaces[i]['limittime'])
				end
				if( ifaces[i]['limittimetype']) then
					wifinet:set("limittimetype", ifaces[i]['limittimetype'])
				end
				if( ifaces[i]['remainingtime']) then
					wifinet:set("remainingtime", ifaces[i]['remainingtime'])
				end
				if( ifaces[i]['periodicaltime']) then
					wifinet:set("periodicaltime", ifaces[i]['periodicaltime'])
				end
			end
		end
	end
	local changes = network:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		nixio.syslog("crit","apply changes")
		network:save("wireless")
		network:commit("wireless")
		sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy; sleep 3; gwifi start")
	end

	local result = {
		code = 0,
		msg = "OK",
	}
	--输出log所需变量
	local ifaces=arg_list_table["ifaces"]
	local wifi_5gssid
	local wifi_24gssid
	for i=1,#ifaces do
		if ifaces[i]["band"]=="2.4G" then
			wifi_24gssid=ifaces[i]["ssid"]
		elseif ifaces[i]["band"]=="5G" then
			wifi_5gssid=ifaces[i]["ssid"]
		end
	end
	sysutil.sflog("INFO","customer wifi iface configure changed!2.4G ssid:%s 5G ssid:%s"%{wifi_24gssid,wifi_5gssid})--输出log
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function wifi_scan()
	local arg_json = luci.http.content()
	local arg_table = json.decode(arg_json)
	local result = {
		code = 0,
		msg = "OK",
		device = "",
		list = {
		--[[
		encryption = {
			enabled = true,
			auth_algs = "",
			description = "WPA2 PSK (CCMP)",
			wep = false,
			auth_suites = "PSK",
			wpa = 2,
			pair_ciphers = "CCMP",
			group_ciphers = "CCMP"
		},
		quality_max = 70,
		ssid = "shiliu",
		channel = 10,
		signal = -49,
		bssid = "B8:86:87:8A:71:18",
		mode = "Master",
		quality = 61
		--]]
		},
		noise = ""
	}
	if arg_table.band == "2.4G" then
		result.device = "radio0"
	elseif arg_table.band == "5G" then
		result.device = "radio1"
	else
		result.code = -1
		result.msg = "Invalid args"
	end

	local iw = luci.sys.wifi.getiwinfo(result.device)
	if iw ~= nil then
		if iw.scanlist ~= nil then
			for _, v in ipairs(iw.scanlist) do
				table.insert(result.list, v)
			end
		end
		result.noise = iw.noise or 0
	end

	nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

nw.init()

--args: channel, ssid, key, encryption
function wifi_connect()
	local arg_json = luci.http.content()
	local arg_table = json.decode(arg_json)
	local result = {
		code = -1,
		msg = "FAIL",
		band = "2.4G",
		ip = "",
	}
	local wifi_if = {
		device = "radio0",
		ifname = "sfi0",
		network = "wwan",
		mode = "sta",
		ssid = "",
		key = "",
		encryption = ""
	}

	if tonumber(arg_table.channel) >= 36 then
		wifi_if.device = "radio1"
		wifi_if.ifname = "sfi1"
		result.band = "5G"
	end
	wifi_if.ssid = arg_table.ssid
	wifi_if.key = arg_table.key
	wifi_if.encryption = arg_table.encryption

	_uci_real:set("network", "lan", "netclash", 1)
	_uci_real:save("network")
	_uci_real:commit("network")

	local wdev = nw:get_wifidev(wifi_if.device)
	if wdev ~= nil then
		wdev:add_wifinet(wifi_if)
		nw:save("wireless")
		nw:commit("wireless")

		_uci_real:set("wireless", wifi_if.device, "channel", arg_table.channel)
		_uci_real:save("wireless")
		_uci_real:commit("wireless")

		nw:add_network(wifi_if.network, { proto = "dhcp", ifname = wifi_if.ifname })
		nw:save("network")
		nw:commit("network")

		result.code = 0
		result.msg = "OK"
	end

	luci.sys.call("/etc/init.d/network reload")

	for i = 10, 1, -1 do
		result.ip = wds_getwanip(result.band)
		if result.ip ~= "nil" then
			break
		end
		luci.sys.call("sleep 1")
	end

	nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)

	return result
end

function wds_getwanip(band)
	local ipaddr = "nil"
	local wifi_if = { deivce = "", ifname = "" }

	if band == "2.4G" then
		wifi_if.device = "radio0"
		wifi_if.ifname = "sfi0"
	elseif band == "5G" then
		wifi_if.device = "radio1"
		wifi_if.ifname = "sfi1"
	end

	local wdev = nw:get_wifidev(wifi_if.device)
	if wdev ~= nil then
		nw.init()
		local wnet = wdev:get_wifinet(wifi_if.ifname)
		if wnet ~= nil then
			local net_wwan = wnet:get_interface()
			local addrs = net_wwan:ipaddrs()
			local addr_t = util.split(tostring(addrs[1]), "/")
			ipaddr = addr_t[1]
		end
	end

	return ipaddr
end

--args: ip is the result.ip got in wifi_connect()
function wds_enable()
	local arg_json = luci.http.content()
	local arg_table = json.decode(arg_json)
	local br_ip = arg_table.ip
	local lanip = _uci_real:get("network", "lan", "ipaddr")
	local redirect_ip = ""
	local result = {
		code = 0,
		msg = "OK",
		redirect = 1
	}

	nw:add_network("stabridge", { proto = "relay", network = "lan wwan", ipaddr = br_ip, disable_dhcp_parse = 1 })
	nw:save("network")
	nw:commit("network")

	if br_ip ~= nil then
		local gw_t = util.split(br_ip, ".")
		if gw_t[1] ~= "nil" then
			local gateway = gw_t[1].."."..gw_t[2].."."..gw_t[3]..".".."1"
			if gateway == lanip then
				local seg = tonumber(gw_t[3]) + 1
				lanip = gw_t[1].."."..gw_t[2].."."..seg..".".."1"
				_uci_real:set("network", "lan", "netclash", 1)
				redirect_ip = lanip
			end
			_uci_real:save("network")
			_uci_real:commit("network")
		end
	end

	_uci_real:set("dhcp", "lan", "ignore", 1)
	_uci_real:save("dhcp")
	_uci_real:commit("dhcp")

	_uci_real:foreach("firewall","zone",
	function(s)
		if (s["name"] == "lan") then
			_uci_real:set("firewall", s[".name"], "forward", "ACCEPT")
			_uci_real:set("firewall", s[".name"], "network", "lan wwan")
		end
	end)
	_uci_real:save("firewall")
	_uci_real:commit("firewall")

	if (arg_table.ifaces) then
		local ifname = ""
		if arg_table.ifaces.band == "2.4G" then
			ifname = "wlan0"
		elseif arg_table.ifaces.band == "5G" then
			ifname = "wlan1"
		end
		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == ifname) then
				_uci_real:set("wireless", s[".name"], "ssid", arg_table.ifaces.ssid)
				_uci_real:set("wireless", s[".name"], "key", arg_table.ifaces.key)
			end
		end)
		_uci_real:save("wireless")
		_uci_real:commit("wireless")
	end

	luci.sys.call("/etc/init.d/relayd enable")
	if redirect_ip ~= "" then
		sysutil.fork_exec("sleep 1;uci set network.lan.ipaddr=%s;uci commit network;/etc/init.d/network restart" % redirect_ip)
	else
		sysutil.fork_exec("sleep 1;/etc/init.d/network restart")
	end

	nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","wds enable configure changed! status:enable %s"%{br_ip})
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function wds_disable()
	local result = {
		code = 0,
		msg = "OK",
		ip = ""
	}
	local arg_json = luci.http.content()
	local arg_table = json.decode(arg_json)

	-- list or option?
	_uci_real:foreach("firewall","zone",
	function(s)
		if(s["name"] == "lan") then
			_uci_real:set("firewall", s[".name"], "network", "lan")
		end
	end)
	_uci_real:save("firewall")
	_uci_real:commit("firewall")

	_uci_real:delete("dhcp", "lan", "ignore")
	_uci_real:save("dhcp")
	_uci_real:commit("dhcp")

	nw:del_network("stabridge")
	nw:del_network("wwan")
	nw:save("network")
	nw:commit("network")

	nw:del_wifinet("sfi0")
	nw:del_wifinet("rai0")
	nw:del_wifinet("sfi1")
	nw:del_wifinet("rai1")
	nw:save("wireless")
	nw:commit("wireless")

	if arg_table.redirect == 1 then
		result.ip = _uci_real:get("network", "lan", "ipaddr")
		sysutil.fork_exec("sleep 1;/etc/init.d/network restart;uci set network.lan.netclash=0;uci commit network")
	else
		luci.sys.call("/etc/init.d/network reload;uci set network.lan.netclash=0;uci commit network")
	end

	sysutil.sflog("INFO","wds disable configure changed! status:disable")
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)

end

function get_wds_info()
	local ifname0 = "sfi0"
	local ifname1 = "sfi1"
	local info = {}
	info[ #info + 1] = {}
	info[ #info ] = {
		band="2.4G",
		ssid= "",
		key = "",
		bssid = "",
		enable = "0",
	}
	info[ #info + 1] = {}
	info[ # info  ] = {
		band="5G",
		ssid= "",
		key = "",
		bssid = "",
		enable = "0",
	}
	info[ #info + 1] = {}
	info[ # info  ] = {
		band="2.4G",
		ssid= "",
		key = "",
		ip = "",
		channel = ""
	}
	info[ #info + 1] = {}
	info[ # info  ] = {
		band="5G",
		ssid= "",
		key = "",
		ip = "",
		channel = ""
	}
	info[ #info + 1] = {}
	info[ # info  ] = {
		lanip=""
	}

	result = {
		code = 0,
		msg = "OK",
		info = info
	}

	local wdev = nw:get_wifidev("radio0")
	if wdev ~= nil then
		nw.init()
		local wnet = wdev:get_wifinet("sfi0")
		if wnet == nil then
			wnet = wdev:get_wifinet("rai0")
			if wnet ~= nil then
				ifname0 = "rai0"
			end
		end
		if wnet ~= nil then
			local net_wwan = wnet:get_interface()
			local addrs = net_wwan:ipaddrs()
			local addr_t = util.split(tostring(addrs[1]), "/")
			info[3].ip = addr_t[1]
		end
	end

	local wdev = nw:get_wifidev("radio1")
	if wdev ~= nil then
		nw.init()
		local wnet = wdev:get_wifinet("sfi1")
		if wnet == nil then
			wnet = wdev:get_wifinet("rai1")
			if wnet ~= nil then
				ifname1 = "rai1"
			end
		end
		if wnet ~= nil then
			local net_wwan = wnet:get_interface()
			local addrs = net_wwan:ipaddrs()
			local addr_t = util.split(tostring(addrs[1]), "/")
			info[4].ip = addr_t[1]
		end
	end
	if info[3].ip ~= "" then
		info[1].enable = "1"
	end
	if info[4].ip ~= "" then
		info[2].enable = "1"
	end

	local iw = luci.sys.wifi.getiwinfo("radio0")
	if iw ~= nil then
		info[1].ssid = iw.ssid
		info[1].bssid = iw.bssid
		info[1].key = iw.key

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "wlan0") then
				info[1].key = s["key"]
			end
		end)
	end

	iw = luci.sys.wifi.getiwinfo("radio1")
	if iw ~= nil then
		info[2].ssid = iw.ssid
		info[2].bssid = iw.bssid
		info[2].key = iw.key

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "wlan1") then
				info[2].key = s["key"]
			end
		end)
	end

	iw = luci.sys.wifi.getiwinfo(ifname0)
	if iw ~= nil then
		info[3].ssid = iw.ssid
		info[3].channel = iw.channel

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == ifname0) then
				info[3].key = s["key"]
			end
		end)
	end

	iw = luci.sys.wifi.getiwinfo(ifname1)
	if iw ~= nil then
		info[4].ssid = iw.ssid
		info[4].channel = iw.channel

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == ifname1) then
				info[4].key = s["key"]
			end
		end)

	end
	info[5].lanip = _uci_real:get("network", "lan", "ipaddr")
	local wanip = ""
	if info[1].enable == "1" then
		wanip = info[3].ip
	elseif info[2].enable == "1" then
		wanip = info[4].ip
	end

	if wanip ~= "" then
		local gw_t = util.split(wanip, ".")
		if gw_t[1] ~= "nil" then
			local gateway = gw_t[1].."."..gw_t[2].."."..gw_t[3]..".".."1"
			if gateway == info[5].lanip then
				local seg = tonumber(gw_t[3]) + 1
				info[5].lanip = gw_t[1].."."..gw_t[2].."."..seg..".".."1"
			end
		end
	end

	nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function wds_is_enabled()
	local wdev = nw:get_wifidev("radio0")
	if wdev ~= nil then
		nw.init()
		local wnet = wdev:get_wifinet("sfi0")
		if wnet == nil then
			wnet = wdev:get_wifinet("rai0")
		end
		if wnet ~= nil then
			local net_wwan = wnet:get_interface()
			if net_wwan then
				return 1
			end
		end
	end

	local wdev = nw:get_wifidev("radio1")
	if wdev ~= nil then
		nw.init()
		local wnet = wdev:get_wifinet("sfi1")
		if wnet == nil then
			wnet = wdev:get_wifinet("rai1")
		end
		if wnet ~= nil then
			local net_wwan = wnet:get_interface()
			if net_wwan then
				return 1
			end
		end
	end

	return 0
end
