module("luci.controller.voip", package.seeall)

function index()
    entry({"admin", "services", "voip"}, alias("admin", "services", "voip", "status"), "VoIP", 60)
    entry({"admin", "services", "voip", "status"}, template("voip/status"), "Status", 1)
    entry({"admin", "services", "voip", "status_data"}, call("action_status_data"), nil)
    entry({"admin", "services", "voip", "trunk"}, cbi("voip/trunk"), "SIP Trunk", 2)
    entry({"admin", "services", "voip", "extensions"}, cbi("voip/extension"), "Extensions", 3)
    entry({"admin", "services", "voip", "peer"}, template("voip/peer"), "Server Peers", 4)
    entry({"admin", "services", "voip", "peer_data"}, call("action_peer_data"), nil)
    entry({"admin", "services", "voip", "peer_update"}, call("action_peer_update"), nil)
    entry({"admin", "services", "voip", "peer_add"}, call("action_peer_add"), nil)
    entry({"admin", "services", "voip", "peer_delete"}, call("action_peer_delete"), nil)
    entry({"admin", "services", "voip", "record_settings"}, cbi("voip/record_settings"), "Record Settings", 5)
    entry({"admin", "services", "voip", "record_files"}, template("voip/record_files"), "Record Files", 6)
    entry({"admin", "services", "voip", "record_files_data"}, call("action_record_files_data"), nil)
    entry({"admin", "services", "voip", "download_record"}, call("action_download_record"), nil)
    entry({"admin", "services", "voip", "delete_record"}, call("action_delete_record"), nil)
    entry({"admin", "services", "voip", "pstn_handler"}, cbi("voip/pstn_handler"), "PSTN Incoming", 7)
    entry({"admin", "services", "voip", "restart"}, call("action_restart"), nil)
    entry({"admin", "services", "voip", "apply"}, call("action_apply"), nil)
end

function action_status_data()
    luci.http.prepare_content("application/json")
    
    local data = {
        peers = {},
        server_peers = {},
        calls = {}
    }
    
    local peer_status = {}
    local f = io.popen("asterisk -rx 'sip show peers' 2>/dev/null")
    if f then
        local in_peer_section = false
        for line in f:lines() do
            if line:match("Name/username") then
                in_peer_section = true
            elseif in_peer_section and not line:match("^-") and not line:match("sip peers") then
                local name = line:match("^(%S+)/")
                if not name then
                    name = line:match("^(%S+)%s+")
                end
                if name then
                    local host = line:match("^%S+%s+(%S+)")
                    local status = line:match("OK") and "OK" or 
                                   line:match("UNKNOWN") and "UNKNOWN" or 
                                   line:match("UNREACHABLE") and "UNREACHABLE" or "Unknown"
                    peer_status[name] = {
                        host = host,
                        status = status
                    }
                end
            end
        end
        f:close()
    end
    
    local uci = require("luci.model.uci").cursor()
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local name = s.number or s[".name"]
            if name and name:match("^%d+$") then
                local status_info = peer_status[name] or {}
                table.insert(data.peers, {
                    name = name,
                    host = status_info.host or "(Unspecified)",
                    status = status_info.status or "Unknown"
                })
            end
        end
    end)
    
    uci:foreach("voip", "peer", function(p)
        if p.name and p.name ~= "" then
            local status_info = peer_status[p.name] or {}
            table.insert(data.server_peers, {
                name = p.name,
                host = p.host or "",
                port = p.port or "5060",
                status = status_info.status or "Unknown"
            })
        end
    end)
    
    f = io.popen("asterisk -rx 'core show channels' 2>/dev/null")
    if f then
        local calls_seen = {}
        for line in f:lines() do
            if line:match("SIP/") then
                local channel = line:match("^(SIP/%d+%-%S+)")
                if channel then
                    local caller = channel:match("SIP/(%d+)")
                    local callee = line:match("(%d+)@internal")
                    
                    if not callee then
                        callee = line:match("Dial%(SIP/(%d+)")
                    end
                    
                    if caller and callee and not calls_seen[caller .. "_" .. callee] then
                        calls_seen[caller .. "_" .. callee] = true
                        table.insert(data.calls, {caller = caller, callee = callee})
                    elseif callee and not calls_seen["_PSTN_" .. callee] then
                        calls_seen["_PSTN_" .. callee] = true
                        table.insert(data.calls, {caller = "PSTN", callee = callee})
                    end
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
    local uci = require("luci.model.uci").cursor()
    
    generate_configs()
    
    os.execute("asterisk -rx 'database deltree record' > /dev/null 2>&1 &")
    os.execute("sleep 1")
    
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local number = s.number
            local ext_record = s.record or "0"
            if number and number ~= "" then
                os.execute("asterisk -rx 'database put record " .. number .. " " .. ext_record .. "' > /dev/null 2>&1 &")
            end
        end
    end)
    
    os.execute("sleep 1")
    os.execute("asterisk -rx 'dialplan reload' > /dev/null 2>&1 &")
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "status"))
end

