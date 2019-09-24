--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/7
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.networknew", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require "luci.json"
local fs  = require "nixio.fs"
local sysutil = require("luci.siwifi.sf_sysutil")
local networkImpl = require("luci.siwifi.networkImpl")
ipc = require "luci.ip"
systemnew = require "luci.controller.admin.systemnew"
local sferr = require "luci.siwifi.sf_error"

function index()
	local uci = require("luci.model.uci").cursor()
	local wds_enable = false
	uci:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "sfi0" or s["ifname"] == "sfi1"
				or s["ifname"] == "rai0" or s["ifname"] == "rai1") then
				wds_enable = true
			end
		end)
	if (wds_enable == false) then
		entry({"admin", "networknew"}, firstchild(), _("Parameters"), 60).logo="network";
		entry({"admin", "networknew", "wan"}, template("new_siwifi/network_params/wan") , _("WAN setting"), 1);
		entry({"admin", "networknew", "lan"}, template("new_siwifi/network_params/lan") , _("LAN setting"), 2);
		entry({"admin", "networknew", "mac"}, template("new_siwifi/network_params/mac") , _("MAC address"), 3);
		entry({"admin", "networknew", "dhcp"}, template("new_siwifi/network_params/dhcp") , _("DHCP server"), 4);
		entry({"admin", "networknew", "ip_mac"}, template("new_siwifi/network_params/ip_mac") , _("IP and MAC bound"), 5);
	else
		entry({"admin", "networknew"}, firstchild());
		entry({"admin", "networknew", "wan"}, call("goto_default_page"));
		entry({"admin", "networknew", "lan"}, call("goto_default_page"));
		entry({"admin", "networknew", "mac"}, call("goto_default_page"));
		entry({"admin", "networknew", "dhcp"}, call("goto_default_page"));
		entry({"admin", "networknew", "ip_mac"}, call("goto_default_page"));
	end
    entry({"admin", "networknew", "get_wan"}, call("get_wan")).leaf = true;
    entry({"admin", "networknew", "set_wan"}, call("set_wan")).leaf = true;
    entry({"admin", "networknew", "set_pppoe_advanced"}, call("set_pppoe_advanced")).leaf = true;
    entry({"admin", "networknew", "set_pppoe_connection_mode"}, call("set_pppoe_connection_mode")).leaf = true;
    entry({"admin", "networknew", "get_lan"}, call("get_lan")).leaf = true;
    entry({"admin", "networknew", "set_lan"}, call("set_lan")).leaf = true;
    entry({"admin", "networknew", "get_mac"}, call("get_mac")).leaf = true;
    entry({"admin", "networknew", "set_mac"}, call("set_mac")).leaf = true;
    entry({"admin", "networknew", "get_dhcp"}, call("get_dhcp")).leaf = true;
    entry({"admin", "networknew", "set_dhcp"}, call("set_dhcp")).leaf = true;
    entry({"admin", "networknew", "get_dhcp_devices"}, call("get_dhcp_devices")).leaf = true;
    entry({"admin", "networknew", "get_ip_mac_online_table"}, call("get_ip_mac_online_table")).leaf = true;
    entry({"admin", "networknew", "get_ip_mac_bind_table"}, call("get_ip_mac_bind_table")).leaf = true;
    entry({"admin", "networknew", "set_ip_mac_bind_table"}, call("set_ip_mac_bind_table")).leaf = true;
	entry({"admin", "networknew", "disable_guide"}, call("disable_guide")).leaf = true;
	entry({"admin", "networknew", "sync_pppoe_info"}, call("sync_pppoe_info")).leaf = true;
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

function goto_default_page()
	luci.http.redirect(luci.dispatcher.build_url())
end

function ip_to_mac(ip)
	local mac = nil
	ipc.neighbors({ family = 4 }, function(n)
		if n.mac and n.dest and n.dest:equal(ip) then
			mac = n.mac
		end
	end)
	return mac
end

function mac_to_ip(mac)
	local ipaddr = nil
	ipc.neighbors({ family = 4 }, function(n)
		if n.mac == mac and n.dest then
			ipaddr = n.dest:string()
		end
	end)
	return ipaddr
end

function int_to_ip(n)
	if n then
		n = tonumber(n)
		local n1 = math.floor(n / (2^24))
		local n2 = math.floor((n - n1*(2^24)) / (2^16))
		local n3 = math.floor((n - n1*(2^24) - n2*(2^16)) / (2^8))
		local n4 = math.floor((n - n1*(2^24) - n2*(2^16) - n3*(2^8)))
		return n1.."."..n2.."."..n3.."."..n4
	end
	return "0.0.0.0"
end

function ip_to_int(ip)
	local num = 0
	if ip and type(ip) == "string" then
		local o1,o2,o3,o4 = ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)" )
		num = 2^24*o1 + 2^16*o2 + 2^8*o3 + o4
	end
	return num
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

function check_ip_legality(check_ip, ifc_ip, netmask)
	local ip = StringSplit(ifc_ip, '%.')
	local mask = StringSplit(netmask, '%.')

	local bottom_ip ={}
	for k, v in pairs( ip ) do
		if mask[k] == "255" then
			bottom_ip[k] = tonumber(v)
		elseif mask[k] == "0" then
			bottom_ip[k] = 0
		else
			local mod = tonumber(v) % (( 255 -  tonumber(mask[k]) ) + 1 )
			bottom_ip[k] = tonumber(v) - mod
		end
	end
	sysutil.nx_syslog("bottom ip is "..myprint(bottom_ip), 1)

	local top_ip = {}
	for k, v in pairs( bottom_ip  ) do
		top_ip[k] = v + (255 - tonumber(mask[k]))
	end
	sysutil.nx_syslog("top ip is "..myprint(top_ip), 1)

	local check_ip_val = ip_to_int(check_ip)
	local bottom_ip_val = bottom_ip[1]*2^24 + bottom_ip[2]*2^16 + bottom_ip[3]*2^8 + bottom_ip[4]
	local top_ip_val = top_ip[1]*2^24 + top_ip[2]*2^16 + top_ip[3]*2^8 + top_ip[4]
	if (check_ip_val < top_ip_val and check_ip_val > bottom_ip_val) then
		return true
	else
		return false
	end
