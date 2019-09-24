--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/7
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.wirelessp", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require "luci.json"
local fs  = require "nixio.fs"
local sferr = require "luci.siwifi.sf_error"
ipc = require "luci.ip"
sysp = require "luci.controller.admin.systemp"

local SAVE_MODE = 0
local NORMAL_MODE = 1
local PERFORMANCE_MODE = 2

local SAVE_MODE_TXPOWER = 5
local NORMAL_MODE_TXPOWER = 10
local PERFORMANCE_MODE_TXPOWER = 20

function index()
    entry({"admin", "wirelessp"}, template("86v/wireless"), _("Wireless"), 61).attrid = "wireless";
    entry({"admin", "wirelessp", "get_wireless_net"}, call("get_wireless_net")).leaf = true;
    entry({"admin", "wirelessp", "set_wireless_net"}, call("set_wireless_net")).leaf = true;
    entry({"admin", "wirelessp", "add_wireless_net"}, call("add_wireless_net")).leaf = true;
    entry({"admin", "wirelessp", "del_wireless_net"}, call("del_wireless_net")).leaf = true;
	entry({"admin", "wirelessp", "get_wireless_advance"}, call("get_wireless_advance")).leaf = true;
	entry({"admin", "wirelessp", "set_wireless_advance"}, call("set_wireless_advance")).leaf = true;
    entry({"admin", "wirelessp", "get_spec_info"}, call("get_spec_info")).leaf = true;
    entry({"admin", "wirelessp", "set_spec_info"}, call("set_spec_info")).leaf = true;
end

function sf_wifinetworks()
	local rv = {  }
	local ntm = require "luci.model.network".init()

	local dev
	for _, dev in ipairs(ntm:get_wifidevs()) do
		local rd = {
		up       = dev:is_up(),
		device   = dev:name(),
		name     = dev:get_i18n(),
		networks = {  }
		}

		local net
		for _, net in ipairs(dev:get_wifinets()) do
			rd.networks[#rd.networks+1] = {
				name       = net:shortname(),
				link       = net:adminlink(),
				up         = net:is_up(),
				mode       = net:active_mode(),
				ssid       = net:active_ssid(),
				bssid      = net:active_bssid(),
				encryption = net:active_encryption(),
				frequency  = net:frequency(),
				channel    = net:channel(),
				signal     = net:signal(),
				quality    = net:signal_percent(),
				noise      = net:noise(),
				bitrate    = net:bitrate(),
				ifname     = net:ifname(),
				assoclist  = net:assoclist(),
				country    = net:country(),
				txpower    = net:txpower(),
				txpoweroff = net:txpower_offset(),
				password   = net:get("key"),
				disable    = net:get("disabled"),
				encryption_src = net:get("encryption")
			}
		end

		rv[#rv+1] = rd
	end

	return rv
end

-- change
-- ifname= "wlan0"  name = "", encode = "", group= "", encrypt = "", password = "", isolate= "", enable = "", broadcast= ""
function set_wireless_net()
	local wifis = sf_wifinetworks()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local band2 = arg_list_table["band2"]
	local band5 = arg_list_table["band5"]
	local code = 0
	local result = {
		code = 0,
		msg = "OK"
	}

	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)

		if band2 then
			if wifidev:get("band") == "2.4G" then
				for _, net in ipairs(wifidev:get_wifinets()) do
					if  net:ifname() == band2["ifname"] then
						net:set("encode", band2["encode"])
						if band2["group"] == '1' then
							net:set("group", band2["group"])
							net:set("disable_input", 0)
						else
							net:set("group", band2["group"])
							net:set("disable_input", 1)
						end
						net:set("ssid", band2["name"])
						net:set("encryption", band2["encrypt"])
						if band2["encrypt"] ~= "none" then
							if #band2["password"] < 8 or #band2["password"] > 63 then
								code = sferr.ERROR_NO_INVALID_PASSWORD
								break
							else
								net:set("key", band2["password"])
							end
						else
							net:set("key", "")
						end
						net:set("isolate", band2["isolate"])
						net:set("disabled", band2["enable"] ~= '1' and 1 or 0)
						net:set("hidden", band2["broadcast"] == false and 1 or 0)
					end
				end
			end
		end

		if band5 then
			if wifidev:get("band") == "5G" then
				for _, net in ipairs(wifidev:get_wifinets()) do
					if  net:ifname() == band5["ifname"] then
						net:set("encode", band5["encode"])
						if band5["group"] == '1' then
							net:set("group", band5["group"])
							net:set("disable_input", 0)
						else
							net:set("group", band5["group"])
							net:set("disable_input", 1)
						end
						net:set("ssid", band5["name"])
						net:set("encryption", band5["encrypt"])
						if band5["encrypt"] ~= "none" then
							if #band5["password"] < 8 or #band5["password"] > 63 then
								code = sferr.ERROR_NO_INVALID_PASSWORD
								break
							else
								net:set("key", band5["password"])
							end
						else
							net:set("key", "")
						end
						net:set("isolate", band5["isolate"])
						net:set("disabled", band5["enable"] ~= '1' and 1 or 0)
						net:set("hidden", band5["broadcast"] == false and 1 or 0)
					end
				end
			end
		end
	end

	local changes = network:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil) and (result["code"] == 0)) then
		network:save("wireless")
		network:commit("wireless")
		sysp.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
	end
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	sysp.sflog("INFO","wireless configure changed!")
	sysp.sflog("INFO",arg_list)
    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function validate_ifname()
	local flag = 0
	for i=0, 7 do
		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if i == tonumber(string.sub(s.ifname, -1)) then
				flag = 1
			end
		end)

		if flag == 0 then
			return "wlan"..i
		end
		flag = 0
	end
