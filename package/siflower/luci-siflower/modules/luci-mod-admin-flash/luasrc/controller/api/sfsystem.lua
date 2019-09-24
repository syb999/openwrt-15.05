--[[
LuCI - Lua Configuration Interface

Description:
Offers an interface for handle app request
]]--

module("luci.controller.api.sfsystem", package.seeall)

local sysutil = require "luci.siwifi.sf_sysutil"
local sysconfig = require "luci.siwifi.sf_sysconfig"
local disk = require "luci.siwifi.sf_disk"
local sferr = require "luci.siwifi.sf_error"
local sfgw = require "luci.siwifi.sf_gateway"
local wirelessnew = require "luci.controller.admin.wirelessnew"
local nixio = require "nixio"
local fs = require "nixio.fs"
local json = require("luci.json")
local http = require "luci.http"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()

local SAVE_MODE = 0
local NORMAL_MODE = 1
local PERFORMANCE_MODE = 2

local SAVE_MODE_TXPOWER = 0
local NORMAL_MODE_TXPOWER = 1
local PERFORMANCE_MODE_TXPOWER = 2

local reset_interval = 30



function index()
    local page   = node("api","sfsystem")
    page.target  = firstchild()
    page.title   = ("")
    page.order   = 100
    page.sysauth = "admin"
    page.sysauth_authenticator = "jsonauth"
    page.index = true
    entry({"api", "sfsystem"}, firstchild(), (""), 100)
    entry({"api", "sfsystem", "welcome"}, call("welcome"), nil)
    entry({"api", "sfsystem", "init_info"}, call("getInitInfo"), nil)

    page = entry({"api", "sfsystem", "command"}, call("parse_command"), nil)
    page.leaf = true

    entry({"api", "sfsystem", "get_stok_local"}, call("get_stok_local"), nil)
    entry({"api", "sfsystem", "get_stok_remote"}, call("get_stok_remote"), nil)
    entry({"api", "sfsystem", "setpasswd"}, call("set_Password"), nil)
    entry({"api", "sfsystem", "wifi_detail"}, call("get_wifi_detail"),nil)
    entry({"api", "sfsystem", "setwifi"}, call("set_wifi_info"),nil)
    entry({"api", "sfsystem", "getwifi_advanced"}, call("get_wifi_advanced"),nil)
    entry({"api", "sfsystem", "setwifi_advanced"}, call("set_wifi_advanced"),nil)
    entry({"api", "sfsystem", "main_status"}, call("get_router_status"),nil)
    entry({"api", "sfsystem", "bind"}, call("bind"),nil)
    entry({"api", "sfsystem", "unbind"}, call("unbind"),nil)
    entry({"api", "sfsystem", "manager"}, call("manager_op"),nil)
    entry({"api", "sfsystem", "device_list_backstage"}, call("get_device_list"),nil)           --just internal call
    entry({"api", "sfsystem", "arp_check_dev"}, call("arp_check_device"),nil)           --just internal call
    entry({"api", "sfsystem", "device_list"}, call("get_device_info"),nil)
    entry({"api", "sfsystem", "del_device_info"}, call("del_device_info"),nil)
    entry({"api", "sfsystem", "setdevice"}, call("set_device"),nil)
    entry({"api", "sfsystem", "ota_check"}, call("ota_check"),nil)
    entry({"api", "sfsystem", "ota_upgrade"}, call("ota_upgrade"),nil)
    entry({"api", "sfsystem", "check_wan_type"}, call("check_wan_type"),nil)
    entry({"api", "sfsystem", "get_wan_type"}, call("get_wan_type"),nil)
    entry({"api", "sfsystem", "set_wan_type"}, call("set_wan_type"),nil)
    entry({"api", "sfsystem", "get_lan_type"}, call("get_lan_type"),nil)
    entry({"api", "sfsystem", "set_lan_type"}, call("set_lan_type"),nil)
    entry({"api", "sfsystem", "detect_wan_type"}, call("detect_wan_type"),nil)
    entry({"api", "sfsystem", "qos_set"}, call("set_qos"),nil)
    entry({"api", "sfsystem", "qos_info"}, call("get_qos_info"),nil)
    entry({"api", "sfsystem", "netdetect"}, call("net_detect"),nil)
    entry({"api", "sfsystem", "check_net"}, call("check_net"),nil)
    entry({"api", "sfsystem", "set_wifi_filter"}, call("set_wifi_filter"),nil)
    entry({"api", "sfsystem", "get_wifi_filter"}, call("get_wifi_filter"),nil)
	entry({"api", "sfsystem", "upload_log"}, call("upload_log"),nil)
    entry({"api", "sfsystem", "sync"}, call("sync"),nil)
	entry({"api", "sfsystem", "download"}, call("download"),nil)
	entry({"api", "sfsystem", "update_qos_local"}, call("update_qos_local"),nil)                            --just internal call
    entry({"api", "sfsystem", "set_user_info"}, call("set_user_info"), nil)
    entry({"api", "sfsystem", "new_oray_params"}, call("new_oray_params"), nil)
    entry({"api", "sfsystem", "destroy_oray_params"}, call("destroy_oray_params"), nil)
    entry({"api", "sfsystem", "setdefault"}, call("set_default_config"), nil)
    entry({"api", "sfsystem", "getdefault"}, call("get_default_config"), nil)
    entry({"api", "sfsystem", "adduser"}, call("add_user"), nil)
    entry({"api", "sfsystem", "setdevicetime"}, call("set_device_time"), nil)
    entry({"api", "sfsystem", "getdevicetime"}, call("get_device_time"), nil)
    entry({"api", "sfsystem", "setdevicerestrict"}, call("set_device_restrict"), nil)
    entry({"api", "sfsystem", "getdevicerestrict"}, call("get_device_restrict"), nil)
    entry({"api", "sfsystem", "setdevicedatausage"}, call("set_device_data_usage"), nil)
    entry({"api", "sfsystem", "getdevicedatausage"}, call("get_device_data_usage"), nil)
    entry({"api", "sfsystem", "routerlivetime"}, call("router_live_time"), nil)
    entry({"api", "sfsystem", "blockrefactory"}, call("block_refactory"), nil)
    entry({"api", "sfsystem", "getrouterlivetime"}, call("get_router_live_time"), nil)
    entry({"api", "sfsystem", "getblockrefactory"}, call("get_block_refactory"), nil)
    entry({"api", "sfsystem", "getaccess"}, call("get_access"), nil)

    entry({"api", "sfsystem", "setspeed"}, call("set_speed"), nil)
    entry({"api", "sfsystem", "urllist_set"}, call("urllist_set"), nil)
    entry({"api", "sfsystem", "urllist_get"}, call("urllist_get"), nil)
    entry({"api", "sfsystem", "urllist_enable"}, call("urllist_enable"), nil)
    entry({"api", "sfsystem", "get_customer_wifi_iface"}, call("get_customer_wifi_iface"), nil)
    entry({"api", "sfsystem", "set_customer_wifi_iface"}, call("set_customer_wifi_iface"), nil)
    entry({"api", "sfsystem", "wifi_scan"}, call("wifi_scan"), nil)
    entry({"api", "sfsystem", "wifi_connect"}, call("wifi_connect"), nil)
    entry({"api", "sfsystem", "wds_getwanip"}, call("wds_getwanip"), nil)
    entry({"api", "sfsystem", "wds_enable"}, call("wds_enable"), nil)
    entry({"api", "sfsystem", "wds_disable"}, call("wds_disable"), nil)
    entry({"api", "sfsystem", "get_wds_info"}, call("get_wds_info"), nil)
    entry({"api", "sfsystem", "set_warn"}, call("set_warn"), nil)
	entry({"api", "sfsystem", "set_dev_warn"}, call("set_dev_warn"), nil)

	--V17
	entry({"api", "sfsystem", "get_freq_intergration"}, call("sf_get_freq_intergration"), nil)
	entry({"api", "sfsystem", "set_freq_intergration"}, call("sf_set_freq_intergration"), nil)
end

function sync()
    --string.format("Downloading %s from %s to %s", file, host, outfile)
--    local cmd = "SYNC -data "..luci.http.formvalue("enable")
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local action = arg_list_table["action"]
    local userid = arg_list_table["userid"]
    local type = arg_list_table["type"]
    local data = arg_list_table["data"]

    local cmd = string.format("SUBE need-callback -data {\"action\": %d,\"userid\": \"%s\",\"type\": %s,\"data\":\"%s\"}",action,userid,type,data);
    local cmd_ret = {}
    local ret1 = sysutil.sendCommandToLocalServer(cmd, cmd_ret)

    local code = 0
    local result = {}

    if(ret1 ~= 0) then
        result["code"] = -1
        result["msg"] = "send command fail"
    else
        --parse json result
        local decoder = {}
        if cmd_ret["json"] then
            decoder = json.decode(cmd_ret["json"]);
            if(decoder["ret"] == "success") then
                result["code"] = 0
                result["msg"] = "success"
            else
                result["code"] = -1
                result["msg"] = "internal-server-error"..(decoder["reason"] or "")
            end
        else
            result["code"] = -1
            result["msg"] = "internal-server-error"
        end
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function check_wan_type()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local time1 = os.time()
        local wantype = luci.util.exec("ubus call network.internet wantype")
        nixio.syslog("crit","check wan type cost time "..tostring(os.time() - time1).."s--result:"..tostring(wantype))
        if(wantype) then
            local decoder = json.decode(wantype);
            if(decoder and decoder['result']) then
                result['type'] = decoder['result']
                if(decoder['result'] < 0) then
                    result["code"] = sferr.ERROR_NO_WAN_TYPE_PARSER_FAIL
                else
                    result["code"] = 0
                end
            else
                result["code"] = sferr.ERROR_NO_WAN_TYPE_PARSER_FAIL
            end
        else
            result["code"] = sferr.ERROR_NO_WAN_TYPE_EXCEPTION
        end
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function check_net()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local  checkret =  luci.util.exec("check_net check")
		local  status = tonumber(string.sub(checkret,1,-2))
		result["status"] = status
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function new_oray_params()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
		local p2pret = {}
		local ret1 = sysutil.sendCommandToLocalServer("CP2P need-callback",p2pret)
		if(ret1 ~= 0) then
			code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
		else
			local decoder = {}
			if p2pret["json"] then
				decoder = json.decode(p2pret["json"]);
				if(decoder["ret"] == "success") then
					result["url"] = decoder["url"]
					result["session"] = decoder["session"]
					code = 0
				else
					result["url"] = ""
					result["session"] = ""
					code = sferr.ERROR_NO_CREATE_P2P_FAIL
					extraInfo = "-"..(decoder["reason"] or "")
				end
			else
				result["url"] = ""
				result["session"] = ""
				code = sferr.ERROR_NO_CREATE_P2P_FAIL
				extraInfo = "-"..(decoder["reason"] or "")
			end
		end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function destroy_oray_params()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local sess = arg_list_table["session"]
	local sessparam = string.format("DP2P need-callback -data {\"session\":\"%s\"}",sess)
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
		local p2pret = {}
		local ret1 = sysutil.sendCommandToLocalServer(sessparam ,p2pret)
		if(ret1 ~= 0) then
			code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
		else
			local decoder = {}
			if p2pret["json"] then
				decoder = json.decode(p2pret["json"]);
				if(decoder["ret"] == "success") then
					code = 0
				else
					code = sferr.ERROR_NO_DESTROY_P2P_FAIL
					extraInfo = "-"..(decoder["reason"] or "")
				end
			else
				code = sferr.ERROR_NO_DESTROY_P2P_FAIL
				extraInfo = "-"..(decoder["reason"] or "")
			end
		end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function set_default_config()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local internet = arg_list_table["internet"]
	local cfg_file = "sidefault"
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        if internet then
			_uci_real:set(cfg_file, "acl", "internet", tostring(internet))
			_uci_real:save(cfg_file)
			_uci_real:commit(cfg_file)
		end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
	else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_default_config()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
	local cfg_file = "sidefault"
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
		local internet = _uci_real:get(cfg_file, "acl", "internet")
		result["internet"] = tonumber(internet or 1)
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
	else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_device_time()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local mac = arg_list_table["mac"]

    if(not protocol) then
		code=ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local op_list = get_list_by_mac(mac)

		result["time"] = tonumber(_uci_real:get(op_list , mac, "time") or 0)

    else
		code=ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	set_easy_return(code,result)
end

