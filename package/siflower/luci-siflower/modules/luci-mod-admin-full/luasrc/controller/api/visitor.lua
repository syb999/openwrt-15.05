--[[
LuCI - Lua Configuration Interface

Description:
Offers an interface for handle app request
]]--

module("luci.controller.api.visitor", package.seeall)

local sysutil = require "luci.siwifi.sf_sysutil"
local sysconfig = require "luci.siwifi.sf_sysconfig"
local disk = require "luci.siwifi.sf_disk"
local sferr = require "luci.siwifi.sf_error"
local nixio = require "nixio"
local fs = require "nixio.fs"
local uci = require "luci.model.uci".cursor()
local test  = require "luci.controller.admin.advancednew"
local networknew = require "luci.controller.admin.networknew"
local wirelessnew = require "luci.controller.admin.wirelessnew"
local json = require("luci.json")
local _uci_real  = cursor or _uci_real or uci.cursor()

function index()
    local page   = node("api","visitor")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    entry({"api", "visitor"}, firstchild(), (""), 100)
    entry({"api", "visitor", "welcome"}, call("welcome"), nil)
    entry({"api", "visitor", "welcome_wds"}, call("welcome_wds"), nil)
    entry({"api", "visitor", "get_bindinfo"}, call("get_bindinfo"), nil)
    entry({"api", "visitor", "get_version"}, call("get_version"), nil)
    entry({"api", "visitor", "get_client_mac"}, call("get_client_mac"), nil)
    entry({"api", "visitor", "get_pay_need_param"}, call("get_pay_need_param"), nil)
    entry({"api", "visitor", "pass_for_now"}, call("pass_for_now"), nil)

end

function get_bindinfo()

    local code = 0
    local result = {}
    local routerkey = {}
    local checkRouterKey = {}
    local passwdset = 0
    local pwh,pwe = luci.sys.user.getpasswd("root")
    local protocol = sysutil.get_version_from_http()
    local ret = io.popen("cat /sys/devices/factory-read/product_key")
    if ret then
        routerkey = ret:read("*a")
        ret:close()
    end
    ret = io.popen("cat /sys/devices/factory-read/product_key_flag")
    if ret then
        checkRouterKey = ret:read("*a")
        ret:close()
    end
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(protocol <=  sysutil.get_version_local()) then
        if pwh then
            passwdset = 1
        else
            passwdset = 0
        end
        result["passwdset"] = passwdset
        result["bind"] = tonumber(uci:get("siserver","cloudrouter","bind"))
        result["binderid"] = uci:get("siserver","cloudrouter","binder") or ''
        result["routerid"] = uci:get("siserver","cloudrouter","routerid") or ''
		result["feature"] = {}
		result["feature"] = sysutil.get_feature()
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
		result["mac"] = uci:get("network", "lan", "macaddr") or ''

        if string.find(checkRouterKey,"pk") then
            result["routerkey"] = routerkey
        end

    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function get_version()
    local code = 0
    local result = {}
    local protocol = sysutil.get_version_from_http()
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        result["version"] =  sysutil.get_version_local()
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)

    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function welcome()
	local rv = { }

	-- local arg_list, data_len = luci.http.content()
	-- local arg_list_table = json.decode(arg_list)
	-- local value = test.get_routing_table();
	-- test.set_static_routing(arg_list_table["routers"])
	-- test.get_static_routing()
	-- test.get_dmz_host()
	-- test.set_dmz_host(arg_list_table["params"])
	-- test.get_virtual_server()
	-- test.set_virtual_server(arg_list_table["servers"])
	-- local value = test.get_routing_table();
	-- test.set_static_routing(arg_list_table["routers"])
	-- test.get_static_routing()

	rv["msg"] = "welcome to sf-system"
	rv["code"] = code
	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end

function welcome_wds()
    local rv = { }

    rv["msg"] = "welcome to sf-system"
    rv["code"] = code
    luci.http.prepare_content("application/json")
    luci.http.header("Access-Control-Allow-Origin", "*")
    luci.http.write_json(rv)
end

-- reply info add wlan interface
function get_client_mac()
	local mac = networknew.ip_to_mac(luci.http.getenv("REMOTE_ADDR")) or "" --string 当前管理pc的mac地址
	local dev_mac = (mac:gsub(":","_")):upper()
	local wlan = uci:get("wldevlist",dev_mac,"dev")
	local status = wirelessnew.wds_is_enabled()
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if s.ifname == wlan then
			net_type = s.network
		end
	end
	)
	local result = {
		code = 0,
		msg = "OK",
		devicemac = mac,
		net_type = net_type,
		wlan = wlan,
		status = status
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end
-- set client mac for get access to internet for a few mins
function set_client_access()

	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local mac = arg_list_table["mac"]
	local timecount = arg_list_table["timecount"]
	if timecount > 300 then
		timecount = 300
	end
	luci.util.exec("aclscript l_time %s %s"%{ mac:gsub("_",":"), tostring(timecount)})

    local result = {
        code = 0,
        msg = "OK",
    }
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_pay_need_param()

    local code = 0
    local result = {}
    local passwdset = 0
	local ssid = ""

	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if string.find(s.ifname,"lease")  then
			ssid = s.ssid
		end
	end
	)
	result["mac"] = networknew.ip_to_mac(luci.http.getenv("REMOTE_ADDR")) or "" --string 当前device的mac地址
	result["objectid"] = uci:get("siserver","cloudrouter","routerid")
	result["ssid"] = ssid

	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)

    luci.http.prepare_content("application/json")
    luci.http.header("Access-Control-Allow-Origin", "*")
    luci.http.write_json(result)
end

function pass_for_now()

    local code = 0
    local result = {}
    local passwdset = 0
	local mac = ""

	mac = networknew.ip_to_mac(luci.http.getenv("REMOTE_ADDR")) or "" --string 当前device的mac地址
	sysutil.fork_exec("aclscript l_fornow %s"%{(mac:upper()):gsub("_", ":")})

	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)

    luci.http.prepare_content("application/json")
    luci.http.header("Access-Control-Allow-Origin", "*")
    luci.http.write_json(result)
end
