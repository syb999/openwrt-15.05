module("luci.controller.voip", package.seeall)

function index()
    entry({"admin", "services", "voip"}, alias("admin", "services", "voip", "status"), "VoIP", 60)
    entry({"admin", "services", "voip", "status"}, template("voip/status"), "Status", 1)
    entry({"admin", "services", "voip", "status_data"}, call("action_status_data"), nil)
    entry({"admin", "services", "voip", "trunk"}, cbi("voip/trunk"), "SIP Trunk", 2)
    entry({"admin", "services", "voip", "extensions"}, cbi("voip/extension"), "Extensions", 3)
    entry({"admin", "services", "voip", "peer"}, template("voip/peer"), "Server Peers", 4)
    entry({"admin", "services", "voip", "peer_data"}, call("action_peer_data"), nil)
    entry({"admin", "services", "voip", "peer_save"}, call("action_peer_save"), nil)
    entry({"admin", "services", "voip", "peer_delete"}, call("action_peer_delete"), nil)
    entry({"admin", "services", "voip", "record_settings"}, cbi("voip/record_settings"), "Record Settings", 5)
    entry({"admin", "services", "voip", "record_files"}, template("voip/record_files"), "Record Files", 6)
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
                local host = line:match("^%S+%s+(%S+)")
                local status = line:match("OK") and "OK" or 
                               line:match("UNKNOWN") and "UNKNOWN" or 
                               line:match("UNREACHABLE") and "UNREACHABLE" or "Unknown"
                if name then
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
        if p.name and p.name ~= "" and not p.name:match("^%d+$") then
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
    
    uci:foreach("voip", "extension", function(s)
        if s.enabled == "1" then
            local number = s.number or s[".name"]
            local ext_record = s.record or "0"
            if number then
                os.execute("asterisk -rx 'database put record " .. number .. " " .. ext_record .. "' > /dev/null 2>&1 &")
            end
        end
    end)
    
    os.execute("asterisk -rx 'dialplan reload' > /dev/null 2>&1 &")
    
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
    
    local file_ext_dot = ""
    local file_ext_plain = ""
    local mixmonitor_opts = ""
    
    if record_format == "wav" then
        file_ext_dot = ".wav"
        file_ext_plain = "wav"
        mixmonitor_opts = ",a"
    else
        file_ext_dot = ".gsm"
        file_ext_plain = "gsm"
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
rtcachefriends=yes
rtsavesysname=yes
qualifyfreq=60

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
        sip_content = sip_content .. "nat=force_rport,comedia\n"
        sip_content = sip_content .. "qualify=yes\n"
        sip_content = sip_content .. "qualifyfreq=30\n"
        sip_content = sip_content .. "session-timers=refuse\n"
        sip_content = sip_content .. "register_timeout=30\n"
        sip_content = sip_content .. "registration_timeout=30\n"
    end
    
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
            sip_content = sip_content .. "context=" .. (p.context or "internal") .. "\n"
            sip_content = sip_content .. "nat=" .. (p.nat == "1" and "yes" or "no") .. "\n"
            sip_content = sip_content .. "qualify=" .. (p.qualify == "1" and "yes" or "no") .. "\n"
            sip_content = sip_content .. "qualifyfreq=60\n"
            sip_content = sip_content .. "dtmfmode=" .. (p.dtmfmode or "rfc2833") .. "\n"
            sip_content = sip_content .. "canreinvite=no\n"
        end
    end)
    
    fs.writefile(sip_conf, sip_content)
    
    local ext_content = [[
[general]

; Macro for outbound calls with recording
[macro-dialout]
exten => s,1,Set(CALLER_RAW=${CALLERID(num)})
exten => s,n,Set(CALLER=${FILTER(0-9,${CALLER_RAW})})
exten => s,n,Set(CALLEE=${ARG1})
exten => s,n,Set(RECORD_ENABLED=${DB(record/${CALLER})})
exten => s,n,GotoIf($["${RECORD_ENABLED}" = "1"]?record,1)
exten => s,n,Dial(SIP/${CALLEE}@trunk_ims,60,r)
exten => s,n,Hangup()
exten => record,1,Set(CALLEE=${ARG1})
exten => record,n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})
exten => record,n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})
exten => record,n,Set(FILE_NAME=/tmp/voip_records/${CALLER}_${CALLEE}_${TIMESTAMP})
exten => record,n,MixMonitor(${FILE_NAME}.gsm)
exten => record,n,Dial(SIP/${CALLEE}@trunk_ims,60,r)
exten => record,n,StopMixMonitor()
exten => record,n,Hangup()

