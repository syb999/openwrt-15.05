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
ipc = require "luci.ip"
systemnew = require "luci.controller.admin.systemnew"

function index()
    entry({"admin", "networknew"}, firstchild(), _("网络参数"), 60).logo="network";
    entry({"admin", "networknew", "wan"}, template("new_siwifi/network_params/wan") , _("WAN口设置"), 1);
    entry({"admin", "networknew", "lan"}, template("new_siwifi/network_params/lan") , _("LAN口设置"), 2);
    entry({"admin", "networknew", "mac"}, template("new_siwifi/network_params/mac") , _("MAC地址设置"), 3);
    entry({"admin", "networknew", "dhcp"}, template("new_siwifi/network_params/dhcp") , _("DHCP服务器"), 4);
    entry({"admin", "networknew", "ip_mac"}, template("new_siwifi/network_params/ip_mac") , _("IP与MAC绑定"), 5);

    entry({"admin", "networknew", "get_wan"}, call("get_wan")).leaf = true;
    entry({"admin", "networknew", "set_wan"}, call("set_wan")).leaf = true;
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

function ip_to_mac(ip)
	local mac = nil
	ipc.neighbors({ family = 4 }, function(n)
		if n.mac and n.dest and n.dest:equal(ip) then
			mac = n.mac
		end
	end)
	return mac
end