function set_device_time()
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local mac = arg_list_table["mac"]
    local action = arg_list_table["action"]

    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local op_list = get_list_by_mac(mac)
		if action == 0 then
			local time = arg_list_table["time"]
			_uci_real:set(op_list , mac, "time", time)
			luci.util.exec("pctl visitor add %s %s"%{ mac:gsub("_",":"), time})
		else
			_uci_real:set(op_list , mac, "time", "0")
			luci.util.exec("pctl visitor del %s"%{ mac:gsub("_",":")})
		end
		_uci_real:save(op_list )
		_uci_real:commit(op_list )
    else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	set_easy_return(code,nil)

	sysutil.sflog("INFO","Device %s visit time configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
end

function get_device_restrict()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local mac = arg_list_table["mac"]

    if(not protocol) then
		code=ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local op_list = get_list_by_mac(mac)

		result["social"] = tonumber(_uci_real:get(op_list , mac, "social") or 0)
		result["video"] = tonumber(_uci_real:get(op_list , mac, "video") or 0)
		result["game"] = tonumber(_uci_real:get(op_list , mac, "game") or 0)
		result["restrictenable"] = tonumber(_uci_real:get(op_list , mac, "restrictenable") or 0)

    else
		code=ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	set_easy_return(code,result)
end

function set_device_restrict()
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local mac = arg_list_table["mac"]
    local social = arg_list_table["social"]
    local video = arg_list_table["video"]
    local game = arg_list_table["game"]
	local restrict_enable = arg_list_table["restrictenable"]

    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local op_list = get_list_by_mac(mac)

		_uci_real:set(op_list , mac, "social", social)
		_uci_real:set(op_list , mac, "video", video)
		_uci_real:set(op_list , mac, "game", game)
		_uci_real:set(op_list , mac, "restrictenable", restrict_enable)
		_uci_real:save(op_list )
		_uci_real:commit(op_list )
		luci.util.exec("tscript type_flow %s %s %s %s %s"%{ mac:gsub("_",":"), restrict_enable, game, video, social})
    else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	sysutil.sflog("INFO","Device %s flow control configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	set_easy_return(code,nil)

end

function set_device_data_usage()
    local code = 0
    local setlist_json = {}
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
	local mac = arg_list_table["mac"]

    if(not protocol) then
		code=ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local setlist = arg_list_table["setlist"]
		local change = arg_list_table["change"]
		local usage_enable = arg_list_table["usageenable"]

		local op_list = get_list_by_mac(mac)

		_uci_real:set(op_list , mac, "setlist", json.encode(setlist))
		_uci_real:set(op_list , mac, "change", change)
		_uci_real:set(op_list , mac, "usageenable", usage_enable)

		_uci_real:save(op_list )
		_uci_real:commit(op_list )
		if usage_enable == 1 then
			luci.util.exec("tscript flow_en %s %s"%{mac:gsub("_",":"), change})
		else
			luci.util.exec("tscript flow_dis %s"%{mac:gsub("_",":")})
		end

    else
		code=ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	sysutil.sflog("INFO","Device %s flow limit configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	set_easy_return(code,nil)
end

function get_dev_credit(mac)
	local fd = io.open("/proc/ts")
	local sign = 1

    if fd then
        while true do
            local tmp = fd:read("*l")
            if not tmp then break end
            if string.match(tmp, mac) then
				local var = splitbysp(tmp)
				fd:close()
				if var[9][1] == '-' then
					sign = -1
				end
				return math.ceil(tonumber(var[9]) / 1000 / 1000) * sign
			end
        end
        fd:close()
	else
		nixio.syslog("crit","Can not open /proc/ts")
    end
	return 0
end

function get_device_data_usage()
    local result = {}
    local code = 0
    local setlist = {}
    local setlist_json = {}
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local mac = arg_list_table["mac"]
    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
    elseif(sysutil.version_check(protocol)) then
		local op_list = get_list_by_mac(mac)

		result["setlist"] = json.decode(_uci_real:get(op_list , mac, "setlist"))
		result["usageenable"] = tonumber(_uci_real:get(op_list , mac, "usageenable") or 0)
		result["credit"] = get_dev_credit((mac:upper()):gsub("_",":"))

    else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
	set_easy_return(code,result)
end

function get_router_live_time()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		result["timelist"] = json.decode(_uci_real:get("siwifi",  "hardware", "timelistofoff"))
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end
	set_easy_return(code,result)

end
function router_live_time()
    local uci = require "luci.model.uci".cursor()
    local code = 0
    local count = 0
    local timelist_json = {}
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		local timelistonoff = arg_list_table["timelist"]
		nixio.syslog("crit","enable id " .. json.encode(timelistonoff))
		if timelistonoff then
			timelist_json = timelistonoff[1]
			local enable  = timelist_json["enable"]
			if enable == 1 then
				local start_time = timelist_json["starttime"]
				local stop_time = timelist_json["endtime"]
				local week = timelist_json["week"]
				-- uci:set("siwifi","timelistonoff",json.encode(timelistonoff))
                -- uci:save("siwifi")
                -- uci:commit("siwifi")
				_uci_real:set("siwifi",  "hardware", "timelistofoff",json.encode(timelistonoff))
				_uci_real:save("siwifi" )
				_uci_real:commit("siwifi")
				local starth = tonumber(string.sub(start_time,1,2))
				local startm = tonumber(string.sub(start_time,4,5))
				local stoph = tonumber(string.sub(stop_time,1,2))
				local stopm = tonumber(string.sub(stop_time,4,5))

				-- one min before we power off, set the delay for start router
				-- so the count would be from (stoph * 60 + stopm -1) to (starth * 60 + startm)
				local total_start = starth * 60 + startm
				local total_stop = stoph * 60 + stopm - 1
				if(total_start - total_stop) > 0 then
					count = total_start - total_stop
				else
					count = (total_start - total_stop) + 24 * 60
				end

				luci.util.exec("pctl onoff 1 %s %s %s"%{ stop_time, count, week })
			else
				luci.util.exec("pctl onoff 0")
			end
		else
			code = sferr.ERROR_INPUT_PARAM_ERROR
		end

	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end

	set_easy_return(code,nil)
end
function get_block_refactory()
    local uci = require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]

    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		result["block"] = tonumber(uci:get("siwifi","block"))
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end
	set_easy_return(code,result)
end

function block_refactory()
    local uci = require "luci.model.uci".cursor()
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local block = arg_list_table["block"]
	if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		uci:set("siwifi","block",tostring(block))
		uci:save("siwifi")
		uci:commit("siwifi")
		if (block == 1) then
			luci.util.exec("echo 1 > /proc/reset_button_mask")
		else
			luci.util.exec("echo 0 > /proc/reset_button_mask")
		end
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end

	set_easy_return(code,nil)
end

function get_access()
    local uci = require "luci.model.uci".cursor()
	local result = {}
	local ret1 = 0
	local code = 0
	local extraInfo = ""
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		code=ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		local data = arg_list_table["data"]
		if(not data) then
			code = sferr.ERROR_NO_USERID_EMPTY
		else
			_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.network ~= "guest" then
					if (data == s.key) then
						local f = assert(io.open("/etc/info.txt", "r"))
						local str1 = nil
						while true do
							local bytes = f:read(1)
							if not bytes then break end
							-- io.write(string.format("%02X ", string.byte(bytes)))
							if str1 then
								str1 = str1 .. string.format("%02X ", string.byte(bytes))
							else
								str1 = string.format("%02X ", string.byte(bytes))
							end
						end
						result["access"] = str1
					end
				end
			end
			)
		end
	else
		code=ERROR_NO_PROTOCOL_NOT_SUPPORT
	end
	set_easy_return(code,result)
end

function add_user()
	local result = {}
	local ret1 = 0
	local code = 0
	local extraInfo = ""
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		local userid = arg_list_table["userobjectid"]
		local device_id= arg_list_table["deviceid"]
		if((not userid) and  (not device_id)) then
			code = sferr.ERROR_NO_USERID_EMPTY
		else
			--check if router is bind
			local bindvalue = sysutil.getbind()
			local binder = sysutil.getbinderId()
			--do bind
			local bindret = {}
			--init sn to uci config in getSN,so the socket server can get config from uic
			local sn = sysutil.getSN()
			if (userid ~= nil) then
				ret1 = sysutil.sendCommandToLocalServer("ADDU need-callback -data {\"binder\":\""..tostring(userid).."\"}",bindret)
			else
				if (device_id ~= nil) then
					ret1 = sysutil.sendCommandToLocalServer("ADDU need-callback -data {\"deviceid\":\""..tostring(device_id).."\"}",bindret)
				end
			end
			if(ret1 ~= 0) then
				code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
			else
				--parse json result
				local decoder = {}
				if bindret["json"] then
					decoder = json.decode(bindret["json"]);
					if(decoder["ret"] == "success") then
						result["routerobjectid"] = decoder["router"]
						code = 0
					else
						result["routerobjectid"] = ""
						code = sferr.ERROR_NO_BIND_FAIL
						extraInfo = "-"..(decoder["reason"] or "")
					end
				else
					result["routerobjectid"] = ""
					code = sferr.ERROR_NO_BIND_FAIL
					extraInfo = "-"..(decoder["reason"] or "")
				end
			end
		end
		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)..extraInfo
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function bind()
	local result = {}
	local code = 0
	local ret1 = 0
	local extraInfo = ""
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		local userid = arg_list_table["userobjectid"]
		local device_id= arg_list_table["deviceid"]
		if((not userid) and  (not device_id)) then
			code = sferr.ERROR_NO_USERID_EMPTY
		else
			--check if router is bind
			local bindvalue = sysutil.getbind()
			local binder = sysutil.getbinderId()
			if(bindvalue == sysconfig.SF_BIND_YET) then
				code = sferr.ERROR_NO_ROUTER_HAS_BIND
				if(binder == userid) then
					result["routerobjectid"] = sysutil.getrouterId()
					result["binderid"] = sysutil.getbinderId()
				end
				if(binder == device_id) then
					result["routerobjectid"] = sysutil.getrouterId()
				end
			else
				--do bind
				local bindret = {}
				--init sn to uci config in getSN,so the socket server can get config from uic
				local sn = sysutil.getSN()
				if (userid ~= nil) then
					ret1 = sysutil.sendCommandToLocalServer("BIND need-callback -data {\"binder\":\""..tostring(userid).."\"}",bindret)
				else
					if (device_id ~= nil) then
						nixio.syslog("crit","device id " .. device_id)
						ret1 = sysutil.sendCommandToLocalServer("BIND need-callback -data {\"deviceid\":\""..tostring(device_id).."\"}",bindret)
					end
				end
				if(ret1 ~= 0) then
					code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
				else
					--parse json result
					local decoder = {}
					if bindret["json"] then
						decoder = json.decode(bindret["json"]);
						if(decoder["ret"] == "success") then
							result["routerobjectid"] = decoder["router"]
							code = 0
						else
							result["routerobjectid"] = ""
							code = sferr.ERROR_NO_BIND_FAIL
							extraInfo = "-"..(decoder["reason"] or "")
						end
					else
                        result["routerobjectid"] = ""
                        code = sferr.ERROR_NO_BIND_FAIL
                        extraInfo = "-"..(decoder["reason"] or "")
                    end
                end
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

	sysutil.sflog("INFO","Router bind!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function manager_op()
    local result = {}
    local code = 0
    local extraInfo = ""
    local simanager = "/etc/config/simanager"
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        --check params
        local action = arg_list_table["action"]
        local managerid = arg_list_table["managerid"]
        local userid = arg_list_table["userid"]
        local phonenumber = arg_list_table["phonenumber"]
        local username = arg_list_table["username"] or ""
        local tag = arg_list_table["tag"] or ""
        local hostuserid = getfenv(1).userid
        if((not action) or ((not (userid or phonenumber)) and  (not managerid))) then
            code = sferr.ERROR_NO_CHECK_MANAGER_PARAMS_FAIL
        else
            --check if router is bind
            local bindvalue = sysutil.getbind()
            if(bindvalue == sysconfig.SF_BIND_NO) then
                code = sferr.ERROR_NO_ROUTER_HAS_NOT_BIND
            else
                --do manager operation
				if (action == 6) then
					local file = io.open(simanager,"r")
					if file then
						local info = file:read("*a")
						file:close()
						local ishas = string.find(info, managerid)
						if not ishas then
							local wfile = io.open(simanager,"w")
							wfile:write(info..managerid)
							wfile:close()
						end
					else
						local wfile = io.open(simanager,"w")
						wfile:write(managerid)
						wfile:close()
					end
				elseif(action == 7) then
					local file = io.open(simanager,"r")
					if file then
						local info = file:read("*a")
						file:close()
						local newinfo = string.gsub(info, managerid,"")
						local wfile = io.open(simanager,"w")
						wfile:write(newinfo)
						wfile:close()
					end
				else
					local bindret = {}
					local ret1 = sysutil.send_manager_op_command(action,userid or "",phonenumber or "",username or "",tag or "",hostuserid or "",bindret)
					if(ret1 ~= 0) then
						code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
					else
						--parse json result
						local decoder = {}
						decoder = json.decode(bindret["json"]);
						if(decoder["ret"] == "success") then
							code = 0
						else
							code = sferr.ERROR_NO_MANAGER_OP_FAIL
							extraInfo = "-"..decoder["reason"]
						end
					end
				end
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function unbind()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local userid = arg_list_table["userobjectid"]
        if(not userid) then
            code = sferr.ERROR_NO_USERID_EMPTY
        else
            --check if router is bind
            local bindvalue = sysutil.getbind()
            local binder = sysutil.getbinderId()
            if(bindvalue == sysconfig.SF_BIND_NO) then
                code = sferr.ERROR_NO_ROUTER_HAS_NOT_BIND
            elseif(binder ~= userid) then
                code = sferr.ERROR_NO_CALLER_NOT_BINDER
            else
                --do unbind
                local bindret = {}
                local ret1 = sysutil.send_unbind_command(bindret)
                if(ret1 ~= 0) then
                    code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
                else
                    --parse json result
                    local decoder = {}
                    if bindret["json"] then
                        decoder = json.decode(bindret["json"]);
                        if(decoder["ret"] == "success") then
                            code = 0
                        else
                            code = sferr.ERROR_NO_UNBIND_FAIL
                            extraInfo = "-"..(decoder["reason"] or "")
                        end
                    else
                        code = sferr.ERROR_NO_UNBIND_FAIL
                        extraInfo = "-"..(decoder["reason"] or "")
                    end

                end
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
    else
        result = sferr.errProtocolNotSupport()
    end

	sysutil.sflog("INFO","Router unbind!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function getInitInfo()
    local uci =require "luci.model.uci".cursor()
    local result = {}
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        result["romtype"] = sysutil.getRomtype()
        result["name"] = sysutil.getRouterName()
        result["romversion"] = sysutil.getRomVersion()
        result["romversionnumber"] = 0       ---------------------------------TODO----------------------
        result["sn"] = sysutil.getSN()
        result["hardware"] = sysutil.getHardware()
        result["account"] =  sysutil.getRouterAccount()
        result["mac"] = sysutil.getMac("eth0")
        result["disk"] = disk.getDiskAvaiable()
        result["routerid"] = uci:get("siserver","cloudrouter","routerid") or ''
		result["zigbee"] = sysutil.getZigbeeAttr()
		result["storage"] = sysutil.getStorage()
        result["code"] = 0
        result["msg"]  = sferr.getErrorMessage(0)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function parse_command()

    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local cmd = arg_list_table["cmd"]

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        if cmd == 0 then
            code = reboot()
        elseif cmd == 2 then
            code = reset()
        else
            code = sferr.ERROR_NO_UNKNOWN_CMD
        end

        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function reboot()
    local reset_shortest_time = 0
    if sysutil.sane("/tmp/reset_shortest_time") then
        reset_shortest_time  = tonumber(fs.readfile("/tmp/reset_shortest_time"))
    else
        reset_shortest_time = 0
    end
    if os.time() > reset_shortest_time then
        sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_REBOOT)
        sysutil.fork_exec("sleep 5;reboot");
        sysutil.resetAllDevice()
        reset_shortest_time = reset_interval + os.time()
        local f = nixio.open("/tmp/reset_shortest_time", "w", 600)
        f:writeall(reset_shortest_time)
        f:close()

        return 0
    else
        return sferr.ERROR_NO_WAITTING_RESET
    end
end

function network_shutdown(iface)
    local netmd = require "luci.model.network".init()
    local net = netmd:get_network(iface)
    if net then
        luci.sys.call("env -i /sbin/ifdown %q >/dev/null 2>/dev/null" % iface)
        luci.http.status(200, "Shutdown")
        return
    end
end

function reset()
    local reset_shortest_time = 0
    if sysutil.sane("/tmp/reset_shortest_time") then
        reset_shortest_time  = tonumber(fs.readfile("/tmp/reset_shortest_time"))
    else
        reset_shortest_time = 0
    end
    if os.time() > reset_shortest_time then
        --before reset we notify the server unbind the current user,maybe unsuccess if the network is not reachable
        sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_RESET)
        sysutil.unbind();
        --do reset
        sysutil.fork_exec("sleep 1; killall dropbear uhttpd; sleep 1; jffs2reset -y && reboot")
        reset_shortest_time = reset_interval + os.time()
        local f = nixio.open("/tmp/reset_shortest_time", "w", 600)
        f:writeall(reset_shortest_time)
        f:close()

        return 0
    else
        return sferr.ERROR_NO_WAITTING_RESET
    end
