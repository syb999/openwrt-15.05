
--require("luci.tools.webadmin")

mp = Map("openvpn", "OpenVPN Server","")

s = mp:section(TypedSection, "openvpn", "", translate("An easy config OpenVPN Server Web-UI"))
s.anonymous = true
s.addremove = false

s:tab("basic",  translate("Base Setting"))

o = s:taboption("basic", Flag, "enabled", translate("Enable"))

port = s:taboption("basic", Value, "port", translate("Port"))
port.datatype = "range(1,65535)"
port.default = "1194"

dev = s:taboption("basic", Value, "dev", translate("device node"))
dev.datatype = "string"
dev.default = "tun"
dev.rmempty = false
dev.description = translate("use tun/tap device node(default tun)")

tun_ipv6 = s:taboption("basic", Value, "tun_ipv6", translate("tun_ipv6"))
tun_ipv6:depends({dev="tun"})
tun_ipv6.datatype = "range(0,1)"
tun_ipv6.default = "0"
tun_ipv6.description = translate("Make tun device IPv6 capable(设置:1 为起用)")

ddns = s:taboption("basic", Value, "ddns", translate("WAN DDNS or IP"))
ddns.datatype = "string"
ddns.default = "exmple.com"
ddns.rmempty = false

persist_key = s:taboption("basic", Value, "persist_key", translate("persist_key"))
persist_key.datatype = "range(0,1)"
persist_key.default = "1"
persist_key.description = translate("重新启动vpn，不重新读取key(设置:1 为起用)")

persist_tun = s:taboption("basic", Value, "persist_tun", translate("persist_tun"))
persist_tun.datatype = "range(0,1)"
persist_tun.default = "1"
persist_tun.description = translate("重新启动vpn,一直保持tun或tap设备的连接(设置:1 为起用)")

max_clients = s:taboption("basic", Value, "max_clients", translate("max_clients"))
max_clients.datatype = "range(1,999)"
max_clients.default = "88"
max_clients.description = translate("最大客户端数")

localnet = s:taboption("basic", Value, "server", translate("Client Network"))
localnet.datatype = "string"
localnet.description = translate("VPN Client Network IP with subnet")
localnet.default = "10.9.9.0 255.255.255.0"

proto = s:taboption("basic",Value,"proto", translate("proto"))
proto.datatype = "string"
proto.default ="tcp"
proto.rmempty = false
proto.description = translate("use udp/tcp proto")

comp_lzo = s:taboption("basic",Value,"comp_lzo", translate("comp_lzo"))
comp_lzo.datatype = "string"
comp_lzo.default="adaptive"
comp_lzo.description = translate("yes,no,adaptive")

auth_user_pass_verify = s:taboption("basic",Value,"auth_user_pass_verify", translate("帐号密码验证"))
auth_user_pass_verify.datatype = "string"
auth_user_pass_verify.default ="/etc/openvpn/server/checkpsw.sh via-env"
auth_user_pass_verify.description = translate("默认设置:/etc/openvpn/server/checkpsw.sh via-env,留空禁用")

script_security = s:taboption("basic",Value,"script_security", translate("script_security配合帐号密码验证使用"))
script_security.datatype = "range(1,3)"
script_security.default = "3"
script_security.description = translate("默认设置:3,留空禁用")

duplicate_cn = s:taboption("basic",Flag,"duplicate_cn", translate("duplicate_cn"))
username_as_common_name = s:taboption("basic",Flag,"username_as_common_name", translate("username_as_common_name"))
client_cert_not_required = s:taboption("basic",Flag,"client_cert_not_required", translate("client_cert_not_required"))
client_cert_not_required.description = translate("打开后客户端则不需要cert和key,不打开则需要cert和key以及帐号密码双重验证")

list = s:taboption("basic", DynamicList, "push")
list.title = translate("Client Settings")
list.datatype = "string"
list.description = translate("Set route 192.168.1.0 255.255.255.0 and dhcp-option DNS 192.168.1.1 base on your router")

listrb = s:taboption("basic", DynamicList, "push")
listrb.title = translate("Client Settings")
listrb.datatype = "string"
listrb.default = "redirect-gateway def1 bypass-dhcp"
listrb.description = translate("所有客户端的默认网关都将重定向到VPN")