function generate_configs()
    local uci = require("luci.model.uci").cursor()
    local fs = require("nixio.fs")
    
    local sip_conf = "/etc/asterisk/sip.conf"
    local extensions_conf = "/etc/asterisk/extensions.conf"
    local musiconhold_conf = "/etc/asterisk/musiconhold.conf"
    
    local record_enabled = uci:get_first("voip", "record", "enabled") or "0"
    local record_dir = uci:get_first("voip", "record", "dir") or "/tmp/voip_records"
    local record_format = uci:get_first("voip", "record", "format") or "gsm"
    local auto_clean = uci:get_first("voip", "record", "auto_clean") or "30"
    
    local pstn_mode = uci:get("voip", "pstn_handler", "mode") or "normal"
    
    local playback_enabled = uci:get("voip", "pstn_handler", "playback_enabled") or "0"
    local playback_dir = uci:get("voip", "pstn_handler", "playback_dir") or "/usr/share/asterisk/sounds"
    local playback_file = uci:get("voip", "pstn_handler", "playback_file") or "ring"
    local playback_loop = tonumber(uci:get("voip", "pstn_handler", "playback_loop")) or 1
    if playback_loop > 6 then
        playback_loop = 6
    end
    
    local ivr_welcome = uci:get("voip", "pstn_handler", "welcome") or "ivr-welcome"
    local ivr_timeout = uci:get("voip", "pstn_handler", "timeout") or "10"
    local ivr_invalid = uci:get("voip", "pstn_handler", "invalid") or "ivr-invalid"
    
    local ivr_options = {}
    uci:foreach("voip", "ivr_option", function(o)
        if o.digit and o.target and o.digit ~= "" then
            table.insert(ivr_options, {
                digit = o.digit,
                action = o.action or "extension",
                target = o.target
            })
        end
    end)
    
    local file_ext_dot = ""
    local mixmonitor_opts = ""
    
    if record_format == "wav" then
        file_ext_dot = ".wav"
        mixmonitor_opts = ",a"
    else
        file_ext_dot = ".gsm"
        mixmonitor_opts = ""
    end
    
    fs.mkdir(playback_dir)
    
    local playback_path = playback_dir .. "/" .. playback_file
    local ivr_welcome_path = playback_dir .. "/" .. ivr_welcome
    local ivr_invalid_path = playback_dir .. "/" .. ivr_invalid
    
    local musiconhold_content = "\n[default]\nmode=files\ndirectory=/usr/share/asterisk/moh\n\n"
    fs.writefile(musiconhold_conf, musiconhold_content)
    
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
rtcachefriends=yes
rtsavesysname=yes
qualifyfreq=60

]]
    
    local trunks = {}
    uci:foreach("voip", "trunk", function(t)
        if t.enabled == "1" and t.server and t.server ~= "" and t.phone and t.phone ~= "" and t.forward_server and t.forward_server ~= "" then
            local trunk_name = t.name
            if not trunk_name or trunk_name == "" then
                trunk_name = t[".name"]
            end
            if not trunk_name or trunk_name == "" then
                trunk_name = "trunk_" .. t.phone
            end
            
            table.insert(trunks, {
                name = trunk_name,
                prefix = t.prefix or "",
                server = t.server,
                forward_server = t.forward_server,
                port = t.port or "5060",
                phone = t.phone,
                password = t.password,
                srtp = t.srtp or "0",
                weight = tonumber(t.weight) or 1
            })
            
            sip_content = sip_content .. "register = " .. t.phone .. "@" .. t.server .. ":" .. t.password .. ":" .. t.phone .. "@" .. t.server .. "@" .. t.forward_server .. ":" .. t.port .. "\n"
            
            sip_content = sip_content .. "\n[" .. trunk_name .. "]\n"
            sip_content = sip_content .. "host=" .. t.forward_server .. "\n"
            sip_content = sip_content .. "username=" .. t.phone .. "@" .. t.server .. "\n"
            sip_content = sip_content .. "secret=" .. t.password .. "\n"
            sip_content = sip_content .. "type=friend\n"
            sip_content = sip_content .. "fromdomain=" .. t.server .. "\n"
            sip_content = sip_content .. "fromuser=" .. t.phone .. "\n"
            sip_content = sip_content .. "insecure=port,invite\n"
            sip_content = sip_content .. "dtmfmode=inband\n"
            sip_content = sip_content .. "context=external\n"
            sip_content = sip_content .. "nat=force_rport,comedia\n"
            sip_content = sip_content .. "qualify=yes\n"
            sip_content = sip_content .. "qualifyfreq=30\n"
            sip_content = sip_content .. "session-timers=refuse\n"
            if t.srtp == "1" then
                sip_content = sip_content .. "encryption=yes\n"
                sip_content = sip_content .. "srtp=yes\n"
            end
        end
    end)
    
    local extensions_info = {}
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local number = s.number or s[".name"]
            local secret = s.secret or "secret"
            local callerid = s.callerid or ("Extension " .. number)
            local ext_record = s.record or "0"
            table.insert(extensions_info, {
                number = number,
                secret = secret,
                callerid = callerid,
                record = ext_record
            })
            sip_content = sip_content .. "\n[" .. number .. "]\n"
            sip_content = sip_content .. "type=friend\n"
            sip_content = sip_content .. "secret=" .. secret .. "\n"
            sip_content = sip_content .. "host=dynamic\n"
            sip_content = sip_content .. "context=internal\n"
            sip_content = sip_content .. "dtmfmode=rfc2833\n"
            sip_content = sip_content .. "nat=force_rport,comedia\n"
            sip_content = sip_content .. "qualify=yes\n"
            sip_content = sip_content .. "qualifyfreq=30\n"
            sip_content = sip_content .. "rtupdate=yes\n"
            sip_content = sip_content .. "rtcachefriends=yes\n"
            sip_content = sip_content .. "session-timers=refuse\n"
            sip_content = sip_content .. "callerid=\"" .. callerid .. "\" <" .. number .. ">\n"
        end
    end)
    
    uci:foreach("voip", "peer", function(p)
        if p.name and p.name ~= "" and p.host and p.host ~= "" then
            local peer_name = p.name
            local context = p.context or "internal"
            
            sip_content = sip_content .. "\n[" .. peer_name .. "]\n"
            sip_content = sip_content .. "type=" .. (p.type or "friend") .. "\n"
            sip_content = sip_content .. "host=" .. p.host .. "\n"
            if p.port and p.port ~= "" then
                sip_content = sip_content .. "port=" .. p.port .. "\n"
            end
            if p.username and p.username ~= "" then
                sip_content = sip_content .. "username=" .. p.username .. "\n"
            end
            if p.password and p.password ~= "" then
                sip_content = sip_content .. "secret=" .. p.password .. "\n"
            end
            sip_content = sip_content .. "context=" .. context .. "\n"
            sip_content = sip_content .. "nat=" .. (p.nat == "1" and "yes" or "no") .. "\n"
            sip_content = sip_content .. "qualify=" .. (p.qualify == "1" and "yes" or "no") .. "\n"
            sip_content = sip_content .. "qualifyfreq=60\n"
            sip_content = sip_content .. "dtmfmode=" .. (p.dtmfmode or "rfc2833") .. "\n"
            sip_content = sip_content .. "canreinvite=no\n"
        end
    end)
    
    fs.writefile(sip_conf, sip_content)
    
    local default_extension = uci:get("voip", "global", "default_extension") or ""
    if default_extension == "" then
        uci:foreach("voip", "global", function(s)
            if s.default_extension and s.default_extension ~= "" then
                default_extension = s.default_extension
            end
        end)
    end
    
    if default_extension == "" and #extensions_info > 0 then
        default_extension = extensions_info[1].number
    end
    
    local all_extensions = {}
    for _, ext in ipairs(extensions_info) do
        table.insert(all_extensions, ext.number)
    end
    
    local ext_content = [[

[general]

; Macro for outbound calls with recording
[macro-dialout]
exten => s,1,Set(CALLER_RAW=${CALLERID(num)})
exten => s,n,Set(CALLER=${FILTER(0-9,${CALLER_RAW})})
exten => s,n,Set(CALLEE=${ARG1})
exten => s,n,Set(TARGET=${ARG2})
exten => s,n,Set(RECORD_ENABLED=${DB(record/${CALLER})})
exten => s,n,GotoIf($["${RECORD_ENABLED}" = "1"]?record,1)
exten => s,n,Dial(SIP/${CALLEE}@${TARGET},60,r)
exten => s,n,Hangup()

; Recording section
exten => record,1,Set(CALLEE=${ARG1})
exten => record,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => record,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => record,n,Set(FILE_NAME=]] .. record_dir .. [[/${CALLER}_${CALLEE}_${TIMESTAMP})
exten => record,n,MixMonitor(${FILE_NAME}]] .. file_ext_dot .. [[)
exten => record,n,Dial(SIP/${CALLEE}@${TARGET},60,r)
exten => record,n,StopMixMonitor()
exten => record,n,Hangup()

[default]
exten => _.,1,Goto(internal,${EXTEN},1)
exten => _.,n,Hangup()

[internal]
]]
    
    for _, ext in ipairs(extensions_info) do
        local number = ext.number
        local ext_record = ext.record
        
        ext_content = ext_content .. "\nexten => " .. number .. ",1,Set(DB(record/" .. number .. ")=" .. ext_record .. ")\n"
        
        if record_enabled == "1" and ext_record == "1" then
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(FILE_NAME=" .. record_dir .. "/${CALLERID(num)}_" .. number .. "_${TIMESTAMP})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,MixMonitor(${FILE_NAME}" .. file_ext_dot .. mixmonitor_opts .. ")\n"
            
            if pstn_mode == "direct" and playback_enabled == "1" and playback_file ~= "" then
                for i = 1, playback_loop do
                    ext_content = ext_content .. "exten => " .. number .. ",n,Playback(" .. playback_path .. ")\n"
                end
            end
            ext_content = ext_content .. "exten => " .. number .. ",n,Dial(SIP/" .. number .. ",60)\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,StopMixMonitor()\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
        else
            if pstn_mode == "direct" and playback_enabled == "1" and playback_file ~= "" then
                for i = 1, playback_loop do
                    ext_content = ext_content .. "exten => " .. number .. ",n,Playback(" .. playback_path .. ")\n"
                end
            end
            ext_content = ext_content .. "exten => " .. number .. ",n,Dial(SIP/" .. number .. ",60)\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
        end
    end
    
    if #trunks > 0 then
        if #trunks == 1 then
            local t = trunks[1]
            ext_content = ext_content .. [[

; Outbound dialing rules for PSTN (single trunk)
exten => _1XX!,1,Macro(dialout,${EXTEN},]] .. t.name .. [[)
exten => _XXXXX!,1,Macro(dialout,${EXTEN},]] .. t.name .. [[)
exten => _XXXXXXXX!,1,Macro(dialout,${EXTEN},]] .. t.name .. [[)
exten => _1XXXXXXXXXX!,1,Macro(dialout,${EXTEN},]] .. t.name .. [[)
]]
        else
            local dial_strings = {}
            for _, trunk in ipairs(trunks) do
                for i = 1, trunk.weight do
                    table.insert(dial_strings, "SIP/${EXTEN}@" .. trunk.name)
                end
            end
            local dial_all = table.concat(dial_strings, "&")
            
            ext_content = ext_content .. [[

; Multi-trunk outbound with load balancing
[macro-multi_dial]
exten => s,1,Set(CALLER=${CALLERID(num)})
exten => s,n,Set(CALLEE=${ARG1})
exten => s,n,Set(RECORD_ENABLED=${DB(record/${CALLER})})
exten => s,n,GotoIf($["${RECORD_ENABLED}" = "1"]?record,1)
exten => s,n,Dial(]] .. dial_all .. [[,60,r)
exten => s,n,Hangup()
exten => record,1,Set(CALLER=${CALLERID(num)})
exten => record,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => record,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => record,n,Set(FILE_NAME=]] .. record_dir .. [[/${CALLER}_${CALLEE}_${TIMESTAMP})
exten => record,n,MixMonitor(${FILE_NAME}]] .. file_ext_dot .. [[)
exten => record,n,Dial(]] .. dial_all .. [[,60,r)
exten => record,n,StopMixMonitor()
exten => record,n,Hangup()

; Outbound dialing rules for PSTN (multi-trunk)
exten => _1XX!,1,Macro(multi_dial,${EXTEN})
exten => _XXXXX!,1,Macro(multi_dial,${EXTEN})
exten => _XXXXXXXX!,1,Macro(multi_dial,${EXTEN})
exten => _1XXXXXXXXXX!,1,Macro(multi_dial,${EXTEN})
]]
            
            for _, trunk in ipairs(trunks) do
                if trunk.prefix and trunk.prefix ~= "" then
                    ext_content = ext_content .. "\n; Force route to trunk " .. trunk.name .. " (prefix: " .. trunk.prefix .. ")\n"
                    ext_content = ext_content .. "exten => _" .. trunk.prefix .. ".,1,Verbose(2, Force routing to " .. trunk.name .. ": ${EXTEN:" .. string.len(trunk.prefix) .. "})\n"
                    ext_content = ext_content .. "exten => _" .. trunk.prefix .. ".,n,Macro(dialout,${EXTEN:" .. string.len(trunk.prefix) .. "}," .. trunk.name .. ")\n"
                    ext_content = ext_content .. "exten => _" .. trunk.prefix .. ".,n,Hangup()\n"
                end
            end
        end
    end
    
    uci:foreach("voip", "peer", function(p)
        if p.name and p.name ~= "" and p.dial_prefix and p.dial_prefix ~= "" then
            local prefix = p.dial_prefix
            ext_content = ext_content .. "\n; Route to server " .. p.name .. " (prefix: " .. prefix .. ")\n"
            ext_content = ext_content .. "exten => _" .. prefix .. ".,1,Verbose(2, Routing to server " .. p.name .. ": ${EXTEN:" .. string.len(prefix) .. "})\n"
            ext_content = ext_content .. "exten => _" .. prefix .. ".,n,Macro(dialout,${EXTEN:" .. string.len(prefix) .. "}," .. p.name .. ")\n"
            ext_content = ext_content .. "exten => _" .. prefix .. ".,n,Hangup()\n"
        end
    end)
    
    if pstn_mode == "ivr" and #ivr_options > 0 then
        ext_content = ext_content .. [[

[external]
exten => s,1,Progress()
exten => s,n,NoOp(Incoming PSTN call - IVR)
exten => s,n,Goto(ivr-menu,s,1)

[ivr-menu]
exten => s,1,Answer()
exten => s,n,Playback(]] .. ivr_welcome_path .. [[)
exten => s,n,Read(digit,]] .. ivr_welcome_path .. [[,1,3,]] .. ivr_timeout .. [[)
exten => s,n,Goto(ivr-menu,${digit},1)
]]
        
        for _, opt in ipairs(ivr_options) do
            if opt.action == "extension" then
                ext_content = ext_content .. "exten => " .. opt.digit .. ",1,Dial(SIP/" .. opt.target .. ",30)\n"
            elseif opt.action == "hangup" then
                ext_content = ext_content .. "exten => " .. opt.digit .. ",1,Hangup()\n"
            end
        end
        
        ext_content = ext_content .. [[
exten => i,1,Playback(]] .. ivr_invalid_path .. [[)
exten => i,n,Goto(ivr-menu,s,1)
exten => t,1,Playback(]] .. ivr_invalid_path .. [[)
exten => t,n,Hangup()
]]
        
    elseif pstn_mode == "direct" then
        ext_content = ext_content .. [[

[external]
exten => s,1,Progress()
exten => s,n,NoOp(Incoming PSTN call - Direct Dial)
exten => s,n,Set(CALLER_NUM=${FILTER(0-9,${CALLERID(num)})})
exten => s,n,GotoIf($["${CALLER_NUM}" = ""]?unknown_caller,1)
exten => s,n,Goto(do_record,1)

exten => unknown_caller,1,Set(CALLER_NUM=unknown)
exten => unknown_caller,n,Goto(do_record,1)

exten => do_record,1,Answer()
exten => do_record,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => do_record,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => do_record,n,Set(FILE_NAME=]] .. record_dir .. [[/${CALLER_NUM}_]] .. default_extension .. [[_${TIMESTAMP})
exten => do_record,n,MixMonitor(${FILE_NAME}]] .. file_ext_dot .. mixmonitor_opts .. [[)
]]
        
        if playback_enabled == "1" and playback_file ~= "" then
            for i = 1, playback_loop do
                ext_content = ext_content .. "exten => do_record,n,Playback(" .. playback_path .. ")\n"
            end
        end
        
        ext_content = ext_content .. [[
exten => do_record,n,Dial(SIP/]] .. default_extension .. [[,60)
exten => do_record,n,StopMixMonitor()
exten => do_record,n,Hangup()
]]
        
    else
        ext_content = ext_content .. [[

[external]
exten => s,1,Progress()
exten => s,n,NoOp(Incoming PSTN call - Normal)
exten => s,n,Set(CALLER_NUM=${FILTER(0-9,${CALLERID(num)})})
exten => s,n,GotoIf($["${CALLER_NUM}" = ""]?unknown_caller,1)
exten => s,n,Goto(do_record,1)

exten => unknown_caller,1,Set(CALLER_NUM=unknown)
exten => unknown_caller,n,Goto(do_record,1)

exten => do_record,1,Answer()
exten => do_record,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => do_record,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => do_record,n,Set(FILE_NAME=]] .. record_dir .. [[/${CALLER_NUM}_]] .. default_extension .. [[_${TIMESTAMP})
exten => do_record,n,MixMonitor(${FILE_NAME}]] .. file_ext_dot .. mixmonitor_opts .. [[)
exten => do_record,n,Dial(SIP/]] .. default_extension .. [[,60)
exten => do_record,n,StopMixMonitor()
exten => do_record,n,Hangup()
]]
    end
    
    if default_extension == "" and #all_extensions > 0 then
        local ring_all = ""
        for i, ext in ipairs(all_extensions) do
            if i > 1 then
                ring_all = ring_all .. "&"
            end
            ring_all = ring_all .. "SIP/" .. ext
        end
        
        ext_content = ext_content .. [[

[external]
exten => s,1,Progress()
exten => s,n,Set(CALLER_NUM=${FILTER(0-9,${CALLERID(num)})})
exten => s,n,GotoIf($["${CALLER_NUM}" = ""]?unknown_caller,1)
exten => s,n,Goto(ring_all,1)

exten => unknown_caller,1,Set(CALLER_NUM=unknown)
exten => unknown_caller,n,Goto(ring_all,1)

exten => ring_all,1,Answer()
]]
        
        if pstn_mode == "direct" and playback_enabled == "1" and playback_file ~= "" then
            for i = 1, playback_loop do
                ext_content = ext_content .. "exten => ring_all,n,Playback(" .. playback_path .. ")\n"
            end
        end
        
        ext_content = ext_content .. [[
exten => ring_all,n,Set(DIAL_STRING=]] .. ring_all .. [[)
exten => ring_all,n,Dial(${DIAL_STRING},60,rg(sub_record_check,s,1))
exten => ring_all,n,Hangup()

[sub_record_check]
exten => s,1,NoOp(Checking recording for answered extension: ${DIALEDPEERNAME})
exten => s,n,Set(ANSWERED_EXTEN=${FILTER(0-9,${DIALEDPEERNAME})})
exten => s,n,Set(RECORD_ENABLED=${DB(record/${ANSWERED_EXTEN})})
exten => s,n,GotoIf($["${RECORD_ENABLED}" = "1"]?record_start,1)
exten => s,n,Return()

exten => record_start,1,NoOp(Recording enabled for ${ANSWERED_EXTEN})
exten => s,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => s,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => s,n,Set(FILE_NAME=]] .. record_dir .. [[/${CALLER_NUM}_${ANSWERED_EXTEN}_${TIMESTAMP})
exten => s,n,MixMonitor(${FILE_NAME}]] .. file_ext_dot .. mixmonitor_opts .. [[)
exten => s,n,Return()

exten => h,1,StopMixMonitor()
]]
    end
    
    fs.writefile(extensions_conf, ext_content)
    
    if record_enabled == "1" then
        fs.mkdir(record_dir)
        if tonumber(auto_clean) and tonumber(auto_clean) > 0 then
            local ext_pattern = (record_format == "wav") and "*.wav" or "*.gsm"
            local cmd = "find " .. record_dir .. " -name \"" .. ext_pattern .. "\" -mtime +" .. auto_clean .. " -delete 2>/dev/null"
            os.execute(cmd)
        end
    end
    
    os.execute("asterisk -rx 'database deltree record' > /dev/null 2>&1 &")
    os.execute("sleep 1")
    
    for _, ext in ipairs(extensions_info) do
        if ext.number then
            os.execute("asterisk -rx 'database put record " .. ext.number .. " " .. ext.record .. "' > /dev/null 2>&1 &")
        end
    end
    
    os.execute("sleep 1")
    os.execute("/etc/init.d/asterisk reload 2>/dev/null")