end

function check_lan_area(check_ip )
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")

	local lan_ip = net:ipaddr() --string IP地址
	local netmask = net:netmask() --string 子网掩码
	if not lan_ip or not netmask then
		return false
	end

	return check_ip_legality(check_ip, lan_ip, netmask)
end

function check_wan_area(check_ip )
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("wan")

	local wan_ip = net:ipaddr() --string IP地址
	local netmask = net:netmask() --string 子网掩码
	if not wan_ip or not netmask then
		return false
	end

	return check_ip_legality(check_ip, wan_ip, netmask)
end

function check_guest_area(check_ip )
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("guest")
	if not net then
		return false
	end

	local guest_ip = net:ipaddr() --string IP地址
	local netmask = net:netmask() --string 子网掩码
	if not guest_ip or not netmask then
		return false
	end

	return check_ip_legality(check_ip, guest_ip, netmask)
end

function calc_lan_dhcp(check_ip_start, check_ip_end )
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")

	local lan_ip = net:ipaddr() --string IP地址
	local netmask = net:netmask() --string 子网掩码

	local s_ip1, s_ip2, s_ip3, s_ip4 = check_ip_start:match('(%d+)%.(%d+).(%d+)%.(%d+)')
	local e_ip1, e_ip2, e_ip3, e_ip4 = check_ip_end:match('(%d+)%.(%d+).(%d+)%.(%d+)')

	local lan_ip1, lan_ip2, lan_ip3, lan_ip4 = lan_ip:match('(%d+)%.(%d+)%.(%d+)%.(%d+)')
	local nm_ip1, nm_ip2, nm_ip3, nm_ip4 = netmask:match('(%d+)%.(%d+)%.(%d+)%.(%d+)')
	local start_ip_int= { tonumber( s_ip1  ), tonumber( s_ip2  ), tonumber( s_ip3  ), tonumber( s_ip4  )}
	local end_ip_int= { tonumber( e_ip1  ), tonumber( e_ip2  ), tonumber( e_ip3  ), tonumber( e_ip4  )}
	local lan_ip_int= { tonumber( lan_ip1  ), tonumber( lan_ip2  ), tonumber( lan_ip3  ), tonumber( lan_ip4  )}
	local nm_ip_int= { tonumber( nm_ip1  ), tonumber( nm_ip2  ), tonumber( nm_ip3  ), tonumber( nm_ip4  )}

	sysutil.nx_syslog("check start ip is "..myprint(start_ip_int), 1)
	sysutil.nx_syslog("check end ip is "..myprint(end_ip_int), 1)
	sysutil.nx_syslog("lan ip is "..myprint(lan_ip_int), 1)
	sysutil.nx_syslog("netmask ip is "..myprint(nm_ip_int), 1)

	local bottom_ip ={}
	for k, v in pairs( lan_ip_int) do
		if nm_ip_int[k] == 255 then
			bottom_ip[k] = v
		elseif nm_ip_int[k] ==  0 then
			bottom_ip[k] = 0
		else
			local mod = v % (( 255 -  nm_ip_int[k] ) + 1 )
			bottom_ip[k] = v - mod
		end
	end

	sysutil.nx_syslog("bottom ip is "..myprint(bottom_ip), 1)
	local top_ip = {}
	for k, v in pairs( bottom_ip  ) do
		top_ip[k] = v + (255 - nm_ip_int[k])
	end

	sysutil.nx_syslog("top ip is "..myprint(top_ip), 1)

	local check_ip_val_start= start_ip_int[1]*2^24 + start_ip_int[2]*2^16 +start_ip_int[3]*2^8 +start_ip_int[4]
	local check_ip_val_end= end_ip_int[1]*2^24 + end_ip_int[2]*2^16 +end_ip_int[3]*2^8 +end_ip_int[4]
	local bottom_ip_val= bottom_ip[1]*2^24 + bottom_ip[2]*2^16 +bottom_ip[3]*2^8 +bottom_ip[4]
	local top_ip_val= top_ip[1]*2^24 + top_ip[2]*2^16 +top_ip[3]*2^8 +top_ip[4]
	if (check_ip_val_start < top_ip_val and check_ip_val_start > bottom_ip_val and check_ip_val_end < top_ip_val and check_ip_val_end > bottom_ip_val) then
		if check_ip_val_start > check_ip_val_end then
			return false
		end
		start = check_ip_val_start - bottom_ip_val
		range = check_ip_val_end - check_ip_val_start
		sysutil.nx_syslog("start value is "..myprint(start).." range value is "..myprint(range), 1)
		return start, range
	else
		return false
	end
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

function BindJudge(mac, ip, flag)
	--[[
	-- read all in path
	local file = io.open(path, "r")
	local data = file:read("*a")
	file:close()
	-]]
	for line in io.lines("/etc/ethers") do
		if flag == 1 then
			if line ==  mac.." "..ip then
				return true
			end
		else
			if string.find(line, mac.." "..ip) ~= nil then
				return true
			end
		end
	end
	return false
end

