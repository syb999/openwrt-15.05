--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/8
-- Time: 9:14
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.systemnew", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require("luci.json")
local sysutil = require "luci.siwifi.sf_sysutil"
local zones = require "luci.sys.zoneinfo"
local sferr = require "luci.siwifi.sf_error"
local fs = require "nixio.fs"
local deviceImpl = require("luci.siwifi.deviceImpl")
local networknewImpl = require("luci.siwifi.networkImpl")

local disp = require "luci.dispatcher"
function index()
local uci = require("luci.model.uci").cursor()
local wds_enable = false;
	uci:foreach("wireless","wifi-iface",
		function(s)
			if(s["ifname"] == "sfi0" or s["ifname"] == "sfi1"
				or s["ifname"] == "rai0" or s["ifname"] == "rai1") then
				wds_enable = true
			end
		end)

    entry({"admin", "systemnew"}, firstchild(), _("Manage"), 63).logo = "system";
    entry({"admin", "systemnew", "time"}, template("new_siwifi/device_manager/time") , _("time & language"), 1);
    if (wds_enable == false) then
        entry({"admin", "systemnew", "software_upgrade"}, template("new_siwifi/device_manager/software_upgrade") , _("software upgrading"), 2);
    else
        entry({"admin", "systemnew", "software_upgrade"}, call("goto_default_page"));
    end
    entry({"admin", "systemnew", "reset_page"}, template("new_siwifi/device_manager/reset") , _("factory reset"), 3);
    if (wds_enable == false) then
        entry({"admin", "systemnew", "import_backup"}, template("new_siwifi/device_manager/import_backup") , _("backup"), 4);
        entry({"admin", "systemnew", "reboot"}, template("new_siwifi/device_manager/reboot") , _("reboot"), 5);
    else
        entry({"admin", "systemnew", "import_backup"}, call("goto_default_page"));
        entry({"admin", "systemnew", "reboot"}, call("goto_default_page"));
    end
    entry({"admin", "systemnew", "modify_password"}, template("new_siwifi/device_manager/modify_password") , _("modify password"), 6);
    entry({"admin", "systemnew", "debug"}, template("new_siwifi/device_manager/debug") , _("diagnostic tools"), 7);
    entry({"admin", "systemnew", "syslog"}, template("new_siwifi/device_manager/syslog") , _("system log"), 8);
    entry({"admin", "systemnew", "get_date"}, call("get_date")).leaf = true;
    entry({"admin", "systemnew", "set_date"}, call("set_date")).leaf = true;
    entry({"admin", "systemnew", "get_version"}, call("get_version")).leaf = true;
    entry({"admin", "systemnew", "reset"}, call("reset")).leaf = true;
    entry({"admin", "systemnew", "restart"}, call("restart")).leaf = true;
    entry({"admin", "systemnew", "set_password"}, call("set_password")).leaf = true;
    entry({"admin", "systemnew", "get_log"}, call("get_log")).leaf = true;
    entry({"admin", "systemnew", "clean_log"}, call("clean_log")).leaf = true;
	entry({"admin", "systemnew", "download_log"}, call("download_log")).leaf = true;
    entry({"admin", "systemnew", "ota_upgrade"}, call("ota_upgrade")).leaf = true;
    entry({"admin", "systemnew", "ac_ota_upgrade"}, call("ac_ota_upgrade")).leaf = true;
    entry({"admin", "systemnew", "upgrade"}, call("upgrade")).leaf = true;
    entry({"admin", "systemnew", "get_zones"}, call("get_zones")).leaf = true;
    entry({"admin", "systemnew", "import_config"}, call("import_config")).leaf = true;
    entry({"admin", "systemnew", "export_config"}, call("export_config")).leaf = true;
    entry({"admin", "systemnew", "start_diagnostic_tool"}, call("start_diagnostic_tool")).leaf = true;
    entry({"admin", "systemnew", "stop_diagnostic_tool"}, call("stop_diagnostic_tool")).leaf = true;
    entry({"admin", "systemnew", "get_diagnostic_result"}, call("get_diagnostic_result")).leaf = true;
    entry({"admin", "systemnew", "get_warn"}, call("get_warn")).leaf = true;
    entry({"admin", "systemnew", "set_warn"}, call("set_warn")).leaf = true;
    entry({"admin", "systemnew", "get_lang"}, call("get_lang")).leaf = true;
    entry({"admin", "systemnew", "set_lang"}, call("set_lang")).leaf = true;
    entry({"admin", "systemnew", "ap_upgrade"}, call("ap_upgrade")).leaf = true;
    entry({"admin", "systemnew", "ap_upgrade_check"}, call("ap_upgrade_check")).leaf = true;
    entry({"admin", "systemnew", "refresh_ap_table"}, call("refresh_ap_table")).leaf = true;
    entry({"admin", "systemnew", "get_style"}, call("get_style")).leaf = true;
    entry({"admin", "systemnew", "get_auto_ota"}, call("get_auto_ota")).leaf = true;
    entry({"admin", "systemnew", "set_auto_ota"}, call("set_auto_ota")).leaf = true;