end

function action_peer_data()
    luci.http.prepare_content("application/json")
    
    local uci = require("luci.model.uci").cursor()
    local peers = {}
    
    uci:foreach("voip", "peer", function(p)
        table.insert(peers, {
            name = p.name or "",
            dial_prefix = p.dial_prefix or "",
            host = p.host or "",
            port = p.port or "5060",
            type = p.type or "friend",
            context = p.context or "internal",
            nat = p.nat or "1",
            qualify = p.qualify or "1",
            dtmfmode = p.dtmfmode or "rfc2833"
        })
    end)
    
    luci.http.write_json(peers)
end

function action_peer_add()
    local uci = require("luci.model.uci").cursor()
    local http = require("luci.http")
    
    local post_data = http.formvalue("data") or ""
    local data = {}
    if post_data ~= "" then
        post_data = post_data:gsub("^%s+", ""):gsub("%s+$", "")
        for key, value in post_data:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
            data[key] = value
        end
        for key, value in post_data:gmatch('"([^"]+)"%s*:%s*([^",][^,}]*)') do
            if value == "true" then
                data[key] = "1"
            elseif value == "false" then
                data[key] = "0"
            elseif value:match("^%d+$") then
                data[key] = value
            end
        end
    end
    
    if data and data.name and data.name ~= "" and data.host and data.host ~= "" then
        local section = "peer_" .. data.name
        uci:set("voip", section, "peer")
        uci:set("voip", section, "name", data.name)
        uci:set("voip", section, "dial_prefix", data.dial_prefix or "")
        uci:set("voip", section, "host", data.host)
        uci:set("voip", section, "port", data.port or "5060")
        uci:set("voip", section, "type", data.type or "friend")
        uci:set("voip", section, "context", data.context or "internal")
        uci:set("voip", section, "nat", data.nat or "0")
        uci:set("voip", section, "qualify", data.qualify or "1")
        uci:set("voip", section, "dtmfmode", data.dtmf or "rfc2833")
        uci:commit("voip")
        generate_configs()
    end
    
    luci.http.status(200, "OK")
    luci.http.write("")