function get_wan()
	local ntm = require "luci.model.network".init()
	local wan = ntm:get_wannet()
	--local device = wan and wan:get_interface()
	--local s = require "luci.tools.status".switch_status(device)
	local prto = {}
	local ipaddr = {}
	local netmask = {}
	local gateway = {}
	local linkstatus = {}
	local dns = {}
	local result = {}
	local code = 0

	if wan then
		proto = wan:proto()
		ipaddr = wan:ipaddr()
		netmask = wan:netmask()
		gateway = wan:gwaddr()
		dns = wan:dnsaddrs()
	else
		proto = _uci_real:get("network","wan","proto")
		ipaddr = _uci_real:get("network","wan","ipaddr")
		netmask = _uci_real:get("network","wan","netmask")
		gateway = _uci_real:get("network","wan","gateway")
		local _dns = _uci_real:get("network","wan","dns")
		if (_dns) then
			local pos = string.find(_dns, " ");
			if (pos) then
				dns[1] = string.sub(_dns, 1, pos-1)
				dns[2] = string.sub(_dns, pos+1, #_dns)
			else
				dns[1] = _dns
				dns[2] = ""
			end
		end
	end

	local wan_ifc = _uci_real:get("network","wan","ifname")
	if wan_ifc == "eth1" then
		local t = io.popen("cat /sys/class/net/eth1/carrier |tr -d '\n'")
		linkstatus = t:read("*all")
		t:close()
	else
		local t = io.popen("cat /sys/kernel/debug/npu_debug |grep phy4 |awk '{print $3}' |tr -d '\n'")
		linkstatus = t:read("*all")
		t:close()
	end

	if (proto == "dhcp") then
		result = {
			code = 0,
			msg = "OK",
			wantype = 1,--1:DHCP， 2：静态IP  4：PPPoE
			wantypesupported = 7,
			DHCP = {
				ipaddr = ipaddr,--string IP地址
				netmask = netmask,--string 子网掩码
				gateway = gateway,--string 网关
				linkstatus = linkstatus, --0/1 连接状态
				manualdns = _uci_real:get("network","wan","peerdns") == '0' and true or false, --boolean 是否手动设置dns
				dns = dns[1],--string DNS服务器
				dnsbak = dns[2],--string 备用DNS服务器
				hostname = luci.sys.hostname(),--string 主机名
				unicast =  _uci_real:get("network","wan","unicast") == '1' and true or false, --boolean 是否为单播方式
				packageMTU = _uci_real:get("network","wan","mtu") or 1500, --int 数据包MTU(字节)
				wanspeed = _uci_real:get("network","wan","speed") or "auto"--string wan口速率设置
			}
		}
	elseif (proto == "static") then
		result = {
			code = 0,
			msg = "OK",
			wantype = 2,
			wantypesupported = 7,
			staticip = {
				ipaddr = ipaddr,--string IP地址
				netmask = netmask,--string 子网掩码
				gateway = gateway,--string 网关
				linkstatus = linkstatus, --0/1 连接状态
				dns = dns[1],
				dnsbak = dns[2],
				packageMTU = _uci_real:get("network","wan","mtu") or 1500, --int 数据包MTU(字节)
				wanspeed = _uci_real:get("network","wan","speed") or "auto" --string wan口速率设置
			},
		}
	elseif (proto == "pppoe") then
		operatoraddress = _uci_real:get("network","wan","pppd_options")
		if operatoraddress then
			operatoraddress = operatoraddress:match("^%d+%.%d+%.%d+%.%d+")  --string 运营商指定的IP地址
		end
		result = {
			code = 0,
			msg = "OK",
			wantype = 4,
			wantypesupported = 7,
			PPPoE = {
				account = _uci_real:get("network","wan","username"),--string 宽带账号
				password = _uci_real:get("network","wan","password"), --string 宽带密码
				mode = "pppoe", --string 拨号模式
				wanspeed = _uci_real:get("network","wan","speed") or "auto", --string wan口速率设置,auto:自动,10mfull:10M全双工,10mhalf:10M半双工
				connect = _uci_real:get("network","wan", "connect") or 0, --pppoe connect status, 1 for connect 0 for disconnect
				linkstatus = linkstatus, --0/1 连接状态
				connectmode = _uci_real:get("network","wan", "connectmode") or 1, --string 连接模式 0 for wakeup, 1 for auto, 2 for manual
				disconnectinterval = _uci_real:get("network","wan","demand") or 0, --int 自动断线等待时间
				packageMTU = _uci_real:get("network","wan","mtu") or 1480, --int 数据包MTU(字节)
				servicename = _uci_real:get("network","wan","service"), --sring 服务器名
				servername = _uci_real:get("network","wan","ac"), --string 服务器名
				useoperatoraddress = _uci_real:get("network","wan","fixipEnb") == '1' and true or false, --string 使用运营商制定的ip地址
				operatoraddress = operatoraddress,
				manualdns = _uci_real:get("network","wan","peerdns") == '0' and true or false, --boolean 是否手动设置dns
				dns = dns[1], --string DNS服务器
				dnsbak = dns[2] --string 备用DNS服务器
			}
		}
	else
		code = sferr.ERROR_NO_PROTOCOL_NOT_FOUND
	end
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_wan_dhcp(arg_list_table,result, releaseip)
	_uci_real:set("network","wan","proto","dhcp")
	local hostname = arg_list_table["hostname"]
	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]
	if hostname then
		hostname = string.sub(hostname,1,31)
		luci.sys.hostname(hostname)
		_uci_real:foreach("system","system",
		function(s)
			if(s[".name"]) then
				_uci_real:set("system",s[".name"],"hostname", hostname)
			end
		end)
		_uci_real:commit("system")
	end

	local wan_ifc = _uci_real:get("network","wan","ifname")
	local old_mtu = _uci_real:get("network","wan","mtu")
	local mtu = arg_list_table["packageMTU"]
	if mtu and mtu ~= old_mtu then
		if tonumber(mtu) < 46 or tonumber(mtu) > 9000 then
			result["code"] = sferr.ERROR_NO_INVALID_MTU
			result["msg"]  = sferr.getErrorMessage(result["code"])
			return result
		end

		if tonumber(mtu) > 1500 and wan_ifc == "eth0.2" then
			luci.util.exec("ifconfig eth0 mtu "..mtu)
		end
		_uci_real:set("network","wan","mtu",mtu)
	end

	local unicast = arg_list_table["unicast"]
	if unicast then
		unicast =  _uci_real:set("network","wan","unicast", 1)
	else
		unicast =  _uci_real:set("network","wan","unicast", 0)
	end

	local wan_ifc = _uci_real:get("network","wan","ifname")
	local updateip = arg_list_table["updateip"]
	if updateip then
		if wan_ifc == "eth1" then
			luci.util.exec("kill -SIGUSR1 `cat /var/run/udhcpc-eth1.pid`")
		else
			luci.util.exec("kill -SIGUSR1 `cat /var/run/udhcpc-eth0.2.pid`")
		end
	end
	if releaseip then
		if wan_ifc == "eth1" then
			luci.util.exec("kill -SIGUSR2 `cat /var/run/udhcpc-eth1.pid`")
		else
			luci.util.exec("kill -SIGUSR2 `cat /var/run/udhcpc-eth0.2.pid`")
		end
	end

	local manualdns = arg_list_table["manualdns"]
	if manualdns then
		if dns1 ~= "" and check_lan_area(dns1) or dns2 ~= "" and check_lan_area(dns2) then--check dns是否与LAN口冲突
			result["code"] = sferr.ERROR_NO_DNS_CONFLICT_WITH_LAN_SEGMENT
			result["msg"]  = sferr.getErrorMessage(result["code"])
			return result
		end
		if dns1 ~= "" or dns2 ~= "" then
			_uci_real:set("network","wan","dns",dns1..dns2)
			_uci_real:set("network","wan","peerdns",0)
		end
		if dns1 ~= "" and dns2 ~= "" then
			local dns = dns1.." "..dns2
			_uci_real:set("network","wan","dns",dns)
		end
	else
		_uci_real:delete("network","wan","dns")
		_uci_real:set("network","wan","peerdns",1)
	end
	return result