ca = s:taboption("basic",Value,"ca.crt", translate("ca.crt"))
ca.datatype = "string"
ca.default ="/etc/openvpn/ca.crt"
ca.description = translate("默认设置:/etc/openvpn/ca.crt,建议使用OPENVPN CERT按键自动更新证书")

dh = s:taboption("basic",Value,"dh.pem", translate("dh.pem"))
dh.datatype = "string"
dh.default ="/etc/openvpn/dh.pem"
dh.description = translate("默认设置:/etc/openvpn/dh.pem,建议使用OPENVPN CERT按键自动更新文件")

cert = s:taboption("basic",Value,"server.crt", translate("server.crt"))
cert.datatype = "string"
cert.default ="/etc/openvpn/server.crt"
cert.description = translate("默认设置:/etc/openvpn/server.crt,建议使用OPENVPN CERT按键自动更新证书")

key = s:taboption("basic",Value,"server.key", translate("server.key"))
key.datatype = "string"
key.default ="/etc/openvpn/server.key"
key.description = translate("默认设置:/etc/openvpn/server.key,建议使用OPENVPN CERT按键自动更新证书")

local o
o = s:taboption("basic", Button,"certificate",translate("OpenVPN Client config file"))
o.inputtitle = translate("Download .ovpn file")
o.description = translate("如果使用单独帐号密码验证,一定要记得删除key和cert内容")
o.inputstyle = "reload"
o.write = function()
  luci.sys.call("sh /etc/genovpn/ovpn.sh 2>&1 >/dev/null")
	Download()
end

local osimple
osimple = s:taboption("basic", Button,"simple-certificate",translate("OpenVPN Client simple config file"))
osimple.inputtitle = translate("Download .ovpn file")
osimple.description = translate("下载简化配置文件，不包含ca cert key内容")
osimple.inputstyle = "reload"
osimple.write = function()
  luci.sys.call("sh /etc/genovpn/simple.sh 2>&1 >/dev/null")
	Downloadsimple()
end

local aca
aca = s:taboption("basic", Button,"ca certificate",translate("OpenVPN Client ca file"))
aca.inputtitle = translate("Download ca file")
aca.description = translate("单独下载ca.crt证书")
aca.inputstyle = "reload"
aca.write = function()
  luci.sys.call("sh /etc/genovpn/ca.sh 2>&1 >/dev/null")
	Downloadca()
end

local bcert
bcert = s:taboption("basic", Button,"cert certificate",translate("OpenVPN Client cert file"))
bcert.inputtitle = translate("Download cert file")
bcert.description = translate("单独下载client.crt证书")
bcert.inputstyle = "reload"
bcert.write = function()
  luci.sys.call("sh /etc/genovpn/cert.sh 2>&1 >/dev/null")
	Downloadcert()
end

local ckey
ckey = s:taboption("basic", Button,"key",translate("OpenVPN Client key file"))
ckey.inputtitle = translate("Download key file")
ckey.description = translate("单独下载client.key文件")
bcert.inputstyle = "reload"
ckey.write = function()
  luci.sys.call("sh /etc/genovpn/key.sh 2>&1 >/dev/null")
	Downloadkey()
end

local ddh
ddh = s:taboption("basic", Button,"dh",translate("OpenVPN Client dh file"))
ddh.inputtitle = translate("Download dh file")
ddh.description = translate("单独下载dh.pem文件")
ddh.inputstyle = "reload"
ddh.write = function()
  luci.sys.call("sh /etc/genovpn/dh.sh 2>&1 >/dev/null")
	Downloaddh()
end

local epass
epass = s:taboption("basic", Button,"user_password",translate("OpenVPN Client user_password file"))
epass.inputtitle = translate("Download userpass file")
epass.description = translate("单独下载userpass文件,请按照默认格式自行修改服务器设置的用户名密码")
epass.inputstyle = "reload"
epass.write = function()
  luci.sys.call("sh /etc/genovpn/pass.sh 2>&1 >/dev/null")
	Downloadpass()
end

