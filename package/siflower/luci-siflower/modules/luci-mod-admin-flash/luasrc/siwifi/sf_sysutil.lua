--[[
LuCI - Lua Configuration Interface

Description:
Offers an common util to resolve system information
]]--

module ("luci.siwifi.sf_sysutil", package.seeall)


local fs     = require "nixio.fs"
local uci = require "luci.model.uci".cursor()
local sysconfig  = require "luci.siwifi.sf_sysconfig"
local nixio = require("nixio")
local json = require("luci.json")
local sferr = require "luci.siwifi.sf_error"
local http = require "luci.http"

--describe cloud type.
--case 0: use xcloud alibaba.
--case 1: use xcloud local.


function sane(file)
	return luci.sys.process.info("uid")
	== fs.stat(file , "uid")
	and fs.stat(file , "modestr")
	== (file and "rw-------" or "rwx------")
end

--describe name when communicate with other device
function getRouterName()
	local hostname = luci.util.pcdata(fs.readfile("/proc/sys/kernel/hostname")) or nixio.uname().nodename
	--ifconfig eth0 | grep HWaddr | cut -c 51- | sed 's/://g'
	local snDevice = luci.util.exec("ifconfig eth0 | grep HWaddr | cut -c 51- | sed 's/://g'")
	if(snDevice) then hostname = hostname..snDevice end
	hostname = string.gsub(hostname, "%c", "")
	return luci.util.trim(hostname)
end

--account id to communicate with remote internet server
function getRouterAccount()
	return ""
end

--Get information about if router support storage
function getStorage()
	return uci:get("siserver", "func", "storage") == "1" and 1 or 0
end

function getZigbeeAttr()
	local zigbee_process_fd = io.popen("ps |grep shuncom_app|grep -v 'grep' 2>/dev/null")
	if zigbee_process_fd then
		local tmp = zigbee_process_fd:read("*l")
		if tmp then
			return 1
		else
			return 0
		end
	end
end

--get router hardware description
--use model instead
function getHardware()

	local cpuinfo = fs.readfile("/etc/openwrt_release")
	local model = cpuinfo:match("DISTRIB_CODENAME='([^']+)")
	model = string.gsub(model, "%c", "")

	local a,t
	t = io.popen("hexdump -c -n2 -s 27 /dev/mtdblock3 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\" ) && (length($i) == 1)) a=a$i }} END{print a}'")
	if t  then
		a = t:read("*all")
		t:close()
		if string.find(a,"hv") then
			t = io.popen("hexdump -c -n32 -s 29 /dev/mtdblock3 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\" ) && (length($i) == 1)) a=a$i }} END {print a}'");
			if t  then
				a = t:read("*all")
				model = a
				t:close()
			end
		end
	end
	return model
end

--unique identify for our router
function getSN()
	--if get from uci
	local sn = uci:get( "siwifi", "hardware", "sn" )
	if(sn and (string.len(sn) > 0)) then
		return sn
	end
end

--rom version
function getRomVersion()
	local version = require "luci.version"
	local romVersion = luci.version.distname..luci.version.distversion
	return luci.util.trim(romVersion)
end

--fork a process to execute command
function fork_exec(command)
	local pid = nixio.fork()
	if pid > 0 then
		return
	elseif pid == 0 then
		-- change to root dir
		nixio.chdir("/")

		-- patch stdin, out, err to /dev/null
		local null = nixio.open("/dev/null", "w+")
		if null then
			nixio.dup(null, nixio.stderr)
			nixio.dup(null, nixio.stdout)
			nixio.dup(null, nixio.stdin)
			if null:fileno() > 2 then
				null:close()
			end
		end

		-- replace with target command
		nixio.exec("/bin/sh", "-c", command)
	end
end