end

function set_wan_static(arg_list_table,result)
	_uci_real:set("network","wan","proto","static")
	local address = arg_list_table["ipaddr"]
	local mask = arg_list_table["netmask"]
	local gateway = arg_list_table["gateway"]
	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]

	if check_lan_area(address) then--check WAN口是否与LAN口冲突
		result["code"] = sferr.ERROR_NO_WAN_CONFLICT_WITH_LAN_SEGMENT
		result["msg"]  = sferr.getErrorMessage(result["code"])
		return result
	end
	if dns1 ~= "" and check_lan_area(dns1) or dns2 ~= "" and check_lan_area(dns2) then--check dns是否与LAN口冲突
		result["code"] = sferr.ERROR_NO_DNS_CONFLICT_WITH_LAN_SEGMENT
		result["msg"]  = sferr.getErrorMessage(result["code"])
		return result
	end
	if not check_ip_legality(address, gateway, mask) then--check WAN是否与gateway在同一网段
		result["code"] = sferr.ERROR_NO_GATEWAY_NOT_IN_WAN_SEGMENT
		result["msg"]  = sferr.getErrorMessage(result["code"])
		return result
	end
	if address then
		_uci_real:set("network","wan","ipaddr",address)
	end
	if mask then
		_uci_real:set("network","wan","netmask",mask)
	end
	if gateway then
		_uci_real:set("network","wan","gateway",gateway)
	end

	local wan_ifc = _uci_real:get("network","wan","ifname")
	local old_mtu = _uci_real:get("network","wan","mtu")
	local mtu = arg_list_table["packageMTU"]
	if mtu and mtu ~= old_mtu then
		if tonumber(mtu) < 46 or tonumber(mtu) > 9000 then
			result["code"] = sferr.ERROR_NO_INVALID_MTU
			result["msg"]  = sferr.getErrorMessage(result["code"])
			return result
		end

		if tonumber(mtu) > 1500 and wan_ifc == "eth0.2" then
			luci.util.exec("ifconfig eth0 mtu "..mtu)
		end
		_uci_real:set("network","wan","mtu",mtu)
	end

	if dns1 ~= "" or dns2 ~= "" then
		_uci_real:set("network","wan","dns",dns1..dns2)
	end
	if dns1 ~= "" and dns2 ~= "" then
		local dns = dns1.." "..dns2
		_uci_real:set("network","wan","dns",dns)
	end
	return result
end

function set_wan_ppoe(arg_list_table, connect)
	_uci_real:set("network","wan","proto","pppoe")
	_uci_real:set("network","wan","ipv6", 0)
	local pppname = arg_list_table["account"]
	if(pppname) then
		_uci_real:set("network", "wan", "username", pppname)
	end

	local ppppwd  = arg_list_table["password"]
	if(ppppwd) then
		_uci_real:set("network", "wan", "password", ppppwd)
	end

	auto = _uci_real:get("network","wan","auto")
	if connect == 0 and auto == '1' then
		-- cause set connect 0 will down wan, but reboot will cause it has no effect
		-- so we set auto to 0 for gurantee
		_uci_real:set("network","wan","auto", 0)
	else
		_uci_real:set("network","wan","auto", 1)
	end
end