[internal]
]]
    
    for _, ext in ipairs(extensions_info) do
        local number = ext.number
        local ext_record = ext.record
        
        if record_enabled == "1" and ext_record == "1" then
            ext_content = ext_content .. "exten => " .. number .. ",1,Set(DB(record/" .. number .. ")=" .. ext_record .. ")\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(CALLER=${CALLERID(num)})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(CALLEE=" .. number .. ")\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(RAW=${SHELL(date +%Y%m%d-%H%M%S)})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(TIMESTAMP=${FILTER(0-9-,${RAW})})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Set(FILE_NAME=" .. record_dir .. "/${CALLER}_${CALLEE}_${TIMESTAMP})\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,MixMonitor(${FILE_NAME}" .. file_ext_dot .. mixmonitor_opts .. ")\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Dial(SIP/" .. number .. ",60)\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,StopMixMonitor()\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
        else
            ext_content = ext_content .. "exten => " .. number .. ",1,Dial(SIP/" .. number .. ")\n"
            ext_content = ext_content .. "exten => " .. number .. ",n,Hangup()\n"
        end
    end
    
    if trunk_enabled == "1" then
        ext_content = ext_content .. [[

; Outbound dialing rules for PSTN
exten => _1XX!,1,Macro(dialout,${EXTEN})
exten => _XXXXX!,1,Macro(dialout,${EXTEN})
exten => _XXXXXXXX!,1,Macro(dialout,${EXTEN})
exten => _1XXXXXXXXXX!,1,Macro(dialout,${EXTEN})
]]
    end
    
    local peer_rules_added = {}
    uci:foreach("voip", "peer", function(p)
        if p.name and p.name ~= "" and p.dial_prefix and p.dial_prefix ~= "" then
            local prefix = p.dial_prefix
            if not peer_rules_added[prefix] then
                peer_rules_added[prefix] = true
                ext_content = ext_content .. "\n; Route to server " .. p.name .. " (prefix: " .. prefix .. ")\n"
                ext_content = ext_content .. "exten => _" .. prefix .. ".,1,Verbose(2, Routing to server " .. p.name .. ": ${EXTEN:" .. string.len(prefix) .. "})\n"
                ext_content = ext_content .. "exten => _" .. prefix .. ".,n,Dial(SIP/${EXTEN:" .. string.len(prefix) .. "}@" .. p.name .. ",60,r)\n"
                ext_content = ext_content .. "exten => _" .. prefix .. ".,n,Hangup()\n"
            end
        end
    end)
    
    local has_prefix = false
    uci:foreach("voip", "peer", function(p)
        if p.dial_prefix and p.dial_prefix ~= "" then
            has_prefix = true
        end
    end)
    if not has_prefix then
        uci:foreach("voip", "peer", function(p)
            if p.name and p.name ~= "" then
                ext_content = ext_content .. "\n; Default route to server " .. p.name .. " (prefix: 8)\n"
                ext_content = ext_content .. "exten => _8.,1,Verbose(2, Routing to server " .. p.name .. ": ${EXTEN:1})\n"
                ext_content = ext_content .. "exten => _8.,n,Dial(SIP/${EXTEN:1}@" .. p.name .. ",60,r)\n"
                ext_content = ext_content .. "exten => _8.,n,Hangup()\n"
                return false
            end
        end)
    end
    
    ext_content = ext_content .. [[

[external]
exten => s,1,Progress()
exten => s,n,Playback(vm-intro)
]]
    
    if trunk_enabled == "1" then
        if default_extension ~= "" then
            ext_content = ext_content .. "exten => s,n,Goto(internal," .. default_extension .. ",1)\n"
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
            username = p.username or "",
            type = p.type or "friend",
            context = p.context or "internal",
            nat = p.nat or "1",
            qualify = p.qualify or "1",
            dtmfmode = p.dtmfmode or "rfc2833"
        })
    end)
    
    luci.http.write_json(peers)
end

function action_peer_delete()
    local uci = require("luci.model.uci").cursor()
    local name = luci.http.formvalue("name")
    
    if name and name ~= "" then
        local found = false
        uci:foreach("voip", "peer", function(s)
            if s.name == name and not found then
                uci:delete("voip", s[".name"])
                found = true
            end
        end)
        uci:commit("voip")
        generate_configs()
    end
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "peer"))
end

function action_peer_save()
    local uci = require("luci.model.uci").cursor()
    local http = require("luci.http")
    
    local data = http.formvalue()
    
    local sections = {}
    uci:foreach("voip", "peer", function(s)
        table.insert(sections, s[".name"])
    end)
    for _, name in ipairs(sections) do
        uci:delete("voip", name)
    end
    
    local peer_count = tonumber(data.peer_count) or 0
    for i = 1, peer_count do
        local name = data["peer_name_" .. i]
        if name and name ~= "" then
            local section = "peer_" .. name
            uci:set("voip", section, "peer")
            uci:set("voip", section, "name", name)
            uci:set("voip", section, "dial_prefix", data["peer_prefix_" .. i] or "")
            uci:set("voip", section, "host", data["peer_host_" .. i] or "")
            uci:set("voip", section, "port", data["peer_port_" .. i] or "5060")
            uci:set("voip", section, "username", data["peer_username_" .. i] or "")
            uci:set("voip", section, "password", data["peer_password_" .. i] or "")
            uci:set("voip", section, "type", data["peer_type_" .. i] or "friend")
            uci:set("voip", section, "context", data["peer_context_" .. i] or "internal")
            uci:set("voip", section, "nat", data["peer_nat_" .. i] or "0")
            uci:set("voip", section, "qualify", data["peer_qualify_" .. i] or "0")
            uci:set("voip", section, "dtmfmode", data["peer_dtmf_" .. i] or "rfc2833")
        end
    end
    
    local new_name = data.new_name
    if new_name and new_name ~= "" and data.new_host and data.new_host ~= "" then
        local section = "peer_" .. new_name
        uci:set("voip", section, "peer")
        uci:set("voip", section, "name", new_name)
        uci:set("voip", section, "dial_prefix", data.new_prefix or "")
        uci:set("voip", section, "host", data.new_host)
        uci:set("voip", section, "port", data.new_port or "5060")
        uci:set("voip", section, "username", data.new_username or "")
        uci:set("voip", section, "password", data.new_password or "")
        uci:set("voip", section, "type", data.new_type or "friend")
        uci:set("voip", section, "context", data.new_context or "internal")
        uci:set("voip", section, "nat", data.new_nat or "0")
        uci:set("voip", section, "qualify", data.new_qualify or "0")
        uci:set("voip", section, "dtmfmode", data.new_dtmf or "rfc2833")
    end
    
    uci:commit("voip")
    generate_configs()
    
    luci.http.redirect(luci.dispatcher.build_url("admin", "services", "voip", "peer"))
end
