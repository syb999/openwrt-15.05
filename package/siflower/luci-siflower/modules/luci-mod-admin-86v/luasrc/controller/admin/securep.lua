--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/7
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.securep", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require "luci.json"
local fs  = require "nixio.fs"
ipc = require "luci.ip"
sysp = require "luci.controller.admin.systemp"

function index()
    entry({"admin", "securep"}, template("86v/secure"), _("Secure"), 62).attrid = "secure";
    entry({"admin", "securep", "get_mac_filter"}, call("get_mac_filter")).leaf = true;
    entry({"admin", "securep", "set_mac_filter"}, call("set_mac_filter")).leaf = true;
    entry({"admin", "securep", "get_vlan_config"}, call("get_vlan_config")).leaf = true;
    entry({"admin", "securep", "set_vlan_config"}, call("set_vlan_config")).leaf = true;
end

function get_mac_filter()

	local info = {}
	local r0info = {}
	local r1info = {}
	local name = {}
	local ssids = {}
	local en_ssids = {}

	 _uci_real:foreach("wireless", "wifi-iface",
	 function(s)
		name[s.ifname] = s.ssid
		ssids[#ssids+1] = {}
		ssids[#ssids] = s.ssid
		if s.macfilter == "allow" then
			en_ssids[#en_ssids+1] = {}
			en_ssids[#en_ssids] = s.ssid
		end
	 end)
	_uci_real:foreach("macfilter", "mac_entry",
	function(s)
		if s.device == 'radio0' then
			r0info[ #r0info + 1] = {}
			r0info[ #r0info ] = {
				mac= s.mac,
				net_name= name[s.net_name],
				comment = s.comment,
			}
		else
			r1info[ #r1info + 1] = {}
			r1info[ #r1info ] = {
				mac= s.mac,
				net_name= name[s.net_name],
				comment = s.comment,
			}
		end
	end)

	info["wifi_24g"] = r0info
	info["wifi_5g"] = r1info

    result = {
        code = 0,
        msg = "OK",
		info = info,
		ssid = ssids,
		en_ssid = en_ssids,
		enable = _uci_real:get("macfilter","status","enable")
    }

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function SearchStringInFile(path, mac)
	local ffile = io.open(path, "r")
	if ffile ~= nil then
		ffile:close()
		for line in io.lines(path) do
			if string.find(line, mac) ~= nil then
				return true
			end
		end
		return false
	end
	return false
end

function set_mac_filter()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local cfg="macfilter"
	local cmd = arg_list_table['cmd'] or ""
	local enable = arg_list_table['enable'] or ""
	local name = {}
	local device = {}

	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		name[s.ssid] = s.ifname
		device[s.ssid] = s.device
	end)

	if cmd == 'add' then
		local ifname = name[arg_list_table['net_name']]
		local entry = ifname..arg_list_table['mac']:gsub(':','_')
		_uci_real:section(cfg, "mac_entry", entry)
		_uci_real:set(cfg, entry, "mac", arg_list_table['mac'])
		_uci_real:set(cfg, entry, "net_name", ifname)
		_uci_real:set(cfg, entry, "device", device[arg_list_table['net_name']])
		_uci_real:set(cfg, entry, "comment", arg_list_table['comment'])
		_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.ifname == ifname then
				if not SearchStringInFile(s.macfile,arg_list_table['mac']) then
					local ffile = io.open(s.macfile,"a")
					ffile:write(arg_list_table['mac'].."\n")
					ffile:close()
				end
			end
		end)
	elseif cmd == 'del' then
		local ifname = name[arg_list_table['net_name']]
		local entry = ifname..arg_list_table['mac']:gsub(':','_')
		_uci_real:foreach(cfg, "mac_entry",
		function(s)
			if entry == s['.name'] then
				_uci_real:delete(cfg, entry)
			end
		end)
		_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.ifname == ifname then
				local ffile = io.open(s.macfile, "r")
				local txt = ffile:read("*a")
				ffile:close()
				txt = string.gsub(txt, arg_list_table['mac'].."\n", "")
				ffile = io.open(s.macfile, "w")
				ffile:write(txt)
				ffile:close()
			end
		end)
	end

	if enable ~= "" then
		if enable == '0' then
			_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				_uci_real:set("wireless", s[".name"], "macfilter", "disable")
			end)
			_uci_real:set("macfilter","status","enable", enable)
		elseif enable == '1' then
			local en_ssid = arg_list_table['en_ssid']
			_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				_uci_real:set("wireless", s[".name"], "macfilter", "disable")
				for n=1,#en_ssid do
					if en_ssid[n] == s.ssid then
						_uci_real:set("wireless", s[".name"], "macfilter", "allow")
					end
				end
			end)
			_uci_real:set("macfilter","status","enable", enable)
		end
	end

	_uci_real:save(cfg)
	_uci_real:commit(cfg)
	_uci_real:save("wireless")
	_uci_real:commit("wireless")

	os.execute("wifi")

	result = {
		code = 0,
		msg = "OK",
	}

	--nixio.syslog("crit", myprint(result))
	sysp.sflog("INFO","MAC filter configure changed!")
	sysp.sflog("INFO",arg_list)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_vlan_config()

	local info = {}
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		info[ #info + 1] = {}
		info[ #info ] = {
			band= _uci_real:get("wireless", s.device, "band"),
			net_name= s.ssid,
			net_type = s.group,
			enable = s.vlan_id_enable,
			vlanid= s.vlan_id
		}
	end)

    result = {
        code = 0,
        msg = "OK",
		info = info,
    }

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_vlan_config()
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
	local cfg="wireless"
	local net_name = arg_list_table['net_name']

	_uci_real:foreach(cfg, "wifi-iface", function(s)
		if net_name == s.ssid then
			entry = s['.name']
			_uci_real:set(cfg, entry, "vlan_id_enable", arg_list_table['enable'])
			_uci_real:set(cfg, entry, "vlan_id", arg_list_table['vlanid'])
		end
	end)
	_uci_real:save(cfg)
	_uci_real:commit(cfg)

	os.execute("wifi reload")

    result = {
        code = 0,
        msg = "OK",
    }

    --nixio.syslog("crit", myprint(result))
	sysp.sflog("INFO","WIFI vlan configure changed!")
	sysp.sflog("INFO",arg_list)
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
