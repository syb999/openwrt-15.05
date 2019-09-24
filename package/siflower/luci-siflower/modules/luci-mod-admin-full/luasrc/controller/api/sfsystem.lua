--
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
local wirelessnew = require "luci.controller.admin.wirelessnew"
local nixio = require "nixio"
local fs = require "nixio.fs"
local json = require("luci.json")
local http = require "luci.http"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local ap = nil
local nixio = require "nixio"
local json = require("luci.json")
local deviceImpl = require("luci.siwifi.deviceImpl")
local networkImpl = require("luci.siwifi.networkImpl")
local wirelessImpl = require("luci.siwifi.wirelessImpl")

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
    entry({"api", "sfsystem", "init_info"}, call("init_info"), nil)

    page = entry({"api", "sfsystem", "command"}, call("command"), nil)
    page.leaf = true

    entry({"api", "sfsystem", "get_stok_local"}, call("get_stok_local"), nil)
    entry({"api", "sfsystem", "get_stok_remote"}, call("get_stok_remote"), nil)
    entry({"api", "sfsystem", "setpasswd"}, call("setpasswd"), nil)
    entry({"api", "sfsystem", "wifi_detail"}, call("wifi_detail"),nil)
    entry({"api", "sfsystem", "setwifi"}, call("setwifi"),nil)
    entry({"api", "sfsystem", "getwifi_advanced"}, call("getwifi_advanced"),nil)
    entry({"api", "sfsystem", "setwifi_advanced"}, call("setwifi_advanced"),nil)
    entry({"api", "sfsystem", "main_status"}, call("main_status"),nil)
    entry({"api", "sfsystem", "bind"}, call("bind"),nil)
    entry({"api", "sfsystem", "unbind"}, call("unbind"),nil)
    entry({"api", "sfsystem", "manager"}, call("manager"),nil)
    entry({"api", "sfsystem", "device_list_backstage"}, call("device_list_backstage"),nil)           --just internal call
    entry({"api", "sfsystem", "arp_check_dev"}, call("arp_check_dev"),nil)           --just internal call
    entry({"api", "sfsystem", "device_list"}, call("device_list"),nil)
    entry({"api", "sfsystem", "del_device_info"}, call("del_device_info"),nil)
    entry({"api", "sfsystem", "setdevice"}, call("setdevice"),nil)
    entry({"api", "sfsystem", "ota_check"}, call("ota_check"),nil)
    entry({"api", "sfsystem", "ota_check2"}, call("ota_check2"),nil)
    entry({"api", "sfsystem", "ac_ap_ota_check"}, call("ac_ap_ota_check"),nil)
    entry({"api", "sfsystem", "ota_upgrade"}, call("ota_upgrade"),nil)
    entry({"api", "sfsystem", "ac_ota_upgrade"}, call("ac_ota_upgrade"),nil)
    entry({"api", "sfsystem", "check_wan_type"}, call("check_wan_type"),nil)
    entry({"api", "sfsystem", "get_wan_type"}, call("get_wan_type"),nil)
    entry({"api", "sfsystem", "set_wan_type"}, call("set_wan_type"),nil)
    entry({"api", "sfsystem", "get_lan_type"}, call("get_lan_type"),nil)
    entry({"api", "sfsystem", "set_lan_type"}, call("set_lan_type"),nil)
    entry({"api", "sfsystem", "detect_wan_type"}, call("detect_wan_type"),nil)
    entry({"api", "sfsystem", "qos_set"}, call("qos_set"),nil)
    entry({"api", "sfsystem", "qos_info"}, call("qos_info"),nil)
    entry({"api", "sfsystem", "netdetect"}, call("netdetect"),nil)
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
    entry({"api", "sfsystem", "setdefault"}, call("setdefault"), nil)
    entry({"api", "sfsystem", "getdefault"}, call("getdefault"), nil)
    entry({"api", "sfsystem", "adduser"}, call("adduser"), nil)
    entry({"api", "sfsystem", "setdevicetime"}, call("setdevicetime"), nil)
    entry({"api", "sfsystem", "getdevicetime"}, call("getdevicetime"), nil)
    entry({"api", "sfsystem", "setdevicerestrict"}, call("setdevicerestrict"), nil)
    entry({"api", "sfsystem", "getdevicerestrict"}, call("getdevicerestrict"), nil)
    entry({"api", "sfsystem", "setdevicedatausage"}, call("setdevicedatausage"), nil)
    entry({"api", "sfsystem", "getdevicedatausage"}, call("getdevicedatausage"), nil)
    entry({"api", "sfsystem", "routerlivetime"}, call("routerlivetime"), nil)
    entry({"api", "sfsystem", "blockrefactory"}, call("blockrefactory"), nil)
    entry({"api", "sfsystem", "getrouterlivetime"}, call("get_routerlivetime"), nil)
    entry({"api", "sfsystem", "getblockrefactory"}, call("getblockrefactory"), nil)
    entry({"api", "sfsystem", "getaccess"}, call("getaccess"), nil)

    entry({"api", "sfsystem", "setspeed"}, call("setspeed"), nil)
    entry({"api", "sfsystem", "urllist_set"}, call("urllist_set"), nil)
    entry({"api", "sfsystem", "urllist_get"}, call("urllist_get"), nil)
    entry({"api", "sfsystem", "urllist_enable"}, call("urllist_enable"), nil)
    entry({"api", "sfsystem", "get_customer_wifi_iface"}, call("get_customer_wifi_iface"), nil)
    entry({"api", "sfsystem", "set_customer_wifi_iface"}, call("set_customer_wifi_iface"), nil)
    entry({"api", "sfsystem", "wifi_scan"}, call("wifi_scan"), nil)
    entry({"api", "sfsystem", "wifi_connect"}, call("wifi_connect"), nil)
    entry({"api", "sfsystem", "wds_getwanip"}, call("wds_getwanip"), nil)
    entry({"api", "sfsystem", "wds_getrelip"}, call("wds_getrelip"), nil)
    entry({"api", "sfsystem", "wds_enable"}, call("wds_enable"), nil)
    entry({"api", "sfsystem", "wds_disable"}, call("wds_disable"), nil)
    entry({"api", "sfsystem", "get_wds_info"}, call("get_wds_info"), nil)
    entry({"api", "sfsystem", "wds_sta_is_disconnected"}, call("wds_sta_is_disconnected"), nil)
    entry({"api", "sfsystem", "set_warn"}, call("set_warn"), nil)
    entry({"api", "sfsystem", "get_warn"}, call("get_warn"), nil)
    entry({"api", "sfsystem", "set_dev_warn"}, call("set_dev_warn"), nil)

    entry({"api", "sfsystem", "set_lease_net"}, call("set_lease_net"), nil)
    entry({"api", "sfsystem", "get_lease_net"}, call("get_lease_net"), nil)
    entry({"api", "sfsystem", "set_lease_mac"}, call("set_lease_mac"), nil)
    entry({"api", "sfsystem", "getrouterfeature"}, call("getrouterfeature"), nil)
    --for local useage
    entry({"api", "sfsystem", "pctl_url_check"}, call("pctl_url_check"),nil)

    entry({"api", "sfsystem", "get_ap_groups"}, call("get_ap_groups"), nil)
    entry({"api", "sfsystem", "set_ap_group"}, call("set_ap_group"), nil)
    entry({"api", "sfsystem", "remove_ap_group"}, call("remove_ap_group"), nil)
    entry({"api", "sfsystem", "get_ap_list"}, call("get_ap_list"), nil)
    entry({"api", "sfsystem", "set_ap"}, call("set_ap"), nil)
    entry({"api", "sfsystem", "delete_ap"}, call("delete_ap"), nil)

    --V17
    entry({"api", "sfsystem", "get_freq_intergration"}, call("get_freq_intergration"), nil)
    entry({"api", "sfsystem", "set_freq_intergration"}, call("set_freq_intergration"), nil)
    --V18
    entry({"api", "sfsystem", "func_adapter"}, call("func_adapter"), nil)
    entry({"api", "sfsystem", "set_samba"}, call("set_samba"), nil)
    entry({"api", "sfsystem", "get_samba"}, call("get_samba"), nil)

