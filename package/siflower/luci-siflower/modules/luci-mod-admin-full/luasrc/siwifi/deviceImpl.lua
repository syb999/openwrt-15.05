--[[
LuCI - Lua Configuration Interface

Description:
Offers an implimation  for handle app request
]]--

module("luci.siwifi.deviceImpl", package.seeall)

local sysutil = require "luci.siwifi.sf_sysutil"
local sysconfig = require "luci.siwifi.sf_sysconfig"
local disk = require "luci.siwifi.sf_disk"
local sferr = require "luci.siwifi.sf_error"
local nixio = require "nixio"
local fs = require "nixio.fs"
local json = require("luci.json")
local http = require "luci.http"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local ap = nil
local advancednew = require "luci.controller.admin.advancednew"

local is_ac = _uci_real:get("basic_setting", "ac", "enable") == "1" and true or false
if (is_ac == true) then
	ap = require("luci.controller.admin.ap")
end

local reset_interval = 30

-- send to ssst so ssst could polling update status and send to app
--  for sure app get progress of download
function send_ota_upgrade(arg_list_table, ota_type, mode)
	local cmd_obj = {}
	sysutil.nx_syslog("send get here", nil)
	if (http.getenv("HTTP_AUTHORIZATION") ~= "") then
		cmd_obj.userid = arg_list_table.userid
		cmd_obj.usersubid = arg_list_table.usersubid
		cmd_obj.msgid = arg_list_table.msgid
		cmd_obj.action = sysutil.SYSTEM_EVENT_UPGRADE
		-- type 0 meas ota 1 means ac ota
		cmd_obj.ota_type = ota_type
		cmd_obj.mode = mode
		local cmd_str = json.encode(cmd_obj)
		local cmd = "RSCH -data "..cmd_str
		local cmd_ret = {}

		sysutil.nx_syslog("send "..tostring(cmd_str), 1)
		sysutil.sendCommandToLocalServer(cmd, cmd_ret)
	end
end

function check_ip_mask_mac(ip, mask, mac)
	local ipaddr = ip
	local netmask = mask
	local macaddr = mac
	if ipaddr and string.len(ipaddr) > 31 then
		ipaddr = string.sub(ipaddr, 1, 31)
	end
	if netmask and string.len(netmask) > 31 then
		ipaddr = string.sub(ipaddr, 1, 31)
	end
	if mac and string.len(mac) > 31 then
		ipaddr = string.sub(ipaddr, 1, 31)
	end
	local result = {
		ipaddr = ipaddr,
		netmask = netmask,
		mac = mac
	}
	return result
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
		sysutil.nx_syslog("Can not open /proc/ts", nil)
	end
	return 0
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
					sysutil.nx_syslog(tmp, 1)
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
	local wldev,j = get_wireless_device_mac()
	local is_wl

	if arp_fd then
		ip_mac = {}
		while true do
			local tmp = arp_fd:read("*l")
			is_wl = 0
			if not tmp then break end
			if(string.match(tmp,"lan")) then
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