end

OTA_DOWNLOAD		= 1
AP_OTA_DOWNLOAD		= 2
AP_OTA_UPGRADE		= 3
NO_AP_UPGRADE		= 4
AP_MAC_LIST			= 5
SEND_CMD_AP_ERR		= 6
AP_FLASH			= 7
AP_UPGRADE_MAC_ERR	= 8
AP_UPGRADE_TIMEOUT	= 9
AP_UPGRADE_DONE		= 10
AP_DOWNLOAD_ERR		= 11
OTA_FLASH			= 12
OTA_DOWNLOAD_ERR	= 13
OTA_NOT_RUNNING		= 14

function _(str)
    return disp._(str)
end

function translate(str)
    return disp.translate(str)
end

function get_ota_message(ota_status)
    local ota_list = {}

	ota_list[1]  = _("ota download")
	ota_list[2]  = _("ap ota download")
	ota_list[3]  = _("ap ota upgrade")
	ota_list[4]  = _("no ap need upgrade")
	ota_list[5]  = _("ap mac list")
	ota_list[6]  = _("send upgrade to ap error")
	ota_list[7]  = _("ap flash")
	ota_list[8]  = _("ap mac upgrade error")
	ota_list[9]  = _("ap upgrade timeout")
	ota_list[10] = _("ap upgrade done")
	ota_list[11] = _("ap download error")
	ota_list[12] = _("ota flash")
	ota_list[13] = _("OTA file download error")
	ota_list[14] = _("OTA not run")
	if (ota_list[ota_status] == nil) then
		return translate(_("unknown error"))
	else
		return translate(ota_list[ota_status])
    end
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
    if sysutil.sane("/tmp/reset_shortest_time") then
        reset_shortest_time  = tonumber(nixio.fs.readfile("/tmp/reset_shortest_time"))
    else
        reset_shortest_time = 0
    end
    if os.time() > reset_shortest_time then
        sysutil.sendSystemEvent(params.event)
        sysutil.resetAllDevice()
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
    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

end

