#!/usr/bin/lua
-- zigbeed-autoreg.lua <ADDR_HEX16> <zigbee_type> <model_id>
--
-- Register a third-party device with the vendor DeviceHub so that it is treated
-- as a known subdevice. Without this DeviceHub logs
--   ERROR GetDeviceModel: can not find device <ADDR>
-- and refuses to manage the device (no alarm bookkeeping, no mete tracking).
--
-- What it does (idempotent, safe to run repeatedly):
--   1. if the device already exists in iot_bas_device -> nothing to do
--   2. add a model entry "deviceModel.json" for <zigbee_type>-<model_id>,
--      copying device_type/device_kind/mete_num from an existing model whose
--      name starts with the same "<zigbee_type>-" prefix (e.g. any 1204-* entry
--      is a door/window sensor -> 21/17/4)
--   3. insert the device into iot_bas_device in devicebase.db and devicehub.db
--   4. when a model entry was added, restart DeviceHub so it reloads the model
--      list (it caches it at startup)
--
-- Called automatically by zigbeed when an unknown device reports in.

local function hex_or(a) return (a:gsub("(..)(..)(..)(..)(..)(..)(..)(..)", "%1:%2:%3:%4:%5:%6:%7:%8")) end

local function sh(cmd)
    local f = io.popen(cmd .. " 2>&1")
    if not f then return "" end
    local out = f:read("*a") or ""
    f:close()
    return out
end

local addr, ztype, model = arg[1], arg[2], arg[3]
if not addr or not ztype or addr == "" then
    io.stderr:write("usage: zigbeed-autoreg.lua <ADDR> <zigbee_type> <model_id>\n")
    os.exit(1)
end
model = model or ""
local log = io.open("/tmp/zigbeed_autoreg.log", "a")
local function say(m)
    if log then log:write(os.date("%Y-%m-%d %H:%M:%S "), m, "\n"); log:flush() end
end

-- 1. already known?
local db_exists = false
for _, db in ipairs({ "/etc/IoT/devicebase.db", "/etc/IoT/devicehub.db" }) do
    if sh("test -f " .. db .. " && echo yes") == "yes\n" then
        local r = sh("sqlite3 " .. db .. " \"select count(*) from iot_bas_device where deviceId='" .. addr .. "';\"")
        if tonumber((r:gsub("%s", ""))) and tonumber((r:gsub("%s", ""))) > 0 then db_exists = true end
    end
end

-- 2. model entry
local model_json = "/etc/IoT/deviceModel.json"
local mk = io.open(model_json, "r")
if not mk then say("no " .. model_json); os.exit(1) end
local raw = mk:read("*a"); mk:close()

local esc = function(s) return (s:gsub("[%c\"\\]", "")) end
local want_name = esc(ztype) .. "-" .. esc(model)
-- category lookup, two passes:
--   a) same product number: our TS0203 matches the vendor's 1204-SM0203 (Tuya
--      renames its sensors SM0x0x) -> that is the exact same device family
--   b) otherwise the most common category among entries with the same
--      "<zigbee_type>-" prefix (1204-* is mostly a door/window sensor)
local dev_type, dev_kind, mete_num = nil, nil, nil
local num = esc(model):match("(%d%d%d%d)$")
if num and num ~= "" then
    for dt, dk, mn in raw:gmatch('"model_name":"[^"]*' .. num .. '[^"]*"[^}]-"device_type":(%d+),"device_kind":(%d+),"mete_num":(%d+)') do
        dev_type, dev_kind, mete_num = tonumber(dt), tonumber(dk), tonumber(mn)
        break
    end
