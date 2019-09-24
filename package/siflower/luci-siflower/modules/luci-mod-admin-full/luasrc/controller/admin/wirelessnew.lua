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

local SAVE_MODE_TXPOWER = 0
local NORMAL_MODE_TXPOWER = 1
local PERFORMANCE_MODE_TXPOWER = 2

module("luci.controller.admin.wirelessnew", package.seeall)
local nw = require "luci.model.network"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local sysutil = require "luci.siwifi.sf_sysutil"
local json = require("luci.json")
local util = require("luci.util")
local sysutil = require("luci.siwifi.sf_sysutil")
local sferr = require "luci.siwifi.sf_error"
local wirelessImpl = require ("luci.siwifi.wirelessImpl")

function index()

	local uci = require "luci.model.uci"
	local _uci_real  = cursor or _uci_real or uci.cursor()
	local no_wifi = _uci_real:get("basic_setting", "no_wifi", "enable") == "1" and true or false
	local wirelessnew = require "luci.controller.admin.wirelessnew"
	if (no_wifi == false) then
		entry({"admin", "wirelessnew"}, firstchild(), _("Wireless"), 61).logo = "wireless";
		entry({"admin", "wirelessnew", "owner"}, template("new_siwifi/wireless_settings/owner") , _("host network"), 2);
		entry({"admin", "wirelessnew", "visitor"}, template("new_siwifi/wireless_settings/visitor") , _("visitor network"), 3);
		if (wirelessnew.wds_is_enabled() > 0) then
			entry({"admin", "wirelessnew", "wds"}, template("new_siwifi/wireless_settings/wds") , _("WDS"), 1);
		else
			entry({"admin", "wirelessnew", "wds"}, template("new_siwifi/wireless_settings/wds") , _("WDS"), 4);
		end
	else
		entry({"admin", "wirelessnew"}, firstchild());
	end
	entry({"admin", "wirelessnew", "wifi_scan"}, call("wifi_scan")).leaf = true;
	entry({"admin", "wirelessnew", "wifi_connect"}, call("wifi_connect")).leaf = true;
	entry({"admin", "wirelessnew", "wds_getrelip"}, call("wds_getrelip")).leaf = true;
	entry({"admin", "wirelessnew", "wds_enable"}, call("wds_enable")).leaf = true;
	entry({"admin", "wirelessnew", "wds_disable"}, call("wds_disable")).leaf = true;
	entry({"admin", "wirelessnew", "get_wds_info"}, call("get_wds_info")).leaf = true;
	entry({"admin", "wirelessnew", "get_wifi_iface"}, call("get_wifi_iface")).leaf = true;
	entry({"admin", "wirelessnew", "set_wifi_iface"}, call("set_wifi_iface")).leaf = true;
	entry({"admin", "wirelessnew", "wds_sta_is_disconnected"}, call("wds_sta_is_disconnected")).leaf = true;
	entry({"admin", "wirelessnew", "get_customer_wifi_iface"}, call("get_customer_wifi_iface")).leaf = true;
	entry({"admin", "wirelessnew", "set_customer_wifi_iface"}, call("set_customer_wifi_iface")).leaf = true;

	entry({"admin", "wirelessnew", "set_freq_intergration"}, call("set_freq_intergration")).leaf = true;
	entry({"admin", "wirelessnew", "get_freq_intergration"}, call("get_freq_intergration")).leaf = true;
	entry({"admin", "wirelessnew", "get_monitor"}, call("get_monitor")).leaf = true;
	entry({"admin", "wirelessnew", "set_monitor"}, call("set_monitor")).leaf = true;
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

		if tonumber(wifidev:get("txpower_lvl")) == SAVE_MODE_TXPOWER then
			ifaces[#ifaces]["signal"] = SAVE_MODE
		elseif tonumber(wifidev:get("txpower_lvl")) == NORMAL_MODE_TXPOWER then
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

		local htcoex = wifidev:get("ht_coex")
		if (htcoex == "1" and wifidev:get("band") == "2.4G") then
			ifaces[#ifaces]["htmode"] = "auto"
		else
			ifaces[#ifaces]["htmode"]     = wifidev:get("htmode")
		end
		ifaces[#ifaces]["hwmode"]     = wifidev:get("hwmode")
		if( wifidev:get("band") == "5G") then
			if (ifaces[#ifaces]["htmode"] == "HT20" or ifaces[#ifaces]["htmode"] == "HT40") then
				ifaces[#ifaces]["hwmode"] = "11n"
			elseif (ifaces[#ifaces]["htmode"] == "VHT20" or ifaces[#ifaces]["htmode"] == "VHT40" or ifaces[#ifaces]["htmode"] == "VHT80") then
				ifaces[#ifaces]["hwmode"] = "11ac"
			end
		end

		ifaces[#ifaces]["country"]    = wifidev:get("country")
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

function get_monitor()
    local result = {}
    local code = 0
    local enable = _uci_real:get("basic_setting", "kerHealth", "enable")
    if enable == nil then
        result["enable"] = 0
    else
        result["enable"] = enable
    end
    sysutil.set_easy_return(code, result)
end

function set_monitor()
	local arg_list_table = get_arg_list()
    local enable = arg_list_table["enable"]

    local code = 0
    local sta = _uci_real:get("basic_setting", "kerHealth", "enable")
    if sta == nil then
        _uci_real:set("basic_setting", "kerHealth", "setting")
    end
    if enable ~= sta then
        _uci_real:set("basic_setting", "kerHealth", "enable", enable)
        _uci_real:save("basic_setting")
        _uci_real:commit("basic_setting")
        luci.util.exec("/etc/init.d/syncservice restart")
    end
    sysutil.set_easy_return(code, nil)
end

--ifaces
function set_wifi_iface_local(ifaces)
	local network = require("luci.model.network").init()
	local device_name
	local wifis = sysutil.sf_wifinetworks()
	local freq_inter = get_freq_intergration_impl()
	local wdev_2= network:get_wifidev("radio0")
	local wifinet_24g = wdev_2:get_wifinet("wlan0")
	for i=1,#ifaces do
		for j, dev in pairs(wifis) do
			wifidev = network:get_wifidev(dev.device)
			wifinet = network:get_wifinet(dev.device..".network1")
			if wifidev:get("band") == ifaces[i]["band"]  then
				wifidev:set("country", ifaces[i]["country"])
				wifidev:set("channel", ifaces[i]["channel"])

				if ( ifaces[i]["htmode"] ~= "auto") then
					wifidev:set("htmode", ifaces[i]["htmode"])
				end
				if not (ifaces[i]["band"]  == "2.4G" and freq_inter == 1) then
					wifinet:set("ssid", ifaces[i]["ssid"])
					if ifaces[i]["open"] == true then
						wifinet:set("encryption", "open")
					else
						wifinet:set("encryption", "psk2+ccmp")
						wifinet:set("key", ifaces[i]["key"])
					end

					if ifaces[i]["enable"] == true then
						wifinet:set("disabled",  nil );
					else
						wifinet:set("disabled",  "1");
					end
					if ifaces[i]["broadcast"] then
						wifinet:set("hidden","0")
					else
						wifinet:set("hidden","1")
					end
					if freq_inter == 1  then
						wifinet_24g:set("ssid", ifaces[i]["ssid"])
						if ifaces[i]["open"] == true then
							wifinet_24g:set("encryption", "open")
						else
							wifinet_24g:set("encryption", "psk2+ccmp")
							wifinet_24g:set("key", ifaces[i]["key"])
						end
						if ifaces[i]["enable"] == true then
							wifinet_24g:set("disabled",  nil );
						else
							wifinet_24g:set("disabled",  "1");
						end
						if ifaces[i]["broadcast"] then
							wifinet_24g:set("hidden","0")
						else
							wifinet_24g:set("hidden","1")
						end
					end
				end

				wifidev:set("hwmode", ifaces[i]["hwmode"])
				if ifaces[i]["hwmode"] == "11b" and wifidev:get("band") == "2.4G" then
					wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["hwmode"] == "11g" and wifidev:get("band") == "2.4G" then
					--wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["hwmode"] == "11n" and wifidev:get("band") == "2.4G" then
					wifidev:set("hwmode", "11g")
					if ( ifaces[i]["htmode"] == "auto") then
						wifidev:set("ht_coex", "1")
						wifidev:set("htmode", "HT40")
						wifidev:set("noscan", "0")
					else
						if ( ifaces[i]["htmode"] == "HT40") then
							wifidev:set("noscan", "1")
						end
						wifidev:set("ht_coex", "0")
					end
				elseif ifaces[i]["hwmode"] == "11a" and wifidev:get("band") == "5G" then
					wifidev:set("htmode", nil)
					wifidev:set("ht_coex", nil)
				elseif ifaces[i]["hwmode"] == "11n" and wifidev:get("band") == "5G" then
					wifidev:set("hwmode", "11a")
					wifidev:set("ht_coex", 0)
				elseif ifaces[i]["hwmode"] == "11ac" and wifidev:get("band") == "5G" then
					wifidev:set("hwmode", "11a")
					wifidev:set("ht_coex", 0)
				end

				if ifaces[i]["signal"] == SAVE_MODE then
					wifidev:set("txpower_lvl", SAVE_MODE_TXPOWER)
				elseif ifaces[i]["signal"] == NORMAL_MODE then
					wifidev:set("txpower_lvl", NORMAL_MODE_TXPOWER)
				elseif ifaces[i]["signal"] == PERFORMANCE_MODE then
					wifidev:set("txpower_lvl", PERFORMANCE_MODE_TXPOWER)
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
	sysutil.sflog("INFO","wifi iface configure changed!2.4G ssid: 5G ssid")--输出log
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_customer_wifi_iface()
	local ifaces = {}
	local code = 0
	code,ifaces = wirelessImpl.get_customer_wifi_iface()
	nixio.syslog("crit", myprint(ifaces))
	sysutil.set_easy_return(code, ifaces)
end

function set_customer_wifi_iface()
	local arg_list_table = get_arg_list()
	local code = 0
	code = wirelessImpl.set_customer_wifi_iface(arg_list_table)
	sysutil.set_easy_return(code, nil)
end

function wifi_scan()
	local arg_list_table = get_arg_list()
	local result = {}
	local code = 0
	code,result = wirelessImpl.wifi_scan(arg_list_table)
	nixio.syslog("crit", myprint(result))
	sysutil.set_easy_return(code, result)
end

nw.init()

--args: channel, ssid, key, encryption
function wifi_connect()
	local arg_list_table = get_arg_list()
	local result = {}
	local code = 0
	code,result = wirelessImpl.wifi_connect(arg_list_table)
	nixio.syslog("crit", myprint(result))
	sysutil.set_easy_return(code, result)
	return result
end
function wds_getrelip()
	local arg_list_table = get_arg_list()
	local result = {}
	local code = 0
	code,result = wirelessImpl.wds_getrelip(arg_list_table)
	nixio.syslog("crit", myprint(result))
	sysutil.set_easy_return(code, result)
end

--args: ip is the result.ip got in wifi_connect()
function wds_enable()
	local arg_list_table = get_arg_list()
	local result = {}
	local code = 0
	code,result = wirelessImpl.wds_enable(arg_list_table)
	nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","wds enable configure changed!")
	return code, result
end

function wds_disable()
	local result = {}
	local code = 0
	local arg_list_table = get_arg_list()
	code,result = wirelessImpl.wds_disable(arg_list_table)
	sysutil.sflog("INFO","wds disable configure changed! status:disable")
	sysutil.set_easy_return(code, result)
end

function get_wds_info()
	local result = {}
	local code = 0
	code,result = wirelessImpl.get_wds_info()
	nixio.syslog("crit", myprint(result))
	sysutil.set_easy_return(code, result)
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
				return 2
			end
		end
	end

	return 0
end

function wds_sta_is_disconnected()
	local code = 0
	code = wirelessImpl.wds_sta_is_disconnected()
	sysutil.set_easy_return(code, nil)
end

function set_freq_intergration_impl(arg_list_table)
	local enable = arg_list_table["enable"]
	local network = require("luci.model.network").init()
	local wdev_5= network:get_wifidev("radio1")
	local wdev_2 = network:get_wifidev("radio0")
	local wifinet_5 = wdev_5:get_wifinet("wlan1")
	local wifinet_2 = wdev_2:get_wifinet("wlan0")
	local wifinet_master = wifinet_5
	local wifinet_slave = wifinet_2
	local suffix = "-2.4G"
	-- mapping interface

	if wds_is_enabled() == 1 then
		wifinet_master = wifinet_2
		wifinet_slave = wifinet_5
		suffix = "-5G"
	end

	if(enable == 1) then

		if (wifinet_master:get("cond_hidden") == 1) then
			return
		end
		wifinet_master:set("cond_hidden","1")
		local ssid = wifinet_master:get("ssid")
		local encryption = wifinet_master:get("encryption")
		local key = nil
		if encryption ~=  "open" then
			key = wifinet_master:get("key")
		end

		if (wifinet_master:get("disabled") == nil) or (wifinet_slave:get("disabled") == nil) then
			wifinet_slave:set("disabled",nil)
			wifinet_master:set("disabled",nil)
		end
		wifinet_slave:set("cond_hidden","1")
		wifinet_slave:set("ssid",ssid )
		wifinet_slave:set("encryption",encryption )
		if key  then
			wifinet_slave:set("key",key )
		end

	else
		if (tonumber(wifinet_master:get("cond_hidden")) ~= 1) then
			return
		end
		wifinet_master:set("cond_hidden","0")
		local ssid = wifinet_master:get("ssid")

		wifinet_slave:set("cond_hidden","0")
		if(string.len(ssid) < 28) then
			wifinet_slave:set("ssid",ssid..suffix )
		else
			wifinet_slave:set("ssid",string.sub(ssid,0,-6)..suffix)
		end
	end
	local changes = network:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		nixio.syslog("crit","freq integration apply changes")
		network:save("wireless")
		network:commit("wireless")
		sysutil.fork_exec("sleep 1; env -i; /etc/init.d/advanced_wifi restart; ubus call network reload;")
	end

end

function set_freq_intergration()
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	set_freq_intergration_impl(arg_list_table)
	sysutil.set_easy_return(code,nil);
end

function get_freq_intergration_impl()
	local network = require("luci.model.network").init()
	-- mapping interface
	local wdev_5= network:get_wifidev("radio1")
	-- AC wdev_5 is nil
	if not wdev_5 then
		return 0
	end
	wifinet = wdev_5:get_wifinet("wlan1")
	if(tonumber(wifinet:get("cond_hidden")) == 1) then
		return 1
	else
		return 0
	end
end

function get_freq_intergration()
	local network = require("luci.model.network").init()
	local code = 0
	local result = {}
	-- mapping interface
	result["enable"] = get_freq_intergration_impl()
	sysutil.set_easy_return(code,result);
end
function get_arg_list()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	return arg_list_table
end