end


function get_stok_local()
    result = {}
    code = 0
    local stok = luci.dispatcher.build_url()
    local stok1,stok2 = string.match(stok,"(%w+)=([a-fA-F0-9]*)")

    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
        result["stok"] = stok2
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_stok_remote()
    --return the same value as local request
    get_stok_local()
end

function set_Password()
    local result = {}
    local code = 0
    local username = "admin"
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local oldpasswd = arg_list_table["oldpwd"]
    local pwd = arg_list_table["newpwd"]

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local authen_vaild = luci.sys.user.checkpasswd(username,oldpasswd)

        if authen_vaild == false then
            code = sferr.ERROR_NO_OLDPASSWORD_INCORRECT
        else
            code = luci.sys.user.setpasswd("admin", pwd)
        end
        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

	sysutil.sflog("INFO","Password changed!")

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end


function get_wifi_detail()

    local code = 0
    local rv = {}
    local result = { }
    local wifis = sysutil.sf_wifinetworks()

    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then

        for i, dev in pairs(wifis) do
            for n=1,#dev.networks do
                    rv[#rv+1] = {}

                    _uci_real:foreach("wireless","wifi-device",
                        function(s)
                                if s[".name"]==dev.device then
                                        rv[#rv]["band"] = s.band
                                end
                        end)

                    rv[#rv]["ifname"]     = dev.networks[n].ifname
                    rv[#rv]["mac"]     = sysutil.getMac(dev.networks[n].ifname)
                    rv[#rv]["ssid"]       = dev.networks[n].ssid
                    rv[#rv]["enable"]     = dev.networks[n].disable ==nil and 1 or 0
                    rv[#rv]["encryption"] = dev.networks[n].encryption_src
                    rv[#rv]["signal"]     = dev.networks[n].signal
                    rv[#rv]["password"]   = dev.networks[n].password
                    rv[#rv]["channel"]    = dev.networks[n].channel
            end
        end
        code = 0
        result["info"] = rv
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
    return

end

function get_ssids()

    local wifis = sysutil.sf_wifinetworks()
    local ssids = {}
    for i, dev in pairs(wifis) do
        for n=1,#dev.networks do

            ssids[#ssids+1] = dev.networks[n].ssid

        end
    end
    return ssids
end


function getdev_by_ssid(ssid)

    local wifis = sysutil.sf_wifinetworks()
    for i, dev in pairs(wifis) do
        for n=1,#dev.networks do

            if dev.networks[n].ssid == ssid then
                return dev
            end
        end
    end
    return
end

function get_wan_type()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local proto   = uci:get("network","wan","proto")
        if(proto == "dhcp") then
            result["type"] = 0
        elseif(proto == "pppoe") then
            result["type"]    = 1
            result["pppname"] = uci:get("network","wan","username")
            result["pppwd"]   = uci:get("network","wan","password")
        elseif(proto == "static") then
            result["type"]    = 2
            result["ip"]      = uci:get("network","wan","ipaddr")
            result["mask"]    = uci:get("network","wan","netmask")
            result["gateway"] = uci:get("network","wan","gateway")
        else
            code = sferr.ERROR_NO_WAN_PROTO_EXCEPTION
        end
        if(code == 0) then
            if( uci:get("network","wan","dns") ) then
                result["autodns"] = 0
                local dns = uci:get("network","wan","dns")
                local dns1, dns2 = dns:match('([^%s]+)%s+([^%s]+)')
                if(not dns1) then
                    result["dns1"] = dns
                else
                    result["dns1"]    = dns1
                    result["dns2"]    = dns2
                end
            else
                result["autodns"] = 1
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_wan_type()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code   = 0
    local pure_config = "basic_setting"
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local _type = arg_list_table["type"]
        if(not _type) then
            code = sferr.ERROR_NO_WANSET_TYPE_NOT_FOUND
        elseif( _type~=0 and _type~=1 and _type~=2 ) then
            code = sferr.ERROR_NO_WANSET_TYPE_EXCEPTION
        else

            local basic_setting = _uci_real:get_all(pure_config)
            if basic_setting.wan_type == nil then
                _uci_real:set(pure_config, "wan_type", "setting")
            end
            _uci_real:set(pure_config, "wan_type", "type", _type)

            local proto = uci:get("network","wan","proto")
            if(proto == "pppoe") then
                uci:delete("network","wan","username")
                uci:delete("network","wan","ppppwd")
            end
            if(proto == "static") then
                uci:delete("network","wan","ipaddr")
                uci:delete("network","wan","netmask")
                uci:delete("network","wan","gateway")
            end
            if(_type == 0) then
                uci:set("network","wan","proto","dhcp")
            elseif(_type == 1) then
                uci:set("network","wan","proto","pppoe")
                local pppname = arg_list_table["pppname"]
                if pppname and string.len(pppname)>31 then
                    local pppname_tmp = pppname
                    pppname = string.sub(pppname,1,31)
                end
                local ppppwd  = arg_list_table["ppppwd"]
                if ppppwd and string.len(ppppwd)>31 then
                    local ppppwd_tmp = ppppwd
                    ppppwd = string.sub(ppppwd,1,31)
                end

                if(pppname) then
                    _uci_real:set(pure_config, "wan_type", "pppname", pppname)
                    uci:set("network","wan","username",pppname)
                end
                if(ppppwd) then
                    _uci_real:set(pure_config, "wan_type", "ppppwd", ppppwd)
                    uci:set("network","wan","password",ppppwd)
                end
            else
                uci:set("network","wan","proto","static")
                local address = arg_list_table["address"]
                if address and string.len(address)>31 then
                    local address_tmp = address
                    address = string.sub(address,1,31)
                end
                local mask    = arg_list_table["mask"]
                if mask and string.len(mask)>31 then
                    local mask_tmp = mask
                    mask = string.sub(mask,1,31)
                end
                local gateway = arg_list_table["gateway"]
                if gateway and string.len(gateway)>31 then
                    local gateway_tmp = gateway
                    gateway = string.sub(gateway,1,31)
                end
                if(address) then
                    uci:set("network","wan","ipaddr",address)
                    _uci_real:set(pure_config, "wan_type", "ip", address)
                end
                if(mask) then
                    uci:set("network","wan","netmask",mask)
                    _uci_real:set(pure_config, "wan_type", "mask", mask)
                end
                if(gateway) then
                    uci:set("network","wan","gateway",gateway)
                    _uci_real:set(pure_config, "wan_type", "gateway", gateway)
                end
            end
            local autodns = arg_list_table["autodns"]

            if autodns then _uci_real:set(pure_config, "wan_type", "autodns", autodns)  end

            if(autodns == 1) then
                uci:delete("network","wan","peerdns")
                uci:delete("network","wan","dns")
            end
            if(autodns == 0 or  _type == 2) then
                local dns =""
                local dns1 = arg_list_table["dns1"]
                if dns1 and string.len(dns1)>31 then
                    local dns1_tmp = dns1
                    dns1 = string.sub(dns1,1,31)
                end
                local dns2 = arg_list_table["dns2"]
                if dns2 and string.len(dns2)>31 then
                    local dns2_tmp = dns2
                    dns2 = string.sub(dns2,1,31)
                end
                if dns1 then _uci_real:set(pure_config, "wan_type", "dns1", dns1) end
                if dns2 then _uci_real:set(pure_config, "wan_type", "dns2", dns2) end
                if(dns1 and dns2) then
                    dns  = dns1..' '..dns2
                elseif(dns1) then
                    dns=dns1
                else
                    code = sferr.ERROR_NO_WANSET_DNS_NOT_FOUND
                end
                if(autodns == 0) then
                    uci:set("network","wan","peerdns","0")
                end
                uci:set("network","wan","dns",dns)
            end
        end
        if(code == 0) then
            local changes = uci:changes("network")
            if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
                uci:save("network")
                uci:commit("network")
                uci:load("network")
                luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
	sysutil.sflog("INFO","WAN configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_lan_type()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        result["ip"]           = uci:get("network","lan","ipaddr")
        result["mtu"]          = tonumber(uci:get("network","lan","mtu"))
        result["dynamic_dhcp"] = uci:get("dhcp","lan","ignore") == '1' and 0 or 1
        result["dhcpstart"]    = tonumber(uci:get("dhcp","lan","start"))
        result["dhcpend"]      = tonumber(uci:get("dhcp","lan","limit"))
        result["leasetime"]    = uci:get("dhcp","lan","leasetime")

        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_lan_type()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code   = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local address = arg_list_table["address"]
    local mtu = arg_list_table["mtu"]
    local dynamic_dhcp = arg_list_table["dynamic_dhcp"]
    local dhcpstart = arg_list_table["dhcpstart"]
    local dhcpend = arg_list_table["dhcpend"]
    local leasetime = arg_list_table["leasetime"]

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        if address then
            uci:set("network","lan","ipaddr",address)
        end

        if mtu and mtu<1500 then
            uci:set("network","lan","mtu",mtu)
        end

        if dynamic_dhcp then
            uci:set("dhcp","lan","ignore",dynamic_dhcp)
        end

        if dhcpstart then
            uci:set("dhcp","lan","start",dhcpstart)
        end
        if dhcpend then
            uci:set("dhcp","lan","limit",dhcpend)
        end
        if leasetime then
            uci:set("dhcp","lan","leasetime",leasetime)
        end

        if(code == 0) then
            local network_changes = uci:changes("network")
            if((network_changes ~= nil) and (type(network_changes) == "table") and (next(network_changes) ~= nil)) then
                uci:save("network")
                uci:commit("network")
                uci:load("network")
                luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
            end
            local dhcp_changes = uci:changes("dhcp")
            if((dhcp_changes ~= nil) and (type(dhcp_changes) == "table") and (next(dhcp_changes) ~= nil)) then
                uci:save("dhcp")
                uci:commit("dhcp")
                uci:load("dhcp")
                luci.sys.call("env -i /etc/init.d/dnsmasq restart; sleep 1")
            end
        end
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
	sysutil.sflog("INFO","LAN configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function detect_wan_type()
    local uci = require "luci.model.uci".cursor()
    local result = {}
    local code = 0
    local extraInfo = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local dt_iface   = uci:get("network","wan","ifname")
		local runcmd  = "wandetect "..dt_iface
		local checkret =  luci.util.exec(runcmd)
		local wantype = string.sub(checkret,1,-2)
		result["wantype"] = wantype
        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)..extraInfo
   else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end


function set_wifi_info()
	local network = require("luci.model.network").init()
	local wifinet = {}
	local wifidev = {}
	local code = 0
	local rv = {}
	local result = { }
	local dev = nil
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local freq_inter = wirelessnew.get_freq_intergration_impl()
	local wdev_2= network:get_wifidev("radio0")
	local wifinet_24g = wdev_2:get_wifinet("wlan0")

	local setting_param = arg_list_table["setting"]
	local protocol = arg_list_table["version"]
	local param_disableall = arg_list_table["disableall"]
	local setting_param_json = nil

	if param_disableall and param_disableall == 0 or param_disableall == 1 then
		ssids = get_ssids()
		setting_param_json = {}
		for i=1,#ssids do
			setting_param_json[i] = {}
			setting_param_json[i].oldssid = ssids[i]
			setting_param_json[i].enable = param_disableall=="1" and 0 or 1
		end
	else
		if setting_param then
			setting_param_json = json.decode(setting_param)
		else
			code = sferr.ERROR_NO_WIFI_SETTING_EMPTY
		end
	end

	local matchssid = false

	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		if setting_param_json then
			for i=1,#setting_param_json do
				if setting_param_json[i].oldssid then
					dev = getdev_by_ssid(setting_param_json[i].oldssid)
				end
				if dev then
					for n=1,#dev.networks do
						local param_ssid = nil
						local param_enable = nil
						local param_key = nil
						local param_encryption = nil
						local param_signal_mode = nil
						local param_channel = nil
						if setting_param_json[i].newssid then
							param_ssid = setting_param_json[i].newssid
						end
						if setting_param_json[i].enable then
							param_enable = setting_param_json[i].enable
						end
						if setting_param_json[i].password then
							param_key = setting_param_json[i].password
						end
						if setting_param_json[i].encryption then
							param_encryption = setting_param_json[i].encryption
						end
						if setting_param_json[i].signalmode then
							param_signal_mode = setting_param_json[i].signalmode
						end
						if setting_param_json[i].channel then
							param_channel = setting_param_json[i].channel
						end

						if param_ssid and string.len(param_ssid)>31 then
							local param_ssid_tmp = param_ssid
							param_ssid = string.sub(param_ssid_tmp,1,31)
						end
						if param_key and string.len(param_key)>31 then
							local param_key_tmp = param_key
							param_key = string.sub(param_key_tmp,1,31)
						end

						local cur_device = nil
						_uci_real:foreach("wireless", "wifi-iface",
						function(s)
							if s.ssid == dev.networks[n].ssid then
								cur_device = s.device
							end
						end
						)

						if(param_ssid or param_enable or param_key or param_encryption or param_signal_mode or param_channel or param_disableall) then
							matchssid = true
							wifidev = network:get_wifidev(dev.device)
							if(wifidev and param_channel) then
								wifidev:set("channel", param_channel)
							end
							wifinet = network:get_wifinet(dev.device..".network1")
							if(wifinet) then
								if not (wifidev:get("band") == "2.4G" and freq_inter) then
									if(param_ssid) then wifinet:set("ssid", param_ssid) end
									if(param_enable) then
										wifinet:set("disabled", param_enable~=1 and 1 or nil )
									end
									if(param_key) then wifinet:set("key", param_key) end
									if(param_encryption) then wifinet:set("encryption",param_encryption) end
									if freq_inter  then
										if(param_ssid) then wifinet_24g:set("ssid", param_ssid) end
										if(param_enable) then
											wifinet_24g:set("disabled", param_enable~=1 and 1 or nil )
										end
										if(param_key) then wifinet_24g:set("key", param_key) end
										if(param_encryption) then wifinet_24g:set("encryption",param_encryption) end
									end
								end
							end
							if(param_signal_mode) then
								if param_signal_mode == SAVE_MODE then
									wifidev:set("txpower", SAVE_MODE_TXPOWER)
								elseif param_signal_mode == NORMAL_MODE then
									wifidev:set("txpower", NORMAL_MODE_TXPOWER)
								elseif param_signal_mode == PREFORMANCE_MODE then
									wifidev:set("txpower", PREFORMANCE_MODE_TXPOWER)
								else
									code = sferr.ERROR_NO_UNKNOWN_SIGNAL_MODE
								end
							end
						end
					end
				end
			end
		else
			code = sferr.ERROR_NO_SSID_NONEXIST
		end

		if(not matchssid) then
			code = sferr.ERROR_NO_SSID_UNMATCH
		end

		if code==0 then
			local changes = network:changes()
			if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
				nixio.syslog("crit","apply changes")
				network:save("wireless")
				network:commit("wireless")
				sysutil.resetWifiDevice()
				sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
			end
		end

		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end

	sysutil.sflog("INFO","Wifi configure changed!")
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function set_wifi_advanced()

	local network = require("luci.model.network").init()
	local wifinet = {}
	local wifidev = {}
	local code = 0
	local result = { }
	local dev = nil
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local setting_param = arg_list_table["setting"]
	local param_disableall = arg_list_table["disableall"]

	local freq_inter = wirelessnew.get_freq_intergration_impl()
	local wdev_2= network:get_wifidev("radio0")
	local wifinet_24g = wdev_2:get_wifinet("wlan0")

	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		if setting_param then
			setting_param_json = setting_param
			local wifis = sysutil.sf_wifinetworks()
			for i, dev in pairs(wifis) do
				wifidev = network:get_wifidev(dev.device)
				wifinet = network:get_wifinet(dev.device..".network1")

				if setting_param_json[i].channel then wifidev:set("channel", setting_param_json[i].channel) end
				if setting_param_json[i].country then wifidev:set("country", setting_param_json[i].country) end
				if setting_param_json[i].distance then wifidev:set("distance", setting_param_json[i].distance) end
				if setting_param_json[i].fragment then wifidev:set("frag", setting_param_json[i].fragment) end
				if setting_param_json[i].rts then wifidev:set("rts", setting_param_json[i].rts) end
				if setting_param_json[i].bandwidth then
					if setting_param_json[i].bandwidth == 0 then
						wifidev:set("htmode", "HT20")
					elseif setting_param_json[i].bandwidth == 1 then
						wifidev:set("htmode", "HT40")
					elseif setting_param_json[i].bandwidth == 2 then
						wifidev:set("htmode", "HT20/HT40")
					elseif setting_param_json[i].bandwidth == 3 then
						wifidev:set("htmode", "VHT80")
					end
				end
				if param_disableall and param_disableall == 1 then setting_param_json[i].enable = 0 end
				if not (wifidev:get("band") == "2.4G" and freq_inter) then
					if setting_param_json[i].ssid then wifinet:set("ssid", setting_param_json[i].ssid) end

					if setting_param_json[i].enable then
						wifinet:set("disabled", setting_param_json[i].enable~=1 and 1 or nil );
					end

					if freq_inter  then
						if setting_param_json[i].ssid then wifinet_24g:set("ssid", setting_param_json[i].ssid) end

						if setting_param_json[i].enable then
							wifinet_24g:set("disabled", setting_param_json[i].enable~=1 and 1 or nil );
						end

					end
				end


				if setting_param_json[i].signalmode then
					if setting_param_json[i].signalmode == SAVE_MODE then
						wifidev:set("txpower", SAVE_MODE_TXPOWER)
					elseif setting_param_json[i].signalmode == NORMAL_MODE then
						wifidev:set("txpower", NORMAL_MODE_TXPOWER)
					elseif setting_param_json[i].signalmode == PREFORMANCE_MODE then
						wifidev:set("txpower", PREFORMANCE_MODE_TXPOWER)
					else
						code = sferr.ERROR_NO_UNKNOWN_SIGNAL_MODE
					end
				end
			end
		else
			code = sferr.ERROR_NO_WIFI_SETTING_EMPTY
		end

		if code==0 then
			local changes = network:changes()
			if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
				nixio.syslog("crit","apply changes")
				network:save("wireless")
				network:commit("wireless")
				sysutil.resetWifiDevice()
				sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
			end
		end

		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end



	sysutil.sflog("INFO","Advanced wifi configure changed!")
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function get_wifi_advanced()

	local code = 0
	local rv = {}
	local result = { }
	local wifis = sysutil.sf_wifinetworks()
	local network = require("luci.model.network").init()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then

		for i, dev in pairs(wifis) do
			wifidev = network:get_wifidev(dev.device)
			wifinet = network:get_wifinet(dev.device..".network1")
			rv[#rv+1] = {}

			rv[#rv]["ifname"]     = wifinet:get("ifname")
			rv[#rv]["enable"]     = wifinet:get("disable")==nil and 1 or 0
			rv[#rv]["ssid"]       = wifinet:get("ssid")
			rv[#rv]["encryption"] = wifinet:get("encryption")
			rv[#rv]["password"]   = wifinet:get("key")
			rv[#rv]["country"]    = wifidev:get("country")
			rv[#rv]["htmode"]     = wifidev:get("htmode")
			rv[#rv]["channel"]    = tonumber(wifidev:get("channel"))
			rv[#rv]["distance"]   = tonumber(wifidev:get("distance"))
			rv[#rv]["fragment"]   = tonumber(wifidev:get("frag"))
			rv[#rv]["rts"]        = tonumber(wifidev:get("rts"))
			if tonumber(wifidev:get("txpower")) == SAVE_MODE_TXPOWER then
				rv[#rv]["signalmode"] = SAVE_MODE
			elseif tonumber(wifidev:get("txpower")) == NORMAL_MODE_TXPOWER then
				rv[#rv]["signalmode"] = NORMAL_MODE
			elseif tonumber(wifidev:get("txpower")) == PREFORMANCE_MODE_TXPOWER then
				rv[#rv]["signalmode"] = PREFORMANCE_MODE
			end
		end

		result["disableall"] = 1
		for i=1,#rv do
			if rv[i]["enable"] == 1 then
				result["disableall"] = 0
			end
		end
		code = 0
		result["info"] = rv
		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function get_customer_wifi_iface()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.get_customer_wifi_iface()
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function set_customer_wifi_iface()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.set_customer_wifi_iface(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	--	sysutil.sflog("INFO","Guest wifi configure changed!"%{mac})--customer wifi configure change!的log是用网页打印的
	return
end

function wifi_scan()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.wifi_scan(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function wifi_connect()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.wifi_connect(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function wds_getwanip()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.wds_getwanip(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function wds_enable()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.wds_enable(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function wds_disable()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.wds_disable(arg_list)
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function get_wds_info()

	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	elseif(sysutil.version_check(protocol)) then
		result = wirelessnew.get_wds_info()
	else
		result = sferr.errProtocolNotSupport()
		luci.http.prepare_content("application/json")
		luci.http.write_json(result)
	end

	return
end

function get_assic_count()

    local assic_count = 0
    local wifis = sysutil.sf_wifinetworks()
    for i, dev in pairs(wifis) do
        for n=1,#dev.networks do
            for assic_addr,assic_info in pairs(dev.networks[n].assoclist) do
                assic_count = assic_count + 1
            end
        end
    end

    return assic_count
end

function get_wifi_speed()

    local wifis = sysutil.sf_wifinetworks()
    local ln = {}
    for i,dev in pairs(wifis) do
        ln[i] = {}
        for n=1,#dev.networks do
            ln[i][n] = {}
            local bwc = io.popen("luci-bwc -i %q 2>/dev/null" % dev.networks[n].ifname)
            if bwc then

                while true do
                    local tmp = bwc:read("*l")
                    if not tmp then break end
                    ln[i][n][#ln[i][n]+1] = {}
                        nixio.syslog("crit",tmp)
                    local stamp,rxb,rxp,txb,txp = string.match(tmp,"(%w+),%s(%w+),%s(%w+),%s(%w+),%s(%w+)")
                    ln[i][n][#ln[i][n]]["stamp"] = stamp
                    ln[i][n][#ln[i][n]]["rxb"] = rxb
                    ln[i][n][#ln[i][n]]["rxp"] = rxp
                    ln[i][n][#ln[i][n]]["txb"] = txb
                    ln[i][n][#ln[i][n]]["txp"] = txp

                end

                bwc:close()
            end
        end
    end

    return ln
end

function get_wan_speed()
    local ntm = require "luci.model.network".init()
    local wandev = ntm:get_wandev()
    local wan_ifname = wandev.ifname
    local data = {}
    local speed = {}
    local bwc = io.popen("luci-bwc -i %q 2>/dev/null" % wan_ifname)
    if bwc then

           while true do
               local tmp = bwc:read("*l")
               if not tmp then break end
               data[#data+1] = {}
               local stamp,rxb,rxp,txb,txp = string.match(tmp,"(%w+),%s(%w+),%s(%w+),%s(%w+),%s(%w+)")
               data[#data]["stamp"] = stamp
               data[#data]["rxb"] = rxb
               data[#data]["rxp"] = rxp
               data[#data]["txb"] = txb
               data[#data]["txp"] = txp

          end
          bwc:close()
    else
        return
    end

    local time_delta = 0
    local rx_speed_avg = 0
    local tx_speed_avg = 0
    if #data>1 then
        time_delta = data[#data]["stamp"] - data[1]["stamp"]
        rx_speed_avg = (data[#data]["rxb"]-data[1]["rxb"])/time_delta
        tx_speed_avg = (data[#data]["txb"]-data[1]["txb"])/time_delta
    end

    speed["rx_speed_avg"] = math.abs(math.floor(rx_speed_avg))
    speed["tx_speed_avg"] = math.abs(math.floor(tx_speed_avg))
    return speed
end

function memory_load()

    local _, _, memtotal, memcached, membuffers, memfree, _, swaptotal, swapcached, swapfree = luci.sys.sysinfo()

    local memrunning = memtotal - memfree
    local memload_rate = memrunning/memtotal
    memload_rate = (memload_rate - memload_rate%0.01)*100
    return memload_rate

end

function cpu_load()

    local data = {}
    local cpuload_rate = -1
    while cpuload_rate == -1 do
        local info =  io.popen("top -n 1 2>/dev/null")
        if info then
              while true do
                   local tmp = info:read("*l")
                   if not tmp then break end
                   data[#data+1] = tmp
                   --get idle
                   local idle = string.match(tmp,"nic%s+(%d+)%.%d+%%%sidle")
                   if idle then
                      cpuload_rate = 100 - idle
                      break
                   end
              end
              info:close()
              break
        end
    end

    return cpuload_rate

end

function get_router_status()

    local code = 0
    local result = { }
    local wifis = sysutil.sf_wifinetworks()
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local querycpu = arg_list_table["querycpu"]
    local querymem = arg_list_table["querymem"]

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        result["status"] = sysutil.readRouterState()
        result["devicecount"] = get_assic_count()
        if get_wan_speed() then
            result["upspeed"] = get_wan_speed().tx_speed_avg
            result["downspeed"] = get_wan_speed().rx_speed_avg
        else
            code = sferr.ERROR_NO_CANNOT_GET_LANSPEED
        end

        result["cpuload"] = (querycpu == 1) and cpu_load() or 0
        result["memoryload"] = (querymem == 1) and memory_load() or 0

        result["downloadingcount"] = 0   --------------------------TODO----------------------
        result["useablespace"] = 0       --------------------------TODO---------------------

        result["code"] = code
        result["msg"]  = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
    return

end

function get_useableifname()

    local useable_ifname = {}
    local allifname = luci.sys.net.devices()
    for i,ifname in pairs(allifname) do
        if ifname:match("eth") or ifname:match("ra") then
                useable_ifname[#useable_ifname+1] = ifname
        end
    end
    return useable_ifname
end

function getdevname(ipaddr)
    local hostname = nil
    dhcp_fd = io.open("/tmp/dhcp.leases", "r")
    if dhcp_fd then
        while true do
            local tmp = dhcp_fd:read("*l")
            if not tmp then break end
            if tmp:find(ipaddr) then
                hostname = tmp:match("^%d+ %S+ %S+ (%S+)")
                break
            end
        end
        dhcp_fd:close()
    end
    if hostname == nil then
        hostname = ""
    end
    return hostname
end

function getofflinemac(ipaddr)
    local mac = nil
    arp_fd = io.open("/proc/net/arp", "r")
    if arp_fd then
        while true do
            local tmp = arp_fd:read("*l")
            if not tmp then break end
            if tmp:find(ipaddr) then
                mac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)")
                break
            end
        end
        arp_fd:close()
    end

    return mac
end

function get_system_runtime()
    local runtime = nil
    local time_fd = io.open("/proc/uptime","r")
    if time_fd then
        local tmp = time_fd:read("*l")
        if tmp then
            runtime = tmp:match("(%d+).*")
        end
    end
    if runtime then
        return tonumber(runtime)
    else
        return 0
    end
end

function ndscan(ipaddr, interface)

    local data = nil
    local scan_fd = nil
    scan_fd = io.popen("ndscan -i %s -d %s -t 10 -c 2 2>/dev/null" %{interface, ipaddr})
    if scan_fd then
        local tmp = scan_fd:read("*l")
        if tmp then
            local mac1,mac2,mac3,mac4,mac5,mac6 = tmp:match("([a-fA-F0-9]*):([a-fA-F0-9]*):([a-fA-F0-9]*):([a-fA-F0-9]*):([a-fA-F0-9]*):([a-fA-F0-9]*)")
            if mac1 and mac2 and mac3 and mac4 and mac5 and mac6 then
                data = {}
                data["dev"] = interface
                data["mac"] = string.upper(mac1.."_"..mac2.."_"..mac3.."_"..mac4.."_"..mac5.."_"..mac6)
                data["ip"] = ipaddr
                data["online"] = "1"
                data["port"] = "0"
            end
        end
        scan_fd:close()
    end

    return data
end

function get_wire_ip_mac()
    local mac = nil
    local ip_mac = nil
    arp_fd = io.open("/proc/net/arp", "r")
    local wan_ifname = _uci_real:get("network", "wan", "ifname")
	local wldev,j = get_wireless_device_mac()
	local is_wl
	if not wan_ifname then
		return nil
	end

    if arp_fd then
        ip_mac = {}
        while true do
            local tmp = arp_fd:read("*l")
			is_wl = 0
            if not tmp then break end
            if(not string.match(tmp,wan_ifname)) then
            	ip = tmp:match("([0-9]+.[0-9]+.[0-9]+.[0-9]+)")
            	mac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)")
				if ip and mac then
					local mac_first_part = mac:match("^([0-9]+):")
					if mac_first_part == "0" then
						mac = "0"..(mac:upper()):gsub(":", "_")
					else
						mac = (mac:upper()):gsub(":", "_")
					end
					for i=1, j do
						if wldev[i]["mac"] == mac then
							is_wl = 1
							break
						end
					end
					_uci_real:foreach("wldevlist", "device",
							function(s)
								if mac == s.mac then
									is_wl = 1
								end
							end
						)

					if is_wl == 0 then
						ip_mac[#ip_mac+1] = {}
						ip_mac[#ip_mac]["ip"] = ip
						ip_mac[#ip_mac]["mac"] = mac
					end
				end
            end
        end
        arp_fd:close()
    end

    return ip_mac

end

function set_easy_return(code, result)
    local result_here = { }
	if result then
		result_here = result
	end
	result_here["code"] = code
	result_here["msg"] = sferr.getErrorMessage(code)

	luci.http.prepare_content("application/json")
	luci.http.write_json(result_here)
end
function get_list_by_mac(mac)
	local op_list="wldevlist"
	_uci_real:foreach("devlist", "device",
		function(s)
			if s.mac == mac then
				op_list="devlist"
			end
		end
	)
	return op_list
end

function set_speed()
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local dev_mac = arg_list_table["mac"]
    local dev_enable = arg_list_table["enable"]

    local code = 0
	dev_mac = dev_mac:upper()
	local op_list = get_list_by_mac(dev_mac)

	if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then

		local mac_fmt = dev_mac:gsub("_",":")
		set_limit = _uci_real:get(op_list, dev_mac,"speedlimit") or 0

		if dev_enable == 1 then
			speed_ul = arg_list_table["limitup"]
			speed_dl = arg_list_table["limitdown"]
			if set_limit == dev_enable then
				luci.util.exec("pctl speed update %s %s %s"%{mac_fmt, speed_ul, speed_dl})
			else
				luci.util.exec("pctl speed add %s %s %s"%{mac_fmt, speed_ul, speed_dl})
			end
			_uci_real:set(op_list, dev_mac, "limitup", speed_ul)
			_uci_real:set(op_list, dev_mac, "limitdown", speed_dl)
		else
			luci.util.exec("pctl speed del %s"%{mac_fmt})
		end
		_uci_real:set(op_list, dev_mac, "speedlimit", dev_enable)
		_uci_real:save(op_list)
		_uci_real:commit(op_list)
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end

	sysutil.sflog("INFO","Device %s speed configure changed!"%{dev_mac})
	set_easy_return(code, nil)

	return
end

function urllist_set()
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]

    local listtype = arg_list_table["listtype"]
    local mac = arg_list_table["mac"]
    local op_list = get_list_by_mac(mac)

	if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		if listtype == 0 then
			if #arg_list_table["urllist"] == 0 then
				_uci_real:set_list(op_list, mac, "white_list", "")
			else
				_uci_real:set_list(op_list, mac, "white_list", arg_list_table["urllist"])
			end

		else
			if #arg_list_table["urllist"] == 0 then
				_uci_real:set_list(op_list, mac, "black_list", "")
			else
				_uci_real:set_list(op_list, mac, "black_list", arg_list_table["urllist"])
			end
		end

		_uci_real:save(op_list)
		_uci_real:commit(op_list)
		--Todo: update url config --

	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end

	sysutil.sflog("INFO","Device %s dns block configure changed!"%{mac})
	set_easy_return(code,nil)
	return
end

function urllist_get()

    local code = 0
    local result = { }
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]

    local listtype= arg_list_table["listtype"]
    local mac = arg_list_table["mac"]
	local url_list= {}
    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then

		local op_list = get_list_by_mac(mac)
		if listtype == 0 then
			url_list= _uci_real:get_list(op_list , mac, "white_list")
		else
			url_list= _uci_real:get_list(op_list , mac, "black_list")
		end
		if url_list then
			result["urllist"] = url_list
		end
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end

	set_easy_return(code,result)
	return
end

function urllist_enable()

    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]

    local listfunc = tostring(arg_list_table["listfunc"])
    local mac = arg_list_table["mac"]


    if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then

		local op_list = get_list_by_mac(mac)
		local uci_list_func = _uci_real:get(op_list , mac,"listfunc")

		if not uci_list_func then
			uci_list_func = "0"
		end

		local url_list_send = {
			["mac"] = mac,
			["func"] = listfunc,
			["uci_func"] = uci_list_func,
			["list"] = arg_list_table["urllist_en"],
		}
		if uci_list_func ~= listfunc then
			_uci_real:set(op_list , mac, "listfunc", listfunc)
			_uci_real:save(op_list )
			_uci_real:commit(op_list )
		end

		local cmd = "URLL -data "..json.encode(url_list_send)
		local cmd_ret = {}
		sysutil.sendCommandToLocalServer(cmd, cmd_ret)
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end
	set_easy_return(code,nil);
	return
end

function get_wire_assocdev(deal_new)
	local data = {}
    local wire_ifname = _uci_real:get("network", "lan", "ifname");
	local lan_ip = _uci_real:get("network", "lan", "ipaddr")
	local lan_net = string.sub(lan_ip,1,lan_ip:len()-string.find(lan_ip:reverse(),"%.")+1).."*" -- only for netmask is 255.255.255.0
    local dev_exist = nil
    local online = nil
    local ip2mac = {}
	local hostname = nil

    ip2mac = get_wire_ip_mac()
	if not ip2mac then
		nixio.syslog("crit", "[sfsystem] get ip_mac failed");
		return nil
	end
    _uci_real:foreach("devlist", "device",
		function(s)
			   data[#data+1] = {}
			   data[#data]["mac"] = s.mac
			   data[#data]["online"] = "0"
		end
		)
	local arpscan_f = io.open("/tmp/arpscan-ip","w")
	for i=1,#ip2mac do
		arpscan_f:write(ip2mac[i]["ip"].."\n")
	end
	arpscan_f:close()

	local arpscan_res = io.popen("arp-scan -I %s -f /tmp/arpscan-ip -r 3 -q -s %s -x" % {wire_ifname,lan_ip})
	local arp_ip = {}
	local arp_mac = {}
	local rip
	local rmac
    if arpscan_res then
        while true do
            local tmp = arpscan_res:read("*l")
            if not tmp then break end
			rip = tmp:match("([0-9]+.[0-9]+.[0-9]+.[0-9]+)")
			rmac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)")
			if rip then
				arp_ip[#arp_ip+1] = rip
				arp_mac[#arp_mac+1] = (rmac:gsub(":","_")):upper()
			end
        end
        arpscan_res:close()
    end

    for i=1,#ip2mac do
        if ip2mac[i]["mac"] ~= "00_00_00_00_00_00" and string.match(ip2mac[i]["ip"],lan_net) then
            dev_exist = 0
            local ip = ip2mac[i]["ip"]
			local online
            _uci_real:foreach("devlist", "device",
                        function(s)
                            if ip2mac[i]["mac"] == s.mac then
                                dev_exist = 1
								ip = s.ip
								online = s.online
								hostname = s.hostname or ""
                            end
                        end
                    )
			local scan_value = 0
			for k=1,#arp_ip do
				if arp_ip[k] == ip2mac[i]["ip"] and arp_mac[k] == ip2mac[i]["mac"] then
					scan_value = 1
				end
			end
			if(dev_exist == 1) then
				if scan_value == 1 then
					data[#data+1] = {}
					data[#data]["mac"] = ip2mac[i]["mac"]
					data[#data]["online"] = "1"
					if online == "0" or ip2mac[i]["ip"] ~= ip then
						data[#data]["ip"] = ip2mac[i]["ip"]
						data[#data]["hostname"] = getdevname(ip2mac[i]["ip"]) or hostname
						data[#data]["associate_time"] = get_system_runtime()
					end
				end
			else
				if scan_value == 1 and deal_new ~= "0" then
					nixio.syslog("crit", "wire add new device "..ip2mac[i]["mac"]);
					local lan = _uci_real:get("sidefault", "acl", "lan")
					local internet = _uci_real:get("sidefault", "acl", "internet")
					luci.util.exec("tscript add "..ip2mac[i]["mac"]:gsub("_", ":")) --add mac to traffic statistic
					luci.util.exec("aclscript add %s %s %s"%{ip2mac[i]["mac"]:gsub("_", ":"), lan, internet}) --add mac to acl
					data[#data+1] = {}
					data[#data]["dev"] = wire_ifname
					data[#data]["port"] = "0"
					data[#data]["ip"] = ip2mac[i]["ip"]
					data[#data]["online"] = "1"
					data[#data]["associate_time"] = get_system_runtime()
					data[#data]["mac"] = ip2mac[i]["mac"]
					data[#data]["hostname"] = getdevname(ip2mac[i]["ip"])
					data[#data]["internet"] = internet
					data[#data]["lan"] = lan
				end
			end
        end
    end

    return data
end

function set_wltab(dev)

    local alldev = dev
	local wlfile = "wldevlist"

    for i=1,#alldev do
        _uci_real:set(wlfile, alldev[i].mac , "device")
        _uci_real:tset(wlfile, alldev[i].mac , alldev[i])
    end
    _uci_real:save(wlfile)
    _uci_real:commit(wlfile)

end

function set_devlist(dev)

    local alldev = dev

    for i=1,#alldev do
        _uci_real:set("devlist", alldev[i].mac , "device")
        _uci_real:tset("devlist", alldev[i].mac , alldev[i])
    end
    _uci_real:save("devlist")
    _uci_real:commit("devlist")

end

function get_dev_trafficinfo(dev_ip, time_stamp)
    local data = {}
    local traffic = {}
    local bwc = io.popen("luci-bwc -d %s 2>/dev/null" %{dev_ip})
    if bwc then

           while true do
               local tmp = bwc:read("*l")
               if not tmp then break end
               data[#data+1] = {}
               local stamp,rxb,rxp,txb,txp = string.match(tmp,"(%w+),%s(%w+),%s(%w+),%s(%w+),%s(%w+)")
               data[#data]["stamp"] = stamp
               data[#data]["rxb"] = rxb
               data[#data]["rxp"] = rxp
               data[#data]["txb"] = txb
               data[#data]["txp"] = txp

          end
          bwc:close()
    else
        return
    end

    local time_delta = 0
    local rx_speed_cur = 0
    local tx_speed_cur = 0
    local down_traffic_total = 0
    local up_traffic_total = 0
    if #data>1 and #data<4 then
        time_delta = data[#data]["stamp"] - data[1]["stamp"]
        rx_speed_cur = (data[#data]["rxb"] - data[1]["rxb"])/time_delta
        tx_speed_cur = (data[#data]["txb"] - data[1]["txb"])/time_delta
    elseif #data >= 4 and tonumber(time_stamp or "0") < tonumber(data[#data-3]["stamp"]) then
        time_delta = data[#data]["stamp"] - data[#data-3]["stamp"]
        rx_speed_cur = (data[#data]["rxb"] - data[#data-3]["rxb"])/time_delta
        tx_speed_cur = (data[#data]["txb"] - data[#data-3]["txb"])/time_delta
    end

    if #data>1 then
        down_traffic_total = data[#data]["rxb"]
        up_traffic_total = data[#data]["txb"]
    end

    traffic["down_speed_cur"] = math.floor(rx_speed_cur)
    traffic["up_speed_cur"] = math.floor(tx_speed_cur)
    traffic["down_traffic_total"] = down_traffic_total
    traffic["up_traffic_total"] = up_traffic_total
    if(traffic["down_speed_cur"] < 0) then
        traffic["down_speed_cur"] = 0
    end
    if(traffic["up_speed_cur"] < 0) then
        traffic["up_speed_cur"] = 0
    end
    return traffic
end

function convert_devinfo_from_uci(s)
	local list_item={}
	list_item["hostname"]                   = s.hostname or ""
	list_item["nickname"]                   = s.nickname or s.hostname or ""
	list_item["mac"]                        = s.mac or ""
	list_item["online"]                     = tonumber(s.online or -1)
	list_item["ip"]                         = s.ip or "0.0.0.0"
	list_item["port"]                       = tonumber(s.port or -1)
	list_item["dev"]                        = s.dev or ""
	list_item["restrictenable"]             = tonumber(s.restrictenable or 0)
	list_item["usageenable"]                = tonumber(s.usageenable or 0)

	list_item["authority"] = {}

	list_item["authority"]["internet"]      = tonumber(s.internet or -1)
	list_item["authority"]["lan"]           = tonumber(s.lan or -1)
	list_item["authority"]["listfunc"]           = tonumber(s.listfunc or -1)
	list_item["authority"]["speedlimit"]      = tonumber(s.speedlimit or 0)
	list_item["authority"]["notify"]        = tonumber(s.notify or -1)
	list_item["authority"]["speedlvl"]      = tonumber(s.speedlvl or -1)
	list_item["authority"]["disk"]      = tonumber(s.disk or -1)
	list_item["authority"]["limitup"]       = tonumber(s.limitup or -1)
	list_item["authority"]["limitdown"]     = tonumber(s.limitdown or -1)

	list_item["speed"]     = {}
	list_item["speed"]["upspeed"]           = tonumber(s.upspeed or 0)
	list_item["speed"]["downspeed"]         = tonumber(s.downspeed or 0)
	list_item["speed"]["uploadtotal"]       = tonumber(s.uploadtotal or 0)
	list_item["speed"]["downloadtotal"]     = tonumber(s.downloadtotal or 0)
	list_item["speed"]["maxuploadspeed"]    = tonumber(s.maxuploadspeed or 0)
	list_item["speed"]["maxdownloadspeed"]  = tonumber(s.maxdownloadspeed or 0)
	if list_item["online"] == 0 then
		list_item["speed"]["online"] = 0
	else
		list_item["speed"]["online"]        = tonumber(s.associate_time or -1)~=-1 and (get_system_runtime()-tonumber(s.associate_time)) or 0
	end
	local timelist = {}
	_uci_real:foreach("timelist",s[".name"],
				function(d)
					timelist[#timelist+1] = {}
					timelist[#timelist]["enable"] = tonumber(d.enable)
					timelist[#timelist]["starttime"] = d.starttime
					timelist[#timelist]["endtime"] = d.endtime
					timelist[#timelist]["week"] = d.week or ""
				end)
	if #timelist ~= 0 then
		list_item["timelist"] = timelist
	end

	return list_item
end


function get_devinfo_from_devlist(mode, mac)
	local list_dev= {}
	local count = 0
	nixio.syslog("crit", "[sfsystem] mode:"..mode.."mac:"..tostring(mac));
	if mode == 3 then
-- first search wireless
		local dev_info  = _uci_real:get_all("wldevlist", mac)
		if dev_info then
			list_dev[#list_dev+1] = convert_devinfo_from_uci(dev_info)
        else
			dev_info  = _uci_real:get_all("devlist", mac)
			if dev_info then
				list_dev[#list_dev+1] = convert_devinfo_from_uci(dev_info)
			end
		end
		return list_dev,1
	end

	_uci_real:foreach("wldevlist", "device",
	function(s)
		nixio.syslog("crit", "[sfsystem] name is :"..tostring(s[".name"]));
		if s[".name"] ~= "00_00_00_00_00_00" then
			if mode == 0 then
				list_dev[#list_dev+1] = convert_devinfo_from_uci(s)
			else
				if s.online == '1' then
					if mode == 1 then
						list_dev[#list_dev+1] = convert_devinfo_from_uci(s)
					else
						count= count + 1
					end
				end
			end
		end
	end
	)

       _uci_real:foreach("devlist", "device",
	function(s)
		nixio.syslog("crit", "[sfsystem] name is :"..tostring(s[".name"]));
		if s[".name"] ~= "00_00_00_00_00_00" then
			if mode == 0 then
				list_dev[#list_dev+1] = convert_devinfo_from_uci(s)
			else
				if s.online == '1' then
					if mode == 1 then
						list_dev[#list_dev+1] = convert_devinfo_from_uci(s)
					else
						count= count + 1
					end
				end
			end
		end
	end
	)
	return list_dev,count
end

function get_wireless_device_mac()
	local ifname = {}
	local number = 0
	local data = {}

	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if s.ifname then
			ifname[number] = s.ifname
			number = number + 1
		end
	end
	)
	for n=0,number do
		if(ifname[n]) then
			local name = ifname[n]
			local iwinfo = io.popen("iwinfo \"%s\" assoclist" %{name})
			local mac = nil
			if iwinfo then
				while true do
					mac = nil
					local tmp = iwinfo:read("*l")
					if not tmp then
						break
                    end
                    mac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)")
                    if mac then
						data[#data+1] = {}
                        data[#data]["mac"] = (mac:upper()):gsub(":", "_")
						data[#data]["ifname"] = ifname[n]
                    end
                end
            end
        end
    end
    return data,#data
end

function do_arp_check_device(ip, mac)
	local data = {}
	local notify = 0
	local scan_value = os.execute("ping -4 -w2 -c1 %s 2>&1 1>/dev/null" %{ip})
	local online = 0
	local finish = 0
	local ret = 0 --if need notify, return 1

	if scan_value == 0 then
		online = "1"
	end

	nixio.syslog("crit","arp check device "..ip.." mac "..mac)
    _uci_real:foreach("devlist", "device",
        function(s)
            if(mac == s.mac) then
				if (s.online == "0" or s.ip ~= ip) then
					data[#data+1] = {}
					data[#data]["mac"] = mac
					data[#data]["online"] = online
					data[#data]["ip"] = ip
					data[#data]["associate_time"] = get_system_runtime()
					data[#data]["hostname"] = s.hostname or getdevname(ip)
				end
				finish = 1
            end
        end
        )
	if finish == 1 then
		set_devlist(data)
		return ret
	end
    _uci_real:foreach("wldevlist", "device",
        function(s)
            if(mac == s.mac) then
				if (s.online == "0" or s.ip ~= ip or (s.notify and s.notify == "1" and s.push_flag == "0")) then
					data[#data+1] = {}
					data[#data]["mac"] = s.mac
					data[#data]["online"] = online
					data[#data]["ip"] = ip
					data[#data]["associate_time"] = get_system_runtime()
					data[#data]["hostname"] = s.hostname or getdevname(ip)

					if ((s.notify and s.notify == "1" and s.push_flag == "0") or s.push_flag == "2") then
						data[#data]["push_flag"] = "1"
						ret = 1
					end
				end
				finish = 1
            end
        end
        )
	if finish == 1 then
		set_wltab(data)
		return ret
	end

	local function do_set(mac, ip, ifname, online, port)
			local data = {}
			local lan = _uci_real:get("sidefault", "acl", "lan")
			local internet = _uci_real:get("sidefault", "acl", "internet")

			luci.util.exec("tscript add "..mac:gsub("_", ":")) --add mac to traffic statistic
			luci.util.exec("aclscript add %s %s %s"%{mac:gsub("_", ":"), lan, internet}) --add mac to acl
			data[#data+1] = {}
			data[#data]["dev"] = ifname
			data[#data]["ip"] = ip
			data[#data]["port"] = port
			data[#data]["online"] = online
			data[#data]["mac"] = mac
			data[#data]["hostname"] = getdevname(ip)
			data[#data]["associate_time"] = get_system_runtime()
			data[#data]["internet"] = internet
			data[#data]["lan"] = lan
			if port == "1" then
				data[#data]["push_flag"] = "1"
			end

			return data
	end

	local wldev,j = get_wireless_device_mac()
	local rdata = {}
	for i=1,j do
		if( mac == wldev[i]["mac"]) then
			rdata = do_set(mac, ip, wldev[i]["ifname"], online, "1")
			finish = 1
			break
		end
	end
	if finish == 1 then
		set_wltab(rdata)
		nixio.syslog("crit","arp check new wireless device "..mac)
		return 1
	end

	local wire_ifname = _uci_real:get("network", "lan", "ifname");
	rdata = do_set(mac, ip, wire_ifname, online, "0")

	nixio.syslog("crit","arp check new wire device "..mac)
	set_devlist(rdata)
	return ret
end

function arp_check_device()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local ip = arg_list_table["ip"]
	local mac = arg_list_table["mac"]
	local code = 0
	local ret = 0
    local result = { }
	local lan_ip = _uci_real:get("network", "lan", "ipaddr")
	local lan_net = string.sub(lan_ip,1,lan_ip:len()-string.find(lan_ip:reverse(),"%.")+1).."*" -- only for netmask is 255.255.255.0

	if mac then
		mac = mac:gsub(":", "_")
	end
	if ip and mac and string.match(ip, lan_net) then
		ret = do_arp_check_device(ip, mac)
		if ret == 1 then
			result["notify"] = 1
		end
	end
	nixio.syslog("crit","need notify is %d"%{ret})
	result["code"] = code
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end


function update_wireless_device()
    local data,j = get_wireless_device_mac()
    local change = {}
    for i=0,j do
        _uci_real:foreach("wldevlist", "device",
            function(s)
                if(data[i] and data[i]["mac"] == s.mac and s.port == '1') then
                    if(s.online == '0') then
                        change[#change+1] = {}
                        change[#change]["mac"] = s.mac
                        change[#change]["online"] = '1'
                        change[#change]["associate_time"] = get_system_runtime()
--                        change[j]["ip"] =
                    end
                end
            end
            )

    end
    _uci_real:foreach("wldevlist", "device",
        function(s)
            if(s.online == '1' and s.port == '1') then
                local dev_online = '0'
                for i=0,j do
                    if(data[i] and data[i]["mac"] == s.mac) then
                        dev_online = '1'
                        break
                    end
                end
                if(dev_online == '0') then
                    change[#change+1] = {}
                    change[#change]["mac"] = s.mac
                    change[#change]["online"] = '0'
                    change[#change]["associate_time"] = -1
                    change[#change]["ip"] = "0.0.0.0"
                end
            end
        end
        )
    set_wltab(change)
end

function splitbysp(str)
	local var = {}
	local substr
	local i = 1

	for substr in string.gmatch(str, "[-%w:]+") do
		var[i] = substr
		i = i + 1
	end
	return var
end

--update traffic statistic information
function update_ts()
	local change = {}
	local wlchange = {}
	local file = io.open("/proc/ts", "r")
	local line = file:read() --pass first line
	local ts
	local mac
	local wire

	while true do
		wire = 0
		line = file:read()
		if not line then break end
		ts = splitbysp(line)
		mac = string.gsub(ts[1], ":", "_")
		_uci_real:foreach("devlist", "device",
			function(s)
				if s.mac == mac then
					wire = 1
				end
			end)
		if (wire == 1) then
			change[#change+1] = {}
			change[#change]["mac"] = mac
			change[#change]["uploadtotal"] = ts[2]
			change[#change]["downloadtotal"] = ts[3]
			change[#change]["upspeed"] = ts[4]
			change[#change]["downspeed"] = ts[5]
			change[#change]["maxuploadspeed"] = ts[6]
			change[#change]["maxdownloadspeed"] = ts[7]
		else
			wlchange[#wlchange+1] = {}
			wlchange[#wlchange]["mac"] = mac
			wlchange[#wlchange]["uploadtotal"] = ts[2]
			wlchange[#wlchange]["downloadtotal"] = ts[3]
			wlchange[#wlchange]["upspeed"] = ts[4]
			wlchange[#wlchange]["downspeed"] = ts[5]
			wlchange[#wlchange]["maxuploadspeed"] = ts[6]
		end
	end
	set_devlist(change)
	set_wltab(wlchange)
	file:close()
end

function get_wifi_if_dev_mac(ifname)
    local data = {}
    local i = 0

	if(ifname) then
		local name = ifname
		local iwinfo = io.popen("iwinfo \"%s\" assoclist" %{name})
		local mac = nil
		if iwinfo then
			while true do
				mac = nil
				local tmp = iwinfo:read("*l")
				if not tmp then
					break
				end
				mac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)",1)
				if mac then
					data[i] = (mac:upper()):gsub(":", "_")
					i = i + 1
				end
			end
		end
	end
    return data,i
end

function get_device_list()

    local code = 0
    local result = { }
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then

		local wiredev = get_wire_assocdev("1")
		if wiredev then
			set_devlist(wiredev)
		end

		_uci_real:save("devlist")
		_uci_real:commit("devlist")

		local change = {}
		local data,j = get_wireless_device_mac()
		for i=1,j do
			_uci_real:foreach("devlist", "device",
				function(s)
					if(data[i]["mac"] and data[i]["mac"] == s.mac ) then
							change[#change+1] = {}
							change[#change]["mac"] = data[i]["mac"]
							change[#change]["port"] = '1'
							change[#change]["dev"] = data[i]["ifname"]
							change[#change]["lan"] = s.lan
							change[#change]["internet"] = s.internet
							change[#change]["ip"] = s.ip
							change[#change]["online"] = s.online
							change[#change]["associate_time"] = s.associate_time
							change[#change]["hostname"] = s.hostname
							_uci_real:delete("devlist",s.mac)
					end
				end
				)
		end
		if next(change) ~= nil then
			set_wltab(change)
			_uci_real:save("devlist")
			_uci_real:commit("devlist")
		end

        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
    return

end

function get_device_info()
    local result = {}
    local code = 0
    local info_type = "1"
    local mac = nil
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local info_type = arg_list_table["type"]
    local mac = arg_list_table["mac"]

	if mac then
		mac = mac:gsub(":","_")
	end

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
--        update_wireless_device()
		local wiredev = get_wire_assocdev("0")
		if wiredev then
			set_devlist(wiredev)
		end
		update_ts()

		local list_dev,count = get_devinfo_from_devlist(info_type, mac)
		if info_type == 2 then
			result["online"] = count
		else
			result["list"] = list_dev
		end

		result["code"] = code
		result["msg"] = sferr.getErrorMessage(code)

	else
		result = sferr.errProtocolNotSupport()
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function del_device_info()
    local result = {}
    local code = 0
    local devlist = ""
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local port = arg_list_table["port"]
    local mac = arg_list_table["mac"]

	if mac then
		mac = mac:gsub(":","_")
	end

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
		if port == 0 then
			devlist = "devlist"
		else
			devlist = "wldevlist"
		end
		_uci_real:foreach(devlist, "device",
		function(s)
			if(s.mac == mac ) then
				_uci_real:delete(devlist, mac)
				_uci_real:commit(devlist)
			end
		end
		)

		result["code"] = code
		result["msg"] = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end
	sysutil.sflog("INFO","Delete device %s!"%{mac})
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function set_qos_config(alldev)

	local ex_list = _uci_real:get_all("qos")
    local exist_flag = 0

    for i=1,#alldev do
        _uci_real:set("qos", alldev[i].mac , "device")
        _uci_real:tset("qos", alldev[i].mac , alldev[i])
    end
    _uci_real:save("qos")
    _uci_real:commit("qos")

end

function update_qos()
    local result = {}
    local wifi_ifname_array = {}
    local wire_ifname_array = {}
    _uci_real:foreach("wireless", "wifi-iface",
    function(s)
        if s.ifname then wifi_ifname_array[#wifi_ifname_array+1] = s.ifname end
    end
    )
    wire_ifname_array[#wire_ifname_array+1] = _uci_real:get("network", "lan", "ifname")
    ---------------------qos--------------------------------------
    local net = {}
    _uci_real:foreach("devlist","device",
    function(s)
        if s.dev and s.online=="1" and s[".name"] ~= "00_00_00_00_00_00" and s.limitdown and s.limitup and s.speedlvl then
            if net[s.dev] == nil then
                net[s.dev] = {}
                net[s.dev][#net[s.dev]+1] = {}
                net[s.dev][#net[s.dev]]["ip"] = s.ip
                net[s.dev][#net[s.dev]]["limitdown"] = (tonumber(s.limitdown)>0) and s.limitdown or nil
                net[s.dev][#net[s.dev]]["limitup"] = (tonumber(s.limitup)>0) and s.limitup or nil
                net[s.dev][#net[s.dev]]["speedlvl"] = (tonumber(s.speedlvl)>0) and s.speedlvl or 2
            else
                net[s.dev][#net[s.dev]+1] = {}
                net[s.dev][#net[s.dev]]["ip"] = s.ip
                net[s.dev][#net[s.dev]]["limitdown"] = (tonumber(s.limitdown)>0) and s.limitdown or nil
                net[s.dev][#net[s.dev]]["limitup"] = (tonumber(s.limitup)>0) and s.limitup or nil
                net[s.dev][#net[s.dev]]["speedlvl"] = (tonumber(s.speedlvl)>0) and s.speedlvl or 2
            end
        end
    end
    )

    local qos = _uci_real:get_all("qos_cfg", "qos")
    local file = nil
    file = io.open("/etc/firewall.user", "w+")
    if (not qos) or qos["enable"] ~= "1" then
        file:close()
        file = io.open("/etc/firewall.user.bk", "w+")
    end

    file:write("#!/bin/sh\n")
    local iface_num = 0

    local lan_ifname_array = {}
    _uci_real:foreach("wireless", "wifi-iface",
    function(s)
        if s.ifname then
            lan_ifname_array[#lan_ifname_array+1] = s.ifname
        end
    end
    )

    lan_ifname_array[#lan_ifname_array+1] = _uci_real:get("network", "lan", "ifname")

    ----------------qos--------download-speed-limit-----------------------
    if qos and qos["mode"] == "2" then
        for lan_ifname_index, lan_ifname in pairs(lan_ifname_array) do
            file:write("tc qdisc del dev %s root\n" %{lan_ifname})
        end
        for ifname,dev_tbl in pairs(net) do
            iface_num = iface_num+1
            file:write("tc qdisc add dev %s root handle %s: htb default 256\n" %{ifname, tostring(iface_num)})
            for i,dev_info in pairs(dev_tbl) do
                if dev_info.limitdown then
                    file:write("tc class add dev %s parent %s: classid %s:%s htb rate %skbps ceil %skbps\n" %{ifname, tostring(iface_num), tostring(iface_num), tostring(i), dev_info.limitdown, dev_info.limitdown })
                    file:write("tc qdisc add dev %s parent %s:%s handle %s: sfq perturb 10\n" %{ifname, tostring(iface_num), tostring(i), tostring(iface_num)..tostring(i) })
                    file:write("tc filter add dev %s parent %s: protocol ip handle %s fw classid %s:%s\n" %{ifname, tostring(iface_num), tostring(iface_num)..tostring(i), tostring(iface_num), tostring(i)  })
                    file:write("iptables -t mangle -A POSTROUTING -d %s -j MARK --set-mark %s\n" %{dev_info.ip, tostring(iface_num)..tostring(i)})
                end
            end
        end

        ----------------qos--------upload-speed-limit-----------------------
        local wan_ifname = _uci_real:get("network","wan","ifname")
        iface_num = 0
        file:write("tc qdisc del dev %s root\n" %{wan_ifname})
        for ifname,dev_tbl in pairs(net) do
            iface_num = iface_num+1
            file:write("tc qdisc add dev %s root handle %s: htb default 256\n" %{wan_ifname, tostring(iface_num)})
            for i,dev_info in pairs(dev_tbl) do
                if dev_info.limitup then
                    file:write("tc class add dev %s parent %s: classid %s:%s htb rate %skbps ceil %skbps\n" %{wan_ifname, tostring(iface_num), tostring(iface_num), tostring(i), dev_info.limitup, dev_info.limitup })
                    file:write("tc qdisc add dev %s parent %s:%s handle %s: sfq perturb 10\n" %{wan_ifname, tostring(iface_num), tostring(i), tostring(iface_num)..tostring(i) })
                    file:write("tc filter add dev %s parent %s: protocol ip handle %s fw classid %s:%s\n" %{wan_ifname, tostring(iface_num), tostring(iface_num)..tostring(i), tostring(iface_num), tostring(i)  })
                    file:write("iptables -t mangle -A PREROUTING -s %s -j MARK --set-mark %s\n" %{dev_info.ip, tostring(iface_num)..tostring(i)})
                end
            end
        end
        ----------------qos--------download-priority-----------------------
    elseif qos and qos["mode"] == "1" then
        for ifname,dev_tbl in pairs(net) do
            iface_num = iface_num+1
            file:write("tc qdisc del dev %s root\n" %{ifname})
            file:write("tc qdisc add dev %s root handle %s: htb default 256\n" %{ifname, tostring(iface_num)})
            for i,dev_info in pairs(dev_tbl) do
                if dev_info.speedlvl then
                    file:write("tc class add dev %s parent %s: classid %s:%s htb default 256\n" %{ifname, tostring(iface_num), tostring(iface_num), tostring(i)})
                    file:write("tc qdisc add dev %s parent %s:%s handle %s: sfq perturb 10\n" %{ifname, tostring(iface_num), tostring(i), tostring(iface_num)..tostring(i) })
                    file:write("tc filter add dev %s parent %s: protocol ip prio %s handle %s fw classid %s:%s\n" %{ifname, tostring(iface_num), dev_info.speedlvl, tostring(iface_num)..tostring(i), tostring(iface_num), tostring(i)  })
                    file:write("iptables -t mangle -A POSTROUTING -d %s -j MARK --set-mark %s\n" %{dev_info.ip, tostring(iface_num)..tostring(i)})
                end
            end
        end

        ----------------qos--------upload-priority-----------------------
        local wan_ifname = _uci_real:get("network","wan","ifname")
        iface_num = 0
        file:write("tc qdisc del dev %s root\n" %{wan_ifname})
        for ifname,dev_tbl in pairs(net) do
            iface_num = iface_num+1
            file:write("tc qdisc add dev %s root handle %s: htb default 256\n" %{wan_ifname, tostring(iface_num)})
            for i,dev_info in pairs(dev_tbl) do
                if dev_info.speedlvl then
                    file:write("tc class add dev %s parent %s: classid %s:%s htb default 256\n" %{wan_ifname, tostring(iface_num), tostring(iface_num), tostring(i)})
                    file:write("tc qdisc add dev %s parent %s:%s handle %s: sfq perturb 10\n" %{wan_ifname, tostring(iface_num), tostring(i), tostring(iface_num)..tostring(i) })
                    file:write("tc filter add dev %s parent %s: protocol ip prio %s handle %s fw classid %s:%s\n" %{wan_ifname, tostring(iface_num), dev_info.speedlvl, tostring(iface_num)..tostring(i), tostring(iface_num), tostring(i)  })
                    file:write("iptables -t mangle -A PREROUTING -s %s -j MARK --set-mark %s\n" %{dev_info.ip, tostring(iface_num)..tostring(i)})
                end
            end
        end
    elseif qos and qos["mode"] == "0" then

    end

    file:close()
--[[
    _uci_real:foreach("devlist","device",
    function(s)
        if s.online == "1" and s[".name"] ~= "00_00_00_00_00_00" then
            local trafficinfo = get_dev_trafficinfo(s.ip, s.reset_stamp)
			_uci_real:set("devlist", s[".name"], "upspeed" , trafficinfo.up_speed_cur)
			_uci_real:set("devlist", s[".name"], "downspeed", trafficinfo.down_speed_cur)
			_uci_real:set("devlist", s[".name"], "uploadtotal_offset", s.uploadtotal or "0")
			_uci_real:set("devlist", s[".name"], "downloadtotal_offset", s.downloadtotal or "0")
			_uci_real:set("devlist", s[".name"], "reset_stamp", get_system_runtime())
			end
			end
			)
			_uci_real:save("devlist")
			_uci_real:commit("devlist")
			--]]
			nixio.syslog("crit","=================firewall reload here===================")
			luci.sys.call("/etc/init.d/firewall reload")

			--[[
			code = 0
			result["code"] = code
			result["msg"] = sferr.getErrorMessage(code)

			if (http.getenv("HTTP_AUTHORIZATION") ~= "") then
			-------the caller is syncservice
			luci.http.prepare_content("application/json")
			luci.http.write_json(result)
			else

			end
			]]
	return
end

function update_qos_local()
	--    update_qos()
	code = 0
	result = {}
	result["code"] = code
	result["msg"] = sferr.getErrorMessage(code)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
	return
end

function set_device()

	local code = 0
	local result = {}
	local wire = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		code = ERROR_NO_PROTOCOL_NOT_FOUND
	elseif(sysutil.version_check(protocol)) then
		repeat
			local mac = arg_list_table["mac"]
			if mac then
				mac = mac:gsub(":","_")
			else
				code = sferr.ERROR_NO_MAC_EMPTY
				break;
			end

			_uci_real:foreach("devlist", "device",
				function(s)
					if s.mac == mac then
						wire = 1
					end
				end
			)


			local nickname = arg_list_table["nickname"]
			if nickname  and string.len(nickname) > 31 then
				code = sferr.ERROR_INPUT_PARAM_ERROR
				break
			end

			local internet = arg_list_table["internet"]
			if internet then
				if internet == 1 or internet == 0 then
					luci.util.exec("aclscript c_net %s %s" %{(mac:gsub("_",":")):upper(), tostring(internet)})
				elseif internet == 2 then
					local json_data = arg_list_table["timelist"]
					local i=1
					local cmd="pctl time update "..(mac:gsub("_",":")):upper()
					local nmac=(mac:gsub(":","_")):upper()
					_uci_real:delete_all("timelist",nmac)
					if json_data then
						while json_data[i] ~= nil do
							if json_data[i]["config"] == 0 then
								cmd=string.format("%s time %s %s %s"%{cmd, json_data[i]["starttime"], json_data[i]["endtime"],json_data[i]["week"] == "*" and "8" or json_data[i]["week"]})
							else
								_uci_real:section("timelist", nmac, nil,{
									enable = tostring(json_data[i]["enable"]),
									starttime = json_data[i]["starttime"],
									endtime = json_data[i]["endtime"],
									week = json_data[i]["week"],
								})
							end
							i=i+1
						end
					end
					luci.util.exec(cmd)
					_uci_real:save("timelist")
					_uci_real:commit("timelist")
				end
			end
			local lan = arg_list_table["lan"]
			if lan then
				luci.util.exec("aclscript c_lan %s %s" %{(mac:gsub("_",":")), tostring(lan)})
			end
			local dev_list= {}
			dev_list[1] = {}
			dev_list[1]["mac"] = mac:gsub(":","_")
			dev_list[1]["internet"] = internet
			dev_list[1]["lan"] = lan
			dev_list[1]["notify"] = arg_list_table["notify"]
			dev_list[1]["disk"] = arg_list_table["disk"]
			dev_list[1]["nickname"] = nickname
			if wire == 1 then
				set_devlist(dev_list)
			else
				set_wltab(dev_list)
			end
		until( 0 )
	else
		code = ERROR_NO_PROTOCOL_NOT_SUPPORT
	end
        set_easy_return(code, nil)
	sysutil.sflog("INFO","Device %s configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	return
end

function set_qos()

	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local qos_enable = arg_list_table["enable"]

	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then

		basic_setting = _uci_real:get_all("basic_setting")
		if basic_setting.qos == nil then
			_uci_real:set("basic_setting", "qos", "setting")
		end

		if qos_enable then
			_uci_real:set("basic_setting", "qos", "enable", qos_enable)
			_uci_real:save("basic_setting")
			_uci_real:commit("basic_setting")
		end
---TODO real enable qos
		result["code"] = code
		result["msg"] = sferr.getErrorMessage(code)

	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)

end

function get_qos_info()

    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then

        result["enable"] = _uci_real:get("basic_setting","qos","enable")
        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)

    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function welcome()
    local userid = getfenv(1).userid
    local rv = { }
    rv["msg"] = "welcome to sf-system"
    rv["code"] = 0
    rv["userid"] = userid or ""
    luci.http.prepare_content("application/json")
    luci.http.write_json(rv)
end

function ota_check()
    local uci =require "luci.model.uci".cursor()
    local result = {}
    local code = 0
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local remote_info = sysutil.getOTAInfo()
        if (remote_info) then
            result["romversion"] = sysutil.getRomVersion()
            result["romtime"]    = uci:get("siwifi","hardware","romtime")
            result["otaversion"] = remote_info["otaversion"]
            result["otatime"]    = remote_info["otatime"]
            result["size"]       = remote_info["size"]
            result["type"]       = remote_info["type"]
            result["log"]        = remote_info["log"]
            code = 0
            result["code"] = code
            result["msg"]  = sferr.getErrorMessage(code)
        else
            code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
            result["code"] = code
            result["msg"]  = sferr.getErrorMessage(code)
        end
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function ota_upgrade()
    local result = {}
    local code   = 0
	local flag = 0

    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local check = arg_list_table["check"]
    local userid = arg_list_table["userid"]
    local msgid = arg_list_table["msgid"]
    local usersubid = arg_list_table["usersubid"]
    --nixio.syslog("crit", "=========check="..check.."===userid="..userid.."===msgid="..msgid.."==zhanggong=="..usersubid)
    result["status"] = 0
    result["downloaded"] = 0
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        if(check ~= 1) then
            local upgrade_shortest_time = 0
            local upgrade_interval = 120
            if sysutil.sane("/tmp/upgrade_shortest_time") then
                upgrade_shortest_time  = tonumber(fs.readfile("/tmp/upgrade_shortest_time"))
            else
                upgrade_shortest_time = 0
            end
            if os.time() > upgrade_shortest_time then
                luci.util.exec("rm /tmp/upgrade_status")
                upgrade_shortest_time = upgrade_interval + os.time()
                local f = nixio.open("/tmp/upgrade_shortest_time", "w", 600)
                f:writeall(upgrade_shortest_time)
                f:close()
                local remote_info = sysutil.getOTAInfo()
                if ( not remote_info ) then
                    luci.util.exec("rm /tmp/upgrade_shortest_time")
                    code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
                else
					nixio.syslog("crit","+++++++++++>>>> OTA Version = "..tostring(remote_info))
                    local otaversion = remote_info["otaversion"]
                    local romversion = sysutil.getRomVersion()
                    if not string.find(romversion,otaversion) then
                        local info = {}
                        info["size"] = remote_info["size"]
                        info["url"] = remote_info["url"]
                        info["checksum"] = remote_info["checksum"]
                        local json_info = json.encode(info)
                        local f = nixio.open("/tmp/ota_info", "w", 600)
                        f:writeall(json_info)
                        f:close()

                        local cmd_obj = {}
                        userid = getfenv(1).userid
                        if (http.getenv("HTTP_AUTHORIZATION") ~= "") then
                            cmd_obj["userid"] = userid
                            cmd_obj["usersubid"] = usersubid
                            cmd_obj["msgid"] = msgid
                            cmd_obj["action"] = "1"
                            local cmd_str = json.encode(cmd_obj)
                            local cmd = "RSCH -data "..cmd_str
                            local cmd_ret = {}
                            sysutil.sendCommandToLocalServer(cmd, cmd_ret)
    --                        luci.util.exec("sleep 10")
                        end

                        sysutil.fork_exec("/usr/bin/otaupgrade")
                    else
                        luci.util.exec("rm /tmp/upgrade_shortest_time")
                        code = sferr.EEROR_NO_LOCALVERSION_EAQULE_OTAVERSION
                    end
                end
            else
                code = sferr.ERROR_NO_WAITTING_OTA_UPGRADE
            end
            result["code"] = code
            result["msg"]  = sferr.getErrorMessage(code)
        else
            result["code"] = 0
            if sysutil.sane("/tmp/upgrade_status") then
                local info  = json.decode( fs.readfile("/tmp/upgrade_status") )
                result["status"] = info["status"]
                result["msg"] = info["msg"]
            else
                result["status"] = 4
                result["msg"] = "ota upgrade is not running"
            end
            if sysutil.sane("/tmp/upgrade_shortest_time") then
                local ret = luci.util.exec("ls -l /tmp/firmware.img")
                local ota_image_size = 0
                if sysutil.sane("/tmp/ota_info") then
                    local info = json.decode(fs.readfile("/tmp/ota_info"))
                    ota_image_size = info["size"]
                end
                if(ota_image_size == 0) then
                    result["downloaded"] = 0
                else
                    local downloaded_size = tonumber(string.match(ret, "admin%s+(%d+)")) or 0
                    local downloaded = downloaded_size/ota_image_size
                    result["downloaded"] = (downloaded - downloaded%0.01)*100
                end
            else
                result["downloaded"] = 0
            end
        end
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function net_detect()
    local wifis = sysutil.sf_wifinetworks()
    local result = {}
    local code   = 0
    local bandwidth = {}
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
	bandwidth["upbandwidth"] = -1
	bandwidth["downbandwidth"] = -1

    ------function wifi_pwd_strong(pwd) to check the strong of wifi password
    local function wifi_pwd_strong(pwd)
        local matching_only_number         = pwd:match('(%d*).*')
        local matching_only_small_letter   = pwd:match('(%l*).*')
        local matching_only_capital_letter = pwd:match('(%u*).*')
        local matching_only_othertype      = pwd:match('(^[%d%l%u]*).*')
        if (matching_only_number == pwd or matching_only_small_letter == pwd or matching_only_capital_letter == pwd or matching_only_othertype == pwd) then
            return 0
        else
            return 1
        end
    end

    local function if_not_calc_bandwidth()
        return arg_list_table["nobandwidth"]
    end

	local function getpingstatus()
        local  pingbaidu      =  luci.util.exec("check_net ping")
        local _pingbaidu      =   json.decode(pingbaidu)
        local  ping_status    =  _pingbaidu["result"]
		return ping_status
	end

    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
    ----- to examine whether wan interface is connected, wanlink = 1 means connected, 0 means not connected.
        local    wanstatus   =  luci.util.exec("check_net port wan")
        local   _wanstatus   =  json.decode(wanstatus)
        local    wanlink     =  _wanstatus["result"]
        result["wanlink"]    =  wanlink

    ------to check the information of wifi password
        local wifi_pwd = {}
        for i, dev in pairs(wifis) do
            for n=1,#dev.networks do
                wifi_pwd[#wifi_pwd+1] = {}
                _uci_real:foreach("wireless","wifi-device",
                                  function(s)
                                    if s[".name"]==dev.device then
                                        wifi_pwd[#wifi_pwd]["band"] = s.band
                                    end
                end)
                if(dev.networks[n].password) then
                    wifi_pwd[#wifi_pwd]["strong"]   = wifi_pwd_strong(dev.networks[n].password)
                    if(luci.sys.user.checkpasswd("admin",dev.networks[n].password)) then
                        wifi_pwd[#wifi_pwd]["same"] = 1
                    else
                        wifi_pwd[#wifi_pwd]["same"] = 0
                    end
                else
                    wifi_pwd[#wifi_pwd]["strong"] = -1
                    wifi_pwd[#wifi_pwd]["same"] = -1
                end
            end
        end
        result["wifi"] = wifi_pwd

        result["memoryuse"]  =  memory_load() or 0
        result["cpuuse"]     =  cpu_load() or 0

        if( wanlink == 0 ) then
            local wanspeed       = {}
            wanspeed["upspeed"]  = 0
            wanspeed["downspeed"]= 0
            result["wanspeed"]   = wanspeed

            local ping     = {}
            ping["status"] = 0
            ping["lost"]   = 100
            result["ping"] = ping

            ------dns = 2 means dns timeout; delay = 10000 means not connect web successfully
            result["dns"]  = 2
            result["delay"]  = 10000

            if(if_not_calc_bandwidth() ~= 1) then
                bandwidth["downbandwidth"] = 0
                bandwidth["upbandwidth"]   = 0
            end
        else
            local wanspeed = {}
            wanspeed["upspeed"]        =  get_wan_speed().tx_speed_avg
            wanspeed["downspeed"]      =  get_wan_speed().rx_speed_avg
            result["wanspeed"]         =  wanspeed

            local  ping           =  {}
			ping["status"] = getpingstatus()
			if(ping["status"] == 0) then
				ping["status"] = getpingstatus()
			end
            if(ping["status"] ==1 ) then

                local ping_info       =   luci.util.exec("netdetect -p")
                local ping_total, ping_success, ping_delay = ping_info : match ('[^%d]+(%d*)[^%d]+(%d*)[^%d]+(%d*).*')
                if(ping_total and ping_success and ping_total ~= 0) then
                    local lost            =  (ping_total-ping_success)/ping_total
                    ping["lost"]          =  (lost - lost%0.01 )*100
                    result["delay"]       =  ping_delay
                else
                    ----- when value of  variable is -1 , means something went wrong in program
                    ping["lost"]          =  -1
                    result["delay"]       =  -1
                end

                if(if_not_calc_bandwidth() ~= 1) then
                    local downbandwidth_info   = luci.util.exec("netdetect -d")
                    bandwidth["downbandwidth"] = downbandwidth_info : match('[^%d]+(%d+).*')
                    if(bandwidth["downbandwidth"] == nil) then
                        bandwidth["downbandwidth"] = -1

                    end
                    local upbandwidth_info     = luci.util.exec("netdetect -u")
                    bandwidth["upbandwidth"]   = upbandwidth_info : match('[^%d]+(%d+).*')
                    if(bandwidth["upbandwidth"] == nil) then
                        bandwidth["upbandwidth"] = -1
                    end
                end

                result["dns"]     = 1
            else
                ping["lost"]     = 100
                result["delay"]  = 10000

                -----dns = 1, means dns analysis successfully, dns = 0 means failed
                local nslookup_info=luci.util.exec("nslookup www.baidu.com")
                if( string.match(nslookup_info, "www.baidu.com")  ) then
                    result["dns"]     = 1
                else
                    result["dns"]     = 0
                end
                if(if_not_calc_bandwidth() ~= 1) then
                    bandwidth["downbandwidth"] = 0
                    bandwidth["upbandwidth"]   = 0
                end
            end
            result["ping"]        =  ping
        end
        result["bandwidth"]  = bandwidth

        result["code"]       =  code
        result["msg"]        = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_wifi_filter()
    local code = 0
    local result = {}
    local pure_config = nil
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    local push_enable = arg_list_table["enable"]
    local push_mode   = arg_list_table["mode"]

    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then

        pure_config = "basic_setting"
        basic_setting = _uci_real:get_all(pure_config)
        if basic_setting.wifi_filter == nil then
            _uci_real:set(pure_config, "wifi_filter", "setting")
        end

        if push_enable then _uci_real:set(pure_config, "wifi_filter", "enable", push_enable) end
        if push_mode then _uci_real:set(pure_config, "wifi_filter", "mode", push_mode) end

        _uci_real:set("notify", "setting", "push")
        _uci_real:set("notify", "setting", "enable", push_enable or "0")
        _uci_real:set("notify", "setting", "mode", push_mode or "0")

        _uci_real:save("notify")
        _uci_real:commit("notify")
        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
	if push_enable then
		sysutil.sflog("INFO","Wifi filter configure changed!enable status:1")
	else
		sysutil.sflog("INFO","Wifi filter configure changed!enable status:0")
	end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function get_wifi_filter()

    local code = 0
    local result = {}

    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    local protocol = arg_list_table["version"]
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then

        result["enable"] = _uci_real:get("notify", "setting", "enable") or "0"
        result["mode"] = _uci_real:get("notify", "setting", "mode") or "0"

        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function upload_log()
    local uci =require "luci.model.uci".cursor()
	local serveraddr = sysutil.get_server_addr()

    local function upload_file(cmd)
		local local_url = ""
		local server_url = ""

		if(sysutil.getCloudType() == '0')then
			server_url = "https://"..serveraddr..sysconfig.FILEUPLOAD
		else
			server_url = "https://192.168.1.12:8090/v1"..sysconfig.FILEUPLOAD
		end
		if(cmd == "logread") then
			local_url = "/tmp/syslog.txt"
			luci.util.exec("%s >%s" %{cmd, local_url} )
		elseif(cmd == "dmesg") then
			local_url = "/tmp/klog.txt"
			luci.util.exec("%s >%s" %{cmd, local_url} )
		elseif(cmd == "top n 1") then
			local_url = "/tmp/RouterStatus.txt"
			luci.util.exec("%s >%s" %{cmd, local_url} )
		elseif(cmd == "wifi") then
			local_url = "/tmp/wifi.tar"
			local file = io.open("/sf16a18", "rb")
			if file then
				file:close()
			else
				return nil
			end
			luci.util.exec("tar -zcvf %s /sf16a18/* " %{local_url} )
		else
			return nil
		end
		local info = luci.util.exec("curl -k -X POST -H \"Content-Type: multipart/form-data\" -F \"file=@%s\" %s" %{local_url, server_url})
		luci.util.exec("rm %s" %{local_url})
		info = tostring(info)

		local decoder = {}
		decoder = json.decode(info);
		local result_data = decoder["data"]

		local cloud_file_url = result_data.fileId
		if(cloud_file_url) then
			local url = ""
			if(sysutil.getCloudType() == '0')then
				url = "https://"..serveraddr.."/file/download?id="..cloud_file_url
			else
				url = "https://192.168.1.12:8090/file/download?id="..cloud_file_url
			end
			return url
		else
			return nil
		end
	end

	local function upload_info(userid, routerid, slogurl, klogurl, statusurl, wifiurl,romversion, feedback, romtype)
		local upload_info_url = ""
		local upload_info = ""
		local info = {}
		info["routerid"] = routerid
		info["romversion"] = romversion
		info["userid"] = userid
		info["romtype"] = romtype
		if(feedback) then
			info["feedback"] = feedback
		end
		if(slogurl and klogurl and statusurl) then
			nixio.syslog("crit","sfsystem slog "..slogurl)
			nixio.syslog("crit","sfsystem klog "..klogurl)
			nixio.syslog("crit","sfsystem statusurl "..statusurl)
			info["slogurl"] = slogurl
			info["klogurl"] = klogurl
			info["statusurl"] = statusurl
			if wifiurl then
				nixio.syslog("crit","sfsystem wifiurl "..wifiurl)
				info["wifiurl"] = wifiurl
			end
		end
		if(sysutil.getCloudType() == '0')then
			upload_info_url = "https://"..serveraddr..sysconfig.ROUTERLOG
		else
			upload_info_url = "https://192.168.1.12:8090/v1"..sysconfig.ROUTERLOG
		end
		local xcloud_info = {}
		xcloud_info["method"] = "insert"
		xcloud_info["object"] = info
		upload_info = json.encode(xcloud_info)
		local token = sysutil.token()
		if (token == "") then
			return nil
		end
		local ret_info = luci.util.exec("curl -k -X POST -H \"Content-Type: application/json\" -H \"Authorization:Bearer %s\" -d \'%s\'  %s" %{token, upload_info, upload_info_url})
		nixio.syslog("crit","----------feedback-result="..ret_info)
		local ret_decoder = {}
		ret_decoder = json.decode(ret_info)
		local ret_data = ret_decoder["data"]
		return ret_data.objectId

	end

	local function if_upload()
		local ret = 0
		local flag = 0
		local upload_shortest_time = 0
		if sysutil.sane("/tmp/upload_shortest_time") then
			flag = 1
			upload_shortest_time  = tonumber(fs.readfile("/tmp/upload_shortest_time"))
		end
		if(flag == 1) then
			if(os.time() - upload_shortest_time > 30) then
				ret = 1
			else
				ret = -1
			end
		else
			ret = 1
		end

		local now = os.time()
		local f = nixio.open("/tmp/upload_shortest_time", "w", 600)
		f:writeall(now)
		f:close()

		return ret
	end

	result = {}
	code = 0
	local flag_upload_file = ""
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		if( if_upload() == 1) then
			local rom_version = sysutil.getRomVersion()
			local rom_type = sysutil.getRomtype()
			local router_id = uci:get("siserver","cloudrouter","routerid") or "UnbindRouter"
			local nolog = arg_list_table["nolog"]
			local feedback_info = arg_list_table["feedback"]
			local slog_url = nil
			local klog_url = nil
			local status_url = nil
			local wifi_url = nil
			if(nolog ~= "1") then
				slog_url = upload_file("logread")
				klog_url = upload_file("dmesg")
				status_url = upload_file("top n 1")
				-- maybe empty
				wifi_url = upload_file("wifi")
				if(not (slog_url and klog_url and status_url)) then
					flag_upload_file = "false"
					code = sferr.EEROR_NO_UPLOAD_FILE_FAILED
				end
			end

			if(flag_upload_file ~= "false") then
				local object_id = upload_info(user_id, router_id, slog_url, klog_url, status_url, wifi_url,rom_version, feedback_info, rom_type)
				if (object_id) then
					result["object_id"] = object_id
				else
					code = sferr.EEROR_NO_UPLOAD_INFO_FAILED
				end
			end
		else
			code = sferr.EEROR_NO_WAITING_UPLOAD_LOG
		end
		result["code"] = code
		result["msg"] = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.util.exec("rm /tmp/upload_shortest_time")

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function download()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local info = ''
    if(not protocol) then
        result = sferr.errProtocolNotFound()
    elseif(sysutil.version_check(protocol)) then
        local src_url = arg_list_table["src_url"]
        local dst_url = "/mnt/sda1"..(arg_list_table["dst_url"] or "")
		nixio.syslog("warning","----------src="..src_url)
		nixio.syslog("warning","----------dst="..dst_url)
        if(src_url) then
            if(dst_url) then
                info = os.execute("wget -c -P %s %s" %{dst_url, src_url})
            else
                code = sferr.ERROR_DSTURL_LOST
            end
        else
            code = sferr.ERROR_SRCURL_LOST
        end
        result["code"] = code
        result["msg"] = sferr.getErrorMessage(code)
    else
        result = sferr.errProtocolNotSupport()
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_user_info()
	local result = {}
	local code = 0
	local extraInfo = ""
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		local ip = arg_list_table["ip"]
		local port = arg_list_table["port"]

		if(not (ip and port)) then
			code = sferr.ERROR_NO_SET_IP_PORT_FAIL
			extraInfo = " because luci.http.content get ip or port fail"
		else
			local cmd = string.format("INFO need-callback -data {\"ip\": \"%s\",\"port\": %d}",ip,port)
			local cmd_ret = {}
			local ret1 = sysutil.sendCommandToLocalServer(cmd, cmd_ret)
			if(ret1 ~= 0) then
				code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
			else
				local decoder = {}
				if cmd_ret["json"] then
					decoder = json.decode(cmd_ret["json"])
					if(decoder["ret"] == "success") then
						extraInfo = " save user ip:"..ip.." port:"..port
					else
						code = sferr.ERROR_NO_SET_IP_PORT_FAIL
						extraInfo = "-"..(decoder["reason"] or "")
					end
				else
					code = sferr.ERROR_NO_SET_IP_PORT_FAIL
					extraInfo = "-"..(decoder["reason"] or "")
				end
			end
		end
		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)..extraInfo
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_warn()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local enable = arg_list_table["enable"]

	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		local cmd = enable == 1 and "start_all" or "stop_all"

		_uci_real:set("basic_setting", "onlinewarn", "enable", enable)
		_uci_real:save("basic_setting" )
		_uci_real:commit("basic_setting")
        luci.util.exec("online-warn "..cmd)

		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_dev_warn()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local protocol = arg_list_table["version"]
	local mac = arg_list_table["mac"]
	local enable = arg_list_table["enable"]

	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then

		_uci_real:set("wldevlist", mac:gsub(":","_"), "warn", "0")
		_uci_real:save("wldevlist" )
		_uci_real:commit("wldevlist")

        luci.util.exec("online-warn stop")


		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function sf_get_freq_intergration()
	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local code = protocol_check(arg_list_table["version"], "V17")
	if code  == 0 then
		result["enable"] = wirelessnew.get_freq_intergration()
	end
	sysutil.set_easy_return(code, result)
end

function sf_set_freq_intergration()
	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local code = protocol_check(arg_list_table["version"], "V17")
	if code  == 0 then
		wirelessnew.set_freq_intergration_impl(arg_list_table)
	end
	sysutil.set_easy_return(code, nil)
end
