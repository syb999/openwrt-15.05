--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/8
-- Time: 9:14
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.systemp", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require("luci.json")
local zones = require "luci.sys.zoneinfo"
local mainp = require "luci.controller.admin.mainp"
local sferr = require "luci.siwifi.sf_error"

function index()
    entry({"admin", "systemp"}, template("86v/system"), _("System"), 63).attrid = "system";
    entry({"admin", "systemp", "get_date"}, call("get_date")).leaf = true;
    entry({"admin", "systemp", "set_date"}, call("set_date")).leaf = true;
    entry({"admin", "systemp", "get_version"}, call("get_version")).leaf = true;
    entry({"admin", "systemp", "get_sysinfo"}, call("get_sysinfo")).leaf = true;
    entry({"admin", "systemp", "set_sysinfo"}, call("set_sysinfo")).leaf = true;
    entry({"admin", "systemp", "set_ping"}, call("set_ping")).leaf = true;
    entry({"admin", "systemp", "get_ping"}, call("get_ping")).leaf = true;
    entry({"admin", "systemp", "reset"}, call("reset")).leaf = true;
    entry({"admin", "systemp", "restart"}, call("restart")).leaf = true;
    entry({"admin", "systemp", "set_password"}, call("set_password")).leaf = true;
    entry({"admin", "systemp", "get_log"}, call("get_log")).leaf = true;
    entry({"admin", "systemp", "clean_log"}, call("clean_log")).leaf = true;
    entry({"admin", "systemp", "download_log"}, call("download_log")).leaf = true;
    entry({"admin", "systemp", "upgrade"}, call("upgrade")).leaf = true;
    entry({"admin", "systemp", "get_zones"}, call("get_zones")).leaf = true;
    entry({"admin", "systemp", "import_config"}, call("import_config")).leaf = true;
    entry({"admin", "systemp", "export_config"}, call("export_config")).leaf = true;
    entry({"admin", "systemp", "get_lang"}, call("get_lang")).leaf = true;
    entry({"admin", "systemp", "set_lang"}, call("set_lang")).leaf = true;
    entry({"admin", "systemp", "get_style_color"}, call("get_style_color")).leaf = true;
    entry({"admin", "systemp", "get_ipaddr"}, call("get_ipaddr")).leaf = true;
end


local file = "/tmp/sf_log.txt"

