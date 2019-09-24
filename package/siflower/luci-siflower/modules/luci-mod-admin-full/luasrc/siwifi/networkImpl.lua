--[[
LuCI - Lua Configuration Interface

Description:
Offers an implimation  for handle app request
]]--

module("luci.siwifi.networkImpl", package.seeall)

local sysutil = require "luci.siwifi.sf_sysutil"
local sysconfig = require "luci.siwifi.sf_sysconfig"
local disk = require "luci.siwifi.sf_disk"
local sferr = require "luci.siwifi.sf_error"
local wirelessnew = require "luci.controller.admin.wirelessnew"
local systemnew = require "luci.controller.admin.systemnew"
local networknew = require "luci.controller.admin.networknew"
local advancednew = require "luci.controller.admin.advancednew"
local nixio = require "nixio"
local fs = require "nixio.fs"
local json = require("luci.json")
local http = require "luci.http"
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local ap = nil

local is_ac = _uci_real:get("basic_setting", "ac", "enable") == "1" and true or false
if (is_ac == true) then
	ap = require("luci.controller.admin.ap")
end

local reset_interval = 30

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

function check_ip_mask_mac(ip, mask, mac)
	local ipaddr = ip
	local netmask = mask
	local macaddr = mac
	if ipaddr and string.len(ipaddr) > 31 then
		ipaddr = string.sub(ipaddr, 1, 31)
	end
	if netmask and string.len(netmask) > 31 then
		netmask = string.sub(netmask, 1, 31)
	end
	if mac and string.len(mac) > 31 then
		mac = string.sub(mac, 1, 31)
	end
	local result = {
		ipaddr = ipaddr,
		netmask = netmask,
		mac = mac
	}
	return result
end

function StringSplit(str, split_char)
	local substr = {}
	local pos = 0
	local index = 0
	while true do
		pos = string.find(str, split_char, index+1)
		if pos == nil then
			table.insert(substr, string.sub(str, index+1));
			break;
		end

		table.insert(substr, string.sub(str, index+1, pos-1));
		index = pos
	end
	return substr
end


function IsInTable(t, val)
	for _, v in ipairs(t) do
		if v == val then
			return true
		end
	end
	return false
end

function check_netmask(mask)
	ligal = {"0","128","192","224","240","252","254","255"}
	local mask_nm1, mask_nm2, mask_nm3, mask_nm4 = mask:match('(%d+)%.(%d+)%.(%d+)%.(%d+)')
	arry = {mask_nm4,mask_nm3,mask_nm2,mask_nm1}
	if arry[4] == "0" or arry[1] == "255" or arry[4] == "254" then
		return false
	end
	for index,v in ipairs(arry) do
		if index < 4 then
			if arry[index] ~= "0" and IsInTable(ligal,arry[index]) then
				if arry[index + 1] ~= "255" then
					return false
				end
			elseif arry[index] == "0" then
				if not IsInTable(ligal,arry[index + 1]) then
					return false
				end
			else
				return false
			end
		end
	end
	return true
end

function check_dhcp_with_lan(address,mask)
	local ip = StringSplit(address, '%.')
	local netmask = StringSplit(mask, '%.')
	local bottom_ip ={}
	for k, v in pairs( ip   ) do
		if netmask[k] == "255" then
			bottom_ip[k] = tonumber(v)
		elseif netmask[k] == "0" then
			bottom_ip[k] = 0
		else
			local mod = tonumber(v) % (( 255 -  tonumber(netmask[k])   ) + 1 )
			bottom_ip[k] = tonumber(v) - mod
		end
	end
	local top_ip = {}
	for k, v in pairs( bottom_ip    ) do
		top_ip[k] = v + (255 - tonumber(netmask[k]))
	end
	local bottom_ip_val = bottom_ip[1]*2^24 + bottom_ip[2]*2^16 + bottom_ip[3]*2^8 + bottom_ip[4]
	local top_ip_val = top_ip[1]*2^24 + top_ip[2]*2^16 + top_ip[3]*2^8 + top_ip[4]
	local start = tonumber(_uci_real:get("dhcp","lan","start"))
	local limit = tonumber(_uci_real:get("dhcp","lan","limit"))
	local dhcp_start_val = bottom_ip_val + start
	local dhcp_end_val = dhcp_start_val + limit
	if(top_ip_val > dhcp_end_val and bottom_ip_val < dhcp_start_val) then
		return true
	else
		return false
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

function welcome()
	local userid = getfenv(1).userid
	local code = 0
	local result = {}
	result["msg"] = "welcome to sf-system"
	result["userid"] = userid or ""
	return code, result
end

function init_info(arg_list_table)
	local uci =require "luci.model.uci".cursor()
	local code = 0
	local result = {}
	result["romtype"] = sysutil.getRomtype()
	result["name"] = sysutil.getRouterName()
	result["romversion"] = sysutil.getRomVersion()
	result["romversionnumber"] = 0
	result["sn"] = sysutil.getSN()
	result["hardware"] = sysutil.getHardware()
	result["account"] =  sysutil.getRouterAccount()
	result["mac"] = sysutil.getMac("eth0")
	result["disk"] = disk.getDiskAvaiable()
	result["routerid"] = uci:get("siserver","cloudrouter","routerid") or ''
	-- make this 0
    result["zigbee"] = sysutil.getZigbeeAttr()
	result["storage"] = sysutil.getStorage()
	return code, result