function set_wan(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local wantype = arg_list_table["wantype"]
	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]
	local timer = 0
	local timeout = 15
	local connect
	local releaseip
	local code = 0
	local result = {
		code = 0,
		msg = "OK"
	}

	local proto = _uci_real:get("network","wan","proto")
	if(proto == "pppoe" and wantype ~= 4) then
		_uci_real:delete("network","wan","username")
		_uci_real:delete("network","wan","password")
		_uci_real:delete("network","wan","service")
		_uci_real:delete("network","wan","ac")
		_uci_real:delete("network","wan","demand")
		_uci_real:delete("network","wan","fixipEnb")
		_uci_real:delete("network","wan","pppd_options")
		_uci_real:delete("network","wan","mtu")
		_uci_real:delete("network","wan","connect")
		_uci_real:delete("network","wan","connectmode")
		_uci_real:delete("network","wan","auto")
		_uci_real:delete("network","wan","ipv6")
	elseif(proto == "static" and wantype ~= 2) then
		_uci_real:delete("network","wan","ipaddr")
		_uci_real:delete("network","wan","netmask")
		_uci_real:delete("network","wan","gateway")
	elseif(proto == "dhcp" and wantype ~= 1) then
		_uci_real:delete("network","wan","unicast")
	end

	_uci_real:delete("network","wan","error")
	_uci_real:delete("network","wan","dns")
	_uci_real:delete("network","wan","peerdns")
	while true
	do
		if wantype == 1 then
			releaseip = arg_list_table["releaseip"]
			result = set_wan_dhcp(arg_list_table,result, releaseip)
			if (result["code"] ~= 0) then
				break
			end
		elseif wantype == 2 then
			result = set_wan_static(arg_list_table,result)
			if (result["code"] ~= 0) then
				break
			end
		elseif wantype == 4 then
			connect  = arg_list_table["connect"]
			set_wan_ppoe(arg_list_table, connect)
		else
			luci.http.status(404, "Protocal unknown")
		end

		local wan_ifc = _uci_real:get("network","wan","ifname")
		if wan_ifc == "eth1" then
			local t = io.popen("cat /sys/class/net/eth1/carrier |tr -d '\n'")
			linkstatus = t:read("*all")
			t:close()
		else
			local t = io.popen("cat /sys/kernel/debug/npu_debug |grep phy4 |awk '{print $3}' |tr -d '\n'")
			linkstatus = t:read("*all")
			t:close()
		end

		local speed = arg_list_table["wanspeed"]
		local speed_cur = _uci_real:get("network","wan","speed") or "auto"
		if speed ~= speed_cur then
			if speed == "auto" then
				_uci_real:set("network","wan","speed",speed)
			elseif speed == "10mfull" then
				_uci_real:set("network","wan","speed",speed)
			elseif speed == "10mhalf" then
				_uci_real:set("network","wan","speed",speed)
			end
		end

		if(result["code"] == 0) then
			_uci_real:save("network")
			_uci_real:commit("network")
			_uci_real:load("network")
			luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
		end

		if linkstatus == "1" then
			if wantype == 1 and not releaseip then
				ifname = _uci_real:get("network","wan","ifname")
				while true
				do
					local t = io.popen("ifconfig "..ifname.." |grep inet |cut -d : -f2 |cut -d ' ' -f1| tr -d '\n'")
					dhcp_ip = t:read("*all")
					t:close()
					if #dhcp_ip ~= 0 or timer >= timeout then
						break
					else
						timer = timer + 1
						os.execute("sleep "..1)
					end
				end

				if timer >= timeout then
					result["code"] = sferr.ERROR_NO_GET_DHCP_IP_TIMEOUT
					break
				end
			elseif wantype == 4 and connect == 1 then
				luci.sys.call("env -i /bin/ubus call network.interface.wan up >/dev/null 2>/dev/null")
				fixip = _uci_real:get("network","wan","fixipEnb")
				if fixip == '1' then
					timeout = 25
				end

				while true
				do
					-- cause we set connect with uci in ppp-up so we must reload config file to check changes
					_uci_real:load("network")
					pppoe_status = _uci_real:get("network","wan","connect")
					pppoe_error = _uci_real:get("network","wan","error")
					if pppoe_error or pppoe_status == '1' or timer >= timeout then
						break
					else
						timer = timer + 3
						os.execute("sleep "..3)
					end
				end

				if timer >= timeout then
					result["code"] = sferr.ERROR_NO_PPPOE_CONNECT_TIMEOUT
					break
				elseif pppoe_error then
					result["code"] = sferr.ERROR_NO_PPPOE_AUTH_ERROR
					break
				end
			elseif wantype == 4 and connect == 0 then
				luci.sys.call("env -i /bin/ubus call network.interface.wan down >/dev/null 2>/dev/null")
				connectmode = _uci_real:get("network","wan","connectmode", connectmode)
				if connectmode ~= '2' then
					luci.sys.call("env -i /bin/ubus call network.interface.wan up >/dev/null 2>/dev/null")
				end
			end
		else
			result["code"] = sferr.ERROR_NO_WAN_OUT_OF_LINK
		end
		break
	end
	result["msg"]  = sferr.getErrorMessage(result["code"])
	sysutil.nx_syslog(myprint(result), 1)
	sysutil.sflog("INFO","wan configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_pppoe_connection_mode()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local result = {
		code = 0,
		msg = "OK"
	}

	local disconnectinterval = arg_list_table["disconnectinterval"]
	local connectmode = arg_list_table["connectmode"]

	if connectmode then
		_uci_real:set("network","wan","connectmode", connectmode)
	end
	if(connectmode == 0) then
		_uci_real:set("network","wan","auto", 1)
		if(disconnectinterval) then
			_uci_real:set("network","wan","demand",disconnectinterval)
		end
	elseif (connectmode == 1) then
		_uci_real:set("network","wan","auto", 1)
		_uci_real:delete("network","wan","demand")
	elseif (connectmode == 2) then
		_uci_real:set("network","wan","auto", 0)
	end

	if(result["code"] == 0) then
		_uci_real:save("network")
		_uci_real:commit("network")
		_uci_real:load("network")
		sysutil.fork_exec("sleep 1; env -i; ubus call network reload;")
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_pppoe_advanced()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]
	local result = {
		code = 0,
		msg = "OK"
	}

	local servicename = arg_list_table["servicename"]
	if(servicename) then
		_uci_real:set("network","wan","service",servicename)
	end
	local servername = arg_list_table["servername"]
	if(servername) then
		_uci_real:set("network","wan","ac",servername)
	end

	local useoperatoraddress = arg_list_table["useoperatoraddress"]
	if(useoperatoraddress) then
		_uci_real:set("network","wan","fixipEnb",1)
		local operatoraddress = arg_list_table["operatoraddress"]
		if(operatoraddress ~= "") then
			_uci_real:set("network","wan","pppd_options",operatoraddress..":")
		end
	else
		_uci_real:set("network","wan","fixipEnb",0)
		_uci_real:delete("network","wan","pppd_options")
	end

	local manualdns = arg_list_table["manualdns"]
	if manualdns then
		if dns1 ~= "" and check_lan_area(dns1) or dns2 ~= "" and check_lan_area(dns2) then--check dns是否与LAN口冲突
			result["code"] = sferr.ERROR_NO_DNS_CONFLICT_WITH_LAN_SEGMENT
			result["msg"]  = sferr.getErrorMessage(result["code"])
		else
			if dns1 ~= "" or dns2 ~= "" then
				_uci_real:set("network","wan","dns",dns1..dns2)
				_uci_real:set("network","wan","peerdns",0)
			end
			if dns1 ~= "" and dns2 ~= "" then
				local dns = dns1.." "..dns2
				_uci_real:set("network","wan","dns",dns)
			end
		end
	else
		_uci_real:delete("network","wan","dns")
		_uci_real:set("network","wan","peerdns",1)
	end

	local wan_ifc = _uci_real:get("network","wan","ifname")
	local old_mtu = _uci_real:get("network","wan","mtu")
	local mtu = arg_list_table["packageMTU"]
	if mtu and mtu ~= old_mtu then
		if tonumber(mtu) < 46 or tonumber(mtu) > 8992 then
			result["code"] = sferr.ERROR_NO_INVALID_MTU
			result["msg"]  = sferr.getErrorMessage(result["code"])
		else
			if tonumber(mtu) > 1500 and wan_ifc == "eth0.2" then
				sysutil.fork_exec("sleep 1; ifconfig eth0 mtu "..mtu)
			end
			_uci_real:set("network","wan","mtu",mtu)
		end
	end

	if(result["code"] == 0) then
		sysutil.nx_syslog("apply changes", nil)
		_uci_real:save("network")
		_uci_real:commit("network")
		sysutil.fork_exec("sleep 2; env -i; ubus call network reload")
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_lan()
	local result = {}
    local code = 0
    code,result = networkImpl.get_lan_type()
	sysutil.nx_syslog(myprint(result), 1)
    sysutil.set_easy_return(code, result)