function get_date()
    local z2 = luci.sys.exec("cat /etc/TZ"):match("^([^%s]+)")
    local czones = {}
    for _, z in ipairs(zones.TZ_NEW) do
        table.insert(czones, z[1])
        if z[2] == z2 then z2 = z[1] end
    end

    local result = {
        code = 0,
        msg = "OK",
        zone = z2, --时区
        zones = czones,
        date = os.time(), --long 前端通过具体数值做转换
    }
    sysutil.nx_syslog(myprint(result), 1)
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
        if(s[".name"]) then
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

    sysutil.sflog("INFO","date configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_version()
    local boardinfo = luci.util.ubus("system", "board")
    local strlist = split(boardinfo.release.description, ' ')
    local result = {
        code = 0,
        msg = "OK",
        hardware = sysutil.getHardware(), --硬件版本
        software = strlist[3] or { }  --软件版本
    }
    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function reset()
    local result = {
        code = 0,
        msg = "OK"
    }
    sysutil.sflog("INFO","configure reset!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    local params = {
	cmd = "sleep 2; killall dropbear uhttpd; sleep 1; jffs2reset -y && reboot",
	event = sysutil.SYSTEM_EVENT_RESET
    }
    sys_reboot(params)
end

function restart()
    local result = {
        code = 0,
        msg = "OK"
    }
    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    local params = {
	cmd = "sleep 2;reboot",
	event = sysutil.SYSTEM_EVENT_REBOOT
    }
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
    local code = 0
    code = deviceImpl.setpasswd(passwd_table)
    sysutil.set_easy_return(code, nil)
end

function get_log()
    local syslog = sysutil.sflog_read()
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
    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function  clean_log()
    local result = {
        code = 0,
        msg = "OK"
    }
	sysutil.sflog_clean()
    sysutil.sflog("INFO","clean log!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function download_log()
	local log_cmd  = "tar -cz - /tmp/sf_log.txt"
	local reader = ltn12_popen(log_cmd)
	luci.http.header('Content-Disposition', 'attachment; filename="log-%s-%s.tar.gz"' % {
		luci.sys.hostname(), os.date("%Y-%m-%d")})
    sysutil.sflog("INFO","Download log!")
	luci.http.prepare_content("application/x-targz")
	luci.ltn12.pump.all(reader, luci.http.write)
end

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
    local keep = value.keep

    if image_supported() then
        sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_UPGRADE)
        sysutil.resetAllDevice()
        fork_exec("sleep 5; killall dropbear uhttpd; sleep 1; /sbin/sysupgrade %s %q" %{ keep, image_tmp })
    else
        result.code = sferr.ERROR_NO_IMG_TYPE_ERROR
	    result.msg = sferr.getErrorMessage(result["code"])
    end

    sysutil.nx_syslog(myprint(result), 1)
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
    sysutil.sflog("INFO","import config!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
    if upload and #upload > 0 then
        fork_exec("tar -xzvf /config.tar.gz;  rm /config.tar.gz")
        sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_REBOOT)
        sysutil.resetAllDevice()
        luci.sys.reboot()
    end
end

function export_config()
    local backup_cmd  = "sysupgrade --create-backup - 2>/dev/null"
    local reader = ltn12_popen(backup_cmd)
    luci.http.header('Content-Disposition', 'attachment; filename="backup-%s-%s.tar.gz"' % {
        luci.sys.hostname(), os.date("%Y-%m-%d")})
    luci.http.prepare_content("application/x-targz")
    luci.ltn12.pump.all(reader, luci.http.write)
    sysutil.sflog("INFO","export config!")
end

--[[
local params = {
	action = "ping", -- 操作类型，"ping"或"tracert"
	ipaddr = "", -- IP地址或域名
	pingamount = "", -- ping包数目
	size = "", -- ping包大小
	timeout = "", -- ping包超时
	tracertamount = "" -- tracert跳数
}
--]]

function stop_diagnostic_tool()
    local diagnostic_tool_json = luci.http.content()
    local arg_table = json.decode(diagnostic_tool_json)
    local result = {
        code = 0,
        msg = "OK",
    }

    sysutil.fork_exec("kill `ps | grep ping | awk '{print $1}'`")
    sysutil.fork_exec("kill `ps | grep traceroute | awk '{print $1}'`")

    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function start_diagnostic_tool()
    local diagnostic_tool_json = luci.http.content()
    local arg_table = json.decode(diagnostic_tool_json)
    local log = ""
    local result = {
        code = 0,
        msg = "OK",
        info = {
            --数组 诊断结果
        }
    }
    luci.util.exec("kill `ps | grep ping | awk '{print $1}'`")
    luci.util.exec("kill `ps | grep traceroute | awk '{print $1}'`")
    if arg_table.action == "ping" then
        sysutil.fork_exec("ping %s -c %s -s %s -W %s > /tmp/diagnostic.log" % {arg_table.ipaddr, arg_table.pingamount, arg_table.size, arg_table.timeout})
        log = nixio.fs.readfile("/tmp/diagnostic.log")
    elseif arg_table.action == "tracert" then
        sysutil.fork_exec("traceroute %s -m %s -w %s > /tmp/diagnostic.log" % {arg_table.ipaddr, arg_table.tracertamount, 1})
        log = nixio.fs.readfile("/tmp/diagnostic.log")
    end
    table.insert(result.info, log)

    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_diagnostic_result()
    local result = {
        code = 0,
        msg = "OK",
        info = {
            --数组 诊断结果
        }
    }
    local log = nixio.fs.readfile("/tmp/diagnostic.log")
    if log == "" then
	    luci.sys.call("echo Destination Host Unreachable! > /tmp/diagnostic.log")
    end
    table.insert(result.info, log)

    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
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

function ota_upgrade()
	local result = {}
	local code   = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
    code,result = networknewImpl.ota_upgrade(arg_list_table)
	sysutil.set_easy_return(code, result)
end

function get_ota_update_status()
	local status = {}
	if sysutil.sane("/tmp/upgrade_status") then
		local info  = json.decode( fs.readfile("/tmp/upgrade_status") )
		status.status = info.status
		status.msg = info.msg
	else
		status.status = OTA_NOT_RUNNING
		status.msg = "ota upgrade is not running"
	end
	return status
end

function get_web_status(ota_status, mode)
	local web_status
	if ota_status == NO_AP_UPGRADE or ota_status == SEND_CMD_AP_ERR or ota_status == AP_UPGRADE_TIMEOUT or ota_status == AP_UPGRADE_DONE  then
		if mode == 2 then
			web_status = 3
		else
			web_status = 2
		end
	end
	if ota_status == OTA_DOWNLOAD or ota_status == AP_OTA_DOWNLOAD then
		web_status = 1
	elseif ota_status ==  AP_OTA_UPGRADE or ota_status == AP_MAC_LIST or ota_status == AP_FLASH  or ota_status == AP_UPGRADE_MAC_ERR or ota_status == OTA_FLASH or ota_status == AP_DOWNLOAD_ERR then
		web_status = 2
	else
		web_status = 3
	end
	return web_status
end

function ac_ota_upgrade()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local check = arg_list_table["check"]
	local mode = arg_list_table["mode"]

	if mode == nil  then
		if check == 1 then
			mode = 3
		else
			mode = 0
		end
	end

	code, result = networknewImpl.ac_ota_upgrade_impl(check, mode)

	sysutil.set_easy_return(code, result)
end

function set_warn()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local enable = arg_list_table["enable"]

    sysutil.nx_syslog(myprint(arg_list_table), 1)
	local cmd = enable == 1 and "start_all" or "stop_all"

	_uci_real:set("basic_setting", "onlinewarn", "enable", enable)
	_uci_real:save("basic_setting" )
	_uci_real:commit("basic_setting")
	luci.util.exec("online-warn "..cmd)

	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)
	sysutil.sflog("INFO","Device warning function is %s!" %{tostring(enable) == "1" and "on" or "off"})

    sysutil.nx_syslog(myprint(result), 1)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_warn()
	local result = {}
	local code = 0
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)

	result["enable"] = tonumber(_uci_real:get("basic_setting", "onlinewarn", "enable") or 0)
	result["code"] = code
	result["msg"]  = sferr.getErrorMessage(code)

    sysutil.nx_syslog(myprint(result), 1)
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
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
    sysutil.nx_syslog(myprint(result), 1)
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
		sysutil.nx_syslog(myprint(result), 1)
		if ( lang == v ) and ( lang_key ~= k) then
			_uci_real:set("luci", "main", "lang", k)
			_uci_real:save("luci")
			_uci_real:commit("luci")
		end
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function ap_upgrade()
	local upgrade_status = 0
	local image_tmp   = "/tmp/ap_firmware.img"
	local fp
	local download_mac_list = " "
	local mac_update_list = {}
	local ret = 0
	local code = 0
	local result = {}

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
	--	local check  = value.check
	--	if (check ~= 1) then
	if image_supported() then

		local image = value.image
		local ap_checksum_info = luci.util.exec("md5sum %s" %{image_tmp})
		local ap_checksum = string.match(ap_checksum_info,"([^%s]+).*")
		local mac_list={}

		_uci_real:foreach("capwap_devices","device", function(s)
			if s.status == "1" and  s.updating ~= "1" and  s.updating ~= "2" then
				download_mac_list=download_mac_list.." "..s.mac
				mac_update_list[#mac_update_list+1] = s.mac
			end
		end)

		if #mac_update_list == 0 then
				sysutil.nx_syslog("no ap need upgrade: ", nil)
				code = sferr.ERROR_NO_AP_UPGRADE
		else
			luci.sys.call("killall siupserver")
			luci.sys.call("siupserver %s &"%{image_tmp})
			-- 0 means no version
			ret = luci.sys.call("wtp_update %s %s %s &"%{"0" , ap_checksum, download_mac_list})
			if ret ~= 0 then
				--toDO error
				sysutil.nx_syslog("send cmd to ap err: "..tostring(ret), 1)
				code = sferr.ERROR_SEND_CMD_AP_ERR
			end

			sysutil.nx_syslog("ap updating is start", nil)
			result["update_list"] = mac_update_list
		end
	else
		code = sferr.ERROR_NO_IMG_TYPE_ERROR
	end
	sysutil.set_easy_return(code,result)
end

function ap_upgrade_check()
	local result = {}
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local mac_update_list= arg_list_table["update_list"]
	local web_status = 0
	local code = 0
	local uci = require "luci.model.uci".cursor()
	local done = 1
	local mac_update_fail = {}
	for i=1,#mac_update_list do
		updating = uci:get("capwap_devices", mac_update_list[i],"updating")
		if updating == "0" or updating == "1" or updating == "2" then
			--not finish
			done = 0
		end
		if updating == "3" or updating == "5" then
			mac_update_fail[#mac_update_fail + 1] = mac_update_list[i]
		end
	end

	result["fail_list"] = mac_update_fail
	result["upgrade_status"] = done

	if(done == 1) then
		luci.sys.call("killall siupserver")
		luci.sys.call("rm /tmp/ap_firmware.img")

	end

	sysutil.set_easy_return(code, result)
end

function refresh_ap_table()
	local mac_list={}

	_uci_real:foreach("capwap_devices","device", function(s)
		if s.status == "1" then
			mac_list[#mac_list+1] = {}
			mac_list[#mac_list]["mac"] = s.mac
			mac_list[#mac_list]["softVersion"] = s.firmware_version
		end
	end)
	local result = {
		devices = mac_list
	}
	sysutil.set_easy_return(sferr.SUCCESS_EXEC,result)
end

function get_style()
    local result = {
        code = 0,
        msg = "OK",
        style = sysutil.getStyle()
    }
    sysutil.nx_syslog(myprint(result), 1)
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_auto_ota()
    local result = {}
    local code = 0
    local enable = _uci_real:get("basic_setting", "auto_ota", "enable")
    if enable == nil then
        result["enable"] = 1
    else
        result["enable"] = enable
    end
    sysutil.set_easy_return(code, result)
end

function set_auto_ota()
	local arg_list_table = get_arg_list()
    local enable = arg_list_table["enable"]
    local code = 0

    local sta = _uci_real:get("basic_setting", "auto_ota", "enable")
    if sta == nil then
        _uci_real:set("basic_setting", "auto_ota", "setting")
    end
    if enable ~= sta then
        _uci_real:set("basic_setting", "auto_ota", "enable", enable)
        _uci_real:save("basic_setting")
        _uci_real:commit("basic_setting")
    end
    sysutil.set_easy_return(code, nil)
end

function get_arg_list()
	local arg_list, data_len = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	return arg_list_table
end