function get_lan_ip_mac()
	local mac = nil
	local ip_mac = nil
	local br = nil
	arp_fd = io.open("/proc/net/arp", "r")

	if arp_fd then
		ip_mac = {}
		while true do
			local tmp = arp_fd:read("*l")
			if not tmp then break end
			if(string.match(tmp,"lan") or string.match(tmp,"guest") or string.match(tmp,"lease")) then
				ip = tmp:match("([0-9]+.[0-9]+.[0-9]+.[0-9]+)")
				mac = tmp:match("([a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*:[a-fA-F0-9]*)")
				br = tmp:match("br.*")
				if ip and mac then
					local mac_first_part = mac:match("^([0-9]+):")
					if mac_first_part == "0" then
						mac = "0"..(mac:upper()):gsub(":", "_")
					else
						mac = (mac:upper()):gsub(":", "_")
					end
					ip_mac[#ip_mac+1] = {}
					ip_mac[#ip_mac]["ip"] = ip
					ip_mac[#ip_mac]["mac"] = mac
					ip_mac[#ip_mac]["br"] = br
				end
			end
		end
		arp_fd:close()
	end

	return ip_mac

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

function get_wire_assocdev(deal_new)
	local data = {}
	local wire_ifname = _uci_real:get("network", "lan", "ifname");
	local lan_ip = _uci_real:get("network", "lan", "ipaddr")
	local dev_exist = nil
	local online = nil
	local ip2mac = {}
	local hostname = nil

	ip2mac = get_wire_ip_mac()
	if not ip2mac then
		sysutil.nx_syslog("[sfsystem] get ip_mac failed", nil);
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
		if ip2mac[i]["mac"] ~= "00_00_00_00_00_00" then
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
					sysutil.nx_syslog("wire add new device "..ip2mac[i]["mac"], 1);
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
	list_item["is_wireless"]                = tonumber(s.is_wireless or 0)
	list_item["ip"]                         = s.ip or "0.0.0.0"
	list_item["port"]                       = tonumber(s.port or -1)
	list_item["dev"]                        = s.dev or ""
	list_item["warn"]                       = tonumber(s.warn or 0)
	list_item["lease_start"]                = tonumber(s.lease_start or 0)
	list_item["lease_time"]                 = tonumber(s.lease_time or 0)
	list_item["restrictenable"]             = tonumber(s.restrictenable or 0)
	list_item["usageenable"]                = tonumber(s.usageenable or 0)

	list_item["authority"] = {}

	list_item["authority"]["internet"]      = tonumber(s.internet or 1)
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
	sysutil.nx_syslog("[sfsystem] mode:"..mode.."mac:"..tostring(mac), 1);
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
		sysutil.nx_syslog("[sfsystem] name is :"..tostring(s[".name"]), 1);
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
		sysutil.nx_syslog("[sfsystem] name is :"..tostring(s[".name"]), 1);
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
		if s.ifname and (s.disabled ~= "1") then
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
				iwinfo:close()
			end
		end
	end
	return data,#data
end

function do_arp_check_device(ip, mac, br)
	local data = {}
	local notify = 0
	local scan_value = os.execute("arping -I %s -c 5 %s 2>&1 1>/dev/null" %{br,ip})
	local online = 0
	local finish = 0
	local ret = 0 --if need notify, return 1

	if scan_value == 0 then
		online = "1"
	end

	sysutil.nx_syslog("arp check device "..ip.." mac "..mac, 1)
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
		data[#data]["warn"] = "0"
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
	-- TODO: here maybe not find anything when in AC
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
		luci.util.exec("online-warn start %s"%{rdata[1].mac:gsub("_", ":")})
		sysutil.nx_syslog("arp check new wireless device "..mac, 1)
		return 1
	end

	local wire_ifname = _uci_real:get("network", "lan", "ifname");
	rdata = do_set(mac, ip, wire_ifname, online, "0")

	sysutil.nx_syslog("arp check new wire device "..mac, 1)
	set_devlist(rdata)
	return ret
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
			iwinfo:close();
		end
	end
	return data,i
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
	sysutil.nx_syslog("=================firewall reload here===================", nil)
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

function qos_set_config(alldev)

	local ex_list = _uci_real:get_all("qos")
	local exist_flag = 0

	for i=1,#alldev do
		_uci_real:set("qos", alldev[i].mac , "device")
		_uci_real:tset("qos", alldev[i].mac , alldev[i])
	end
	_uci_real:save("qos")
	_uci_real:commit("qos")

end

function bind(arg_list_table)
	local result = {}
	local ret1 = 0
	local extraInfo = ""
	local code = 0
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
					sysutil.nx_syslog("device id " .. device_id, 1)
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
	sysutil.sflog("INFO","Router bind!")
	return code, result
end

function unbind(arg_list_table)
	local extraInfo = ""
	local code = 0
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

				_uci_real:foreach("wireless", "wifi-iface",
				function(s)
					if string.find(s.ifname, "lease") then
						_uci_real:set("wireless", s[".name"], "disabled", "1")
					end
				end)

				local changes = _uci_real:changes()
				if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
					_uci_real:save("wireless")
					_uci_real:commit("wireless")
					sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
				end

			end
		end
	end
	return code
end

function manager(arg_list_table)
	local extraInfo = ""
	local simanager = "/etc/config/simanager"
	local code = 0
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
						code = sferr.ERROR_NO_manager_FAIL
						extraInfo = "-"..decoder["reason"]
					end
				end
			end
		end
	end
	return code
end

function adduser(arg_list_table)
	local result = {}
	local ret1 = 0
	local extraInfo = ""
	local code = 0
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
	return code, result
end

function getaccess(arg_list_table)
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local ret1 = 0
	local extraInfo = ""
	local code = 0
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
	return code, result
end

function device_list(arg_list_table)
	local result = {}
	local info_type = "1"
	local mac = nil
	local info_type = arg_list_table["type"]
	local mac = arg_list_table["mac"]
	local code = 0
	local ap_mac_list =  advancednew.get_ap_mac_list()

	if mac then
		mac = mac:gsub(":","_")
	end
	local wiredev = get_wire_assocdev("0")
	if wiredev then
		set_devlist(wiredev)
	end
	update_ts()

	local list_dev,count = get_devinfo_from_devlist(info_type, mac)
	-- add for filter fit ap mac address in ac
	for i =1, #list_dev do
		list_dev[i].is_ap = 0
		if #ap_mac_list ~=  0 then
			for j =1, #ap_mac_list do
				if ap_mac_list[j]:upper() == list_dev[i].mac then
					list_dev[i].is_ap = 1
				end
			end
		end
	end
	if info_type == 2 then
		result["online"] = count
	else
		result["list"] = list_dev
	end
	return code, result
end

function setdevice(arg_list_table)
	local code = 0
	local wire = 0
	local mac = arg_list_table["mac"]
	if mac then
		mac = mac:gsub(":","_")
	else
		code = sferr.ERROR_NO_MAC_EMPTY
		return code, nil
		--break;
	end
	repeat
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
								starttime = json_data[i]["starttime"], endtime = json_data[i]["endtime"], week = json_data[i]["week"],
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
	sysutil.sflog("INFO","Device %s configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	return code
end

function del_device_info(arg_list_table)
	local devlist = ""
	local port = arg_list_table["port"]
	local mac = arg_list_table["mac"]
	local code = 0

	if mac then
		mac = mac:gsub(":","_")
	end
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
	sysutil.sflog("INFO","Delete device %s!"%{mac})
	return code
end

function get_wifi_filter()
	local result = {}
	local code = 0
	result["enable"] = _uci_real:get("notify", "setting", "enable") or "0"
	result["mode"] = _uci_real:get("notify", "setting", "mode") or "0"
	return code, result
end

function set_wifi_filter(arg_list_table)
	local code = 0
	local push_enable = arg_list_table["enable"]
	local push_mode   = arg_list_table["mode"]
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
	if push_enable then
		sysutil.sflog("INFO","Wifi filter configure changed!enable status:1")

		sysutil.sflog("INFO","Wifi filter configure changed!enable status:0")
	end
	return code
end

function getdefault()
	local result = {}
	local extraInfo = ""
	local cfg_file = "sidefault"
	local code = 0
	local internet = _uci_real:get(cfg_file, "acl", "internet")
	result["internet"] = tonumber(internet or 1)
	return code, result
end

function setdefault(arg_list_table)
	local extraInfo = ""
	local internet = arg_list_table["internet"]
	local cfg_file = "sidefault"
	local code = 0

	if internet then
		_uci_real:set(cfg_file, "acl", "internet", tostring(internet))
		_uci_real:save(cfg_file)
		_uci_real:commit(cfg_file)
	end
	return code
end

function setdevicedatausage(arg_list_table)
	local setlist_json = {}
	local mac = arg_list_table["mac"]
	local code = 0
	local setlist = arg_list_table["setlist"]
	local change = arg_list_table["change"]
	local usage_enable = arg_list_table["usageenable"]

	local checkdata = check_ip_mask_mac(nil, nil, mac)
	mac = checkdata.mac
	local op_list = get_list_by_mac(mac)

	if setlist and op_list then
		_uci_real:set(op_list , mac, "setlist", json.encode(setlist))
	end
	if change and op_list then
		_uci_real:set(op_list , mac, "change", change)
	end
	if usage_enable and op_list then
		_uci_real:set(op_list , mac, "usageenable", usage_enable)
	end

	_uci_real:save(op_list )
	_uci_real:commit(op_list )
	if usage_enable == 1 then
		luci.util.exec("tscript flow_en %s %s"%{mac:gsub("_",":"), change})
	else
		luci.util.exec("tscript flow_dis %s"%{mac:gsub("_",":")})
	end
	sysutil.sflog("INFO","Device %s flow limit configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	return code
end

function getdevicedatausage(arg_list_table)
	local result = {}
	local setlist = {}
	local setlist_json = {}
	local mac = arg_list_table["mac"]
	local code = 0
	local op_list = get_list_by_mac(mac)

	result["setlist"] = json.decode(_uci_real:get(op_list , mac, "setlist"))
	result["usageenable"] = tonumber(_uci_real:get(op_list , mac, "usageenable") or 0)
	result["credit"] = get_dev_credit((mac:upper()):gsub("_",":"))
	return code, result
end

function set_warn(arg_list_table)
	local enable = arg_list_table["enable"]
	local code = 0
	local cmd = enable == 1 and "start_all" or "stop_all"

	if enable then
		_uci_real:set("basic_setting", "onlinewarn", "enable", enable)
	end
	_uci_real:save("basic_setting" )
	_uci_real:commit("basic_setting")
	luci.util.exec("online-warn "..cmd)

	sysutil.sflog("INFO","Device warning function is %s!" %{tostring(enable) == "1" and "on" or "off"})
	return code
end

function get_warn()
	local result = {}
	local code = 0
	result["enable"] = tonumber(_uci_real:get("basic_setting", "onlinewarn", "enable") or 0)
	return code, result
end

function set_dev_warn(arg_list_table)
	local maclist = arg_list_table["mac"]
	local enable = arg_list_table["enable"]
	local code = 0
	if maclist then
		for i,value in ipairs(maclist) do
			_uci_real:set("wldevlist", value:gsub(":","_"), "warn", "0")
		end
	end
	_uci_real:save("wldevlist" )
	_uci_real:commit("wldevlist")

	luci.util.exec("online-warn stop")

	sysutil.sflog("INFO","Close some devices warning!")
	return code
end

function setdevicetime(arg_list_table)
	local mac = arg_list_table["mac"]
	local action = arg_list_table["action"]
	local code = 0
	local op_list = get_list_by_mac(mac)
	if action == 0 then
		local time = arg_list_table["time"]
		if time then
			_uci_real:set(op_list , mac, "time", time)
			luci.util.exec("pctl visitor add %s %s"%{ mac:gsub("_",":"), time})
		end
	else
		_uci_real:set(op_list , mac, "time", "0")
		luci.util.exec("pctl visitor del %s"%{ mac:gsub("_",":")})
	end
	_uci_real:save(op_list )
	_uci_real:commit(op_list )
	sysutil.sflog("INFO","Device %s visit time configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	return code
end

function getdevicetime(arg_list_table)
	local result = {}
	local mac = arg_list_table["mac"]
	local code = 0
	local op_list = get_list_by_mac(mac)

	result["time"] = tonumber(_uci_real:get(op_list , mac, "time") or 0)
	return code, result
end

function set_lease_net(arg_list_table)
	local enable = arg_list_table["enable"]
	local lssid = arg_list_table["ssid"]
	local llimit = arg_list_table["limitdownload"]
	local code = 0
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)

		if string.find(s.ifname, "lease") then
			if enable == true then
				_uci_real:set("wireless", s[".name"], "disabled", "0")
			else
				_uci_real:set("wireless", s[".name"], "disabled", "1")
			end

			if( lssid) then
				_uci_real:set("wireless", s[".name"], "ssid", lssid)
			end
		end
	end)

	local changes = _uci_real:changes()
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		_uci_real:save("wireless")
		_uci_real:commit("wireless")
		sysutil.fork_exec("sleep 1; env -i; ubus call network reload ; wifi reload_legacy")
	end

	local speed_ori = _uci_real:get("basic_setting", "lease_wifi", "speed")
	if( tostring(llimit) ~= speed_ori ) then
		_uci_real:set("basic_setting", "lease_wifi", "speed", tostring(llimit))
		_uci_real:save("basic_setting")
		_uci_real:commit("basic_setting")
		luci.util.exec("tc qdisc replace dev br-lease root handle 1: tbf rate %skbps latency 50ms burst 2048 "%{tostring(llimit)})
	end
	return code
end

function get_lease_net()
	local result = {}
	local code = 0
	_uci_real:foreach("wireless", "wifi-iface",
	function(s)
		if string.find(s.ifname, "lease") then
			if _uci_real:get("wireless", s[".name"], "disabled") == "0" or    _uci_real:get("wireless", s[".name"], "disabled") == nil  then
				result["enable"] = true
			else
				result["enable"] = false
			end
			result["ssid"] = _uci_real:get("wireless", s[".name"], "ssid")
		end
	end)

	result["limitdownload"] = tonumber(_uci_real:get("basic_setting", "lease_wifi", "speed"))
	return code, result
end

function set_lease_mac(arg_list_table)
	local mac = arg_list_table["mac"]
	local timecount = arg_list_table["timecount"]
	local code = 0

	local checkdata = check_ip_mask_mac(nil, nil, mac)
	mac = checkdata.mac
	local uci_mac = (mac:upper()):gsub(":", "_")
	local old_time = _uci_real:get("wldevlist", uci_mac, "lease_time")
	local old_start = _uci_real:get("wldevlist", uci_mac, "lease_start")
	local nstart = os.time()
	if old_time then
		timediff= nstart - tonumber(old_start)
		if (timediff < tonumber(old_time)) then
			timecount = timecount + tonumber(old_time) - timediff
		end
	end
	if timecount > 0 then
		luci.util.exec("aclscript l_time %s %s"%{ (mac:gsub("_",":")):upper(), tostring(timecount)})
	else
		luci.util.exec("aclscript l_del %s"%{ (mac:gsub("_",":")):upper()})
	end
	return code
end

function set_user_info(arg_list_table)
	local extraInfo = ""
	local code = 0
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
	return code
end

function get_stok_local()
	result = {}
	local stok = luci.dispatcher.build_url()
	local stok1,stok2 = string.match(stok,"(%w+)=([a-fA-F0-9]*)")

	local code = 0
	result["stok"] = stok2
	return code, result
end

function main_status(arg_list_table)

	local result = { }
	local wifis = sysutil.sf_wifinetworks()
	local querycpu = arg_list_table["querycpu"]
	local querymem = arg_list_table["querymem"]
	local code = 0
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
	return code, result
end

function setpasswd(arg_list_table)
	local username = "admin"
	local oldpasswd = arg_list_table["oldpwd"]
	local pwd = arg_list_table["newpwd"]
	local code = 0
	local authen_vaild = luci.sys.user.checkpasswd(username,oldpasswd)

	if authen_vaild == false then
		code = sferr.ERROR_NO_OLDPASSWORD_INCORRECT
	else
		code = luci.sys.user.setpasswd("admin", pwd)
	end
	sysutil.sflog("INFO","Password changed!")
	return code
end


