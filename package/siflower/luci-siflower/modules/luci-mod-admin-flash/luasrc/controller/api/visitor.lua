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
local json = require("luci.json")

function index()
    local page   = node("api","visitor")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.index = true
    entry({"api", "visitor"}, firstchild(), (""), 100)
    entry({"api", "visitor", "welcome"}, call("welcome"), nil)
    entry({"api", "visitor", "get_bindinfo"}, call("get_bindinfo"), nil)
    entry({"api", "visitor", "get_version"}, call("get_version"), nil)

end

function get_bindinfo()

    local code = 0
    local result = {}
    local passwdset = 0
    local pwh,pwe = luci.sys.user.getpasswd("root")
    local protocol = sysutil.get_version_from_http()
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

        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)

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