end

function command(arg_list_table)

	local cmd = arg_list_table["cmd"]
	local code = 0
	if cmd == 0 then
		code = reboot()
	elseif cmd == 2 then
		code = reset()
	else
		code = sferr.ERROR_NO_UNKNOWN_CMD
	end
	return code
end
function device_list_backstage()

	local code = 0
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
	return code
end

function arp_check_dev(arg_list_table)
	local ip = arg_list_table["ip"]
	local mac = arg_list_table["mac"]
	local code = 0
	local ret = 0
	local result = { }
	local is_lan = 0
	local ip2mac = {}
	local br = nil

	ip2mac = get_lan_ip_mac()
	if not ip2mac then
		sysutil.nx_syslog("[sfsystem] get ip_mac failed", nil)
		return nil
	end

	for i=1,#ip2mac do
		if ip2mac[i]["ip"] == ip then
			br = ip2mac[i]["br"]
			is_lan = 1
			break
		end
	end

	if mac then
		mac = mac:gsub(":", "_")
	end
	if ip and mac and is_lan == 1 then
		ret = do_arp_check_device(ip, mac, br)
		if ret == 1 then
			result["notify"] = 1
		end
	end
	sysutil.nx_syslog("need notify is %d"%{ret}, 1)
	return code, result
end
function ota_check()
	local uci =require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	local remote_info = sysutil.getOTAInfo()
	if (remote_info) then
		updateToVersion = remote_info["updateToVersion"]
		currentVersion = remote_info["currentVersion"]
		result["romversion"] = sysutil.getRomVersion()
		result["romtime"]    = uci:get("siwifi","hardware","romtime")
		result["otaversion"] = updateToVersion["version"]
		result["otatime"]    = updateToVersion["updateAt"]
		result["checksum"]   = updateToVersion["checksum"]
		result["size"]       = updateToVersion["size"]
		result["type"]       = updateToVersion["romtype"]
		result["url"]        = updateToVersion["path"]
		result["log"]        = updateToVersion["releaseNote"]
		result["force"]      = currentVersion["force"]
		result["stop"]       = currentVersion["stop"]
		code = 0
	else
		code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
	end
	return code, result
end

function ota_check2()
	local uci =require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	local remote_info = sysutil.getOTAInfo()
	if (remote_info) then
		updateToVersion = remote_info["updateToVersion"]
		currentVersion = remote_info["currentVersion"]
		result["romversion"] = sysutil.getRomVersion()
		result["romtime"]    = uci:get("siwifi","hardware","romtime")
		result["otaversion"] = updateToVersion["version"]
		result["otatime"]    = updateToVersion["updateAt"]
		result["checksum"]   = updateToVersion["checksum"]
		result["size"]       = updateToVersion["size"]
		result["type"]       = updateToVersion["romtype"]
		result["url"]        = updateToVersion["path"]
		result["log"]        = updateToVersion["releaseNote"]
		result["force"]      = currentVersion["force"]
		result["stop"]       = currentVersion["stop"]
		code = 0
	else
		code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
	end
	return code, result
end