function get_style_color()
    local result = {
        code=0,
        msg="OK",
    }
    local style = {}
    local font = {}
    local background = {}
    local border = {}
    local border_bottom = {}
    local border_right = {}
 -- all title --
    font[".panel-title,p.hsVigWDSPWD,.wireless-service-setting-font"]=_uci_real:get("style","font","panel_title")
 -- all table_td --
    font["table td,div.hsTip span.detail,.sp-postion-enable"]=_uci_real:get("style","font","table_td")
 -- all table_th --
    font["table th"]=_uci_real:get("style","font","table_th")
 -- all button --
    font["button,.btn"]=_uci_real:get("style","font","button")
 -- all input_radio except wireless-param --
    font[".input-radio"]=_uci_real:get("style","font","input_radio")
 -- all select ,all input --
    font["select,input,span.select input.hsValueA,.sta_min_dbm-font"]=_uci_real:get("style","font","select")
 -- input disable --
    font["input:disabled"]=_uci_real:get("style","font","input_disabled")
 -- navigation bar unchecked --
    font["li.slide a"]=_uci_real:get("style","font","li_slide_a")
 -- navigation bar selection --
    font["li.slide a.current"]=_uci_real:get("style","font","li_slide_a_current")
 -- all help text --
    font[".helpWord"]=_uci_real:get("style","font","helpWord")
 -- log list --
    font["div.pageListDiv span"]=_uci_real:get("style","font","div_pageListDiv_span")
 -- logout --
    font["ul.headFunc li label"]=_uci_real:get("style","font","ul_headFunc_li_label")
 -- software version --
    font["footer"]=_uci_real:get("style","font","footer")
 -- navigation bar selection area --
    font["li.slide a:hover"]=_uci_real:get("style","font","li_slide_a_hover")
 -- login help --
    font["span.loginHelp,.loginTip"]=_uci_real:get("style","font","loginHelp")
 -- login help text --
    font["#loginFeg"]=_uci_real:get("style","font","helpWord")
 -- login password --
    font[".lb-pwd"]=_uci_real:get("style","font","lb_pwd")
 -- login input password --
    font[".cbi-input-password"]=_uci_real:get("style","font","lb_pwd")
 -- login button --
    font[".cbi-button.cbi-button-apply"]=_uci_real:get("style","font","helpWord")

 -- html_body --
    background["html, body"]=_uci_real:get("style","background","html_body")
 -- navigation bar --
    background["header"]=_uci_real:get("style","background","header")
 -- all content body --
   background[".main-right > #maincontent"]=_uci_real:get("style","background","main_right_maincontent")
 -- navigation bar selection --
    background["li.slide a.current"]=_uci_real:get("style","background","li_slide_a_current")
 -- input disabled --
    background["input:disabled"]=_uci_real:get("style","background","input_disabled")
 -- window frame --
    background["div.hsVignette,div.hsTip"]=_uci_real:get("style","background","div_hsVignette")
 -- help --
    background[".helpWord,.btnFeg"]=_uci_real:get("style","background","helpWord")
 -- all button except 'Delete' button --
    background["button,.btn,div.hsTip input"]=_uci_real:get("style","background","button")
 -- button disabled --
    background["button:disabled"]=_uci_real:get("style","background","button_disabled")
 -- log list --
    background["div.pageListDiv span"]=_uci_real:get("style","background","div_pageListDiv_span")
 -- login button --
    background[".cbi-button.cbi-button-apply"]=_uci_real:get("style","background","cbi_button_cbi_button_apply")
 -- login help text --
    background["#loginFeg"]=_uci_real:get("style","background","helpWord")
 -- login input window --
    background[".login-tb"]=_uci_real:get("style","background","login_tb")
 -- login inputpassword --
    background[".cbi-input-password"]=_uci_real:get("style","background","input_password")
 -- login page background --
    background[".bg"]=_uci_real:get("style","background","bg")
 -- login border bottom --
    border_bottom["#loginFeg i"] = _uci_real:get("style", "background", "helpWord")
 -- border right  --
    border_right[".btnFeg i"] = _uci_real:get("style", "background", "helpWord")

 -- all forms --
    border[".panel-title,table>tbody>tr>td, table>tbody>tr>th, table>tfoot>tr>td, table>tfoot>tr>th, table>thead>tr>td, table>thead>tr>th"]=_uci_real:get("style","border","panel_title")
 -- all input frams --
    border["input,select,input:disabled"]=_uci_real:get("style","border","input")
 -- window frame --
    border["div.hsVignette,div.hsTip"]=_uci_real:get("style","border","div_hsVignette")
    style = {
        font = font,
        background = background,
        border = border,
        border_bottom = border_bottom,
        border_right = border_right
    }
    result['style'] = style
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function sflog(level, msg)
   local ff = io.open(file, "a+")
   ff:write(string.format("%s %s %s\n", os.date(), level, msg))
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

function set_ping()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local info = arg_list_table["info"]

	if info.ip ~= "" then
		luci.sys.exec("sed -i 's/ipaddr.*/ipaddr %s/g' /etc/watchdog-ping/watchdog_ping.conf" %info.ip)
	end

	if info.period ~= "" then
		luci.sys.exec("sed -i 's/period.*/period %s/g' /etc/watchdog-ping/watchdog_ping.conf" %info.period)
	end

	if info.delay ~= "" then
		luci.sys.exec("sed -i 's/delay.*/delay %s/g' /etc/watchdog-ping/watchdog_ping.conf" %info.delay)
	end

	if info.miss ~= "" then
		luci.sys.exec("sed -i 's/maxdrop.*/maxdrop %s/g' /etc/watchdog-ping/watchdog_ping.conf" %info.miss)
	end

	if info.enable ~= "" then
		luci.sys.exec("sed -i 's/enable.*/enable %s/g' /etc/watchdog-ping/watchdog_ping.conf" %info.enable)
	end

	luci.sys.call("/etc/init.d/watchdog-ping restart >/dev/null 2>/dev/null; sleep 2")

	result = {
		code = 0,
		msg = "OK",
	}