end
if not dev_type then
    local tally, best, bestn = {}, nil, 0
    local pref = esc(ztype) .. "%-"
    for dt, dk, mn in raw:gmatch('"model_name":"' .. pref .. '[^"]*"[^}]-"device_type":(%d+),"device_kind":(%d+),"mete_num":(%d+)') do
        local k = dt .. "/" .. dk .. "/" .. mn
        tally[k] = (tally[k] or 0) + 1
        if tally[k] > bestn then best, bestn = { tonumber(dt), tonumber(dk), tonumber(mn) }, tally[k] end
    end
    if best then dev_type, dev_kind, mete_num = best[1], best[2], best[3] end
end
if not dev_type then
    -- no sibling: keep the device out of the model list rather than guess wrong
    say("no model category for type " .. tostring(ztype) .. " (device " .. addr .. " left unregistered)")
    os.exit(0)
end

local added_model = false
if not raw:find('"model_name":"' .. want_name .. '"', 1, true) then
    -- next free device_model id
    local maxid = 0
    for id in raw:gmatch('"device_model":(%-?%d+)') do
        local n = tonumber(id)
        if n and n > maxid then maxid = n end
    end
    local entry = string.format('{"device_model":%d,"device_name":"third-party","model_name":"%s","device_type":%d,"device_kind":%d,"mete_num":%d}',
                                maxid + 1, want_name, dev_type, dev_kind, mete_num)
    local n, cnt = raw:gsub('(%"gem_models%":%[)', '%1' .. entry .. ',', 1)
    if cnt == 0 then
        n, cnt = raw:gsub('(%"gem_models%":%[%s*%])', '%1' .. entry, 1)
    end
    if cnt > 0 then
        n = n:gsub('"modelNum":%d+', '"modelNum":' .. tostring((select(2, raw:gsub('"device_model"', ''))) + 1))
        sh("cp -f " .. model_json .. " /tmp/deviceModel.json.autoreg.bak")
        local w = io.open(model_json, "w")
        if w then w:write(n); w:close(); added_model = true end
    end
end

-- 3. device table (both DBs; the vendor reads one of them)
if not db_exists then
    for _, db in ipairs({ "/etc/IoT/devicebase.db", "/etc/IoT/devicehub.db" }) do
        if sh("test -f " .. db .. " && echo yes") == "yes\n" then
            sh(string.format("cp -f %s /tmp/%s.autoreg.bak", db, (db:gsub(".*/", ""))))
            sh(string.format("sqlite3 %s \"insert or replace into iot_bas_device (deviceId,device_name,module_name,mete_num,device_kind,device_type,online) values ('%s','%s','%s',%d,%d,%d,1);\"",
                             db, addr, "子设备", want_name, mete_num, dev_kind, dev_type))
        end
    end
    say(string.format("registered device %s model=%s (%d/%d/%d) model_added=%s",
                      addr, want_name, dev_type, dev_kind, mete_num, tostring(added_model)))
else
    say("device " .. addr .. " already registered")
end

-- 3b. 把型号回写到我们自己的设备表（页面靠它显示型号/中文类型；刷机后不会丢）
do
    local kd = "/etc/zigbeed/known_devices.conf"
    local kf = io.open(kd, "r")
    if kf then
        local hex = hex_or(addr)
        local lines, found = {}, false
        for line in kf:lines() do
            local ieee, rest = line:match("^(%S+)%s+(.*)$")
            if ieee and (ieee == hex or ieee == addr) then
                local tail = rest:gsub("^%S+%s*", "")        -- 去掉旧的 model 字段
                line = hex .. " " .. model .. " " .. tail
                found = true
            end
            lines[#lines + 1] = line
        end
        kf:close()
        if not found then lines[#lines + 1] = hex .. " " .. model .. " 0 " .. os.time() end
        local w = io.open(kd, "w")
        if w then w:write(table.concat(lines, "\n") .. "\n"); w:close() end
    end
end

-- 4. reload the vendor when the model list changed
if added_model then
    sh("sleep 15; /etc/init.d/devicehub restart >/dev/null 2>&1 &")
    say("model list changed -> DeviceHub restart scheduled")
end
if log then log:close() end
