module("luci.controller.voip", package.seeall)

function index()
    entry({"admin", "services", "voip"}, alias("admin", "services", "voip", "status"), "VoIP", 60)
    entry({"admin", "services", "voip", "status"}, template("voip/status"), "Status", 1)
    entry({"admin", "services", "voip", "status_data"}, call("action_status_data"), nil)
    entry({"admin", "services", "voip", "trunk"}, cbi("voip/trunk"), "SIP Trunk", 2)
    entry({"admin", "services", "voip", "extensions"}, cbi("voip/extension"), "Extensions", 3)
    entry({"admin", "services", "voip", "record_settings"}, cbi("voip/record_settings"), "Record Settings", 4)
    entry({"admin", "services", "voip", "record_files"}, template("voip/record_files"), "Record Files", 5)
    entry({"admin", "services", "voip", "record_files_data"}, call("action_record_files_data"), nil)
    entry({"admin", "services", "voip", "download_record"}, call("action_download_record"), nil)
    entry({"admin", "services", "voip", "delete_record"}, call("action_delete_record"), nil)
    entry({"admin", "services", "voip", "restart"}, call("action_restart"), nil)
    entry({"admin", "services", "voip", "apply"}, call("action_apply"), nil)
end

function action_status_data()
    luci.http.prepare_content("application/json")
    
    local data = {
        peers = {},
        calls = {}
    }
    
    local f = io.popen("asterisk -rx 'sip show peers' 2>/dev/null")
    if f then
        local in_peer_section = false
        for line in f:lines() do
            if line:match("Name/username") then
                in_peer_section = true
            elseif in_peer_section and not line:match("^-") and not line:match("sip peers") then
                local name = line:match("^(%d+)/")
                if name then
                    local host = line:match("^%S+%s+(%S+)")
                    if host == "(Unspecified)" or host == "" then
                        host = "(Unspecified)"
                    end
                    local status = line:match("OK") and "OK" or 
                                   line:match("UNKNOWN") and "UNKNOWN" or 
                                   line:match("UNREACHABLE") and "UNREACHABLE" or "Unknown"
                    table.insert(data.peers, {name=name, host=host, status=status})
                end
            end
        end
        f:close()
    end
    
    f = io.popen("asterisk -rx 'core show channels' 2>/dev/null")
    if f then
        for line in f:lines() do
            if line:match("SIP/%d+.*%d+@internal") then
                local caller = line:match("SIP/(%d+)")
                local callee = line:match("(%d+)@internal")
                if caller and callee then
                    table.insert(data.calls, {caller = caller, callee = callee})
                end
            end
        end
        f:close()
    end
    
    luci.http.write_json(data)
end

function action_record_files_data()
    luci.http.prepare_content("application/json")
    
    local uci = require("luci.model.uci").cursor()
    local record_dir = uci:get_first("voip", "record", "dir") or "/tmp/voip_records"
    
    local data = {
        dir = record_dir,
        files = {},
        total_size = 0,
        total_count = 0
    }
    
    local f = io.popen("ls -lt \"" .. record_dir .. "\" 2>/dev/null | grep -E '\\.(wav|gsm)$' | awk '{print $9, $5}'")
    if f then
        for line in f:lines() do
            local filename, size = line:match("^([^%s]+)%s+(%d+)")
            if filename and size then
                local parts = {}
                for part in filename:gmatch("[^_]+") do
                    table.insert(parts, part)
                end
                
                local caller = parts[1] or "Unknown"
                local callee = parts[2] or "Unknown"
                local timestamp_str = parts[3] or ""
                timestamp_str = timestamp_str:gsub("%.wav$", ""):gsub("%.gsm$", "")
                
                local formatted_time = timestamp_str
                if #timestamp_str == 15 then
                    local year = timestamp_str:sub(1, 4)
                    local month = timestamp_str:sub(5, 6)
                    local day = timestamp_str:sub(7, 8)
                    local hour = timestamp_str:sub(10, 11)
                    local minute = timestamp_str:sub(12, 13)
                    local second = timestamp_str:sub(14, 15)
                    formatted_time = year .. "-" .. month .. "-" .. day .. " " .. hour .. ":" .. minute .. ":" .. second
                end
                
                table.insert(data.files, {
                    name = filename,
                    caller = caller,
                    callee = callee,
                    timestamp = formatted_time,
                    size = tonumber(size)
                })
            end
        end
        f:close()
    end
    
    f = io.popen("ls -la \"" .. record_dir .. "\" 2>/dev/null | grep -E '\\.(wav|gsm)$' | wc -l")
    if f then
        data.total_count = tonumber(f:read("*line")) or 0
        f:close()
    end
    
    f = io.popen("du -sk \"" .. record_dir .. "\" 2>/dev/null | cut -f1")
    if f then
        local size_kb = tonumber(f:read("*line")) or 0
        data.total_size = size_kb * 1024
        f:close()
    end
    
    luci.http.write_json(data)