function sf_wifinetworks()
	local rv = { }
	local ntm = require "luci.model.network".init()

	local dev
	for _, dev in ipairs(ntm:get_wifidevs()) do
		local rd = {
			up       = dev:is_up(),
			device   = dev:name(),
			name     = dev:get_i18n(),
			networks = { }
		}

		local net
		for _, net in ipairs(dev:get_wifinets()) do
			rd.networks[#rd.networks+1] = {
				name       = net:shortname(),
				link       = net:adminlink(),
				up         = net:is_up(),
				mode       = net:active_mode(),
				ssid       = net:active_ssid(),
				bssid      = net:active_bssid(),
				encryption = net:active_encryption(),
				frequency  = net:frequency(),
				channel    = net:channel(),
				signal     = net:signal(),
				quality    = net:signal_percent(),
				noise      = net:noise(),
				bitrate    = net:bitrate(),
				ifname     = net:ifname(),
				assoclist  = net:assoclist(),
				country    = net:country(),
				txpower    = net:txpower(),
				txpoweroff = net:txpower_offset(),
				password   = net:get("key"),
				disable    = net:get("disabled"),
				encryption_src = net:get("encryption"),
				network = net:get("network")
			}
		end

		rv[#rv+1] = rd
	end

	return rv
end

function getbind()
	local bind = uci:get( "siserver", "cloudrouter", "bind" )
	return bind
end

function getbinderId()
	local binder = uci:get( "siserver", "cloudrouter", "binder" )
	return binder
end

function getrouterId()
	local binder = uci:get( "siserver", "cloudrouter", "routerid" )
	return binder

end

function getMac(ifname)
	local mac = fs.readfile("/sys/class/net/" .. ifname .. "/address")

	if not mac then
		mac = luci.util.exec("ifconfig " .. ifname)
		mac = mac and mac:match(" ([a-fA-F0-9:]+)%s*\n")
	else
		mac = mac and mac:match("([a-fA-F0-9:]+)%s*%S*\n")
	end

	if mac and #mac > 0 then
		return mac:upper()
	end

	return ""
end

local function _nethints(what, callback)
	local _, k, e, mac, ip, name
	local ifn = { }
	local hosts = { }

	local function _add(i, ...)
		local k = select(i, ...)
		if k then
			if not hosts[k] then hosts[k] = { } end
			hosts[k][1] = select(1, ...) or hosts[k][1]
			hosts[k][2] = select(2, ...) or hosts[k][2]
			hosts[k][3] = select(3, ...) or hosts[k][3]
			hosts[k][4] = select(4, ...) or hosts[k][4]
		end
	end

	if fs.access("/proc/net/arp") then
		for e in io.lines("/proc/net/arp") do
			ip, mac = e:match("^([%d%.]+)%s+%S+%s+%S+%s+([a-fA-F0-9:]+)%s+")
			if ip and mac then
				_add(what, mac:upper(), ip, nil, nil)
			end
		end
	end

	if fs.access("/etc/ethers") then
		for e in io.lines("/etc/ethers") do
			mac, ip = e:match("^([a-f0-9]%S+) (%S+)")
			if mac and ip then
				_add(what, mac:upper(), ip, nil, nil)
			end
		end
	end

	if fs.access("/var/dhcp.leases") then
		for e in io.lines("/var/dhcp.leases") do
			mac, ip, name = e:match("^%d+ (%S+) (%S+) (%S+)")
			if mac and ip then
				_add(what, mac:upper(), ip, nil, name ~= "*" and name)
			end
		end
	end

	uci:foreach("dhcp", "host",
	function(s)
		for mac in luci.util.imatch(s.mac) do
			_add(what, mac:upper(), s.ip, nil, s.name)
		end
	end)

	for _, e in luci.util.kspairs(hosts) do
		callback(e[1], e[2], e[3], e[4])
	end
end

--- Returns a two-dimensional table of mac address hints.
-- @return  Table of table containing known hosts from various sources.
--          Each entry contains the values in the following order:
--          [ "mac", "name" ]
function sf_mac_hints(callback)
	if callback then
		_nethints(1, function(mac, v4, v6, name)
			name = name or nixio.getnameinfo(v4 or v6, nil, 100) or v4
			if name and name ~= mac then
				callback(mac, name or nixio.getnameinfo(v4 or v6, nil, 100) or v4)
			end
		end)
	else
		local rv = { }
		_nethints(1, function(mac, v4, v6, name)
			name = name or nixio.getnameinfo(v4 or v6, nil, 100) or v4
			if name and name ~= mac then
				rv[#rv+1] = { mac, name or nixio.getnameinfo(v4 or v6, nil, 100) or v4 }
			end
		end)
		return rv
	end
end

--- Returns a two-dimensional table of IPv4 address hints.
-- @return  Table of table containing known hosts from various sources.
--          Each entry contains the values in the following order:
--          [ "ip", "name" ]
function sf_ipv4_hints(callback)
	if callback then
		_nethints(2, function(mac, v4, v6, name)
			name = name or nixio.getnameinfo(v4, nil, 100) or mac
			if name and name ~= v4 then
				callback(v4, name)
			end
		end)
	else
		local rv = { }
		_nethints(2, function(mac, v4, v6, name)
			name = name or nixio.getnameinfo(v4, nil, 100) or mac
			if name and name ~= v4 then
				rv[#rv+1] = { v4, name }
			end
		end)
		return rv
	end
end
function sendCommandToLocalServer(command,result)
	nixio.syslog("crit", "send command"..tostring(command))
	-- TODO need check the return value
	local socket = nixio.socket("unix","stream")
	if socket.connect(socket,"/tmp/UNIX.domain") ~= true then
		nixio.syslog("crit", "can not connect the socket("..tostring(socket)..") to /tmp/UNIX.domain")
		socket.close(socket)
		return sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
	end

	---send the changes to server
	--- Send a message on the socket.
	-- This function is identical to sendto except for the missing destination
	-- paramters. See the sendto description for a detailed description.
	-- @class function
	-- @name Socket.send
	-- @param buffer    Buffer holding the data to be written.
	-- @param offset    Offset to start reading the buffer from. (optional)
	-- @param length    Length of chunk to read from the buffer. (optional)
	-- @see Socket.sendto
	-- @return number of bytes written
	---TODO : use a while loop to make sure that all the changes string has been sent to the socket server
	local send_buf = command
	local total_bytes = string.len(send_buf)
	local send_bytes = 0
	while(send_bytes < total_bytes)
		do
			send_bytes = send_bytes + socket.send(socket, send_buf, send_bytes)
		end

	nixio.syslog("crit", "socket send "..tostring(send_bytes).." OK, total "..tostring(total_bytes))
	--receivercv_buffers
	local buffer = socket.recv(socket,512)
	nixio.syslog("crit","recv buffer:"..tostring(buffer))
	socket.close(socket);
	if(string.len(tostring(buffer)) <= 0) then
		return sferr.ERROR_NO_INTERNAL_SOCKET_FAIL
	end
	result["json"] = tostring(buffer)
	return 0
end

function get_software_version()
    local boardinfo = luci.util.ubus("system", "board")
    local strlist = luci.util.split(boardinfo.release.description, ' ')
    return   strlist[3] or ""  --软件版本
end

function getOTAInfo()
	nixio.syslog("crit","recv buffer:")
	local xcloud_info = {}
	local xcloud_info_json = ""
	local cloud_code_url = ""
	local serveraddr = get_server_addr()
	if(getCloudType() == '0')then
		-- todo should get from uci
		cloud_code_url = "https://"..serveraddr..sysconfig.LOOKOTAVERSION
	else
		cloud_code_url = "https://192.168.1.12:8090/v1"..sysconfig.LOOKOTAVERSION
	end
	local romtype = getRomtype()
	local chiptype = getChiptype()
	local data = {}
	data.romtype = romtype
	data.otaversion = ""
	if (chiptype == 0) then
		data.chip="fullmask"
	else
		data.chip="mpw0"
	end
	data.type = getImgtype()
	--data.version = uci:get("sicloud","cloudcode","version")
	local json_data = json.encode(data)
	nixio.syslog("crit","curl -X POST -k -H \"Content-Type: application/json\" -d \'%s\' \"%s\"" %{json_data,cloud_code_url});
	xcloud_info_json = luci.util.exec("curl -X POST -k -H \"Content-Type: application/json\" -d \'%s\' \"%s\"" %{json_data,cloud_code_url})
	xcloud_info_table = json.decode(xcloud_info_json)
	if(xcloud_info_table) then
		xcloud_info = xcloud_info_table["data"]
	else
		return 1
	end
	if(xcloud_info[1] and xcloud_info[1]["romtype"] == romtype) then
		return xcloud_info[1]
	else
		return nil
	end
end

function getOTAInfo2()
	nixio.syslog("crit","recv buffer:")
	local xcloud_info = {}
	local xcloud_info_json = ""
	local cloud_code_url = ""
	local serveraddr = get_server_addr()
	if(getCloudType() == '0')then
		-- todo should get from uci
		cloud_code_url = "https://"..serveraddr..sysconfig.LOOKOTAVERSION2
	else
		cloud_code_url = "https://192.168.1.12:8090/v1"..sysconfig.LOOKOTAVERSION2
	end
	local romtype = getRomtype()
	local chiptype = getChiptype()
	local data = {}
	data.romtype = romtype
	if (chiptype == 0) then
		data.chip="fullmask"
	else
		data.chip="mpw0"
	end
	data.type = getImgtype()
	data.version = get_software_version()
	data.sn = uci:get("siwifi", "hardware", "sn")
	data.imagetype = 0
	data.env = 0
	--data.version = uci:get("sicloud","cloudcode","version")
	local json_data = json.encode(data)
	nixio.syslog("crit","curl -X POST -k -H \"Content-Type: application/json\" -d \'%s\' \"%s\"" %{json_data,cloud_code_url});
	xcloud_info_json = luci.util.exec("curl -X POST -k -H \"Content-Type: application/json\" -d \'%s\' \"%s\"" %{json_data,cloud_code_url})
	xcloud_info_table = json.decode(xcloud_info_json)
	if(xcloud_info_table) then
		xcloud_info = xcloud_info_table["data"]
	else
		return nil
	end

	return xcloud_info
end

-- 0means fullmask 1 means mpw0
function getChiptype()
	local cpuinfo = fs.readfile("/etc/openwrt_release")

	local model = cpuinfo:match("DISTRIB_TARGET='([^']+)")
	model = string.gsub(model, "%c", "")
	if (model == "siflower/sf16a18-fullmask") then
		return 0
	else
		return 1
	end
end

-- 0 means p10  1 means p20 2 means p10m  3 means 86v 4 means ac  5 means air001
function getRomtype()
	---todo get hardware error
	local htype = getHardware()
	if (htype == "sf16a18-p10-v1") or  (htype == "sf16a18-p10-v2") or (htype == "sf16a18-p10-flash-v2") then
		return 0
	elseif (htype == "sf16a18-p10-v2-gmac") or string.find(htype,"A18_P10BM2_V3_20180704") or string.find(htype,"A18_P10BM2_V4_20180815") then
		return 2
	elseif (htype == "sf16a18-evb-v2") or (htype == "sf16a18-evb-v1") then
		return 1
	elseif (htype == "sf16a18-86v-v2") or (htype == "sf16a18-86v-v1") or (htype == "sf16a18-86v-v5") then
		return 3
	elseif (htype == "sf16a18-acctl-v1") then
		return 4
	elseif (htype == "air001") then
		return 5
	end
end

function getImgtype()
	---todo get hardware error
	local htype = getHardware()
	if (htype == "sf16a18-p10-flash-v2") then
		return sysconfig.SF_OTA_FLASH
	end

	local file_temp= nixio.open("/router/common.sh", "r")
	if file_temp then
		file_temp:close()
		return sysconfig.SF_OTA_DEV
	else
		return sysconfig.SF_OTA_REL
	end

end

function send_unbind_command(bindret)
	local caller = (http.getenv("HTTP_AUTHORIZATION") ~= "") and 1 or 0
	return sendCommandToLocalServer("UBND need-callback -data {\"binder\":\""..tostring(userid).."\",\"caller\":"..tostring(caller).."}",bindret)
end

function send_manager_op_command(action,userid,phonenumber,username,tag,hostuserid,ret)
	return sendCommandToLocalServer("MGOP need-callback -data {\"action\":"..tostring(action)..",\"userid\":\""..tostring(userid).."\",\"phonenumber\":\""..tostring(phonenumber).."\",\"username\":\""..tostring(username).."\",\"hostuserid\":\""..tostring(hostuserid).."\",\"tag\":\""..tostring(tag).."\"}",ret)
end

function unbind()
	local bindvalue = getbind()
	if(bindvalue == sysconfig.SF_BIND_YET) then
		local bindret = {}
		local ret1 = send_unbind_command(bindret);
		if(ret1 ~= 0) then
			nixio.syslog("crit","send_unbind_command fail ret="..tostring(ret1))
		else
			nixio.syslog("crit","unbind success")
		end
	end
end


function writeRouterState(state)
	local f = nixio.open("/tmp/router_state", "w", 600)
	f:writeall(tostring(state))
	f:close()
end

function readRouterState()
	if sane("/tmp/router_state") then
		return tonumber(fs.readfile("/tmp/router_state"))
	else
		return 0
	end
end

--event when upgrade
SYSTEM_EVENT_UPGRADE = 1
--event when reboot
SYSTEM_EVENT_REBOOT = 2
--event when reset
SYSTEM_EVENT_RESET = 3
--- broast system event to local server.
---@action 1--enter upgrade  2--reboot now 3--reseting now
-- @return  Table of table containing known hosts from various sources.
--          Each entry contains the values in the following order:
--          [ "ip", "name" ]
function sendSystemEvent(action)
	writeRouterState(action)
	local bindvalue = getbind()
	--if bind we send command
	if(bindvalue == sysconfig.SF_BIND_YET) then
		local bindret = {}
		local ret1 = sendCommandToLocalServer("RSCH -data {\"action\":"..tostring(action).."}",bindret)
		nixio.syslog("crit","send system event="..tostring(action).."-ret="..tostring(ret1))
	end
end


function resetAllDevice()
	uci:foreach("devlist", "device",
	function(s)
		uci:set("devlist", s[".name"], "online", "0")
		uci:set("devlist", s[".name"], "ip", "0.0.0.0")
		uci:set("devlist", s[".name"], "associate_time", "-1")
	end
	)
	uci:save("devlist")
	uci:commit("devlist")
end



function resetWifiDevice()
	uci:foreach("devlist", "device",
	function(s)
		if s.port == '1' then
			uci:set("devlist", s[".name"], "online", "0")
			uci:set("devlist", s[".name"], "ip", "0.0.0.0")
			uci:set("devlist", s[".name"], "associate_time", "-1")
		end
	end
	)
	uci:save("devlist")
	uci:commit("devlist")
end

function get_version_from_http()
	return luci.http.formvalue("version")
end

function get_version_local()
	return uci:get("siversion","version","api")
end

function getCloudType()
	return uci:get("sicloud","addr","cloudtype")
end

function get_server_addr()
	local serverip = uci:get("sicloud","addr","ip")
	local serverport = uci:get("sicloud","addr","port")
	local serverversion = uci:get("sicloud","addr","version")
	local serveraddr = serverip..(":")..serverport..("/")..serverversion
	return serveraddr
end

function version_check(version_http)
	return (version_http <=  get_version_local())
end

function get_token()
    local result = {}
    local code = 0
	local tokenret = {}
	local ret1 = sendCommandToLocalServer("TOKN need-callback",tokenret)
	if(ret1 ~= 0) then
		code = -1
	else
		local decoder = {}
		if tokenret["json"] then
			decoder = json.decode(tokenret["json"]);
			if(decoder["ret"] == "success") then
				result["token"] = decoder["token"]
				code = 0
			else
				result["token"] = ""
				code = -1
			end
		end
	end
	result["code"] = code
	return result
end

function token()
	local i = 0
	local token = {}
	while(i < 3)
	do
		token = get_token()
		if (token['code'] == -1) then
			i = i + 1
		else
			break
		end
	end
	return token['token']
end

local file = "/tmp/sf_log.txt"

function sflog(level, msg)
	local ff = io.open(file, "a+")
	ff:write(os.date().." "..level.." "..msg.."\n")
	ff:close()
end

function sflog_read()
	local ff = io.open(file, "r+")
	local  msg = ff:read("*a")
	ff:close()
	return msg
end

function sflog_clean()
	local ff = io.open(file, "w")
	ff:close()
end
