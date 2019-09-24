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

function index()
    entry({"admin", "systemnew"}, firstchild(), _("设备管理"), 63).logo = "system";
    entry({"admin", "systemnew", "time"}, template("new_siwifi/device_manager/time") , _("时间设置"), 1);
    entry({"admin", "systemnew", "software_upgrade"}, template("new_siwifi/device_manager/software_upgrade") , _("软件升级"), 2);
    entry({"admin", "systemnew", "reset_page"}, template("new_siwifi/device_manager/reset") , _("恢复出厂设置"), 3);
    entry({"admin", "systemnew", "import_backup"}, template("new_siwifi/device_manager/import_backup") , _("载入和备份"), 4);
    entry({"admin", "systemnew", "reboot"}, template("new_siwifi/device_manager/reboot") , _("重启路由器"), 5);
    entry({"admin", "systemnew", "modify_password"}, template("new_siwifi/device_manager/modify_password") , _("修改登录密码"), 6);
    entry({"admin", "systemnew", "debug"}, template("new_siwifi/device_manager/debug") , _("诊断工具"), 7);
    entry({"admin", "systemnew", "syslog"}, template("new_siwifi/device_manager/syslog") , _("系统日志"), 8);
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
    entry({"admin", "systemnew", "upgrade"}, call("upgrade")).leaf = true;
    entry({"admin", "systemnew", "get_zones"}, call("get_zones")).leaf = true;
    entry({"admin", "systemnew", "import_config"}, call("import_config")).leaf = true;
    entry({"admin", "systemnew", "export_config"}, call("export_config")).leaf = true;
    entry({"admin", "systemnew", "start_diagnostic_tool"}, call("start_diagnostic_tool")).leaf = true;
    entry({"admin", "systemnew", "get_diagnostic_result"}, call("get_diagnostic_result")).leaf = true;
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
    nixio.syslog("crit", myprint(result))
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
        if(s["hostname"] == "SiWiFi") then
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
        hardware = strlist[2] or { }, --硬件版本
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
    nixio.syslog("crit", myprint(result))
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
    local result = {
        code = 0,
        msg = "OK"
    }
    if luci.sys.user.checkpasswd("admin", passwd_table.passwordold) then
        stat = luci.sys.user.setpasswd("admin", passwd_table.passwordnew)
    else
	result.code = -1
	result.msg = "error old passwd!"
    end
    sysutil.sflog("INFO","password configure changed!")
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
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
    nixio.syslog("crit", myprint(result))
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

function ota_upgrade()
    local result = {
        code = 0,
        msg = "OK"
    }

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
				result.code = -1
				result.msg = "OTA file is not right"
            end
        end
    end

    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
	if result.code ~= 0 then
		return
	end
    sysutil.sendSystemEvent(sysutil.SYSTEM_EVENT_UPGRADE)
    sysutil.resetAllDevice()
    fork_exec("sleep 5; killall dropbear uhttpd; sleep 1; /sbin/sysupgrade -n %q" %{ image_tmp })
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
        result.code = -1
	result.msg = "Invalid image type!"
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
    if arg_table.action == "ping" then
        sysutil.fork_exec("ping %s -c %s -s %s -W %s > /tmp/diagnostic.log" % {arg_table.ipaddr, arg_table.pingamount, arg_table.size, arg_table.timeout})
        log = nixio.fs.readfile("/tmp/diagnostic.log")
    elseif arg_table.action == "tracert" then
        sysutil.fork_exec("traceroute %s -m %s -w %s > /tmp/diagnostic.log" % {arg_table.ipaddr, arg_table.tracertamount, 1})
        log = nixio.fs.readfile("/tmp/diagnostic.log")
    end
    table.insert(result.info, log)

    nixio.syslog("crit", myprint(result))
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

    nixio.syslog("crit", myprint(result))
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
