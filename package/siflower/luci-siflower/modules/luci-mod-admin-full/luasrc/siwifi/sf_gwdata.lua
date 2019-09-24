--[[
--LuCI - Lua Configuration Interface
--
--Description:
--Offers an util to resolve extra disk information
--]]--


module ("luci.siwifi.sf_gwdata", package.seeall)

local sysconfig  = require "luci.siwifi.sf_sysconfig"
local sql = require "luasql.sqlite3"
local sferr = require "luci.siwifi.sf_error"

function sql_update_op(tableName, data, condition)
    local res = -1
    if tableName and type(tableName) == "string" and data and type(data) == "table" then
        local count = 0
        local update_k_v = nil
        data["update_time"] = os.time()
        for key,val in pairs(data) do
            if type(val) == "string" then
                val = "'"..val.."'"
            end

            if count == 0 then
                update_k_v = key.."="..val
            else
                update_k_v = update_k_v..","..key.."="..val
            end
            count = count + 1
        end
        count = 0
        local condition_k_v = nil
        for key,val in pairs(condition) do
            if type(val) == "string" then
                val = "'"..val.."'"
            end
            if count == 0 then
                condition_k_v = key.."="..val
            else
                condition_k_v = condition_k_v..","..key.."="..val
            end
            count = count + 1
        end
        local env = assert (luasql.sqlite3())
        local con = assert (env:connect("/siwifi.db"))
        local cmd = string.format([=[
        UPDATE %s SET %s WHERE %s
        ]=], tableName, update_k_v, condition_k_v)
        res = assert (con:execute(cmd))
        con:close()
        env:close()
    else
        res = sferr.ERROR_NO_GW_ILLEGAL_DB_PARAM
    end
    return res
end

function sql_insert_op(tableName, data, ret_table)
    local res = -1
    if tableName and type(tableName) == "string" and data and type(data) == "table" and ret_table and type(ret_table) == "table" then
        local random_str = nil
        if data.id then
            random_str = data.id
        else
            math.randomseed(os.time())
            local random1_int = math.random(math.ldexp(1,31)-1)
            local random2_int = math.random(math.ldexp(1,31)-1)
            random_str = string.format("%08x%08x", random1_int, random2_int)
        end
        data["objectId"] = random_str
        data["create_time"] = os.time()
        data["update_time"] = os.time()
        local insert_col = nil
        local insert_value = nil
        local count = 0
        for key,val in pairs(data) do
            if type(val) == "string" then
                val = "'"..val.."'"
            end

            if count == 0 then
                insert_col = key
                insert_value = val
            else
                insert_col = insert_col..","..key
                insert_value = insert_value..","..val
            end
            count = count + 1
        end
        local env = assert (luasql.sqlite3())
        local con = assert (env:connect("/siwifi.db"))
        local cmd = string.format([=[
            INSERT INTO %s (%s) VALUES (%s)
        ]=], tableName, insert_col, insert_value)
        res = assert (con:execute(cmd))
        ret_table["objectId"] = random_str
        con:close()
        env:close()
    else
        res = sferr.ERROR_NO_GW_ILLEGAL_DB_PARAM
    end
    return res
end

--func:sql_select_op
--brief:select from the database
--param:
--      tableName(string) --- the table will be select from
--      colName(array)    --- the col will be select        nil or {} means all col
--      condition(table)  --- the select condition          nil or {} means no condition
--      ret_table(table)  --- carry the select result
--return:   0----success   other----failed
--example:
--      sql_select_op("device_basic", {id,profileid}, nil, ret_table)    equal to the state "select id,profileid from device_basic"
--      sql_select_op("device_basci", nil, {id:"a2345123fe1c"}, ret_table)  equal to the state "select * from device_basic where id=\'a2345123fe1c\'"
function sql_select_op(tableName, colName, condition, ret_table)
    local res = -1
    if tableName and type(tableName) == "string" then
        local select_col = nil
        if colName and type(colName) == "table" then
            local count = 0
            for key,val in pairs(colName) do
                if count == 0 then
                    select_col = val
                else
                    select_col = select_col..","..val
                end
                count = count + 1
            end
        end
        count = 0
        local condition_k_v = nil
        if condition then
            for key,val in pairs(condition) do
                if type(val) == "string" then
                    val = "'"..val.."'"
                end
                if count == 0 then
                    condition_k_v = key.."="..val
                else
                    condition_k_v = condition_k_v..","..key.."="..val
                end
                count = count + 1
            end
        end
        if select_col == nil then
            select_col = " * "
        end
        if condition_k_v == nil then
            condition_k_v = ""
        else
            condition_k_v = " where "..condition_k_v
        end
        local cmd = string.format([=[
            select %s from %s %s
        ]=], select_col, tableName, condition_k_v)

        local env = assert (luasql.sqlite3())
        local con = assert (env:connect("/siwifi.db"))
        local cur = assert(con:execute(cmd))
        local colnames = cur:getcolnames()
        local coltype = cur:getcoltypes()
        local name_type_table = {}
        for i=1,#colnames do
            name_type_table[colnames[i]] = coltype[i]
        end
        while true do
            local row = cur:fetch({}, "a")
            if row then
                local index = #ret_table+1
                ret_table[index] = {}
                for key,val in pairs(row) do
                    if name_type_table[key]:match("varchar") then
                        ret_table[index][key] = tostring(val)
                    elseif name_type_table[key]:match("int") then
                        ret_table[index][key] = tonumber(val)
                    end
                end
            else
                break
            end
        end
        cur:close()
        con:close()
        env:close()
    else
        res = sferr.ERROR_NO_GW_ILLEGAL_DB_PARAM
    end
    return res