end

function set_lan(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
    local code = 0
	sysutil.nx_syslog(myprint(arg_list_table), 1)
    code = networkImpl.set_lan_type(arg_list_table)
	sysutil.sflog("INFO","lan configure changed!")
    sysutil.set_easy_return(code, nil)
end


function get_mac()
	local ntm = require "luci.model.network".init()
	local ip = require "luci.ip"
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
	local wanmac = string.lower(string.sub(device:mac(),1,15))..string.format("%02x",(tonumber("0x"..string.sub(device:mac(),16,17)) + 1))

	local result = {
		code = 0,
		msg = "OK",
		mode = _uci_real:get("network","wan","mode") or 0, --int 模式 0：使用路由器mac地址， 使用当前管理pc的mac地址，使用自定义的mac地址
		routermac = wanmac, --string 路由器的mac地址
		devicemac = ip_to_mac(luci.http.getenv("REMOTE_ADDR")) or "", --string 当前管理pc的mac地址
		custommac = _uci_real:get("network","wan","macaddr") or "" --string 自定义的mac地址
	}

	sysutil.nx_syslog(myprint(result), 1)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_mac(params)
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local custommac = arg_list_table["custommac"]
	local mode = arg_list_table["mode"]

	--if mac and mac:match("^([A-Fa-f0-9]{2}[-,:]){5}[A-Fa-f0-9]{2}$") then
	if mode == 0 then
		_uci_real:set("network","wan","mode",mode)
		local wanmac = string.sub(device:mac(),1,15)..string.format("%02x",(tonumber("0x"..string.sub(device:mac(),16,17)) + 1))
		if wanmac then
			_uci_real:set("network","wan","macaddr",wanmac)
		end
	elseif mode == 1 then
		_uci_real:set("network","wan","mode",mode)
		local devicemac = ip_to_mac(luci.http.getenv("REMOTE_ADDR"))
		if devicemac then
			_uci_real:set("network","wan","macaddr",devicemac)
		end
	elseif mode == 2 then
		_uci_real:set("network","wan","mode",mode)
		if custommac then
			_uci_real:set("network","wan","macaddr",custommac)
		end
	end

	local changes = _uci_real:changes("network")
	if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) then
		_uci_real:save("network")
		_uci_real:commit("network")
		_uci_real:load("network")
		sysutil.fork_exec("sleep 1; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
	end

    local result = {
        code = 0,
        msg = "OK"
    }

    sysutil.nx_syslog(myprint(result), 1)
	sysutil.sflog("INFO","mac configure changed! mode is %d"%{mode})
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_dhcp()
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
	local gateway
	local dns1, dns2

	local lan_ip = net:ipaddr() --string IP地址
	local netmask = net:netmask() --string 子网掩码
	local lan_ip1, lan_ip2, lan_ip3, lan_ip4 = lan_ip:match('(%d+)%.(%d+)%.(%d+)%.(%d+)')
	local nm_ip1, nm_ip2, nm_ip3, nm_ip4 = netmask:match('(%d+)%.(%d+)%.(%d+)%.(%d+)')
	local lan_ip_int= { tonumber( lan_ip1  ), tonumber( lan_ip2  ), tonumber( lan_ip3  ), tonumber( lan_ip4  )}
	local nm_ip_int= { tonumber( nm_ip1  ), tonumber( nm_ip2  ), tonumber( nm_ip3  ), tonumber( nm_ip4  )}

	local bottom_ip ={}
	for k, v in pairs( lan_ip_int) do
		if nm_ip_int[k] == 255 then
			bottom_ip[k] = v
		elseif nm_ip_int[k] ==  0 then
			bottom_ip[k] = 0
		else
			local mod = v % (( 255 -  nm_ip_int[k] ) + 1 )
			bottom_ip[k] = v - mod
		end
	end
	local bottom_ip_val = bottom_ip[1]*2^24 + bottom_ip[2]*2^16 +bottom_ip[3]*2^8 +bottom_ip[4]
	local start = tonumber(_uci_real:get("dhcp","lan","start"))
	local limit = tonumber(_uci_real:get("dhcp","lan","limit"))
	local dhcp_start_value = bottom_ip_val + start
	local dhcp_end_value = dhcp_start_value + limit

	local dhcp_start = int_to_ip(dhcp_start_value)
	local dhcp_end = int_to_ip(dhcp_end_value)

	local dhcp_ops = _uci_real:get_list("dhcp","lan","dhcp_option")
	if dhcp_ops[1] then
		if string.sub(dhcp_ops[1],1,2) == "3," then
			gateway = string.sub(dhcp_ops[1], 3)
			if dhcp_ops[2] then
				dns = string.sub(dhcp_ops[2], 3)
				pos = string.find(dns, ",", 1)
				if pos then
					dns1 = string.sub(dns, 1, pos-1)
					dns2 = string.sub(dns, pos+1)
				else
					dns1 = dns
				end
			end
		elseif string.sub(dhcp_ops[1],1,2) == "6," then
			dns = string.sub(dhcp_ops[1], 3)
			pos = string.find(dns, ",", 1)
			if pos then
				dns1 = string.sub(dns, 1, pos-1)
				dns2 = string.sub(dns, pos+1)
			else
				dns1 = dns
			end
			if dhcp_ops[2] then
				gateway = string.sub(dhcp_ops[2], 3)
			end
		end
	end

    local result = {
        code = 0,
        msg = "OK",
        enable = _uci_real:get("dhcp","lan","ignore") ~= '1' and true or false, --boolean 服务是否已经开启
        ipbegin = dhcp_start, --String 地址池开始地址
        ipend = dhcp_end, --String 地址池结束地址
        lease = _uci_real:get("dhcp","lan","leasetime"), --int 地址租期 ）范围为 1-2880
        gateway = gateway or _uci_real:get("network","lan","ipaddr"),--string 网关
        dns = dns1,--string DNS服务器
        dnsbak = dns2, --string 备用DNS服务器
        hide_enable = _uci_real:get("basic_setting", "no_wifi", "enable") == "1" and true or false
    }

    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_dhcp(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local enable = arg_list_table["enable"]
	local dhcpstart = arg_list_table["ipbegin"]
	local dhcpend = arg_list_table["ipend"]
	local leasetime = arg_list_table["lease"]
	local gateway = arg_list_table["gateway"]
	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]
	local code = 0
	local result = {
		code = 0,
		msg = "OK"
	}

	if not check_lan_area(gateway) then
		code = sferr.ERROR_INPUT_PARAM_ERROR
	else
		if enable == false then
			_uci_real:set("dhcp","lan","ignore", '1')
			_uci_real:set("dhcp","guest","ignore", '1')
		else
			_uci_real:set("dhcp","lan","ignore", "")
			_uci_real:set("dhcp","guest","ignore", "")
		end

		if dhcpstart and dhcpend then
			local start, range = calc_lan_dhcp(dhcpstart, dhcpend)
			if start and range then
				_uci_real:set("dhcp","lan","start", start)
				_uci_real:set("dhcp","lan","limit", range)
			else
				code = sferr.ERROR_INPUT_PARAM_ERROR
			end
		end

		if leasetime then
			_uci_real:set("dhcp","lan","leasetime",leasetime)
		end

		if dns1 ~= "" then
			dns = "6,"..dns1
		end
		if dns1 ~= "" and dns2 ~= "" then
			dns = "6,"..dns1..","..dns2
		end
		local lan_ip = _uci_real:get("network","lan","ipaddr")--获取LAN口IP
		if gateway ~= lan_ip then--不相等则设置gateway
			local dhcp_list = {"3,"..gateway, dns}
			_uci_real:set_list("dhcp","lan","dhcp_option",dhcp_list)
		elseif gateway == lan_ip and dns then
			local dhcp_list = {dns}
			_uci_real:set_list("dhcp","lan","dhcp_option",dhcp_list)
		else
			_uci_real:delete("dhcp","lan","dhcp_option")
		end

		if(result["code"] == 0) then
			_uci_real:save("dhcp")
			_uci_real:commit("dhcp")
			sysutil.fork_exec("sleep 2;/etc/init.d/dnsmasq restart")
		end
		sysutil.sflog("INFO","dhcp configure changed! enable status:%s"%{tostring(enable)})
	end
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	sysutil.nx_syslog(myprint(result), 1)

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_dhcp_devices()
	local s = require "luci.tools.status".dhcp_leases()
	local rv = {}

	for k, v in pairs(s) do
		rv[#rv+1] = {}

		rv[#rv]["name"] = v.hostname
		rv[#rv]["mac"] = v.macaddr
		rv[#rv]["ipaddr"] = v.ipaddr
		rv[#rv]["term"] = os.date('%Hh %Mm %Ss', v.expires)
	end

	local result = {
		code = 0,
		msg = "OK",
		devices = rv
	}

	sysutil.nx_syslog(myprint(result), 1)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

--ARP映射表
function get_ip_mac_online_table()
	local rv = {}
	local e, r, v

	if fs.access("/proc/net/arp") then
		for e in io.lines("/proc/net/arp") do
			local r = { }, v
			for v in e:gmatch("%S+") do
				r[#r+1] = v
			end

			if r[1] ~= "IP" then
				rv[#rv+1] = {}
				_uci_real:foreach("devlist", "device",
				function(s)
					if string.lower(s.mac:gsub("_", ":")) == r[4] then
						rv[#rv]["name"] = s.hostname
					end
				end
				)
				_uci_real:foreach("wldevlist", "device",
				function(s)
					if string.lower(s.mac:gsub("_", ":")) == r[4] then
						rv[#rv]["name"] = s.hostname
					end
				end
				)
				_uci_real:foreach("bindtable", "device",
				function(s)
					if string.lower(s.mac):gsub("_", ":") == r[4] then
						rv[#rv]["name"] = s.name
					end
				end)
				rv[#rv]["ipaddr"] = r[1]
				rv[#rv]["mac"] = string.upper(r[4])
				rv[#rv]["band"] = BindJudge(r[4], r[1], 1) --boolean  状态 false:未绑定 true：已绑定
			end
		end
	end

    local result = {
        code = 0,
        msg = "OK",
        devices = rv
    }

    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

--获取已经绑定的IP与MAC的映射表
function get_ip_mac_bind_table()
	local rv = {}
	file = io.open("/etc/ethers","r")
	io.input(file)
	while true do
		local line = io.read()
		if not line then
			break
		end

		rv[#rv+1] = {}
		_uci_real:foreach("devlist", "device",
			function(s)
				if s.mac and string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.hostname
				end
			end)

		_uci_real:foreach("wldevlist", "device",
			function(s)
				if s.mac and string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.hostname
				end
			end)

		_uci_real:foreach("bindtable", "device",
			function(s)
				if s.mac and string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.name
				end
			end)
		rv[#rv]["mac"] = string.upper(string.sub(line, 1, 17))
		rv[#rv]["ipaddr"] = string.sub(line, 19)
	end
	io.close(file)

    local result = {
        code = 0,
        msg = "OK",
        devices = rv
    }

    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

--设置已经绑定的IP与MAC的映射表
function set_ip_mac_bind_table(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local action = arg_list_table["action"]
	local code = 0
	local result = {
		code = 0,
		msg = "OK"
	}

	if (action == 0) then
		for k, v in pairs(arg_list_table["devices"]) do
			local name = v.name
			local line = string.lower(v.mac):gsub("_", ":").." "..v.ipaddr
			if not check_lan_area(v.ipaddr) and not check_wan_area(v.ipaddr) and not check_guest_area(v.ipaddr) then
				code = sferr.ERROR_INPUT_PARAM_ERROR
				break
			end
			if BindJudge(string.lower(v.mac):gsub("_", ":"), "", 0) then
				luci.util.exec("sed -i 's/%s.*/%s/g' /etc/ethers"%{string.lower(v.mac):gsub("_", ":"), line})
				if name then
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "device")
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "name", name)
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "mac", (v.mac:gsub(":", "_")))
				end
			else
				luci.util.exec("echo "..line.." >> /etc/ethers")
				if name then
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "device")
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "name", name)
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "mac", (v.mac:gsub(":", "_")))
				end
			end
		end
	elseif (action == 1) then
		file = io.open("/etc/ethers","r")
		io.input(file)
		for k, v in pairs(arg_list_table["devices"]) do
			luci.util.exec("sed -i '/%s/d' /etc/ethers"%{string.lower(v.mac):gsub("_", ":")})
			_uci_real:delete("bindtable", (v.mac:gsub(":", "_")))
		end
		io.close(file)
	elseif (action == 2) then
		luci.util.exec("> /etc/ethers")
		luci.util.exec("> /etc/config/bindtable")
	end
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	_uci_real:commit("bindtable")
	sysutil.fork_exec("sleep 1; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")

    sysutil.nx_syslog(myprint(result), 1)
	sysutil.sflog("INFO","ip mac bind table configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function disable_guide()
	_uci_real:set("basic_setting", "guide", "enable", 0)
	_uci_real:save("basic_setting")
	_uci_real:commit("basic_setting")
	local auto_to_web = _uci_real:get("basic_setting", "auto_to_web", "enable")
	if auto_to_web and auto_to_web == '1' then
		_uci_real:foreach("dhcp","dnsmasq",
		function(s)
			if(s["address"] ~= nil) then
				_uci_real:delete("dhcp",s[".name"],"address")
			end
		end)
		_uci_real:save("dhcp")
		_uci_real:commit("dhcp")
		sysutil.fork_exec("/etc/init.d/dnsmasq restart")

		_uci_real:set("uhttpd", "main", "index_page", "cgi-bin/luci")
		_uci_real:save("uhttpd")
		_uci_real:commit("uhttpd")

		luci.util.exec("rm -f /www/cgi-bin/first.lua")
	end
	local result = {
		code = 0,
		msg = "OK"
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function sync_pppoe_info()
	local timer = 0
	local timeout = 15
	local result = {
		code = 0,
		msg = "OK"
	}

    _uci_real:set("pppoe", "pppoe_server", "enabled", 1)
    _uci_real:commit("pppoe")
    luci.util.exec("/etc/init.d/pppoe-server restart")
    while true
    do
        if sysutil.checkFileExist("/tmp/pppoe_info") == 1 then
            local t = io.popen("cat /tmp/pppoe_info |head -n 1 |tr -d '\n'")
            result["username"] = t:read("*all")
            t:close()
            t = io.popen("cat /tmp/pppoe_info |tail -n 1 |tr -d '\n'")
            result["password"] = t:read("*all")
            t:close()
            break
        else
            os.execute("sleep "..1)
            timer = timer + 1
        end

        if timer >= timeout then
            result["code"] = sferr.ERROR_SYNC_PPPOE_TIMEOUT
            break
        end
    end

    _uci_real:set("pppoe", "pppoe_server", "enabled", 0)
    _uci_real:commit("pppoe")
    luci.util.exec("/etc/init.d/pppoe-server restart; sleep 1; rm /tmp/pppoe_info")

    result["msg"]  = sferr.getErrorMessage(result["code"])
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end