function ac_ap_ota_check()
	local uci =require "luci.model.uci".cursor()
	local result = {}
	local ac_result = {}
	local ap_result = {}
	local ap_romversion = ""
	local code = 0
	local ac_remote_info = sysutil.getOTAInfo()
	if (ac_remote_info) then
		updateToVersion = ac_remote_info["updateToVersion"]
		currentVersion = ac_remote_info["currentVersion"]
		ac_result["romversion"] = sysutil.getRomVersion()
		ac_result["romtime"]    = uci:get("siwifi","hardware","romtime")
		ac_result["otaversion"] = updateToVersion["version"]
		ac_result["otatime"]    = updateToVersion["updateAt"]
		ac_result["checksum"]   = updateToVersion["checksum"]
		ac_result["size"]       = updateToVersion["size"]
		ac_result["type"]       = updateToVersion["romtype"]
		ac_result["url"]        = updateToVersion["path"]
		ac_result["log"]        = updateToVersion["releaseNote"]
		ac_result["force"]      = currentVersion["force"]
		ac_result["stop"]       = currentVersion["stop"]
	end
	local ap_remote_infos = sysutil.getApOTAInfos()
	if (ap_remote_infos) then
		for i=1, #ap_remote_infos do
			updateToVersion = ap_remote_infos[i].updateToVersion
			currentVersion = ap_remote_infos[i].currentVersion
			sysutil.nx_syslog("version info here"..currentVersion.version, 1)
			sysutil.nx_syslog("version info here"..updateToVersion.version, 1)
			if currentVersion.version  ~= updateToVersion.version  then

				ap_result[#ap_result+1] = {}
				ap_result[#ap_result].romversion = currentVersion.version
				ap_result[#ap_result].romtime    = uci:get("siwifi","hardware","romtime")
				ap_result[#ap_result].otaversion = updateToVersion.version
				ap_result[#ap_result].otatime    = updateToVersion.updateAt
				ap_result[#ap_result].checksum   = updateToVersion.checksum
				ap_result[#ap_result].size       = updateToVersion.size
				ap_result[#ap_result]["type"]     = updateToVersion["romtype"]
				ap_result[#ap_result].url        = updateToVersion.path
				ap_result[#ap_result].log        = updateToVersion.releaseNote
				ap_result[#ap_result].force      = currentVersion.force
				ap_result[#ap_result].stop       = currentVersion.stop
			end
		end
	end
	if (ac_remote_info or ap_remote_info) then
		code = 0
		result["ac"] = ac_result
		result["ap"] = ap_result
		result["ap_len"] = #ap_result
	else
		code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
	end
	return code, result
end

function ota_upgrade(arg_list_table)
	local result = {}
	local flag = 0
	local code = 0

	local mode = 0
	local check = arg_list_table["check"]
	result["status"] = 0
	result["downloaded"] = 0

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
			local ota_info = sysutil.getOTAInfo()
			if ( not ota_info ) then
				luci.util.exec("rm /tmp/upgrade_shortest_time")
				code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
			else
				local remote_info = ota_info["updateToVersion"]
				local otaversion = remote_info["version"]
				local romversion = sysutil.getRomVersion()
				if not string.find(romversion,otaversion) then
					local info = {}
					info["size"] = remote_info["size"]
					info["url"] = remote_info["path"]
					info["checksum"] = remote_info["checksum"]
					local json_info = json.encode(info)
					local f = nixio.open("/tmp/ota_info", "w", 600)
					f:writeall(json_info)
					f:close()
					mode = 1
					send_ota_upgrade(arg_list_table,0, mode)
					sysutil.fork_exec("/usr/bin/otaupgrade")
				else
					luci.util.exec("rm /tmp/upgrade_shortest_time")
					code = sferr.EEROR_NO_LOCALVERSION_EAQULE_OTAVERSION
				end
			end
		else
			code = sferr.ERROR_NO_WAITTING_OTA_UPGRADE
		end
		result["mode"] = mode
	else
		mode = 1
		local ota_sta = systemnew.get_ota_update_status()

		result["status"] = systemnew.get_web_status(ota_sta.status, mode)
		result["status_msg"] = systemnew.get_ota_message(ota_sta.status)

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
				local downloaded_size = tonumber(string.match(ret, "root%s+(%d+)")) or 0
				local downloaded = downloaded_size/ota_image_size
				result["downloaded"] = (downloaded - downloaded%0.01)*100
			end
		else
			result["downloaded"] = 0
		end
	end
	return code, result
end

function ac_ota_upgrade(arg_list_table)
	local result = {}
	local check = arg_list_table["check"]
	local mode = arg_list_table["mode"]
	local code = 0

	if mode == nil  and check == 1 then
		mode = 3
	else
		mode = 0
	end

	sysutil.nx_syslog("ac_ota_upgrade mode "..tostring(mode), 1)
	code,result = ac_ota_upgrade_impl(check,mode)

	sysutil.nx_syslog("ac_ota_upgrade check "..tostring(check).." code "..tostring(code), 1)
	if check == 0 and code == 0 then
		send_ota_upgrade(arg_list_table,1,result.mode)
	end
	return code, result
end

function ac_ota_upgrade_impl(check, mode)
	local result = {}
	local code   = 0

	result["status"] = 0
	result["downloaded"] = 0
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
			local ota_info = sysutil.getOTAInfo()
			local ap_ota_infos = sysutil.getApOTAInfos()
			local apallsame = 1
			local acsame = 1
			if ( not ota_info and not ap_ota_infos ) then
				luci.util.exec("rm /tmp/upgrade_shortest_time")
				code = sferr.EEROR_NO_OTAVESION_NOT_DOWNLOADED
			else
				if ota_info then
					local remote_info = ota_info["updateToVersion"]
					local otaversion = remote_info["version"]
					local romversion = sysutil.getRomVersion()
					if not string.find(romversion,otaversion) then
						acsame = 0
						local info = {}
						info["size"] = remote_info["size"]
						info["url"] = remote_info["path"]
						info["checksum"] = remote_info["checksum"]
						local json_info = json.encode(info)
						local f = nixio.open("/tmp/ota_info", "w", 600)
						f:writeall(json_info)
						f:close()
						mode = mode + 1
					end
				end
				if ap_ota_infos then
					local info = {}
					for i=1, #ap_ota_infos do
						local ap_remote_info = ap_ota_infos[i].updateToVersion
						local ap_local_info = ap_ota_infos[i].currentVersion
						local ap_ota_version = ap_remote_info.version


						local ap_local_version = ap_local_info.version
						if ap_ota_version ~= ap_local_version then
							apallsame = 0
							info[#info+1] = {}
							info[#info]["size"] = ap_remote_info["size"]
							info[#info]["url"] = ap_remote_info["path"]
							info[#info]["checksum"] = ap_remote_info["checksum"]
							info[#info]["otaversion"] = ap_ota_version
							info[#info]["oriversion"] = ap_local_version
						end
					end
					if apallsame == 0 then
						local json_info = json.encode(info)
						local f = nixio.open("/tmp/ap_ota_info", "w", 600)
						f:writeall(json_info)
						f:close()
						mode = mode + 2
					end
				end
				if (acsame == 1 and apallsame == 1) then
					luci.util.exec("rm /tmp/upgrade_shortest_time")
					code = sferr.EEROR_NO_LOCALVERSION_EAQULE_OTAVERSION
				else
					sysutil.fork_exec("/usr/bin/otaupgrade")
				end
			end
		else
			code = sferr.ERROR_NO_WAITTING_OTA_UPGRADE
		end
		result["mode"]  =  mode
	else
		local ota_sta = systemnew.get_ota_update_status()
		result["status"] = systemnew.get_web_status(ota_sta.status, mode)
		result["status_msg"] = systemnew.get_ota_message(ota_sta.status)
		if ota_sta.status == 5 or ota_sta.status == 8  or ota_sta.status == 11 then
			result["status_msg"] = result["status_msg"]..ota_sta.msg
		end
		if ota_sta.status == systemnew.OTA_FLASH and mode == 3 then
			result["ac_start"] = 1
		end
		if result.status == 1 then
			if sysutil.sane("/tmp/upgrade_shortest_time") then
				local ret = luci.util.exec("ls -l /tmp/firmware.img")
				local ota_image_size = 0
				local ap_ota_image_size = 0
				local ap_img_num = 0
				if sysutil.sane("/tmp/ota_info") then
					local info = json.decode(fs.readfile("/tmp/ota_info"))
					ota_image_size = info["size"]
				end

				if sysutil.sane("/tmp/ap_download.info") then
					local info = json.decode(fs.readfile("/tmp/ap_download.info"))
					for i =1, #info do
						ap_ota_image_size = ap_ota_image_size  + info[i].size
					end
					ap_img_num = #info
				end
				local ap_ret = {}
				for i = 1, ap_img_num do
					ap_ret[i] = luci.util.exec("ls -l /tmp/ap_firmware.img"..tostring(i))
				end
				if(ota_image_size == 0 and ap_ota_image_size == 0) then
					result["downloaded"] = 0
				else
					local downloaded_size = tonumber(string.match(ret, "root%s+(%d+)")) or 0
					local ap_downloaded_size = 0
					for i = 1, #ap_ret do
						if string.match(ap_ret[i], "root%s+(%d+)") ~= nil then
							ap_downloaded_size = ap_downloaded_size + tonumber(string.match(ap_ret[i], "root%s+(%d+)")) or 0
						end
					end
					sysutil.nx_syslog("ota size"..tostring(ota_image_size).." download size "..tostring(downloaded_size).."ap ota size"..tostring(ap_ota_image_size).." download size"..tostring(ap_downloaded_size), 1)
					local downloaded = (downloaded_size + ap_downloaded_size)/(ota_image_size + ap_ota_image_size)
					result["downloaded"] = (downloaded - downloaded%0.01)*100
				end
			else
				result["downloaded"] = 0
			end
		end
	end
	return code, result
end

function check_wan_type()
	local result = {}
	local code = 0
	local time1 = os.time()
	local wantype = luci.util.exec("ubus call network.internet wantype")
	sysutil.nx_syslog("check wan type cost time "..tostring(os.time() - time1).."s--result:"..tostring(wantype), 1)
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
	return code, result
end

function get_wan_type()
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local code = 0
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
	return code, result
end

function set_wan_type(arg_list_table)
	local uci = require "luci.model.uci".cursor()
	local pure_config = "basic_setting"
	local _type = arg_list_table["type"]
	local code = 0
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
			uci:delete("network","wan","error")
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
			sysutil.fork_exec("sleep 1; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
		end
	end
	if(_type == 1 and code == 0) then
		local timer = 0
		local timeout = 15
		local fixip = uci:get("network","wan","fixipEnb")
		if fixip == '1' then
			timeout = 25
		end
		while true do
			-- cause we set connect with uci in ppp-up so we must reload config file to check changes
			uci:load("network")
			pppoe_status = uci:get("network","wan","connect")
			pppoe_error = uci:get("network","wan","error")
			if pppoe_error or pppoe_status == '1' or timer >= timeout then
				break
			else
				timer = timer + 3
				os.execute("sleep "..3)
			end
		end
		if timer >= timeout then
			code = sferr.ERROR_PPPOE_CONNECT_TIMEOUT
		elseif pppoe_error then
			code = sferr.ERROR_NO_PPPOE_AUTH_ERROR
		end
	end
	sysutil.sflog("INFO","WAN configure changed!")
	return code
end

function get_lan_type()
	--web
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
	--app
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local code = 0

	result["ip"]           = uci:get("network","lan","ipaddr")
	result["mtu"]          = tonumber(uci:get("network","lan","mtu"))
	result["dynamic_dhcp"] = uci:get("dhcp","lan","ignore") == '1' and 0 or 1
	result["dhcpstart"]    = tonumber(uci:get("dhcp","lan","start"))
	result["dhcpend"]      = tonumber(uci:get("dhcp","lan","limit"))
	result["leasetime"]    = uci:get("dhcp","lan","leasetime")
	--//web
	result["mac"]          = device:mac()--string mac地址
	result["mode"]         = uci:get("network","lan","mode") or 0 --int Lan口ip设置模式 0：自动 1:手动
	result["netmask"]      = net:netmask() --string 子网掩码

	return code, result
end

function set_lan_type(arg_list_table)
	local uci = require "luci.model.uci".cursor()
	local address = arg_list_table["address"]
	local mtu = arg_list_table["mtu"]
	local dynamic_dhcp = arg_list_table["dynamic_dhcp"]
	local dhcpstart = arg_list_table["dhcpstart"]
	local dhcpend = arg_list_table["dhcpend"]
	local leasetime = arg_list_table["leasetime"]
	local mode = arg_list_table["mode"]
	local mask = arg_list_table["netmask"]
	local code = 0

	local origin_address =  _uci_real:get("network","lan","ipaddr")
	if mask and string.len(mask)>31 then
		mask = string.sub(mask,1,31)
	end
	if address and string.len(address)>31 then
		address = string.sub(address,1,31)
	end
	if mode == 1 and check_netmask(mask) then
		if check_dhcp_with_lan(address,mask) then
			uci:set("network","lan","ipaddr",address)
			uci:set("network","lan","netmask",mask)
			uci:set("network","lan","mode",mode)
		else
			code = sferr.ERROR_INPUT_PARAM_ERROR
		end
	elseif mode == 0 then
		uci:set("network","lan","netmask","255.255.255.0")
		uci:set("network","lan","mode",mode)
	else
		-- code = sferr.ERROR_NO_INPUT_NETMASK_ILLEGAL
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
			if(origin_address ~= address) then
				luci.sys.call("echo %s siwifi.cn > /etc/hosts" %{address})
				sysutil.fork_exec("sleep 2; env -i /bin/ubus call network restart >/dev/null 2>/dev/null")
			else
				sysutil.fork_exec("sleep 2; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
			end
		end
		local dhcp_changes = uci:changes("dhcp")
		if((dhcp_changes ~= nil) and (type(dhcp_changes) == "table") and (next(dhcp_changes) ~= nil)) then
			uci:save("dhcp")
			uci:commit("dhcp")
			uci:load("dhcp")
			luci.sys.call("env -i /etc/init.d/dnsmasq restart; sleep 1")
		end
	end
	sysutil.sflog("INFO","LAN configure changed!")
	return code
end

function detect_wan_type()
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local extraInfo = ""
	local code = 0

	local dt_iface   = uci:get("network","wan","ifname")
	local runcmd  = "wandetect "..dt_iface
	local checkret =  luci.util.exec(runcmd)
	local wantype = string.sub(checkret,1,-2)
	result["wantype"] = wantype
	return code, result
end

function qos_set(arg_list_table)
	local qos_enable = arg_list_table["enable"]
	local code = 0

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
	return code
end

function qos_info()

	local result = {}
	local code = 0

	result["enable"] = _uci_real:get("basic_setting","qos","enable")
	return code, result
end

function netdetect(arg_list_table)
	local wifis = sysutil.sf_wifinetworks()
	local result = {}
	local code = 0
	local bandwidth = {}
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
				local lost        =  (ping_total-ping_success)/ping_total
				result["lost"]    =  (lost - lost%0.01 )*100
				result["delay"]   =  ping_delay
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
				-- local upbandwidth_info     = luci.util.exec("netdetect -u")
				-- bandwidth["upbandwidth"]   = upbandwidth_info : match('[^%d]+(%d+).*')
				-- if(bandwidth["upbandwidth"] == nil) then
				--     bandwidth["upbandwidth"] = -1
				-- end
				bandwidth["upbandwidth"] = -1
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
	return code,result
end

function check_net()
	local result = {}
	local extraInfo = ""
	local code = 0
	local  checkret =  luci.util.exec("check_net check")
	local  status = tonumber(string.sub(checkret,1,-2))
	result["status"] = status
	return code, result
end
function upload_log(arg_list_table)
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
		if(cmd == "system") then
			local_url = "/tmp/syslog.tar"
			luci.util.exec("logread  > /tmp/syslog.txt")
			luci.util.exec("tar -zcvf %s /tmp/syslog.txt /tmp/sf_log.txt" %{local_url} )
		elseif(cmd == "kernel") then
			local_url = "/tmp/klog.txt"
			--dump npu buff status
			luci.util.exec("echo 7 > /sys/kernel/debug/npu_debug")
			--pmu status
			luci.util.exec("echo 0 r 0x30 0x1 > /sys/kernel/debug/i2c_debug")
			luci.util.exec("echo 0 r 0x30 0x3 > /sys/kernel/debug/i2c_debug")
			luci.util.exec("echo 0 r 0x30 0x4 > /sys/kernel/debug/i2c_debug")
			luci.util.exec("dmesg > %s" %{local_url} )
		elseif(cmd == "status") then
			local_url = "/tmp/RouterStatus.txt"
			luci.util.exec("cat /proc/uptime > %s" %{local_url} )
			luci.util.exec("free >> %s" %{local_url} )
			luci.util.exec("df >> %s" %{local_url} )
			luci.util.exec("cat /sys/kernel/debug/npu_debug >> %s" %{local_url} )
			luci.util.exec("ifconfig -a >> %s" %{local_url} )
			luci.util.exec("netstat -nlp >> %s" %{local_url} )
			luci.util.exec("ipset --list >> %s" %{local_url} )
			luci.util.exec("iptables -L >> %s" %{local_url} )
			luci.util.exec("cat /proc/power-manager/* >> %s" %{local_url} )
			luci.util.exec("cat /sys/kernel/debug/clk/clk_summary >> %s" %{local_url} )
			luci.util.exec("cat /proc/uptime >> %s" %{local_url} )
			luci.util.exec("top n 1 >> %s" %{local_url} )
		elseif(cmd == "wifi") then
			local_url = "/tmp/wifi.tar"
			local file = io.open("/sf16a18", "rb")
			luci.util.exec("dd if=/dev/mtdblock3 of=/tmp/fac count=1 bs=4096")
			if file then
				file:close()
				luci.util.exec("cp /tmp/fac /sf16a18/")
				luci.util.exec("tar -zcvf %s /sf16a18/* " %{local_url} )
			else
				luci.util.exec("cd /tmp/;tar -zcvf %s fac " %{local_url} )
			end
			luci.util.exec("rm /tmp/fac")
		elseif(cmd == "config") then
			local_url = "/tmp/config.tar"
			luci.util.exec("tar -zcvf %s /etc/config/* " %{local_url} )
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

	local function upload_info(userid, routerid, slogurl, klogurl, statusurl, wifiurl, configurl, romversion, feedback, romtype)
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
			sysutil.nx_syslog("sfsystem slog "..slogurl, 1)
			sysutil.nx_syslog("sfsystem klog "..klogurl, 1)
			sysutil.nx_syslog("sfsystem statusurl "..statusurl, 1)
			sysutil.nx_syslog("sfsystem configurl "..configurl, 1)
			info["slogurl"] = slogurl
			info["klogurl"] = klogurl
			info["statusurl"] = statusurl
			info["configurl"] = configurl
			if wifiurl then
				sysutil.nx_syslog("sfsystem wifiurl "..wifiurl, 1)
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
		sysutil.nx_syslog("----------feedback-result="..ret_info, 1)
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
	local code = 0
	local flag_upload_file = ""
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
			slog_url = upload_file("system")
			klog_url = upload_file("kernel")
			status_url = upload_file("status")
			config_url = upload_file("config")
			-- maybe empty
			wifi_url = upload_file("wifi")
			if(not (slog_url and klog_url and status_url and config_url)) then
				flag_upload_file = "false"
				code = sferr.EEROR_NO_UPLOAD_FILE_FAILED
			end
		end

		if(flag_upload_file ~= "false") then
			local object_id = upload_info(user_id, router_id, slog_url, klog_url, status_url, wifi_url, config_url, rom_version, feedback_info, rom_type)
			if (object_id) then
				result["object_id"] = object_id
			else
				code = sferr.EEROR_NO_UPLOAD_INFO_FAILED
			end
		end
	else
		code = sferr.EEROR_NO_WAITING_UPLOAD_LOG
	end

	luci.util.exec("rm /tmp/upload_shortest_time")
	return code, result
end
function sync(arg_list_table)
	--string.format("Downloading %s from %s to %s", file, host, outfile)
	--    local cmd = "SYNC -data "..luci.http.formvalue("enable")
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
	return code, result
end

function download(arg_list_table)
	local info = ''
	local code = 0

	local src_url = arg_list_table["src_url"]
	local dst_url = "/mnt/sda1"..(arg_list_table["dst_url"] or "")
	sysutil.nx_syslog("----------src="..src_url, 1)
	sysutil.nx_syslog("----------dst="..dst_url, 1)
	if(src_url) then
		if(dst_url) then
			info = os.execute("wget -c -P %s %s" %{dst_url, src_url})
		else
			code = sferr.ERROR_DSTURL_LOST
		end
	else
		code = sferr.ERROR_SRCURL_LOST
	end
	return code
end
function update_qos_local()
	--    update_qos()
	code = 0
	return code
end

function new_oray_params()
	local result = {}
	local extraInfo = ""
	local code = 0
	local p2pret = {}
	local ret1 = io.popen("ubus call siwifi_p2p_api.network set_cp2p")
	if ret1 then
		p2pret = ret1:read("*a")
		ret1:close()
	end
	if(p2pret == {}) then
		code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
	else
		local decoder = {}
		local decoder2 = {}
		decoder2 = json.decode(p2pret)
		if decoder2["p2p_data"] then
			decoder = json.decode(decoder2["p2p_data"]);
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
	return code, result
end
function destroy_oray_params(arg_list_table)
	local extraInfo = ""
	local sess = arg_list_table["session"]
	local code = 0
	local p2pret = {}
	local ret1 = io.popen("ubus call siwifi_p2p_api.network set_dp2p \'\{\"p2p_name\":\"%s\"\}\'"% sess)
	if ret1 then
		p2pret = ret1:read("*a")
		ret1:close()
	end
	if(p2pret == {}) then
		code = sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
	else
		local decoder = {}
		local decoder2 = {}
		decoder2 = json.decode(p2pret)
		if decoder2["p2p_data"] then
			decoder = json.decode(decoder2["p2p_data"]);
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
	return code
end
function setdevicerestrict(arg_list_table)
	local mac = arg_list_table["mac"]
	local social = arg_list_table["social"]
	local video = arg_list_table["video"]
	local game = arg_list_table["game"]
	local restrict_enable = arg_list_table["restrictenable"]
	local code = 0
	local op_list = get_list_by_mac(mac)
	local dev = _uci_real:get(op_list, mac, "dev")
	if string.find(dev, "lease") then
		code = sferr.ERROR_NO_OPERATION_NOT_PERMIT
	else
		if social then
			_uci_real:set(op_list , mac, "social", social)
		end
		if video then
			_uci_real:set(op_list , mac, "video", video)
		end
		if game then
			_uci_real:set(op_list , mac, "game", game)
		end
		if restrict_enable then
			_uci_real:set(op_list , mac, "restrictenable", restrict_enable)
		end
		_uci_real:save(op_list )
		_uci_real:commit(op_list )
		luci.util.exec("tscript type_flow %s %s %s %s %s"%{ mac:gsub("_",":"), restrict_enable, game, video, social})
		local ip = networknew.mac_to_ip((mac:gsub("_",":")):lower())
		if ip then
			sysutil.fork_exec("conntrack -D -s %s"%{ip})
			nixio.syslog("crit","clean ip %s conntrack!"%{ip})
		end
	end
	sysutil.sflog("INFO","Device %s flow control configure changed!"%{string.sub(string.gsub(mac,"_",":"),1,string.len(mac))})
	return code
end
function getdevicerestrict(arg_list_table)
	local result = {}
	local mac = arg_list_table["mac"]
	local code = 0
	local op_list = get_list_by_mac(mac)
	result["social"] = tonumber(_uci_real:get(op_list , mac, "social") or 0)
	result["video"] = tonumber(_uci_real:get(op_list , mac, "video") or 0)
	result["game"] = tonumber(_uci_real:get(op_list , mac, "game") or 0)
	result["restrictenable"] = tonumber(_uci_real:get(op_list , mac, "restrictenable") or 0)
	return code, result
end
function routerlivetime(arg_list_table)
	local uci = require "luci.model.uci".cursor()
	local count = 0
	local timelist_json = {}
	local code = 0
	local timelistonoff = arg_list_table["timelist"]
	sysutil.nx_syslog("enable id " .. json.encode(timelistonoff), 1)
	if timelistonoff then
		timelist_json = timelistonoff[1]
		local enable  = timelist_json["enable"]
		if enable then
			_uci_real:set("siwifi",  "hardware", "timelistofoff",json.encode(timelistonoff))
			_uci_real:save("siwifi" )
			_uci_real:commit("siwifi")
		end
		if enable == 1 then
			local start_time = timelist_json["starttime"]
			local stop_time = timelist_json["endtime"]
			local week = timelist_json["week"]
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
	return code
end
function blockrefactory(arg_list_table)
	local uci = require "luci.model.uci".cursor()
	local block = arg_list_table["block"]
	local code = 0
	if block then
		uci:set("siwifi","block",tostring(block))
		uci:save("siwifi")
		uci:commit("siwifi")
	end
	if (block == 1) then
		luci.util.exec("echo 1 > /proc/reset_button_mask")
	else
		luci.util.exec("echo 0 > /proc/reset_button_mask")
	end
	return code
end
function get_routerlivetime()
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	result["timelist"] = json.decode(_uci_real:get("siwifi",  "hardware", "timelistofoff"))
	return code, result

end
function getblockrefactory()
	local uci = require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	result["block"] = tonumber(uci:get("siwifi","block"))
	return code, result
end

function setspeed(arg_list_table)
	local dev_mac = arg_list_table["mac"]
	local dev_enable = arg_list_table["enable"]
	local code = 0

	dev_mac = dev_mac:upper()
	local checkdata = check_ip_mask_mac(nil, nil, dev_mac)
	dev_mac = checkdata.mac
	local op_list = get_list_by_mac(dev_mac)
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
	if dev_enable then
		_uci_real:set(op_list, dev_mac, "speedlimit", dev_enable)
		_uci_real:save(op_list)
		_uci_real:commit(op_list)
	end
	sysutil.sflog("INFO","Device %s speed configure changed!"%{dev_mac})
	return code
end
function urllist_set(arg_list_table)
	local listtype = arg_list_table["listtype"]
	local mac = arg_list_table["mac"]
	local code = 0
	local checkdata = check_ip_mask_mac(nil, nil, mac)
	mac = checkdata.mac
	local op_list = get_list_by_mac(mac)
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
	sysutil.sflog("INFO","Device %s dns block configure changed!"%{mac})
	return code
end
function urllist_get(arg_list_table)
	local result = { }
	local listtype= arg_list_table["listtype"]
	local mac = arg_list_table["mac"]
	local url_list= {}
	local code = 0
	local op_list = get_list_by_mac(mac)
	if listtype == 0 then
		url_list= _uci_real:get_list(op_list , mac, "white_list")
	else
		url_list= _uci_real:get_list(op_list , mac, "black_list")
	end
	if url_list then
		result["urllist"] = url_list
	end
	return code, result
end
function urllist_enable(arg_list_table)
	local listfunc = tostring(arg_list_table["listfunc"])
	local mac = arg_list_table["mac"]
	local code = 0
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
	return code
end

function check_log_md()
	local basic_setting = _uci_real:get_all("basic_setting")
	if basic_setting.mode == nil then
		_uci_real:set("basic_setting", "mode", "setting")
		_uci_real:set("basic_setting", "mode", "mode_code", '0')
		_uci_real:save("basic_setting")
		_uci_real:commit("basic_setting")
	end
end

function getrouterfeature()
	local result = {}
	local code = 0
	local flag = 0

	result = sysutil.get_feature()
    check_log_md()
	if result["leaseWeb"] == 1 then
		local net_name = _uci_real:get("network","lease","ifname")
		_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.network == "lease" then
				flag = 1
			end
		end
		)
		if net_name ~= 'lease' and flag == 0 then
			sysutil.fork_exec("/usr/bin/lease.sh")
			sysutil.fork_exec("sleep 3;/etc/init.d/network restart")
		end
	end
	return code, result
end

function get_ap_groups()
	local result = {}
	local code = 0
	if ap then
		result["ap_group_list"] = ap.get_groups(1)
	else
		code = sferr.ERROR_AC_NOT_SUPPORT
	end
	return code, result
end
function pctl_url_check(arg_list_table)
	local uci =require "luci.model.uci".cursor()
	local result = {}
	local code = 0
	local protocol = arg_list_table["version"]
	if(not protocol) then
		result = sferr.errProtocolNotFound()
	elseif(sysutil.version_check(protocol)) then
		local remote_info = {}
		local xcloud_info_json = ""
		local cloud_code_url = ""
		local serveraddr = sysutil.get_server_addr()
		if(sysutil.getCloudType() == '0')then
			cloud_code_url = "https://"..serveraddr..sysconfig.LOOK_PCTL_URL_VERSION
		else
			cloud_code_url = "https://192.168.1.12:8090/v1"..sysconfig.LOOK_PCTL_URL_VERSION
		end
		local data = {}
		data.sn = uci:get("siwifi", "hardware", "sn")
		data.province =  tonumber(uci:get("tsconfig", "tsrecord", "province"))
		data.updateAt = tonumber(uci:get("tsconfig", "tsrecord", "updateAt"))
		data.dataVersion = tonumber(uci:get("tsconfig", "tsrecord", "dataVersion"))
		data.count = tonumber(uci:get("tsconfig", "tsrecord", "count"))
		local json_data = json.encode(data)
		local token = sysutil.token()
		if (token == "") then
			code = -1
		else
			sysutil.nx_syslog("curl -X POST -k -H \"Content-Type: application/json\" -H \"Authorization:Bearer %s\" -d \'%s\' \"%s\"" %{token, json_data, cloud_code_url}, 1);
			xcloud_info_json = luci.util.exec("curl -X POST -k -H \"Content-Type: application/json\" -H \"Authorization:Bearer %s\" -d \'%s\' \"%s\"" %{token, json_data, cloud_code_url})
			remote_info = json.decode(xcloud_info_json)
			result.content = remote_info
		end
		result["code"] = code
		result["msg"]  = sferr.getErrorMessage(code)
	else
		result = sferr.errProtocolNotSupport()
	end
	return code, result
end

function set_ap_group(arg_list_table)
	local code = 0
	if code  == 0 then
		if ap then
			code = ap.set_ap_group_impl(arg_list_table)
		else
			code = sferr.ERROR_AC_NOT_SUPPORT
		end
	end
	return code
end
function remove_ap_group(arg_list_table)
	local code = 0
	if code  == 0 then
		if ap then
			code = ap.remove_ap_group_impl(arg_list_table)
		else
			code = sferr.ERROR_AC_NOT_SUPPORT
		end
	end
	return code
end
function get_ap_list(arg_list_table)
	local result = {}
	local code = 0
	if ap then
		local groups = ap.get_groups(0)
		if (arg_list_table["index"]) then
			result["ap_list"] = groups[tonumber(arg_list_table["index"])]["devices"]
		else
			code = sferr.ERROR_INPUT_PARAM_ERROR
		end
	else
		code = sferr.ERROR_AC_NOT_SUPPORT
	end
	return code, result
end
function set_ap(arg_list_table)
	local code = 0
	if ap then
		code = ap.set_ap_impl(arg_list_table)
	else
		code = sferr.ERROR_AC_NOT_SUPPORT
	end
	return code
end
function delete_ap(arg_list_table)
	local code = 0
	if ap then
		code = ap.delete_ap_impl(arg_list_table)
	else
		code = sferr.ERROR_AC_NOT_SUPPORT
	end
	return code
end

function func_adapter(arg_list_table)
	local result = {}
	local result_list = {}
	local i = 0
	local func_list = arg_list_table.func_list
	for k,v  in pairs(func_list) do
		local code_tmp = 0
		local result_tmp = {}
		local func = getfenv()[k]
		code_tmp, result_tmp = func(v)
		result_list[k] = {}
		result_list[k] = get_result(code_tmp, result_tmp)
	end
	result.result_list={}
	result.result_list = result_list
	return code, result
end

function get_result(code, result)
	local result_here = {}
	if result then
		result_here = result
	end
	result_here["code"] = code
	result_here["msg"] = sferr.getErrorMessage(code)
	return result_here
end

function set_samba(arg_list_table)
	local code = 0
	local result = {}
    local samba_md = arg_list_table["samba_md"]
    code,result = get_samba()
    if samba_md == 1 then
        if result.pid then
            luci.util.exec("/etc/init.d/samba restart")
        else
            luci.util.exec("/etc/init.d/samba start")
        end
    else
        if result.pid then
            luci.util.exec("/etc/init.d/samba stop")
        end
    end
	return code
end

function get_samba()
    local result = {
        pid = {}
    }
	local code = 0
	local ret = io.popen("ps |grep \[s]mbd |awk '{print $1}'")
	if ret then
		result.pid = ret:read("*l")
		ret:close()
	end
	return code, result
end
