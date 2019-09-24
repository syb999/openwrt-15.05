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

module("luci.siwifi.wirelessImpl", package.seeall)
local nw = require "luci.model.network"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local sysutil = require "luci.siwifi.sf_sysutil"
local json = require("luci.json")
local util = require("luci.util")
local sysutil = require("luci.siwifi.sf_sysutil")
local sferr = require "luci.siwifi.sf_error"
local wirelessnew = require "luci.controller.admin.wirelessnew"

function getdev_by_ssid(ssid,channel)

	local wifis = sysutil.sf_wifinetworks()
	local band_local = "2.4G"
	local band_search = "2.4G"
	if channel == nil or channel == "auto" or channel < 15 then
		band_local = "2.4G"
	else
		band_local = "5G"
	end
	for i, dev in pairs(wifis) do
		for n=1,#dev.networks do
			if dev.networks[n].channel == nil or dev.networks[n].channel == "auto" or dev.networks[n].channel < 15 then
				band_search = "2.4G"
			else
				band_search = "5G"
			end
			if dev.networks[n].ssid == ssid and band_local == band_search then
				return dev
			end
		end
	end
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

function get_customer_wifi_iface()
	local ifaces = {}
	local code = 0
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if string.find(s.ifname, "guest") then
			ifaces[#ifaces+1] = {}
			ifaces[#ifaces]["enable"] = _uci_real:get("wireless", s[".name"], "disabled") == "0" and true or false
			ifaces[#ifaces]["ssid"] = _uci_real:get("wireless", s[".name"], "ssid")
			ifaces[#ifaces]["localaccess"] = _uci_real:get("wireless", s[".name"], "network") == "lan" and true or false

			if(_uci_real:get("wireless", s[".name"], "encryption") == "open") then
				ifaces[#ifaces]["open"] = true
			else
				ifaces[#ifaces]["open"] = false
				ifaces[#ifaces]["key"] = _uci_real:get("wireless", s[".name"], "key")
			end

			ifaces[#ifaces]["band"] =  _uci_real:get("wireless", s[".name"], "device") == "radio0" and "2.4G" or "5G"
			ifaces[#ifaces]["limitupload"] = tonumber(_uci_real:get("wireless", s[".name"], "limitupload") or 0) --上行速率上限 0表示不限速
			ifaces[#ifaces]["limitdownload"] = tonumber(_uci_real:get("wireless", s[".name"], "limitdownload") or 0) --下行速率上限 0表示不限速
			ifaces[#ifaces]["limittime"] = _uci_real:get("wireless", s[".name"], "limittime") or false --是否限制时间
			ifaces[#ifaces]["limittimetype"] = tonumber(_uci_real:get("wireless", s[".name"], "limittimetype") or 0) --限制类型 0：限制剩余时间， 1：周期性限制时间
			ifaces[#ifaces]["remainingtime"] = tonumber(_uci_real:get("wireless", s[".name"], "remainingtime") or 0) --8小时之后关闭访客网络
			-- use cornd
			ifaces[#ifaces]["periodicaltime"] = _uci_real:get("wireless", s[".name"], "periodicaltime") or ""
		end
	end)
	local result = {
		ifaces = ifaces
	}
	return code, result
end

function set_customer_wifi_iface(arg_list_table)
	local ifaces = arg_list_table["ifaces"]
    local code = 0
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if string.find(s.ifname, "guest") then
			for i=1,#ifaces do
				if  _uci_real:get("wireless", s.device, "band") == ifaces[i]["band"] then
					if ifaces[i]["enable"] == true then
						_uci_real:set("wireless", s[".name"], "disabled", "0")
					else
						_uci_real:set("wireless", s[".name"], "disabled", "1")
					end

					if ifaces[i]["ssid"] then
						_uci_real:set("wireless", s[".name"], "ssid", ifaces[i]["ssid"])
					end
					if(ifaces[i]["open"] == true) then
						_uci_real:set("wireless", s[".name"], "encryption", "open")
					else
						_uci_real:set("wireless", s[".name"], "encryption", "psk2+ccmp")
						_uci_real:set("wireless", s[".name"], "key", ifaces[i]["key"] )
					end

					if( ifaces[i]["localaccess"]) then
						_uci_real:set("wireless", s[".name"], "network", "lan")
					else
						_uci_real:set("wireless", s[".name"], "network", "guest")
					end
					if( ifaces[i]['limitupload']) then
						_uci_real:set("wireless", s[".name"], "limitupload", ifaces[i]['limitupload'])
					end
					if( ifaces[i]['limitdownload']) then
						_uci_real:set("wireless", s[".name"], "limitdownload", ifaces[i]['limitdownload'])
					end
					if( ifaces[i]['limittime']) then
						_uci_real:set("wireless", s[".name"], "limittime", ifaces[i]['limittime'])
					end
					if( ifaces[i]['limittimetype']) then
						_uci_real:set("wireless", s[".name"], "limittimetype", ifaces[i]['limittimetype'])
					end
					if( ifaces[i]['remainingtime']) then
						_uci_real:set("wireless", s[".name"], "remainingtime", ifaces[i]['remainingtime'])
					end
					if( ifaces[i]['periodicaltime']) then
						_uci_real:set("wireless", s[".name"], "periodicaltime", ifaces[i]['periodicaltime'])
					end
				end
			end
		end
	end)

	local changes = _uci_real:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		--nixio.syslog("crit","apply changes")
		sysutil.nx_syslog("apply changes", nil)
		_uci_real:save("wireless")
		_uci_real:commit("wireless")
		sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy; sleep 3; gwifi start; gwifi speed_rst 0;gwifi speed_rst 1")
	end

	--输出log所需变量
	local ifaces=arg_list_table["ifaces"]
	local wifi_5gssid
	local wifi_24gssid
	for i=1,#ifaces do
		if ifaces[i]["band"]=="2.4G" then
			wifi_24gssid=ifaces[i]["ssid"]
			sysutil.sflog("INFO","customer wifi iface configure changed!2.4G ssid:%s"%{wifi_24gssid})--输出log
		elseif ifaces[i]["band"]=="5G" then
			wifi_5gssid=ifaces[i]["ssid"]
			sysutil.sflog("INFO","customer wifi iface configure changed!5G ssid:%s"%{wifi_5gssid})--输出log
		end
	end
	return code
end

function wifi_scan(arg_list_table)
	local result = {
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
	local code = 0
	if arg_list_table.band == "2.4G" then
		result.device = "radio0"
	elseif arg_list_table.band == "5G" then
		result.device = "radio1"
	else
		code = sferr.ERROR_INPUT_PARAM_ERROR
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
	return code, result
end

--args: channel, ssid, key, encryption
function wifi_connect(arg_list_table)
	local result = {
		band = "2.4G",
		ip = "",
	}
	local code = 0
	local wifi_if = {
		device = "radio0",
		ifname = "sfi0",
		network = "wwan",
		mode = "sta",
		ssid = "",
		bssid = "",
		key = "",
		encryption = ""
	}

	if tonumber(arg_list_table.channel) >= 36 then
		wifi_if.device = "radio1"
		wifi_if.ifname = "sfi1"
		result.band = "5G"
	end
	local channel_file = io.open("/tmp/wds_channel", "w+")
	if channel_file ~= nil then
		channel_file:write(arg_list_table.channel)
		channel_file:flush()
		io.close(channel_file)
	end
	wifi_if.ssid = arg_list_table.ssid
	wifi_if.key = arg_list_table.key
	wifi_if.encryption = arg_list_table.encryption
	wifi_if.bssid = arg_list_table.bssid

	local wdev = nw:get_wifidev(wifi_if.device)
	if wdev ~= nil then
		wdev:add_wifinet(wifi_if)
		nw:save("wireless")
		nw:commit("wireless")

		nw:add_network(wifi_if.network, { proto = "dhcp", ifname = wifi_if.ifname })
		nw:save("network")
		nw:commit("network")

		code = 0
	end

	_uci_real:set("network", "lan", "netclash", 1)
	_uci_real:save("network")
	_uci_real:commit("network")

	return code, result
end

function wds_getrelip(arg_list_table)
	local result = {
		ip = "",
	}
	local code = 0
	local is_radar = arg_list_table["is_radar"]
	local timeout = 30
	if is_radar and is_radar == 1 then
		timeout = 90
	end
	local sync_file, waiting
	sync_file = io.open("/tmp/wds_sync", "r")
	if sync_file ~= nil then
		io.input("/tmp/wds_sync")
		waiting = io.read(1)
		io.close(sync_file)
	end

	for i = timeout, 1, -1 do
		if (waiting == "1") then
			local err = check_wds_passwderr("/tmp/wds_reason_code")
			if (err == -1) then
				code = -1
				result.ip = "nil"
				break;
			elseif (err == -2) then
				result.ip = "nil"
				break;
			end
			if (arg_list_table) then
				result.ip = wds_getwanip(arg_list_table.band)
			else
				result.ip = wds_getwanip("2.4G")
				if result.ip == "nil" then
					result.ip = wds_getwanip("5G")
				end
			end
			local relayd_fd = io.popen("ps|grep relayd|grep grep -vc")
			local relayd_sta = relayd_fd:read("*n")
			if result.ip ~= "nil" and relayd_sta ~= 0 then
				break
			end
			luci.sys.call("sleep 1")
		else
			luci.sys.call("sleep 1")
		end
		sync_file = io.open("/tmp/wds_sync", "r")
		if sync_file ~= nil then
			io.input("/tmp/wds_sync")
			waiting = io.read(1)
			io.close(sync_file)
		end
	end
	local redirect_ip = ""
	local gw_t = util.split(result.ip, ".")
	local lanip = _uci_real:get("network", "lan", "ipaddr")
	if gw_t[1] ~= "nil" then
		local gateway = gw_t[1].."."..gw_t[2].."."..gw_t[3]..".".."1"
		if gateway == lanip then
			local seg = tonumber(gw_t[3]) + 1
			lanip = gw_t[1].."."..gw_t[2].."."..seg..".".."1"
			redirect_ip = lanip
		end
	end
	if redirect_ip ~= "" then
		sysutil.fork_exec("sleep 3; alter_lan %s no_delay" %{redirect_ip})
	end


	if (code == -1) then
		result.ip = "nil"
		code = sferr.ERROR_NO_INVALID_PASSWORD
	elseif (result.ip == "nil") then
		code = sferr.ERROR_NO_WIFI_CONNECT_FAILED
	end
	return code, result
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
function wds_enable(arg_list_table)
	local br_ip
	local lanip = _uci_real:get("network", "lan", "ipaddr")
	local redirect_ip = ""
	local result = {
		redirect = 1
	}
	local code = 0

	local sync_file
	sync_file = io.open("/tmp/wds_sync", "w+")
	if sync_file ~= nil then
		sync_file:write(0)
		sync_file:flush()
		io.close(sync_file)
	end

	clear_wds_passwderr("/tmp/wds_reason_code")
	for retry = 2, 1, -1 do
		local passwd_err = 0
		luci.sys.call("/sbin/wifi restart")
		for i = 15, 1, -1 do
			local err = check_wds_passwderr("/tmp/wds_reason_code")
			if ((err == -1) or (err == -2)) then
				br_ip = "nil"
				passwd_err = 1
				break;
			end
			if (arg_list_table.ifaces) then
				br_ip = wds_getwanip(arg_list_table.ifaces.band)
			else
				br_ip = wds_getwanip("2.4G")
				if br_ip == "nil" then
					br_ip = wds_getwanip("5G")
				end
			end
			if br_ip ~= "nil" then
				break
			end
			luci.sys.call("sleep 1")
		end
		if passwd_err == 1 then
			break;
		end
		if br_ip ~= "nil" then
			break
		end
	end

	if br_ip ~= "nil" then
		nw:add_network("stabridge", { proto = "relay", network = "lan wwan", ipaddr = br_ip, disable_dhcp_parse = 1 })
		nw:save("network")
		nw:commit("network")

		_uci_real:set("network", "wan", "disabled", 1)
		_uci_real:save("network")
		_uci_real:commit("network")

		local gw_t = util.split(br_ip, ".")
		if gw_t[1] ~= "nil" then
			local gateway = gw_t[1].."."..gw_t[2].."."..gw_t[3]..".".."1"
			if gateway == lanip then
				local seg = tonumber(gw_t[3]) + 1
				lanip = gw_t[1].."."..gw_t[2].."."..seg..".".."1"
				redirect_ip = lanip
			end
			_uci_real:save("network")
			_uci_real:commit("network")
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

		if (arg_list_table.ifaces) then
			local ifname = ""
			local ifname2 = ""
			local freq_inter = wirelessnew.get_freq_intergration_impl()
			if arg_list_table.ifaces.band == "2.4G" then
				ifname = "wlan0"
				ifname2 = "wlan1"
			elseif arg_list_table.ifaces.band == "5G" then
				ifname = "wlan1"
				ifname2 = "wlan0"
			end
			_uci_real:foreach("wireless","wifi-iface",
			function(s)
				if(s["ifname"] == ifname or (freq_inter == 1 and s["ifname"] == ifname2)) then
					_uci_real:set("wireless", s[".name"], "ssid", arg_list_table.ifaces.ssid)
					if (arg_list_table.ifaces.key and arg_list_table.ifaces.key ~= "") then
						_uci_real:set("wireless", s[".name"], "key", arg_list_table.ifaces.key)
						_uci_real:set("wireless", s[".name"], "encryption", "psk2+ccmp")
					else
						_uci_real:set("wireless", s[".name"], "encryption", "open")
					end
				end
			end)
			_uci_real:save("wireless")
			_uci_real:commit("wireless")
		end

		luci.sys.call("killall relayd")
		luci.sys.call("/etc/init.d/relayd enable")
		local channel
		if arg_list_table.channel then
			channel = arg_list_table.channel
		else
			local channel_file = io.open("/tmp/wds_channel", "r")
			if channel_file ~= nil then
				channel = channel_file:read("*n")
				io.close(channel_file)
			else
				nixio.syslog("crit","read channel error , wds stop !")
			end
		end
		local radio_num = "radio0"
		if tonumber(channel) >= 36 then
			radio_num = "radio1"
		end
		_uci_real:set("wireless", radio_num, "channel", channel)
		_uci_real:save("wireless")
		_uci_real:commit("wireless")
		if redirect_ip ~= "" then
			sysutil.fork_exec("alter_lan %s delay" %{redirect_ip})
		else
			luci.sys.call("/etc/init.d/network restart")
		end
		sysutil.fork_exec("sleep 1; /sbin/check_wds")
		code = 0
	else
		code = -1

		nw:del_wifinet("sfi0")
		nw:del_wifinet("sfi1")
		nw:save("wireless")
		nw:commit("wireless")

		nw:del_network("wwan")
		nw:save("network")
		nw:commit("network")

		luci.sys.call("/sbin/wifi reload")
	end

	sync_file = io.open("/tmp/wds_sync", "w+")
	if sync_file ~= nil then
		sync_file:write(1)
		sync_file:flush()
		io.close(sync_file)
	end
	return code, result
end

function wds_disable(arg_list_table)
	local result = {
		ip = ""
	}
	local code = 0
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

	_uci_real:delete("network", "wan", "disabled")
	_uci_real:save("network")
	_uci_real:commit("network")

	nw:del_wifinet("sfi0")
	nw:del_wifinet("rai0")
	nw:del_wifinet("sfi1")
	nw:del_wifinet("rai1")
	nw:save("wireless")
	nw:commit("wireless")

	if arg_list_table.redirect == 1 then
		result.ip = _uci_real:get("network", "lan", "ipaddr")
		sysutil.fork_exec("sleep 1;/etc/init.d/network restart;uci set network.lan.netclash=0;uci commit network")
	else
		luci.sys.call("/etc/init.d/network reload;uci set network.lan.netclash=0;uci commit network")
	end
	return code, result
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
		info = info
	}
	local code = 0
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

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "wlan0") then
				if (s["encryption"] ~= "open") then
					info[1].key = s["key"]
				else
					info[1].key = ""
				end
			end
		end)
	end

	iw = luci.sys.wifi.getiwinfo("radio1")
	if iw ~= nil then
		info[2].ssid = iw.ssid
		info[2].bssid = iw.bssid

		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "wlan1") then
				if (s["encryption"] ~= "open") then
					info[2].key = s["key"]
				else
					info[2].key = ""
				end
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
				if (s["encryption"] ~= "open") then
					info[3].key = s["key"]
				else
					info[3].key = ""
				end
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
				if (s["encryption"] ~= "open") then
					info[4].key = s["key"]
				else
					info[4].key = ""
				end
			end
		end)

	end
	info[5].lanip = _uci_real:get("network", "lan", "ipaddr")
	local wanip = ""
	local relay = _uci_real:get("network", "stabridge", "proto")
	if info[1].enable == "1" then
		wanip = info[3].ip
		if relay ~= "relay" then
			info[1].enable = 2
		end
	elseif info[2].enable == "1" then
		wanip = info[4].ip
		if relay ~= "relay" then
			info[2].enable = 2
		end
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
	return code, result
end

function wds_sta_is_disconnected()
	local sta_status, sta_status_f, ssid, bssid
	local filename = "/tmp/wds_sta_status"
	local code = 0

	ssid = ""
	bssid = ""
	code = sferr.ERROR_NO_WDS_SSID_MISS
	sta_status_f = io.open(filename)
	if sta_status_f ~= nil then
		io.input(filename)
		sta_status = io.read()
		while (sta_status == "b") do
			sta_status = io.read()
		end
		io.close(sta_status_f)
	end

	if (sta_status == "0") then
		code = 0
	else
		_uci_real:foreach("wireless","wifi-iface",
		function(s)
			if (s["ifname"] == "sfi0" or s["ifname"] == "sfi1"
				or s["ifname"] == "rai0" or s["ifname"] == "rai1") then
				ssid = s["ifname"]
				bssid = _uci_real:get("wireless", s[".name"], "bssid")
			end
		end)
		-- Modified by nevermore.
		-- This is a bug that we can't call wpa_cli in luci.sys.call().
		-- So fork to execute the shell and wait for the result.
		sysutil.fork_exec("/usr/bin/wpa_cli_event.sh %s RECONNECT %s" %{ssid,bssid})
		-- luci.sys.call("sleep 5")
		--	luci.sys.call("/usr/bin/wpa_cli_event.sh %s RECONNECT %s" %{ssid,bssid})

		sta_status_f = io.open(filename)
		if sta_status_f ~= nil then
			io.input(filename)
			sta_status = io.read()
			while (sta_status == "b") do
				sta_status = io.read()
			end
			io.close(sta_status_f)
		end

		if (sta_status == "0") then
			code = 0
		end

		if (sta_status == "1") then
			code = sferr.ERROR_NO_WDS_SSID_PWD_CHANGE
		end

		if (sta_status == "2") then
			code = sferr.ERROR_NO_WDS_SSID_MISS
		end
	end
	return code
end

function check_wds_passwderr(filename)
	local deauth_file, deauth
	deauth_file = io.open(filename, "r")
	if deauth_file ~= nil then
		io.input(filename)
		deauth = io.read(1)
		io.close(deauth_file)
	end
	-- deauth/disassoc recieved
	if (deauth == "1") then
		return -2
	end
	-- password error
	if (deauth == "2") then
		return -1
	end
	return 0
end

function clear_wds_passwderr(filename)
	local deauth_file
	deauth_file = io.open(filename, "w+")
	if deauth_file ~= nil then
		deauth_file:write(0)
		deauth_file:flush()
		io.close(deauth_file)
	end
	return 0;
end

function wifi_detail(arg_list_table)

	local rv = {}
	local result = { }
	local wifis = sysutil.sf_wifinetworks()
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
			if dev.networks[n].disable ~= nil and tonumber(dev.networks[n].disable) == 1 then
				rv[#rv]["mac"]     =  nil
			else
				rv[#rv]["mac"]     =  sysutil.getMac(dev.networks[n].ifname)
			end
			rv[#rv]["ssid"]       = dev.networks[n].ssid
			wifi_en = dev.networks[n].disable == nil and 0 or tonumber(dev.networks[n].disable)
			rv[#rv]["enable"]     = wifi_en == 0 and 1 or 0
			rv[#rv]["encryption"] = dev.networks[n].encryption_src
			rv[#rv]["signal"]     = dev.networks[n].signal
			rv[#rv]["password"]   = dev.networks[n].password
			rv[#rv]["channel"]    = dev.networks[n].channel
			rv[#rv]["net_type"]    = dev.networks[n].network
			if dev.networks[n].country ~= nil then
				rv[#rv]["country"]    = dev.networks[n].country
			end
		end
	end
	code = 0
	result["info"] = rv
	return code,result
end

function setwifi(arg_list_table)

	local network = require("luci.model.network").init()
	local wifinet = {}
	local wifidev = {}
	local rv = {}
	local dev = nil

	local setting_param = arg_list_table["setting"]
	local param_disableall = arg_list_table["disableall"]
	local setting_param_json = nil

	local freq_inter = wirelessnew.get_freq_intergration_impl()
	local wdev_2= network:get_wifidev("radio0")
	local wifinet_24g = wdev_2:get_wifinet("wlan0")
	local code = 0

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

	if setting_param_json then
		for i=1,#setting_param_json do
			if setting_param_json[i].oldssid then
				dev = getdev_by_ssid(setting_param_json[i].oldssid,setting_param_json[i].channel)
			end
			if dev then
				local param_ssid = nil
				local param_enable = nil
				local param_key = nil
				local param_encryption = nil
				local param_signal_mode = nil
				local param_channel = nil
				local param_country = nil
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
				if setting_param_json[i].country then
					param_country = setting_param_json[i].country
				end

				if param_ssid and string.len(param_ssid)>32 then
					local param_ssid_tmp = param_ssid
					param_ssid = string.sub(param_ssid_tmp,1,32)
				end
				if param_key and string.len(param_key)>63 then
					local param_key_tmp = param_key
					param_key = string.sub(param_key_tmp,1,63)
				end

				if(param_ssid or param_enable or param_key or param_encryption or param_signal_mode or param_channel or param_disableall) then
					matchssid = true
					wifidev = network:get_wifidev(dev.device)
					if(wifidev and param_channel) then
						nixio.syslog("crit","set channel="..tostring(param_channel))
						wifidev:set("channel", param_channel)
					end
					wifinet = network:get_wifinet(dev.device..".network1")
					if(wifinet) then

						if not (wifidev:get("band") == "2.4G" and freq_inter == 1) then
							if(param_ssid) then wifinet:set("ssid", param_ssid) end
							if(param_enable) then
								wifinet:set("disabled", param_enable~=1 and 1 or nil )
							end
							if(param_key) then wifinet:set("key", param_key) end
							if(param_encryption) then wifinet:set("encryption",param_encryption) end
							if freq_inter == 1  then
								if(param_ssid) then wifinet_24g:set("ssid", param_ssid) end
								if(param_enable) then
									wifinet_24g:set("disabled", param_enable~=1 and 1 or nil )
								end
								if(param_key) then wifinet_24g:set("key", param_key) end
								if(param_encryption) then wifinet_24g:set("encryption",param_encryption) end
							end
						end
						if(param_signal_mode) then
							if param_signal_mode == SAVE_MODE then
								wifidev:set("txpower_lvl", SAVE_MODE_TXPOWER)
							elseif param_signal_mode == NORMAL_MODE then
								wifidev:set("txpower_lvl", NORMAL_MODE_TXPOWER)
							elseif param_signal_mode == PERFORMANCE_MODE then
								wifidev:set("txpower_lvl", PERFORMANCE_MODE_TXPOWER)
							else
								code = sferr.ERROR_NO_UNKNOWN_SIGNAL_MODE
							end
						end
						if(param_country) then
							wifidev:set("country",param_country)
						end
					end
				end

			else
				code = sferr.ERROR_NO_SSID_NONEXIST
			end
		end
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
	return code
end

function setwifi_advanced(arg_list_table)

	local network = require("luci.model.network").init()
	local wifinet = {}
	local wifidev = {}
	local dev = nil
	local setting_param = arg_list_table["setting"]
	local param_disableall = arg_list_table["disableall"]

	local freq_inter = wirelessnew.get_freq_intergration_impl()
	local wdev_2= network:get_wifidev("radio0")
	local wifinet_24g = wdev_2:get_wifinet("wlan0")
	local code = 0

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
				if wifidev:get("band") == "5G" then
					wifidev:set("hwmode", "11a")
					wifidev:set("ht_coex", 0)
					if setting_param_json[i].bandwidth == 0 then
						wifidev:set("htmode", "VHT20")
					elseif setting_param_json[i].bandwidth == 1 then
						wifidev:set("htmode", "VHT40")
					elseif setting_param_json[i].bandwidth == 3 then
						wifidev:set("htmode", "VHT80")
					end
				end

				if wifidev:get("band") == "2.4G" then
					wifidev:set("hwmode", "11g")
					if setting_param_json[i].bandwidth == 0 then
						wifidev:set("htmode", "HT20")
						wifidev:set("ht_coex", "0")
					elseif setting_param_json[i].bandwidth == 1 then
						wifidev:set("htmode", "HT40")
						wifidev:set("noscan", "1")
						wifidev:set("ht_coex", "0")
					elseif setting_param_json[i].bandwidth == 2 then
						wifidev:set("htmode", "HT40")
						wifidev:set("ht_coex", "1")
						wifidev:set("noscan", "0")
					end
				end

			end

			if param_disableall and param_disableall == 1 then setting_param_json[i].enable = 0 end

			if not (wifidev:get("band") == "2.4G" and freq_inter == 1) then
				if setting_param_json[i].ssid then wifinet:set("ssid", setting_param_json[i].ssid) end
				if setting_param_json[i].encryption then wifinet:set("encryption", setting_param_json[i].encryption) end
				if setting_param_json[i].enable then
					wifinet:set("disabled", setting_param_json[i].enable~=1 and 1 or nil );
				end

				if freq_inter == 1  then
					if setting_param_json[i].ssid then wifinet_24g:set("ssid", setting_param_json[i].ssid) end
					if setting_param_json[i].encryption then wifinet_24g:set("encryption", setting_param_json[i].encryption) end
					if setting_param_json[i].enable then
						wifinet_24g:set("disabled", setting_param_json[i].enable~=1 and 1 or nil );
					end

				end
			end

			if setting_param_json[i].signalmode then
				if setting_param_json[i].signalmode == SAVE_MODE then
					wifidev:set("txpower_lvl", SAVE_MODE_TXPOWER)
				elseif setting_param_json[i].signalmode == NORMAL_MODE then
					wifidev:set("txpower_lvl", NORMAL_MODE_TXPOWER)
				elseif setting_param_json[i].signalmode == PERFORMANCE_MODE then
					wifidev:set("txpower_lvl", PERFORMANCE_MODE_TXPOWER)
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

	sysutil.sflog("INFO","Advanced wifi configure changed!")
	return code
end

function getwifi_advanced()

	local rv = {}
	local result = { }
	local wifis = sysutil.sf_wifinetworks()
	local network = require("luci.model.network").init()
	local code = 0

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
		if wifidev:get("band") == "5G" then
			if wifidev:get("htmode") == "VHT20" then
				rv[#rv]["htmode"]     = "HT20"
			elseif wifidev:get("htmode") == "VHT40" then
				rv[#rv]["htmode"]     = "HT40"
			elseif wifidev:get("htmode") == "VHT80" then
				rv[#rv]["htmode"]     = "VHT80"
			else
				rv[#rv]["htmode"]     = wifidev:get("htmode")
			end
		end
		if wifidev:get("band") == "2.4G" then
			if wifidev:get("ht_coex") == "1" then
				rv[#rv]["htmode"]     = "HT20/HT40"
			else
				rv[#rv]["htmode"]     = wifidev:get("htmode")
			end
		end
		rv[#rv]["channel"]    = tonumber(wifidev:get("channel"))
		rv[#rv]["distance"]   = tonumber(wifidev:get("distance"))
		rv[#rv]["fragment"]   = tonumber(wifidev:get("frag"))
		rv[#rv]["rts"]        = tonumber(wifidev:get("rts"))
		if tonumber(wifidev:get("txpower_lvl")) == SAVE_MODE_TXPOWER then
			rv[#rv]["signalmode"] = SAVE_MODE
		elseif tonumber(wifidev:get("txpower_lvl")) == NORMAL_MODE_TXPOWER then
			rv[#rv]["signalmode"] = NORMAL_MODE
		else
			rv[#rv]["signalmode"] = PERFORMANCE_MODE
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
	return code, result
end


function wds_getwanipimpl(arg_list_table)
	local result = {}
	local code = 0
	for i = 15, 1, -1 do
		result.ip = wds_getwanip(arg_list_table["band"])
		if result.ip ~= "nil" then
			break
		end
		luci.sys.call("sleep 1")
	end
	if result.ip ~= "nil" then
		code = 0
		result.msg = "OK"
	else
		code = -1
		result.msg = "Failed to get ipaddr"
	end
	return code, result
end
function get_freq_intergration()
	local result = {}
	local code = 0
	result["enable"] = wirelessnew.get_freq_intergration_impl()
	return code, result
end
function set_freq_intergration(arg_list_table)
	local code = 0
	wirelessnew.set_freq_intergration_impl(arg_list_table)
	return code
end