end
-- send to ssst so ssst could polling update status and send to app
-- for sure app get progress of download
function sync()
    --string.format("Downloading %s from %s to %s", file, host, outfile)
    --    local cmd = "SYNC -data "..luci.http.formvalue("enable")

    local code = 0
    local result = {}
    code,result = networkImpl.sync(get_arg_list())
    sysutil.set_easy_return(code,result)
end

function check_wan_type()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.check_wan_type()
    end
    sysutil.set_easy_return(code,result)
    return
end

function check_net()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.check_net()
    end
    sysutil.set_easy_return(code,result)

end

function new_oray_params()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code,result = networkImpl.new_oray_params()
    end
    sysutil.set_easy_return(code,result)

end

function destroy_oray_params()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = networkImpl.destroy_oray_params(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)

end

function setdefault()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.setdefault(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
end

function getdefault()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.getdefault()
    end
    sysutil.set_easy_return(code,result)

end

function getdevicetime()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.getdevicetime(arg_list_table)
    end
    sysutil.set_easy_return(code,result)
end

function setdevicetime()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.setdevicetime(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
end

function getdevicerestrict()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.getdevicerestrict(arg_list_table)
    end
    sysutil.set_easy_return(code,result)
end

function setdevicerestrict()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.setdevicerestrict(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)

end

function setdevicedatausage()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.setdevicedatausage(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
end

function getdevicedatausage()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.getdevicedatausage(arg_list_table)
    end
    sysutil.set_easy_return(code,result)
end

function get_routerlivetime()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.get_routerlivetime()
    end
    sysutil.set_easy_return(code,result)

end
function routerlivetime()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.routerlivetime(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
end
function getblockrefactory()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.getblockrefactory()
    end
    sysutil.set_easy_return(code,result)
end

function blockrefactory()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.blockrefactory(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
end

function getaccess()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.getaccess(arg_list_table)
    end
    sysutil.set_easy_return(code,result)
end

function adduser()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.adduser(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function bind()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.bind(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function manager()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.manager(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function unbind()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.unbind(arg_list_table)
    end
    sysutil.sflog("INFO","Router unbind!")
    sysutil.set_easy_return(code, nil)
end

function init_info()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")
    if code  == 0 then
        code, result = networkImpl.init_info()
    end
    sysutil.set_easy_return(code, result)
end

function command()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")
    if code  == 0 then
        code, result = networkImpl.command(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function get_stok_local()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")
    if code  == 0 then
        code,result = deviceImpl.get_stok_local()
    end
    sysutil.set_easy_return(code, result)
end

function get_stok_remote()
    --return the same value as local request
    get_stok_local()
end

function setpasswd(arg_list_table)
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.setpasswd(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end


function wifi_detail()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wifi_detail(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
    return
end

function get_wan_type()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.get_wan_type()
    end
    sysutil.set_easy_return(code, result)
    return
end

function set_wan_type()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.set_wan_type(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function get_lan_type()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.get_lan_type()
    end
    sysutil.set_easy_return(code, result)
    return
end

function set_lan_type()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.set_lan_type(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function detect_wan_type()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.detect_wan_type()
    end
    sysutil.set_easy_return(code, result)
    return
end


function setwifi()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")
    if code  == 0 then
        code = wirelessImpl.setwifi(arg_list_table)
    end
    sysutil.sflog("INFO","Wifi configure changed!")
    sysutil.set_easy_return(code, nil)
    return

end

function setwifi_advanced()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = wirelessImpl.setwifi_advanced(arg_list_table)
    end
    sysutil.sflog("INFO","Advanced wifi configure changed!")
    sysutil.set_easy_return(code, nil)
    return
end

function getwifi_advanced()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.getwifi_advanced()
    end
    sysutil.set_easy_return(code, result)
    return
end

function get_customer_wifi_iface()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.get_customer_wifi_iface()
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function set_customer_wifi_iface()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.set_customer_wifi_iface(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    --	sysutil.sflog("INFO","Guest wifi configure changed!"%{mac})--customer wifi configure change!的log是用网页打印的
    return
end

function wifi_scan()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wifi_scan(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function wifi_connect()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wifi_connect(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function wds_getrelip()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V17")

    if code == 0 then
        code,result = wirelessImpl.wds_getrelip(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function wds_getwanip()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wds_getwanipimpl(arg_list_table)
    end
    sysutil.set_easy_return(code, result)

    return
end

function wds_enable()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wds_enable(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function wds_disable()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.wds_disable(arg_list_table)
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function get_wds_info()

    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = wirelessImpl.get_wds_info()
    else
        sysutil.set_easy_return(code, result)
    end
    sysutil.set_easy_return(code, result)
    return
end

function wds_sta_is_disconnected()
	local arg_list_table = get_arg_list()
	local code = protocol_check(arg_list_table["version"], "V18")

	if code  == 0 then
		code = wirelessImpl.wds_sta_is_disconnected()
	end
	sysutil.set_easy_return(code, nil)
end

function main_status()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.main_status(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
    return
end
function protocol_check(protocol, version )
    local code = 0
    if(not protocol) then
        code = sferr.ERROR_NO_PROTOCOL_NOT_FOUND
    elseif( not sysutil.version_check(protocol) or  protocol < version) then
        code = sferr.ERROR_NO_PROTOCOL_NOT_SUPPORT
    end
    return code
end

function setspeed()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = networkImpl.setspeed(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function urllist_set()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = networkImpl.urllist_set(arg_list_table)
    end
    sysutil.set_easy_return(code,nil)
    return
end

function urllist_get()

    local result = { }
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code,result = networkImpl.urllist_get(arg_list_table)
    end
    sysutil.set_easy_return(code,result)
    return
end

function urllist_enable()

    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = networkImpl.urllist_enable(arg_list_table)
    end
    sysutil.set_easy_return(code,nil);
    return
end

function arp_check_dev()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = 0
    code,result = networkImpl.arp_check_dev(arg_list_table)
    sysutil.set_easy_return(code, result)
end

function device_list_backstage()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.device_list_backstage()
    end
    sysutil.set_easy_return(code, nil)
    return

end

function device_list()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.device_list(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
    return
end

function del_device_info()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.del_device_info(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function update_qos_local()
    --    update_qos()
    code = 0
    code = networkImpl.update_qos_local()
    sysutil.set_easy_return(code, nil)
    return
end

function setdevice()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = deviceImpl.setdevice(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function qos_set()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code = networkImpl.qos_set(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
    return
end

function qos_info()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code,result = networkImpl.qos_info()
    end
    sysutil.set_easy_return(code, result)
    return
end

function welcome()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code,result = networkImpl.welcome()
    end
    sysutil.set_easy_return(code, result)
end

function ota_check()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.ota_check()
    end
    sysutil.set_easy_return(code, result)
    return
end

function ota_check2()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.ota_check2()
    end
    sysutil.set_easy_return(code, result)
    return
end

function ac_ap_ota_check()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V12")

    if code  == 0 then
        code,result = networkImpl.ac_ap_ota_check()
    end
    sysutil.set_easy_return(code, result)
    return
end

function ota_upgrade()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.ota_upgrade(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
    return
end

function ac_ota_upgrade()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V15")

    if code  == 0 then
        code,result = networkImpl.ac_ota_upgrade(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
    return
end

function netdetect()
    local arg_list_table = get_arg_list()
    local result = {}
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.netdetect(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function set_wifi_filter()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.set_wifi_filter(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function get_wifi_filter()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.get_wifi_filter()
    end
    sysutil.set_easy_return(code, result)

end

function upload_log()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.upload_log(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function download()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = networkImpl.download(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function set_user_info()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.set_user_info(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function set_warn()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.set_warn(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function get_warn()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = deviceImpl.get_warn()
    end
    sysutil.set_easy_return(code, result)
end

function set_dev_warn()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code = deviceImpl.set_dev_warn(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function set_lease_net()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V14")

    if code  == 0 then
        code = deviceImpl.set_lease_net(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function get_lease_net()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V14")

    if code  == 0 then
        code,result = deviceImpl.get_lease_net()
    end
    sysutil.set_easy_return(code, result)
end

function set_lease_mac()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V14")

    if code  == 0 then
        code = deviceImpl.set_lease_mac(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

-- internal interface for ssst
function getrouterfeature()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V10")

    if code  == 0 then
        code,result = networkImpl.getrouterfeature(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function get_ap_groups()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code,result = networkImpl.get_ap_groups()
    end
    sysutil.set_easy_return(code, result)
end

function set_ap_group()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code = networkImpl.set_ap_group(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function remove_ap_group()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code = networkImpl.remove_ap_group(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function get_ap_list()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code,result = networkImpl.get_ap_list(arg_list_table)
    end
    sysutil.set_easy_return(code, result)
end

function set_ap()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code = networkImpl.set_ap(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function delete_ap()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V16")
    if code  == 0 then
        code = networkImpl.delete_ap(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function pctl_url_check()
    local result = {}
    local code = 0
    code,result = networkImpl.pctl_url_check(arg_list_table)
    sysutil.set_easy_return(code, result)
end

function get_freq_intergration()
    local result = {}
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V17")
    if code  == 0 then
        code,result = wirelessImpl.get_freq_intergration()
    end
    sysutil.set_easy_return(code, result)
end

function set_freq_intergration()
    local arg_list_table = get_arg_list()
    local code = protocol_check(arg_list_table["version"], "V17")
    if code  == 0 then
        code = wirelessImpl.set_freq_intergration(arg_list_table)
    end
    sysutil.set_easy_return(code, nil)
end

function set_samba()
    local arg_list_table = get_arg_list()
	local code = protocol_check(arg_list_table["version"], "V18")
	if code  == 0 then
		code = networkImpl.set_samba(arg_list_table)
	end
    sysutil.set_easy_return(code, nil)
end

function get_samba()
    local result = {}
    local arg_list_table = get_arg_list()
	local code = protocol_check(arg_list_table["version"], "V18")
	if code  == 0 then
		code,result = networkImpl.get_samba()
	end
    sysutil.set_easy_return(code, result)
end

function get_arg_list()
    local arg_list, data_len = luci.http.content()
    local arg_list_table = json.decode(arg_list)
    return arg_list_table
end
function func_adapter()
	local result = {}
	local arg_list_table = get_arg_list()
	local code = protocol_check(arg_list_table["version"], "V18")
	if code  == 0 then
		code,result = networkImpl.func_adapter(arg_list_table)
	end
	sysutil.set_easy_return(code, result)
end