end


function sql_delete_op(tableName, condition)
    local res = -1
    if tableName and type(tableName) == "string" and condition and type(condition) == "table" then
        local count = 0
        local condition_k_v = nil
        for key,val in pairs(condition) do
            if type(val) == "string" then
                val = "'"..val.."'"
            end
            if count == 0 then
                condition_k_v = key.."="..val
            else
                condition_k_v = condition_k_v..","..key.."="..val
            end
            count = count + 1
        end
        local cmd = string.format([=[
            delete from %s where %s
        ]=], tableName, condition_k_v)
        local env = assert (luasql.sqlite3())
        local con = assert (env:connect("/siwifi.db"))
        res = assert(con:execute(cmd))
        con:close()
        env:close()
    else
        res = sferr.ERROR_NO_GW_ILLEGAL_DB_PARAM
    end
    return res
end

function insertDeviceData(basic_info, status, record)
    if basic_info and type(basic_info) == "table" then
        local table_name = "device_basic"
        local insert_col = ""
        local insert_value = ""
        local update_k_v = ""
        local count = 0
        local id = nil
        if basic_info.id then
            id = basic_info.id
        end

        for key,val in pairs(basic_info) do
            if type(val) == "string" then
                val = "'"..val.."'"
            end

            if count == 0 then
                insert_col = key
                insert_value = val
                update_k_v = key.."="..val
            else
                insert_col = insert_col..","..key
                insert_value = insert_value..","..val
                update_k_v = update_k_v..","..key.."="..val
            end
            count = count + 1
        end

        nixio.syslog("crit", "=====insert_col=="..insert_col)
        nixio.syslog("crit", "=====insert_value=="..insert_value)
        nixio.syslog("crit", "=====update_k_v=="..update_k_v)

        nixio.syslog("crit", "=========1")
        local env = assert (luasql.sqlite3())
        nixio.syslog("crit", "=========2")
        local con = assert (env:connect("/siwifi.db"))
        if con then
            nixio.syslog("crit", "====con is non-nil====")
        else
            nixio.syslog("crit", "====con is nil====")
        end
        nixio.syslog("crit", "=========3")
        local cmd = ""
        local cur = nil
        local row = nil
        nixio.syslog("crit", "=====id===="..id)
        cmd = string.format([=[
        SELECT * FROM %s WHERE id='%s'
        ]=], table_name, id)
        --	cmd = "SELECT * FROM device_basic WHERE id='00124b0008f237ff'"
        nixio.syslog("crit", "=======3.1===cmd=="..cmd)
        cur = assert(con:execute(cmd))

        --	nixio.syslog("crit", "=========4==="..cur)
        if cur then
            nixio.syslog("crit", "====cur is non-nil====")
        else
            nixio.syslog("crit", "====cur is nil====")
        end
        row = cur:fetch({}, "a")
        nixio.syslog("crit", "=====after cur-fetch====")
        if row then
            ----TODO----
            --update----
            cmd = string.format([=[
            UPDATE %s SET %s WHERE id='%s'
            ]=], table_name, update_k_v, id)
        else
            ----TODO----
            --insert----
            cmd = string.format([=[
            INSERT INTO %s (%s) VALUES (%s)
            ]=], table_name, insert_col, insert_value)
        end

        nixio.syslog("crit", "====cmd==="..cmd)

        --[[        local cmd = string.format([==[
        CREATE TABLE devices(
        id  varchar(50),
        profileid int,
        deviceid int,
        endpointid int,
        manufaceturerName varchar(50),
        swversion varchar(50),
        hwversion varchar(50),
        type int,
        location varchar(50)
        )]===])
        local res = assert (con:execute(cmd))
        ]]
        --        cmd = string.format([=[
        --        UPDATE device_basic SET
        --        ]=])
        --        cmd = string.format("INSERT INTO %s (%s) VALUES (%s)", table_name, col, value)
        --        res = assert (con:execute(cmd))
        nixio.syslog("crit", "======OK=====hahahah=====11")
        res = assert (con:execute(cmd))
        nixio.syslog("crit", "======OK=====hahahah=====")
        cur:close()
        con:close()
        env:close()
    end
end