s:tab("code",  translate("客户端代码"))
local conf = "/etc/ovpnadd.conf"
local NXFS = require "nixio.fs"
o = s:taboption("code", TextValue, "conf")
o.description = translate("想要加入到.ovpn文件里的代码,如果使用帐号密码验证则需要加入auth-user-pass")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(conf) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(conf, value:gsub("\r\n", "\n"))
end


s:tab("passwordfile",  translate("帐号密码"))
local pass = "/etc/openvpn/server/psw-file"
local NXFS = require "nixio.fs"
o = s:taboption("passwordfile", TextValue, "pass")
o.description = translate("user_password一排一组帐号密码,帐号密码中间空格隔开")
o.rows = 13
o.wrap = "off"
o.cfgvalue = function(self, section)
	return NXFS.readfile(pass) or ""
end
o.write = function(self, section, value)
	NXFS.writefile(pass, value:gsub("\r\n", "\n"))
end


local pid = luci.util.exec("/usr/bin/pgrep openvpn")

function openvpn_process_status()
  local status = "OpenVPN is not running now "

  if pid ~= "" then
      status = "OpenVPN is running with the PID " .. pid .. ""
  end

  local status = { status=status }
  local table = { pid=status }
  return table
end



function Download()
	local t,e
	t=nixio.open("/tmp/my.ovpn","r")
	luci.http.header('Content-Disposition','attachment; filename="my.ovpn"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloadsimple()
	local t,e
	t=nixio.open("/tmp/my-simple.ovpn","r")
	luci.http.header('Content-Disposition','attachment; filename="my-simple.ovpn"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloadca()
	local t,e
	t=nixio.open("/tmp/ca.crt","r")
	luci.http.header('Content-Disposition','attachment; filename="ca.crt"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloadcert()
	local t,e
	t=nixio.open("/tmp/client.crt","r")
	luci.http.header('Content-Disposition','attachment; filename="client.crt"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloadkey()
	local t,e
	t=nixio.open("/tmp/client.key","r")
	luci.http.header('Content-Disposition','attachment; filename="client.key"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloaddh()
	local t,e
	t=nixio.open("/tmp/dh.pem","r")
	luci.http.header('Content-Disposition','attachment; filename="dh.pem"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

function Downloadpass()
	local t,e
	t=nixio.open("/tmp/userpass.txt","r")
	luci.http.header('Content-Disposition','attachment; filename="userpass.txt"')
	luci.http.prepare_content("application/octet-stream")
	while true do
		e=t:read(nixio.const.buffersize)
		if(not e)or(#e==0)then
			break
		else
			luci.http.write(e)
		end
	end
	t:close()
	luci.http.close()
end

t = mp:section(Table, openvpn_process_status())
t.anonymous = true

t:option(DummyValue, "status", translate("OpenVPN status"))

if pid == "" then
  start = t:option(Button, "_start", translate("Start"))
  start.inputstyle = "apply"
  function start.write(self, section)
        luci.util.exec("uci set openvpn.myvpn.enabled=='1' &&  uci commit openvpn")
        message = luci.util.exec("/etc/init.d/openvpn start 2>&1")
        luci.util.exec("sleep 2")
        luci.http.redirect(
                luci.dispatcher.build_url("admin", "vpn", "openvpn-server") .. "?message=" .. message
        )
  end
else
  stop = t:option(Button, "_stop", translate("Stop"))
  stop.inputstyle = "reset"
  function stop.write(self, section)
        luci.util.exec("uci set openvpn.myvpn.enabled=='0' &&  uci commit openvpn")
        luci.util.exec("/etc/init.d/openvpn stop")
        luci.util.exec("sleep 2")
        luci.http.redirect(
                luci.dispatcher.build_url("admin", "vpn", "openvpn-server")
        )
  end
end

function mp.on_after_commit(self)
  os.execute("uci set firewall.openvpn.dest_port=$(uci get openvpn.myvpn.port) && uci commit firewall &&  /etc/init.d/firewall restart")
  os.execute("/etc/init.d/openvpn restart")
end

gen = t:option(Button,"cert",translate("OpenVPN Cert"))
gen.inputstyle = "apply"
function gen.write(self, section)
  luci.util.exec("/etc/openvpncert.sh")
end

--local apply = luci.http.formvalue("cbi.apply")
--if apply then
--	os.execute("/etc/init.d/openvpn restart")
--end

return mp