--nixio.syslog("crit", myprint(result))
	sflog("INFO","Do ping!")
	sflog("INFO", arg_list)
luci.http.prepare_content("application/json")
luci.http.write_json(result)
end

function get_ping()
	local info = {
		enable = luci.sys.exec("cat /etc/watchdog-ping/watchdog_ping.conf |grep enable |awk '{print $2}' |tr -d '\n'"),
		ip = luci.sys.exec("cat /etc/watchdog-ping/watchdog_ping.conf |grep ipaddr |awk '{print $2}' |tr -d '\n'"),
		period = luci.sys.exec("cat /etc/watchdog-ping/watchdog_ping.conf |grep period |awk '{print $2}' |tr -d '\n'"),
		delay = luci.sys.exec("cat /etc/watchdog-ping/watchdog_ping.conf |grep delay |awk '{print $2}' |tr -d '\n'"),
		miss = luci.sys.exec("cat /etc/watchdog-ping/watchdog_ping.conf |grep maxdrop |awk '{print $2}' |tr -d '\n'"),
	}

	result = {
		code = 0,
		msg = "OK",
		info = info
	}

	--nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
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
	nixio.syslog("crit", "bottom ip is "..myprint(bottom_ip))

	local top_ip = {}
	for k, v in pairs( bottom_ip  ) do
		top_ip[k] = v + (255 - tonumber(mask[k]))
	end
	nixio.syslog("crit", "top  ip is "..myprint(top_ip))

	local check_ip_val = ip_to_int(check_ip)
	local bottom_ip_val = bottom_ip[1]*2^24 + bottom_ip[2]*2^16 + bottom_ip[3]*2^8 + bottom_ip[4]
	local top_ip_val = top_ip[1]*2^24 + top_ip[2]*2^16 + top_ip[3]*2^8 + top_ip[4]
	if (check_ip_val < top_ip_val and check_ip_val > bottom_ip_val) then
		return true
	else
		return false
	end
end