function SearchStringInFile(path, str)
	local file = io.open(path, "r")
	local data = file:read("*a")
	file:close()
	if string.find(data,str) ~= nil then
		return true
	else
		return false
	end
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
		local t = io.popen("printf $(($(devmem 0x10b000d8) & 0x8))")
		linkstatus = t:read("*all")
	else
		local t = io.popen("cat /sys/kernel/debug/npu_debug |grep phy4 |awk '{print $3}' |tr -d '\n'")
		linkstatus = t:read("*all")
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
				manualdns = _uci_real:get("network","wan","manualdns") == '1' and true or false, --boolean 是否手动设置dns
				dns = dns[1],--string DNS服务器
				dnsbak = dns[2],--string 备用DNS服务器
				hostname = luci.sys.hostname(),--string 主机名
				unicast =  _uci_real:get("network","wan","unicast") == '1' and true or false, --boolean 是否为单播方式
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
				linkstatus = linkstatus, --0/1 连接状态
				connectmode = "", --string 连接模式
				disconnectinterval = _uci_real:get("network","wan","demand") or 0, --int 自动断线等待时间
				packageMTU = _uci_real:get("network","wan","mtu") or 1500, --int 数据包MTU(字节)
				servicename = _uci_real:get("network","wan","service") or "auto", --sring 服务器名
				servername = _uci_real:get("network","wan","ac") or "auto", --string 服务器名
				useoperatoraddress = _uci_real:get("network","wan","fixipEnb") and true or false, --string 使用运营商制定的ip地址
				operatoraddress = _uci_real:get("network","wan","pppd_options"):match("^%d+%.%d+%.%d+%.%d+"),  --string 运营商指定的IP地址
				manualdns = _uci_real:get("network","wan","manualdns") == '1' and true or false, --boolean 是否手动设置dns
				dns = dns[1], --string DNS服务器
				dnsbak = dns[2] --string 备用DNS服务器
			}
		}
	else
		result = {
			code = 1,
			msg = "Protocol unknown"
		}
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_wan(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local wantype = arg_list_table["wantype"]
	local result = {}
	local code = 0

	local proto = _uci_real:get("network","wan","proto")
	if(proto == "pppoe") then
		_uci_real:delete("network","wan","username")
		_uci_real:delete("network","wan","ppppwd")
		_uci_real:delete("network","wan","service")
		_uci_real:delete("network","wan","ac")
		_uci_real:delete("network","wan","demand")
		_uci_real:delete("network","wan","fixipEnb")
		_uci_real:delete("network","wan","pppd_options")
	elseif(proto == "static") then
		_uci_real:delete("network","wan","ipaddr")
		_uci_real:delete("network","wan","netmask")
		_uci_real:delete("network","wan","gateway")
	end

	_uci_real:delete("network","wan","dns")
	_uci_real:delete("network","wan","manualdns")
	_uci_real:delete("network","wan","speed")

	if wantype == 1 then
		_uci_real:set("network","wan","proto","dhcp")
		local hostname = arg_list_table["hostname"]
		if hostname and string.len(hostname)>31 then
			hostname = string.sub(hostname,1,31)
			luci.sys.hostname(hostname)
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
		local releaseip = arg_list_table["releaseip"]
		if releaseip then
			if wan_ifc == "eth1" then
				luci.util.exec("kill -SIGUSR2 `cat /var/run/udhcpc-eth1.pid`")
			else
				luci.util.exec("kill -SIGUSR2 `cat /var/run/udhcpc-eth0.2.pid`")
			end
		end
	elseif wantype == 2 then
		_uci_real:set("network","wan","proto","static")
		local address = arg_list_table["ipaddr"]
		if address and #address>31 then
			address = string.sub(address,1,31)
		end
		local mask = arg_list_table["netmask"]
		if mask and #mask>31 then
			mask = string.sub(mask,1,31)
		end
		local gateway = arg_list_table["gateway"]
		if gateway and #gateway>31 then
			gateway = string.sub(gateway,1,31)
		end
		if(address) then
			_uci_real:set("network","wan","ipaddr",address)
		end
		if(mask) then
			_uci_real:set("network","wan","netmask",mask)
		end
		if(gateway) then
			_uci_real:set("network","wan","gateway",gateway)
		end
	elseif wantype == 4 then
		_uci_real:set("network","wan","proto","pppoe")
		local pppname = arg_list_table["account"]
		if pppname and #pppname>31 then
			pppname = string.sub(pppname,1,31)
		end

		local ppppwd  = arg_list_table["password"]
		if ppppwd and string.len(ppppwd)>31 then
			ppppwd = string.sub(ppppwd,1,31)
		end

		local connect = arg_list_table["connect"]
		if connect ~= 0 then
			_uci_real:set("network", "wan", "enabled", 1)
		else
			_uci_real:set("network", "wan", "enabled", 0)
		end

		if(pppname) then
			_uci_real:set("network", "wan", "username", pppname)
		end
		if(ppppwd) then
			_uci_real:set("network", "wan", "password", ppppwd)
		end
		local servicename = arg_list_table["servicename"]
		if(servicename) then
			_uci_real:set("network","wan","service",servicename)
		end
		local servername = arg_list_table["servername"]
		if(servername) then
			_uci_real:set("network","wan","ac",servername)
		end
		local disconnectinterval = arg_list_table["disconnectinterval"]
		if(disconnectinterval) then
			_uci_real:set("network","wan","demand",disconnectinterval)
		end
		local useoperatoraddress = arg_list_table["useoperatoraddress"]
		if(useoperatoraddress) then
			_uci_real:set("network","wan","fixipEnb",1)
		end
		local operatoraddress = arg_list_table["operatoraddress"]
		if(operatoraddress) then
			_uci_real:set("network","wan","pppd_options",operatoraddress..":")
		end
	else
		luci.http.status(404, "Protocal unknown")
	end

	local dns1 = arg_list_table["dns"]
	local dns2 = arg_list_table["dnsbak"]
	if dns1 and string.len(dns1)>31 then
		dns1 = string.sub(dns1,1,31)
	end
	if dns2 and string.len(dns2)>31 then
		dns2 = string.sub(dns2,1,31)
	end

	_uci_real:set("network","wan","manualdns",0)
	if dns1 ~= "" then
		_uci_real:delete("network","wan","dns")
		_uci_real:set("network","wan","dns",dns1)
		_uci_real:set("network","wan","manualdns",1)
	end
	if dns1 ~= "" and dns2 ~= "" then
		local dns = dns1.." "..dns2
		_uci_real:set("network","wan","dns",dns)
		_uci_real:set("network","wan","manualdns",1)
	end

	local mtu = arg_list_table["packageMTU"]
	if mtu then
		_uci_real:set("network","wan","mtu",mtu)
	end

	local speed = arg_list_table["wanspeed"]
	if speed == "auto" then
		_uci_real:set("network","wan","speed",speed)
		luci.util.exec("echo 0x8 0x4 0x0 0x1000 > /sys/kernel/debug/npu_debug")
	elseif speed == "10mfull" then
		_uci_real:set("network","wan","speed",speed)
		luci.util.exec("echo 0x8 0x4 0x0 0x100 > /sys/kernel/debug/npu_debug")
	elseif speed == "10mhalf" then
		_uci_real:set("network","wan","speed",speed)
		luci.util.exec("echo 0x8 0x4 0x0 0x0 > /sys/kernel/debug/npu_debug")
	end

	if(code == 0) then
		_uci_real:save("network")
		_uci_real:commit("network")
		_uci_real:load("network")
		luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
	end

    result = {
        code = 0,
        msg = "OK"
    }

    --nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","wan configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_lan()
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()

    local result = {
        code = 0,
        msg = "OK",
        mac = device:mac(),--string mac地址
        mode = _uci_real:get("network","lan","mode") or 0, --int Lan口ip设置模式 0：自动 1:手动
        ipaddr = net:ipaddr(), --string IP地址
        netmask = net:netmask() --string 子网掩码
    }
    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_lan(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local mode = arg_list_table["mode"]
	local address = arg_list_table["ipaddr"]
	local mask = arg_list_table["netmask"]
	local result = {}
	local code = 0

	if address and string.len(address)>31 then
		address = string.sub(address,1,31)
	end
	if mask and string.len(mask)>31 then
		mask = string.sub(mask,1,31)
	end

	if(address) then
		_uci_real:set("network","lan","ipaddr",address)
	end
	if(mask) then
		_uci_real:set("network","lan","netmask",mask)
	end
	if(mode) then
		_uci_real:set("network","lan","mode",mode)
	end

	if(code == 0) then
		_uci_real:save("network")
		_uci_real:commit("network")
		_uci_real:load("network")
		sysutil.fork_exec("sleep 2; env -i /bin/ubus call network reload >/dev/null 2>/dev/null")
	end

    result = {
        code = 0,
        msg = "OK"
    }
    --nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","lan configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_mac()
	local ntm = require "luci.model.network".init()
	local ip = require "luci.ip"
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
	local wanmac = string.sub(device:mac(),1,15)..string.format("%02x",(tonumber("0x"..string.sub(device:mac(),16,17)) + 1))

    local result = {
        code = 0,
        msg = "OK",
        mode = _uci_real:get("network","wan","mode") or 0, --int 模式 0：使用路由器mac地址， 使用当前管理pc的mac地址，使用自定义的mac地址
        routermac = wanmac, --string 路由器的mac地址
        devicemac = ip_to_mac(luci.http.getenv("REMOTE_ADDR")) or "", --string 当前管理pc的mac地址
        custommac = _uci_real:get("network","wan","macaddr") or "" --string 自定义的mac地址
    }

    --nixio.syslog("crit", myprint(result))
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
		luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
	end

    local result = {
        code = 0,
        msg = "OK"
    }

    --nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","mac configure changed! mode is %d"%{mode})
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_dhcp()
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local dns = net:dnsaddrs()
	local ipmask = (_uci_real:get("network","lan","ipaddr")):match("^%d+%.%d+%.%d+%.")

    local result = {
        code = 0,
        msg = "OK",
        enable = _uci_real:get("dhcp","lan","ignore") ~= '1' and true or false, --boolean 服务是否已经开启
        ipbegin = ipmask..(_uci_real:get("dhcp","lan","start")), --String 地址池开始地址
        ipend = ipmask..(_uci_real:get("dhcp","lan","limit")), --String 地址池结束地址
        lease = _uci_real:get("dhcp","lan","leasetime"), --int 地址租期 ）范围为 1-2880
        gateway = net:gwaddr(),--string 网关
        dns = dns[1],--string DNS服务器
        dnsbak = dns[2]--string 备用DNS服务器
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
	local result = {}
	local code = 0

	if enable == false then
		_uci_real:set("dhcp","lan","ignore", '1')
	else
		_uci_real:set("dhcp","lan","ignore", "")
	end

	if dhcpstart then
		_uci_real:set("dhcp","lan","start",dhcpstart)
	end
	if dhcpend then
		_uci_real:set("dhcp","lan","limit",dhcpend)
	end
	if leasetime then
		_uci_real:set("dhcp","lan","leasetime",leasetime)
	end
	if gateway then
		_uci_real:set("network","lan","gateway",gateway)
	end

	if dns1 and string.len(dns1)>31 then
		dns1 = string.sub(dns1,1,31)
	end
	if dns2 and string.len(dns2)>31 then
		dns2 = string.sub(dns2,1,31)
	end

	if dns1 ~= "" then
		_uci_real:delete("network","lan","dns")
		_uci_real:set("network","lan","dns",dns1)
	end
	if dns1 ~= "" and dns2 ~= "" then
		local dns = dns1.." "..dns2
		_uci_real:set("network","lan","dns",dns)
	end

    result = {
        code = 0,
        msg = "OK"
    }

	if(code == 0) then
		_uci_real:save("dhcp")
		_uci_real:save("network")
		_uci_real:commit("dhcp")
		_uci_real:commit("network")
		_uci_real:load("network")
		luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")
	end

    --nixio.syslog("crit", myprint(result))

	sysutil.sflog("INFO","dhcp configure changed! enable status:%s"%{tostring(enable)})
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

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

--获取在线的IP与MAC的映射表
function get_ip_mac_online_table()
	local rv = {}

	_uci_real:foreach("devlist", "device",
		function(s)
			if s.online == '1' then
				rv[#rv+1] = {}
				rv[#rv]["name"] = s.hostname
				rv[#rv]["mac"] = s.mac:gsub("_", ":")
				rv[#rv]["ipaddr"] = s.ip
				rv[#rv]["band"] = SearchStringInFile("/etc/ethers",string.lower(s.mac:gsub("_", ":"))) --boolean  状态 false:未绑定 true：已绑定
			end
		end
	)

	_uci_real:foreach("wldevlist", "device",
		function(s)
			if s.online == '1' then
				rv[#rv+1] = {}
				rv[#rv]["name"] = s.hostname
				rv[#rv]["mac"] = s.mac:gsub("_", ":")
				rv[#rv]["ipaddr"] = s.ip
				rv[#rv]["band"] = SearchStringInFile("/etc/ethers",string.lower(s.mac:gsub("_", ":"))) --boolean  状态 false:未绑定 true：已绑定
			end
		end
	)
--[[ --ARP表
	local s = require "luci.ip".neighbors({ family = 4 })
	local rv = {}

	for k, v in pairs(s) do
		rv[#rv+1] = {}

		rv[#rv]["name"] = ""
		rv[#rv]["mac"] = v.mac
		rv[#rv]["ipaddr"] = v.dest
		rv[#rv]["band"] = false --boolean  状态 false:未绑定 true：已绑定
	end
]]
    local result = {
        code = 0,
        msg = "OK",
        devices = rv
    }

    --nixio.syslog("crit", myprint(result))
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
				if string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.hostname
				end
			end)

		_uci_real:foreach("wldevlist", "device",
			function(s)
				if string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.hostname
				end
			end)

		_uci_real:foreach("bindtable", "device",
			function(s)
				if string.lower(s.mac):gsub("_", ":") == string.sub(line, 1, 17) then
					rv[#rv]["name"] = s.hostname
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

    --nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

--设置已经绑定的IP与MAC的映射表
function set_ip_mac_bind_table(params)
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local action = arg_list_table["action"]
	local hostname = arg_list_table["hostname"]

	if (action == 0) then
		for k, v in pairs(arg_list_table["devices"]) do
			local line = string.lower(v.mac):gsub("_", ":").." "..v.ipaddr
			if SearchStringInFile("/etc/ethers",string.lower(v.mac):gsub("_", ":")) then
				luci.util.exec("sed -i 's/%s.*/%s/g' /etc/ethers"%{string.lower(v.mac):gsub("_", ":"), line})
				if hostname then
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "hostname", hostname)
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "mac", (v.mac:gsub(":", "_")))
				end
			else
				luci.util.exec("echo "..line.." >> /etc/ethers")
				if hostname then
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "device")
					_uci_real:set("bindtable", v.mac:gsub(":", "_"), "hostname", hostname)
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

	_uci_real:commit("bindtable")
	luci.sys.call("env -i /bin/ubus call network reload >/dev/null 2>/dev/null; sleep 2")

    local result = {
        code = 0,
        msg = "OK"
    }

    --nixio.syslog("crit", myprint(result))
	sysutil.sflog("INFO","ip mac bind table configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end