end

function action_peer_update()
    local uci = require("luci.model.uci").cursor()
    local http = require("luci.http")
    
    local post_data = http.formvalue("data") or ""
    local data = {}
    if post_data ~= "" then
        post_data = post_data:gsub("^%s+", ""):gsub("%s+$", "")
        for key, value in post_data:gmatch('"([^"]+)"%s*:%s*"([^"]*)"') do
            data[key] = value
        end
        for key, value in post_data:gmatch('"([^"]+)"%s*:%s*([^",][^,}]*)') do
            if value == "true" then
                data[key] = "1"
            elseif value == "false" then
                data[key] = "0"
            elseif value:match("^%d+$") then
                data[key] = value
            end
        end
    end
    
    if data and data.name then
        local section = "peer_" .. data.name
        uci:set("voip", section, "peer")
        uci:set("voip", section, "name", data.name)
        uci:set("voip", section, "dial_prefix", data.dial_prefix or "")
        uci:set("voip", section, "host", data.host or "")
        uci:set("voip", section, "port", data.port or "5060")
        uci:set("voip", section, "type", data.type or "friend")
        uci:set("voip", section, "context", data.context or "internal")
        uci:set("voip", section, "nat", data.nat or "0")
        uci:set("voip", section, "qualify", data.qualify or "1")
        uci:set("voip", section, "dtmfmode", data.dtmf or "rfc2833")
        uci:commit("voip")
        generate_configs()
    end
    
    luci.http.status(200, "OK")
    luci.http.write("")
end

function action_peer_delete()
    local uci = require("luci.model.uci").cursor()
    local name = luci.http.formvalue("name")
    
    if name and name ~= "" then
        local section = "peer_" .. name
        uci:delete("voip", section)
        uci:commit("voip")
        generate_configs()
    end
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "peer"))
end