end

function add_wireless_net()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local band2 = arg_list_table["band2"]
	local band5 = arg_list_table["band5"]
	local code = 0
	local result = {
		code = 0,
		msg = "OK"
	}

	local num_24g = 0
	local num_5g = 0
    _uci_real:foreach("wireless","wifi-iface",
    function(s)
		if s.device == "radio0" then
			num_24g = num_24g + 1
		elseif s.device == "radio1" then
			num_5g = num_5g + 1
		end
	end)

	for i=1,1 do
		if band2 and num_24g < 4 or band5 and num_5g < 4 then
			if band2 then
				if band2["encrypt"] ~= "none" and #band2["password"] < 8 or #band2["password"] > 63 then
					code = sferr.ERROR_NO_INVALID_PASSWORD
					break
				end

				wifidev = network:get_wifidev("radio0")
				if band2["group"] == '1' then
					group = 1 -- 1 for employee 2 for visitor
					disable_input = 0
				else
					group = 2
					disable_input = 1
				end

				local ifname = validate_ifname()
				local band2_net = {
					ifname = ifname,
					mode = "ap",
					network = "lan",
					macfilter = "disable",
					macfile = "/etc/wlan-file/"..ifname..".allow",
					group = group,
					disable_input = disable_input,
					encode = band2["encode"],
					ssid = band2["name"],
					encryption = band2["encrypt"],
					key = band2["password"],
					isolate = band2["isolate"],
					netisolate = tonumber(wifidev:get("netisolate")),
					disabled = band2["enable"] ~= '1' and 1 or 0,
					hidden = band2["broadcast"] == false and 1 or 0
				}
				if band2["encrypt"] == "none" then
					band2_net["key"] = ""
				end
				wifidev:add_wifinet(band2_net)
			end

			if band5 then
				if band5["encrypt"] ~= "none" and #band5["password"] < 8 or #band5["password"] > 63 then
					code = sferr.ERROR_NO_INVALID_PASSWORD
					break
				end

				wifidev = network:get_wifidev("radio1")
				if band5["group"] == '1' then
					group = 1 -- 1 for employee 2 for visitor
					disable_input = 0
				else
					group = 2
					disable_input = 1
				end

				local ifname = validate_ifname()
				local band5_net = {
					ifname = ifname,
					mode = "ap",
					network = "lan",
					macfilter = "disable",
					macfile = "/etc/wlan-file/"..ifname..".allow",
					group = group,
					disable_input = disable_input,
					encode = band5["encode"],
					ssid = band5["name"],
					encryption = band5["encrypt"],
					key = band5["password"],
					isolate = band5["isolate"],
					netisolate = tonumber(wifidev:get("netisolate")),
					disabled = band5["enable"] ~= '1' and 1 or 0,
					hidden = band5["broadcast"] == false and 1 or 0
				}
				if band5["encrypt"] == "none" then
					band5_net["key"] = ""
				end
				wifidev:add_wifinet(band5_net)
			end

			local changes = network:changes()
			if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
				network:save("wireless")
				network:commit("wireless")
				sysp.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
			end
		else
			code = sferr.ERROR_NO_WIFI_OUT_OF_LIMIT
		end
	end
	--nixio.sysl
	--og("crit", myprint(result))
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	sysp.sflog("INFO","Add wireless network!")
	sysp.sflog("INFO",arg_list)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function del_wireless_net()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local band2 = arg_list_table["band2"]
	local band5 = arg_list_table["band5"]

	if band2 then
		wifidev = network:get_wifidev("radio0")
		wifinet = network:get_wifinet(band2["ifname"])
		if wifinet then
			wifidev:del_wifinet(wifinet)
		end
	end

	if band5 then
		wifidev = network:get_wifidev("radio1")
		wifinet = network:get_wifinet(band5["ifname"])
		if wifinet then
			wifidev:del_wifinet(wifinet)
		end
	end

    result = {
        code = 0,
        msg = "OK"
    }

	local changes = network:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		network:save("wireless")
		network:commit("wireless")
		sysp.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
	end

    --nixio.syslog("crit", myprint(result))
	sysp.sflog("INFO","Delete wireless network!")
	sysp.sflog("INFO",arg_list)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_wireless_net()
	local band2 = {}
	local band5 = {}

	_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.device == "radio0" then
				band2[#band2 + 1] = {
					name = s.ssid,
					ifname = s.ifname,
					encode = "UTF-8",
					group = s.group,
					encrypt = s.encryption,
					password = s.key,
					isolate = s.isolate,
					enable = s.disabled ~= '1' and 1 or 0,
					broadcast = s.hidden ~= '1' and true or false
				}
			elseif s.device == "radio1" then
				band5[#band5 + 1] = {
					name = s.ssid,
					ifname = s.ifname,
					encode = "UTF-8",
					group = s.group,
					encrypt = s.encryption,
					password = s.key,
					isolate = s.isolate,
					enable = s.disabled ~= '1' and 1 or 0,
					broadcast = s.hidden ~= '1' and true or false
				}
			end
		end)

	local result = {
		code = 0,
		msg = "OK",
		band2 = band2,
		band5 = band5
	}

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_wireless_advance()
	local wifis = sf_wifinetworks()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local band2 = arg_list_table["band2"]
	local band5 = arg_list_table["band5"]
    result = {
        code = 0,
        msg = "OK",
    }

	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)

		if wifidev:get("band") == "2.4G" then
			if band2.htmode ~= "auto" then
				wifidev:set("htmode", band2.htmode)
			end

			wifidev:set("hwmode", band2.hwmode)
			if band2.hwmode == "11b" then
				wifidev:set("htmode", nil)
				wifidev:set("ht_coex", nil)
			elseif band2.hwmode == "11g" then
				wifidev:set("htmode", nil)
				wifidev:set("ht_coex", nil)
			elseif band2.hwmode == "11n" then
				wifidev:set("hwmode", "11g")
				if band2.htmode == "auto" then
					wifidev:set("htmode", "HT40")
					wifidev:set("ht_coex", "1")
					wifidev:set("noscan", "0")
				else
					if band2.htmode == "HT40" then
						wifidev:set("noscan", "1")
					end
					wifidev:set("ht_coex", "0")
				end
			end

			wifidev:set("channel", band2.channel)


			if band2.signal_strength == SAVE_MODE then
			   wifidev:set("txpower", SAVE_MODE_TXPOWER)
			elseif band2.signal_strength == NORMAL_MODE then
			   wifidev:set("txpower", NORMAL_MODE_TXPOWER)
			elseif band2.signal_strength == PERFORMANCE_MODE then
			   wifidev:set("txpower", PERFORMANCE_MODE_TXPOWER)
			end

			wifidev:set("beacon_int", band2.beacon_int)
			if band2.isolate ~= wifidev:get("netisolate") then
				wifidev:set("netisolate", band2.isolate)
				_uci_real:foreach("wireless","wifi-iface",
				function(s)
					if(s["device"] == "radio0") then
						_uci_real:set("wireless", s[".name"], "netisolate", band2.isolate)
					end
				end)
			end
			if band2.maxassoc then
				wifidev:set("max_all_num_sta", band2.maxassoc)
			end

			if band2.enable_prevent == '1' then
				wifidev:set("prohibit_weak_sig_sta_enable", 1);
				if band2.sta_min_dbm then
					wifidev:set("sta_min_dbm", band2.sta_min_dbm)
				end
			else
				wifidev:set("prohibit_weak_sig_sta_enable", 0);
			end

			if band2.enable_kick == '1' then
				wifidev:set("disassociate_weak_sig_sta_enable", 1);
				if band2.weak_sta_signal then
					wifidev:set("weak_sta_signal", band2.weak_sta_signal)
				end
			else
				wifidev:set("disassociate_weak_sig_sta_enable", 0);
			end
		elseif wifidev:get("band") == "5G" then
			if band5.channel == 165 and band5.htmode ~= "VHT20" and band5.htmode ~= "HT20" then
				result["code"] = sferr.ERROR_NO_CHANNEL_NOT_MATCH_HTMODE
				result["msg"] = sferr.getErrorMessage(result["code"])
			end
			if band5.htmode ~= "auto" then
				wifidev:set("htmode", band5.htmode)
			end

			wifidev:set("hwmode", band5.hwmode)
			if band5.hwmode == "11a" then
				wifidev:set("htmode", nil)
				wifidev:set("ht_coex", nil)
			elseif band5.hwmode == "11n" then
				wifidev:set("hwmode", "11a")
				if band5.htmode == "auto" then
					wifidev:set("htmode", "HT40")
					wifidev:set("ht_coex", "1")
					wifidev:set("noscan", "0")
				else
					if band5.htmode == "HT40" then
						wifidev:set("noscan", "1")
					end
					wifidev:set("ht_coex", "0")
				end
			elseif band5.hwmode == "11ac" then
				wifidev:set("hwmode", "11a")
				if band5.htmode == "VHT80" then
					wifidev:set("noscan", "1")
				end
				wifidev:set("ht_coex", "0")
			end

			if band5.signal_strength == SAVE_MODE then
			   wifidev:set("txpower", SAVE_MODE_TXPOWER)
			elseif band5.signal_strength == NORMAL_MODE then
			   wifidev:set("txpower", NORMAL_MODE_TXPOWER)
			elseif band5.signal_strength == PERFORMANCE_MODE then
			   wifidev:set("txpower", PERFORMANCE_MODE_TXPOWER)
			end

			wifidev:set("channel", band5.channel)
			wifidev:set("beacon_int", band5.beacon_int)
			if band5.isolate ~= wifidev:get("netisolate") then
				wifidev:set("netisolate", band5.isolate)
				_uci_real:foreach("wireless","wifi-iface",
				function(s)
					if(s["device"] == "radio1") then
						_uci_real:set("wireless", s[".name"], "netisolate", band5.isolate)
					end
				end)
			end
			if band5.maxassoc then
				wifidev:set("max_all_num_sta", band5.maxassoc)
			end

			if band5.enable_prevent == '1' then
				wifidev:set("prohibit_weak_sig_sta_enable", 1);
				if band5.sta_min_dbm then
					wifidev:set("sta_min_dbm", band5.sta_min_dbm)
				end
			else
				wifidev:set("prohibit_weak_sig_sta_enable", 0);
			end

			if band5.enable_kick == '1' then
				wifidev:set("disassociate_weak_sig_sta_enable", 1);
				if band5.weak_sta_signal then
					wifidev:set("weak_sta_signal", band5.weak_sta_signal)
				end
			else
				wifidev:set("disassociate_weak_sig_sta_enable", 0);
			end
		end
	end

	local changes = network:changes() or _uci_real:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		network:save("wireless")
		network:commit("wireless")
		_uci_real:commit("wireless")
		sysp.fork_exec("sleep 1; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
	end

    --nixio.syslog("crit", myprint(result))
	sysp.sflog("INFO","Advanced wireless configure changed!")
	sysp.sflog("INFO",arg_list)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_wireless_advance()
	local band2 = {}
	local band5 = {}
	local wifis = sf_wifinetworks()
	local network = require("luci.model.network").init()
	local signal_strength = SAVE_MODE
	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)

		if wifidev:get("band") == "2.4G" then
			local htcoex = wifidev:get("ht_coex")
			if (htcoex == "1") then
				htmode = "auto"
			else
				htmode = wifidev:get("htmode")
			end

			local hwmode = wifidev:get("hwmode")
			if htmode == "HT20" or htmode == "HT40" or htmode == "auto" then
				hwmode = "11n"
			end

			if tonumber(wifidev:get("txpower")) == SAVE_MODE_TXPOWER then
				signal_strength = SAVE_MODE
			elseif tonumber(wifidev:get("txpower")) == NORMAL_MODE_TXPOWER then
				signal_strength = NORMAL_MODE
			else
				signal_strength = PERFORMANCE_MODE
			end

			band2 = {
				htmode = htmode,
				hwmode = hwmode,
				channel = wifidev:get("channel"),
				signal_strength = signal_strength,
				beacon_int = wifidev:get("beacon_int") or "100",
				isolate = wifidev:get("netisolate"),
				maxassoc = wifidev:get("max_all_num_sta"),
				sta_min_dbm = wifidev:get("sta_min_dbm"),
				weak_sta_signal = wifidev:get("weak_sta_signal"),
				enable_prevent = wifidev:get("prohibit_weak_sig_sta_enable"),-- 0means not enable
				enable_kick= wifidev:get("disassociate_weak_sig_sta_enable")
			}
		elseif wifidev:get("band") == "5G" then
			local htcoex = wifidev:get("ht_coex")
			if (htcoex == "1") then
				htmode = "auto"
			else
				htmode = wifidev:get("htmode")
			end

			local hwmode = wifidev:get("hwmode")
			if htmode == "HT20" or htmode == "HT40" or htmode == "auto" then
				hwmode = "11n"
			elseif htmode == "VHT20" or htmode == "VHT40" or htmode == "VHT80" then
				hwmode = "11ac"
			end

			if tonumber(wifidev:get("txpower")) == SAVE_MODE_TXPOWER then
				signal_strength = SAVE_MODE
			elseif tonumber(wifidev:get("txpower")) == NORMAL_MODE_TXPOWER then
				signal_strength = NORMAL_MODE
			else
				signal_strength = PERFORMANCE_MODE
			end

			band5 = {
				htmode = htmode,
				hwmode = hwmode,
				channel = wifidev:get("channel"),
				signal_strength = signal_strength,
				beacon_int = wifidev:get("beacon_int") or "100",
				maxassoc = wifidev:get("max_all_num_sta"),
				isolate = wifidev:get("netisolate"),
				sta_min_dbm = wifidev:get("sta_min_dbm"),
				weak_sta_signal = wifidev:get("weak_sta_signal"),
				enable_prevent = wifidev:get("prohibit_weak_sig_sta_enable"),-- 0means not enable
				enable_kick = wifidev:get("disassociate_weak_sig_sta_enable")
			}
		end
	end

    result = {
        code = 0,
        msg = "OK",
		band2= band2,
		band5= band5
    }

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_spec_info()
	info= {
	}

    result = {
        code = 0,
        msg = "OK",
    }

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_spec_info()
	info= {
		enable = "",
		delta = "",
		fail = ""
	}

    result = {
        code = 0,
        msg = "OK",
		info = info
    }

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

--将table转化为字符串，用于打印
function myprint(params)
    if type(params) ~= "table" then
        return tostring(params)
    end
    local rv = "\n{\n"
    for k, v in pairs(params) do
        rv = rv..tostring(k)..":"..myprint(v)..",\n"
    end
    return string.sub(rv,0,string.len(rv)-2).."\n}\n";
end