end

function action_download_record()
    local fs = require "nixio.fs"
    local filename = luci.http.formvalue("file")
    
    if filename then
        local uci = require("luci.model.uci").cursor()
        local record_dir = uci:get_first("voip", "record", "dir") or "/tmp/voip_records"
        local fullpath = record_dir .. "/" .. filename
        
        if fs.access(fullpath) then
            local file = io.open(fullpath, "rb")
            if file then
                local content = file:read("*all")
                file:close()
                
                if filename:match("%.wav$") then
                    luci.http.header('Content-Type', 'audio/x-wav')
                elseif filename:match("%.gsm$") then
                    luci.http.header('Content-Type', 'audio/x-gsm')
                else
                    luci.http.header('Content-Type', 'application/octet-stream')
                end
                
                luci.http.header('Content-Disposition', 'attachment; filename="' .. filename .. '"')
                luci.http.write(content)
                return
            end
        end
    end
    
    luci.http.status(404, "Not Found")
    luci.http.write("File not found")
end

function action_delete_record()
    local fs = require "nixio.fs"
    local filename = luci.http.formvalue("file")
    
    if filename then
        local uci = require("luci.model.uci").cursor()
        local record_dir = uci:get_first("voip", "record", "dir") or "/tmp/voip_records"
        local fullpath = record_dir .. "/" .. filename
        fs.unlink(fullpath)
    end
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "record_files"))
end

function action_restart()
    local sys = require "luci.sys"
    sys.call("/etc/init.d/asterisk restart 2>/dev/null")
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "status"))
end

function action_apply()
    generate_configs()
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "status"))
end