function get_ipaddr()
	fork_exec("/bin/sh /getIp.sh >/dev/null")
	tmp_ipaddr = _uci_real:get("network", "lan", "tmp_ipaddr")
	result = {
		code = 0,
		msg = "OK",
		tmp_ip = tmp_ipaddr,
	}
	--nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function set_sysinfo()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local info = arg_list_table["info"]
	local code = 0
	local tmp_ip
	result = {
		code = 0,
		msg = "OK",
	}

	nixio.syslog("crit", myprint(arg_list_table))
	if info.lan_ip ~= "" and info.mask ~= "" and info.gateway ~= "" and info.connectmode ~= 0 and info.dhcp_enable ~= "" then
		if not check_ip_legality(info.gateway , info.lan_ip , info.mask) then
			code = sferr.ERROR_NO_GATEWAY_CONFLICT_WITH_LAN_SEGMENT
		end
	end
    if info.connectmode == 1 and code == 0 then --static model
		if _uci_real:get("network", "lan", "ipaddr") ~= info.lan_ip then
			_uci_real:set("network", "lan", "ipaddr", info.lan_ip)
		end
		if _uci_real:get("network", "lan", "netmask") ~= info.mask then
			_uci_real:set("network", "lan", "netmask", info.mask)
		end
		if _uci_real:get("network", "lan", "gateway") ~= info.gateway then
			_uci_real:set("network", "lan", "gateway", info.gateway)
			-- here dns for ntp
		end
		if _uci_real:get("auto_tmp", "tmp",  "dns") ~= info.defaultDNS then
			_uci_real:set("auto_tmp", "tmp", "dns", info.defaultDNS)
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("auto_tmp", "tmp",  "standbyDns") ~= info.standbyDNS then
			_uci_real:set("auto_tmp", "tmp", "standbyDns", info.standbyDNS)
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("uhttpd", "main",  "network_timeout") ~= info.web_timeout then
			_uci_real:set("uhttpd", "main", "network_timeout", info.web_timeout)
		end
		if _uci_real:get("auto_tmp","tmp","connectmode") ~= info.connectmode then
			_uci_real:set("auto_tmp","tmp","connectmode",info.connectmode)
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("auto_tmp","tmp","dhcp_enable") ~= info.dhcp_enable then
			_uci_real:set("auto_tmp","tmp","dhcp_enable",info.dhcp_enable)
			_uci_real:commit("auto_tmp")
    	end
		if _uci_real:get("network","lan","proto") ~= info.dhcp_enable then
			_uci_real:set("network","lan","proto","static")
		end

		if info.web_port then
			local port_list = _uci_real:get_list("uhttpd", "main", "listen_http")
			nixio.syslog("crit", myprint(port_list))
			nixio.syslog("crit", myprint(info.web_port))
			set_port = "0.0.0.0:"..info.web_port
			if set_port  ~= port_list[1] then
				port_list[1] = set_port
				_uci_real:set_list("uhttpd", "main", "listen_http", port_list)
			end
		end
		local changes = _uci_real:changes("network")
		if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) and result.code == 0 then
			nixio.syslog("crit", "change network")
			_uci_real:save("network")
			_uci_real:commit("network")
			_uci_real:load("network")
		end
		fork_exec("sleep 2; /etc/init.d/network restart >/dev/null 2>/dev/null")
	elseif info.connectmode == 0 and code == 0 then --auto model
		if _uci_real:get("auto_tmp","tmp","connectmode") ~= info.connectmode then
			_uci_real:set("auto_tmp","tmp","connectmode",info.connectmode)
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("auto_tmp","tmp","dhcp_enable") ~= info.dhcp_enable then
			_uci_real:set("auto_tmp","tmp","dhcp_enable",info.dhcp_enable)
			_uci_real:commit("auto_tmp")
    	end
		if _uci_real:get("auto_tmp", "tmp",  "dns") ~= info.defaultDNS then
			_uci_real:set("auto_tmp", "tmp", "dns", "")
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("auto_tmp", "tmp",  "standbyDns") ~= info.standbyDNS then
			_uci_real:set("auto_tmp", "tmp", "standbyDns", "")
			_uci_real:commit("auto_tmp")
		end
		if _uci_real:get("network","lan","proto") ~= info.dhcp_enable then
			_uci_real:set("network","lan","proto","dhcp")
		end
		local changes = _uci_real:changes("network")
		if((changes ~= nil) and (type(changes) == "table") and (next(changes) ~= nil)) and result.code == 0 then
			nixio.syslog("crit", "change network")
			_uci_real:save("network")
			_uci_real:commit("network")
			_uci_real:load("network")
		end
		fork_exec("sleep 2; env -i /bin/ubus call network restart >/dev/null 2>/dev/null")
	end
	if _uci_real:get("led", "BTN0", "wifi_enable") ~= info.led then
		_uci_real:set("led", "BTN0", "wifi_enable", info.led)
		_uci_real:commit("led")
		fork_exec("sh -c \"ACTION=released;.  /etc/rc.button/BTN_1 sync\"  >/dev/null 2>/dev/null")
	end
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	nixio.syslog("crit", myprint(result))
	sflog("INFO","system information  configure changed!")
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_sysinfo()
	local listen_httpd = _uci_real:get("uhttpd", "main", "listen_http")
	local connectmode = _uci_real:get("auto_tmp","tmp","connectmode")
    if connectmode == '0' then   --auto
		lan_ip = _uci_real:get("auto_tmp", "tmp", "ipaddr")
		mask = _uci_real:get("auto_tmp", "tmp", "netmask")
		gateway = _uci_real:get("auto_tmp", "tmp", "gateway")
		defaultDNS= _uci_real:get("auto_tmp","tmp","dns")
		standbyDNS = _uci_real:get("auto_tmp","tmp","standbyDns")
	elseif connectmode == '1' then  --static
		lan_ip = _uci_real:get("network", "lan", "ipaddr")
		mask = _uci_real:get("network", "lan", "netmask")
		gateway = _uci_real:get("network", "lan", "gateway")
		defaultDNS= _uci_real:get("auto_tmp","tmp","dns")
		standbyDNS = _uci_real:get("auto_tmp","tmp","standbyDns")
	end
	local info = {
		web_port = string.sub(listen_httpd[1], string.find(listen_httpd[1], ":")+1, #listen_httpd[1]),
		web_timeout = _uci_real:get("uhttpd", "main", "network_timeout"),
		led = _uci_real:get("led", "BTN0", "wifi_enable"),
		dhcp_enable = _uci_real:get("auto_tmp","tmp","dhcp_enable"),
		connectmode = connectmode,
		lan_ip = lan_ip,
		mask = mask,
		gateway = gateway,
		defaultDNS = defaultDNS,
		standbyDNS = standbyDNS,
	}

	result = {
		code = 0,
		msg = "OK",
		info = info
	}

	--nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
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

function split( str,reps )
	local resultStrList = {}
	string.gsub(str,'[^'..reps..']+',function ( w )
		table.insert(resultStrList,w)
	end)
	return resultStrList
end

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

function sys_reboot(params)
    local reset_shortest_time = 0
    --if sysutil.sane("/tmp/reset_shortest_time") then
	if nixio.fs.access("/tmp/reset_shortest_time") then
        reset_shortest_time  = tonumber(nixio.fs.readfile("/tmp/reset_shortest_time"))
    else
        reset_shortest_time = 0
    end
    if os.time() > reset_shortest_time then
        --sysutil.sendSystemEvent(params.event)
        --sysutil.resetAllDevice()
        fork_exec(params.cmd)
        local reset_interval = 30
        reset_shortest_time = reset_interval + os.time()
        local f = nixio.open("/tmp/reset_shortest_time", "w", 600)
        f:writeall(reset_shortest_time)
        f:close()
    end
end

function get_zones()
    local czones = {}
    for _, v in ipairs(zones.TZ_NEW) do
        table.insert(czones, v[1])
    end

    local result = {
        code = 0,
        msg = "OK",
        zones = czones, --时区
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function get_date()
    local z2 = luci.sys.exec("cat /etc/TZ"):match("^([^%s]+)")
    local czones = {}
	local ntp_list = {}
    for _, z in ipairs(zones.TZ_NEW) do
        table.insert(czones, z[1])
        if z[2] == z2 then z2 = z[1] end
    end

	ntp_list = _uci_real:get_list("system", "ntp", "server")
    local result = {
        code = 0,
        msg = "OK",
        zone = z2, --时区
        zones = czones,
        date = os.time(), --long 前端通过具体数值做转换
		ntp_list = ntp_list
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_date()
    --通过 luci.http.content() 获取json字符串参数
    --[[
    local params = {
        zone = "?" --时区
    }
    --]]
    local date_json = luci.http.content()
    local date_table = json.decode(date_json)

    local zonename = date_table.zone

    for _, z in ipairs(zones.TZ_NEW) do
        if z[1] == date_table.zone then date_table.zone = z[2] break end
    end

    luci.sys.exec("echo %s > /etc/TZ" %date_table.zone)

    _uci_real:foreach("system","system",
    function(s)
        if(s["hostname"] ~= nil ) then
            _uci_real:set("system", s[".name"], "zonename", zonename)
            _uci_real:set("system", s[".name"], "timezone", date_table.zone)
        end
    end)

    if date_table.ntp_list then
        _uci_real:set_list("system", "ntp", "server", date_table.ntp_list)
        _uci_real:save("system")
        _uci_real:commit("system")
        _uci_real:load("system")
        -- let time ntp restart and set time to kernel
        luci.sys.call("env -i /etc/init.d/sysntpd restart >/dev/null 2>/dev/null")
        luci.sys.call("env -i /etc/init.d/system restart >/dev/null 2>/dev/null")
    else
        _uci_real:save("system")
        _uci_real:commit("system")
    end

    local result = {
        code = 0,
        msg = "OK",
    }

    nixio.syslog("crit", myprint(result))
	sflog("INFO","date configure changed!")
	sflog("INFO", date_json)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_version()
    local boardinfo = luci.util.ubus("system", "board")
    local strlist = split(boardinfo.release.description, ' ')
    local result = {
        code = 0,
        msg = "OK",
        hardware = mainp.getHardware(), --硬件版本
        software = strlist[3] or { }  --软件版本
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function reset()
    local result = {
        code = 0,
        msg = "OK"
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    local params = {
		cmd = "sleep 1; killall dropbear uhttpd; sleep 1; jffs2reset -y && reboot",
		--event = sysutil.SYSTEM_EVENT_RESET
    }
    fork_exec("source /etc/rc.button/blink; blink 600 1")
	sflog("INFO","Do reset!")
    sys_reboot(params)
end

function restart()
    local result = {
        code = 0,
        msg = "OK"
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    local params = {
		cmd = "sleep 2;reboot",
		--event = sysutil.SYSTEM_EVENT_REBOOT
    }
	sflog("INFO","Do restart!")
    sys_reboot(params)
end

function set_password()
    --通过 luci.http.content() 获取json字符串参数
    --[[
    local params = {
        passwordold = "?", --旧密码
        passwordnew = "?" --新密码
    }
    --]]
    local passwd_json = luci.http.content()
    local passwd_table = json.decode(passwd_json)
    local result = {
        code = 0,
        msg = "OK"
    }
    if luci.sys.user.checkpasswd("admin", passwd_table.passwordold) then
        stat = luci.sys.user.setpasswd("admin", passwd_table.passwordnew)
    else
		result.code = sferr.ERROR_NO_OLDPASSWORD_INCORRECT
		result.msg = sferr.getErrorMessage(result.code)
    end
    nixio.syslog("crit", myprint(result))
	sflog("INFO","Change password!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_log()
    local syslog = sflog_read()
    local content_list = split(syslog, '\n')
    local result = {
        code = 0,
        msg = "OK",
        logs = {--数组
        --索引 index
        --类型 type
        --内容 content
        }
    }
    local index = 1
    for i = 1, #content_list do
        local year = string.sub(content_list[i], 21, 24)
        if string.match(year, string.sub(os.date("%c"), 21, 24)) == year then
            table.insert(result.logs, {index = index, type = "INFO", content = content_list[i]})
            index = index + 1
        end
    end
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function  clean_log()
    local result = {
        code = 0,
        msg = "OK"
    }
    luci.util.exec("/etc/init.d/log restart")
    nixio.syslog("crit", myprint(result))
	sflog("INFO","Clean log!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end


function download_log()
    local log_cmd  = "tar -cz - /tmp/sf_log.txt"
    local reader = ltn12_popen(log_cmd)
    luci.http.header('Content-Disposition', 'attachment; filename="log-%s-%s.tar.gz"' % {
        luci.sys.hostname(), os.date("%Y-%m-%d")})
	sflog("INFO","Download log!")
    luci.http.prepare_content("application/x-targz")
    luci.ltn12.pump.all(reader, luci.http.write)
end

--[[
function ota_upgrade()
    local result = {
        code = 0,
        msg = "OK"
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    local image_tmp   = "/tmp/firmware.img"

    local function image_checksum()
        return (luci.sys.exec("md5sum %q" % image_tmp):match("^([^%s]+)"))
    end

    local remote_info = {}
    remote_info= sysutil.getOTAInfo()
    if (not remote_info) then
        --undownloaded
        result.code = -1
        result.msg = "OTA file is not downloaded successfully, please check your network connection"
    elseif (remote_info == 1) then
        --404 error
        result.code = -1
        result.msg = "Not Found"
    else
        local otaversion = remote_info["otaversion"]
        local romversion = sysutil.getRomVersion()
        if (not string.find(romversion, otaversion)) then
            local url  = remote_info["url"]
            luci.util.exec(" curl -k -o %q  %s" %{image_tmp,url})
            local local_checksum = image_checksum()
            local ota_checksum = remote_info["checksum"]
            if (ota_checksum ~= local_checksum) then
                nixio.fs.unlink(image_tmp)
            end
        end
    end
    sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_UPGRADE)
    sysutil.resetAllDevice()
    fork_exec("sleep 5; killall dropbear uhttpd; sleep 1; /sbin/sysupgrade -n %q" %{ image_tmp })
end
]]
function upgrade()
    --必须处理formdata数据，即上传的镜像，判定镜像是否正确；不正确需要给非0返回值
    --读取文件示例如下
    local image_tmp   = "/tmp/firmware.img"
    local fp
    local result = {
        code = 0,
        msg = "OK"
    }

    local function image_supported()
        return (os.execute("sysupgrade -T %q >/dev/null" % image_tmp) == 0)
    end

    luci.http.setfilehandler(
        function(meta, chunk, eof)
            if not fp then
                if meta and meta.name == "image" then
                    fp = io.open(image_tmp, "w")
                end
            end
            if chunk then
                fp:write(chunk)
            end
            if eof then
                fp:close()
            end
        end
    )

    local value = luci.http.formvalue()
    local image = value.image

    if image_supported() then
        --sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_UPGRADE)
        --sysutil.resetAllDevice()
        fork_exec("source /etc/rc.button/blink; blink 600 1")
        fork_exec("sleep 5; killall dropbear uhttpd; sleep 1; /sbin/sysupgrade %q" %{ image_tmp })
		sflog("INFO","Do upgrade!")
    else
        result.code = -1
	result.msg = "Invalid image type!"
		sflog("INFO","upgrade, Invalid image type!")
    end

    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function import_config()
    local restore_cmd = "/config.tar.gz"
    local fp
    luci.http.setfilehandler(
            function(meta, chunk, eof)
                if not fp then
                    if meta and meta.name == "archive" then
                        fp = io.open(restore_cmd, "w")
                    end
                end
                if chunk then
                    fp:write(chunk)
                end
                if eof then
                    fp:close()
                end
            end
    )
    local upload = luci.http.formvalue("archive")

    local result = {
        code = 0,
        msg = "OK"
    }
    nixio.syslog("crit", myprint(result))
	sflog("INFO","Import configure!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
    if upload and #upload > 0 then
        fork_exec("tar -xzvf /config.tar.gz;  rm /config.tar.gz")
        luci.sys.reboot()
    end
end

function export_config()
    local backup_cmd  = "sysupgrade --create-backup - 2>/dev/null"
    local reader = ltn12_popen(backup_cmd)
    luci.http.header('Content-Disposition', 'attachment; filename="backup-%s-%s.tar.gz"' % {
        luci.sys.hostname(), os.date("%Y-%m-%d")})
	sflog("INFO","Export configure!")
    luci.http.prepare_content("application/x-targz")
    luci.ltn12.pump.all(reader, luci.http.write)
end

function ltn12_popen(command)

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid > 0 then
        fdo:close()
        local close
        return function()
            local buffer = fdi:read(2048)
            local wpid, stat = nixio.waitpid(pid, "nohang")
            if not close and wpid and stat == "exited" then
                close = true
            end

            if buffer and #buffer > 0 then
                return buffer
            elseif close then
                fdi:close()
                return nil
            end
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exec("/bin/sh", "-c", command)
    end
end

function get_lang()
    local values = _uci_real:get_all("luci", "languages")
    local lang = _uci_real:get("luci", "main", "lang")
    local data = {}
    for k, v in pairs(values) do
        if ( k ~= ".name" ) and ( k ~= ".type" ) and ( k ~= ".anonymous") then
            table.insert(data, v)
        end
        if ( k == lang ) then
          lang_str = v
        end
    end
    local result = {
        code = 0,
        msg = "OK",
        data = data,
        lang = lang_str
    }
    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function set_lang()
    --[[
    local params = {
        lang = "English"
    }
    --]]
    local diagnostic_tool_json = luci.http.content()
    local arg_table = json.decode(diagnostic_tool_json)
    local lang = arg_table.lang
    local lang_key = _uci_real:get("luci", "main", "lang")
    local result = {
        code = 0,
        msg = "OK",
    }
    local values = _uci_real:get_all("luci", "languages")
    for k, v in pairs(values) do
    nixio.syslog("crit", myprint(v))
        if ( lang == v ) and ( lang_key ~= k) then
            _uci_real:set("luci", "main", "lang", k)
            _uci_real:save("luci")
            _uci_real:commit("luci")
        end
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end