function generate_configs()
    local uci = require("luci.model.uci").cursor()
    local fs = require("nixio.fs")
    
    local sip_conf = "/etc/asterisk/sip.conf"
    local extensions_conf = "/etc/asterisk/extensions.conf"
    
    local record_enabled = uci:get_first("voip", "record", "enabled") or "0"
    local record_dir = uci:get_first("voip", "record", "dir") or "/tmp/voip_records"
    local record_format = uci:get_first("voip", "record", "format") or "gsm"
    local auto_clean = uci:get_first("voip", "record", "auto_clean") or "30"
    
    local file_ext = ""
    local mixmonitor_opts = ""
    if record_format == "wav" then
        file_ext = ".wav"
        mixmonitor_opts = ",a"
    else
        file_ext = ".gsm"
        mixmonitor_opts = ""
    end
    
    local sip_content = [[
[general]
context = default
bindport = 5060
bindaddr = 0.0.0.0
allowguest = yes
allowoverlap = yes
dtmfmode = rfc2833
alwaysauthreject = yes
nat = yes
allow = ulaw
allow = alaw
canreinvite = no

]]
    
    local trunk_enabled = uci:get_first("voip", "trunk", "enabled") or "0"
    local server = uci:get_first("voip", "trunk", "server") or ""
    local forward_server = uci:get_first("voip", "trunk", "forward_server") or ""
    local port = uci:get_first("voip", "trunk", "port") or "5060"
    local phone = uci:get_first("voip", "trunk", "phone") or ""
    local password = uci:get_first("voip", "trunk", "password") or ""
    local nat = uci:get_first("voip", "trunk", "nat") or "1"
    local use_srtp = uci:get_first("voip", "trunk", "srtp") or "0"
    local default_extension = uci:get_first("voip", "trunk", "default_extension") or ""
    
    if trunk_enabled == "1" and server ~= "" and phone ~= "" and password ~= "" and forward_server ~= "" then
        sip_content = sip_content .. "register = " .. phone .. "@" .. server .. ":" .. password .. ":" .. phone .. "@" .. server .. "@" .. forward_server .. ":" .. port .. "\n"
        
        if use_srtp == "1" then
            sip_content = sip_content .. "encryption=yes\n"
            sip_content = sip_content .. "srtp=yes\n"
        end
        
        sip_content = sip_content .. "\n[trunk_ims]\n"
        sip_content = sip_content .. "host=" .. forward_server .. "\n"
        sip_content = sip_content .. "username=" .. phone .. "@" .. server .. "\n"
        sip_content = sip_content .. "secret=" .. password .. "\n"
        sip_content = sip_content .. "type=friend\n"
        sip_content = sip_content .. "fromdomain=" .. server .. "\n"
        sip_content = sip_content .. "fromuser=" .. phone .. "\n"
        sip_content = sip_content .. "insecure=port,invite\n"
        sip_content = sip_content .. "dtmfmode=inband\n"
        sip_content = sip_content .. "context=external\n"
        sip_content = sip_content .. "nat=" .. (nat == "1" and "yes" or "no") .. "\n"
        sip_content = sip_content .. "qualify=yes\n"
    end
    
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local number = s.number or s[".name"]
            local secret = s.secret or "secret"
            local callerid = s.callerid or ("Extension " .. number)
            sip_content = sip_content .. "\n[" .. number .. "]\n"
            sip_content = sip_content .. "type=friend\n"
            sip_content = sip_content .. "secret=" .. secret .. "\n"
            sip_content = sip_content .. "host=dynamic\n"
            sip_content = sip_content .. "context=internal\n"
            sip_content = sip_content .. "dtmfmode=rfc2833\n"
            sip_content = sip_content .. "nat=yes\n"
            sip_content = sip_content .. "qualify=yes\n"
            sip_content = sip_content .. "callerid=\"" .. callerid .. "\" <" .. number .. ">\n"
        end
    end)
    
    fs.writefile(sip_conf, sip_content)
    
    local ext_content = [[
[general]

[internal]
]]
    
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local number = s.number or s[".name"]
            local ext_record = s.record or "0"
            
            if record_enabled == "1" and ext_record == "1" then
                ext_content = ext_content .. "exten => " .. number .. ",1,Set(CALLER=${CALLERID(num)})\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Set(CALLEE=" .. number .. ")\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Set(TIMESTAMP=${SHELL(date +%Y%m%d-%H%M%S | tr -d '\\n')})\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Set(FILE_NAME=" .. record_dir .. "/${CALLER}_${CALLEE}_${TIMESTAMP})\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,MixMonitor(${FILE_NAME}" .. file_ext .. mixmonitor_opts .. ")\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Dial(SIP/" .. number .. ",30)\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,StopMixMonitor()\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
            else
                ext_content = ext_content .. "exten => " .. number .. ",1,Dial(SIP/" .. number .. ")\n"
                ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
            end
        end
    end)
    
    if trunk_enabled == "1" then
        ext_content = ext_content .. [[

; Outbound dialing rules for PSTN
exten => _1XX!,1,Dial(SIP/${EXTEN}@trunk_ims,60,r)
exten => _XXXXX!,1,Dial(SIP/${EXTEN}@trunk_ims,60,r)
exten => _XXXXXXXX!,1,Dial(SIP/${EXTEN}@trunk_ims,60,r)
exten => _1XXXXXXXXXX!,1,Dial(SIP/${EXTEN}@trunk_ims,60,r)
]]
    end
    
    ext_content = ext_content .. [[

[external]
exten => s,1,Answer()
]]
    
    if trunk_enabled == "1" then
        if default_extension ~= "" then
            ext_content = ext_content .. "exten => s,n,Dial(SIP/" .. default_extension .. ",60)\n"
        else
            local ring_all = ""
            uci:foreach("voip", "extension", function(s)
                if s.enabled == "1" then
                    local number = s.number or s[".name"]
                    if ring_all == "" then
                        ring_all = "SIP/" .. number
                    else
                        ring_all = ring_all .. "&SIP/" .. number
                    end
                end
            end)
            if ring_all ~= "" then
                ext_content = ext_content .. "exten => s,n,Dial(" .. ring_all .. ",60)\n"
            else
                ext_content = ext_content .. "exten => s,n,Playback(invalid)\n"
            end
        end
    else
        ext_content = ext_content .. "exten => s,n,Playback(invalid)\n"
    end
    ext_content = ext_content .. "exten => s,n,Hangup()\n"
    
    fs.writefile(extensions_conf, ext_content)
    
    if record_enabled == "1" then
        fs.mkdir(record_dir)
        if tonumber(auto_clean) and tonumber(auto_clean) > 0 then
            local ext_pattern = (record_format == "wav") and "*.wav" or "*.gsm"
            local cmd = "find " .. record_dir .. " -name \"" .. ext_pattern .. "\" -mtime +" .. auto_clean .. " -delete 2>/dev/null"
            os.execute(cmd)
        end
    end
    
    os.execute("/etc/init.d/asterisk reload 2>/dev/null")
end
