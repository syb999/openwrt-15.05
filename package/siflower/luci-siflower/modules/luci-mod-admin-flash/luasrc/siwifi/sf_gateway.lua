--[[
LuCI - Lua Configuration Interface

Description:
Offers an util to resolve gateway information
]]--


module ("luci.siwifi.sf_gateway", package.seeall)

local sysconfig  = require "luci.siwifi.sf_sysconfig"
local json = require "luci.json"
local db = require "luci.siwifi.sf_gwdata"
local sferr = require "luci.siwifi.sf_error"
local sysutil = require "luci.siwifi.sf_sysutil"

------define--------
local ZCL_HA_PROFILE_ID = 0x0104
local ZCL_SHUNCOM_PROFILE_ID = 0x0105
local ZLL_PROFILE_ID = 0xc05e

local ZCL_HA_DEVICEID_ON_OFF_LIGHT           = 0x0100
local ZCL_HA_DEVICEID_DIMMABLE_LIGHT         = 0x0101
local ZCL_HA_DEVICEID_COLORED_DIMMABLE_LIGHT = 0x0102


local ZLL_DEVICEID_COLOR_LIGHT               = 0x0200
local ZLL_DEVICEID_EXTENDED_COLOR_LIGHT      = 0x0210
local ZLL_DEVICEID_DIMMABLE_LIGHT            = 0x0100

local LIGHT_BULB = 1001





function checkDeviceInfo(deviceInfo)
    local res = 0
    local basicInfo = {}
    local statusInfo = {}
    local select_ret = {}
    local location = nil
    local ruleid = {}
    if deviceInfo then
        local cond = {}
        cond.id = deviceInfo.id
        db.sql_select_op("device_basic", nil, cond, select_ret)
        if #select_ret == 1 then
            if select_ret[1].location then
                location = select_ret[1].location
            end
            if select_ret[1].ruleid then
                ruleid = json.decode(select_ret[1].ruleid)
            end
            res = 0
        elseif #select_ret == 0 then
            res = 1
        else
            res = -1
        end
    end
    if res ~= -1 then
        if deviceInfo.online then statusInfo.online = deviceInfo.online end
        if deviceInfo.id then
            statusInfo.id = deviceInfo.id
            basicInfo.id = deviceInfo.id
        end
        if deviceInfo.online and deviceInfo.online == 1 then
            if deviceInfo.profileid then basicInfo.profileid = deviceInfo.profileid end
            if deviceInfo.deviceid then basicInfo.deviceid = deviceInfo.deviceid end
            if deviceInfo.endpointid then basicInfo.endpointid = deviceInfo.endpointid end
            if deviceInfo.id then basicInfo.id = deviceInfo.id end
            if location and string.len(location)>0 then
                basicInfo.location = location
            else
                basicInfo.location = deviceInfo.id
            end
            if ruleid then basicInfo.ruleid = ruleid end
            if deviceInfo.hwversion then basicInfo.hwversion = deviceInfo.hwversion end
            if deviceInfo.swversion then basicInfo.swversion = deviceInfo.swversion end
            if deviceInfo.ManufacturerName then basicInfo.ManufacturerName = deviceInfo.ManufacturerName end

            if deviceInfo.data then statusInfo.data = deviceInfo.data end
        end
    end
    return res, basicInfo, statusInfo
end

function getAllZigbeeDev()
    local ret_device = {}
    local device_str = ""
    local device_fd = io.popen("ubus call zha list 2>/dev/null")
    if device_fd then
        local tmp = nil
        repeat
            tmp = device_fd:read("*l")
            if tmp then device_str = device_str..tmp end
        until(tmp == nil)
        device_fd:close()
    end
    local device_json = json.decode(device_str)
    local origin_item_name = {"profileid", "deviceid", "endpointid", "id", "SWversion", "HWversion", "online", "ManufacturerName"}
    local sf_item_name = {"profileid", "deviceid", "endpointid", "id", "swversion", "hwversion", "online", "manufacturerName", "location"}
    if device_json and device_json.devices then
--        local device_tmp = {}
        for i=1,#device_json.devices do
--[=[            device_tmp[i] = {}
            for j=1,#origin_item_name do
                if device_json.devices[i][origin_item_name[j]] then
                    device_tmp[i][origin_item_name[j]] = device_json.devices[i][origin_item_name[j]]
                end
            end
            device_tmp[i].data = json.decode(device_json.devices[i].data)
            ]=]
            local deviceInfoNeedInsert, basicInfo, statusInfo = checkDeviceInfo(device_json.devices[i])
            if deviceInfoNeedInsert == 1 then
                local basic_objectId = {}
                local status_objectId = {}
                for basicInfo_key, basicInfo_val in pairs(basicInfo) do
                    if type(basicInfo_val) == "table" then
                        basicInfo[basicInfo_key] = json.encode(basicInfo_val)
                    end
                end
                db.sql_insert_op("device_basic", basicInfo, basic_objectId)
                db.sql_insert_op("device_status", statusInfo, status_objectId)
            elseif deviceInfoNeedInsert == 0 then
                local cond = {}
                for basicInfo_key, basicInfo_val in pairs(basicInfo) do
                    if type(basicInfo_val) == "table" then
                        basicInfo[basicInfo_key] = json.encode(basicInfo_val)
                    end
                end
                cond.id = device_json.devices[i].id
                db.sql_update_op("device_basic", basicInfo, cond)
                db.sql_update_op("device_status", statusInfo, cond)
            else
                local cond = {}
                cond.id = device_json.devices[i].id
                db.sql_delete_op("device_basic", cond)
                db.sql_delete_op("device_status", cond)
            end
        end
        local device_basic = {}
        local device_status = {}
        db.sql_select_op("device_basic", nil, nil, device_basic)
        db.sql_select_op("device_status", nil, nil, device_status)
        for i=1,#device_basic do
            local device_tmp = {}
            for j=1,#device_status do
                if device_basic[i].id == device_status[j].id then
                    if device_status[j].data then device_tmp.data = json.decode(device_status[j].data) end
                    if device_status[j].online then device_tmp.online = device_status[j].online end
                    break;
                end
            end
--            if ret_device[i].online and ret_device[i].online == 0 or (ret_device[i].online == 1 and ret_device[i].data) then
            if device_tmp.online and device_tmp.online == 1 and device_tmp.data then
                ret_device[#ret_device+1] = {}
                for k=1,#sf_item_name do
                    if device_basic[i][sf_item_name[k]] then
                        ret_device[#ret_device][sf_item_name[k]] = device_basic[i][sf_item_name[k]]
                    end
                end
                ret_device[#ret_device].data = device_tmp.data
                ret_device[#ret_device].online = device_tmp.online
            end
        end
        if #ret_device == 0 then
            return nil
        end
        return ret_device
    end
    return nil
end

function delZigbeeDev(id)
    if id then
        luci.util.exec("ubus call zha leave_req '{\"id\":%s}'" %{id})
    else
        nixio.syslog("crit", "delete zigbee device parameter illegal")
    end
end

function permitJoinZigbeeDev(time)
    if time then
        --TODO----
        --1.list currect online device
        --2.permit_join(duration)
        --do
        --3.list currect online device
        --while(new device join)
        --4.permit_join(0)
        local last_all_device = {}
        local last_online_device = {}
        last_all_device = getAllZigbeeDev()
        luci.util.exec("ubus call zha time '{\"time\":%d}'" %{time})
        local cur_all_device = {}
        local cur_online_device = {}
        cur_all_device = getAllZigbeeDev()
        for i=1,#cur_all_device do
            if cur_all_device.online == true then

            end
        end
    else
        syslog("crit", "permit_join zigbee device parameter illegal")
    end
end


function checkBasicInfoChanges(newInfo, oldInfo)
    local res = 0
    local newBasicInfo = {}
    newBasicInfo.profileid = newInfo["profileid"]
    newBasicInfo.deviceid = newInfo["deviceid"]
    newBasicInfo.id = newInfo["id"]
    newBasicInfo.endpointid = newInfo["endpointid"]
    if newInfo and oldInfo then
        if newInfo.location and oldInfo.location and oldInfo.location ~= newInfo.location then
            newBasicInfo.location = newInfo.location
            res = 1
        end
    end
    return res, newBasicInfo
end


function setZigbeeDev(setting_param, id)
    local res = 0
    local setting = {}
    local status = {}
	local sync_data = {}
    if setting_param and id then
        local cond = {}
        local select_ret = {}
        cond.id = id
        db.sql_select_op("device_basic", nil, cond, select_ret)
        local item = nil
        if #select_ret == 1 then
            item = select_ret[1]
        end
        if item then
            if setting_param.data then
                setting = setting_param.data
				local status_ret = {}
				db.sql_select_op("device_status", nil, cond, status_ret)
				if #status_ret == 1 and status_ret[1].data then
					for status_key, status_val in pairs(json.decode(status_ret[1].data)) do
						if not setting_param.data[status_key] then
							setting_param.data[status_key] = status_val
						end
					end
				end
				status.data = json.encode(setting_param.data)
				db.sql_update_op("device_status", status, cond)

				sync_data.zigbee_device_status = {}
				db.sql_select_op("device_status", nil, cond, sync_data.zigbee_device_status)
			end
			if setting_param.location then
				setting["location"] = setting_param.location
			end
			if setting.colortemp then setting.colortemp = nil end     ---------to disable colortemp
			setting["profileid"] = item.profileid
			setting["deviceid"] = item.deviceid
			setting["id"] = item.id
			setting["endpointid"] = item.endpointid
			if setting.profileid == ZCL_HA_PROFILE_ID then
				if setting.deviceid == ZCL_HA_DEVICEID_DIMMABLE_LIGHT or
					setting.deviceid == ZCL_HA_DEVICEID_ON_OFF_LIGHT or
					setting.deviceid == ZCL_HA_DEVICEID_COLORED_DIMMABLE_LIGHT then
					if setting.on then
						if setting.on == 1 or setting.on == true then
							setting.on = true
						else
							setting.on = false
							setting.hue = nil
							setting.bri = nil
							setting.sat = nil
							setting.colortemp = nil
						end
					end
				end
			elseif setting.profileid == ZLL_PROFILE_ID then
				if setting.deviceid == ZLL_DEVICEID_COLOR_LIGHT or
					ZLL_DEVICEID_EXTENDED_COLOR_LIGHT or
					ZLL_DEVICEID_DIMMABLE_LIGHT then
					if setting.on then
						if setting.on == 1 or setting.on == true then
							setting.on = true
						else
							setting.on = false
							setting.hue = nil
							setting.bri = nil
							setting.sat = nil
							setting.colortemp = nil
						end
					end
				end
			end
			local check_ret, newBasicInfo = checkBasicInfoChanges(setting, item)
			if check_ret == 1 then
				db.sql_update_op("device_basic", newBasicInfo, cond)

				sync_data.zigbee_device_basic = {}
				db.sql_select_op("device_basic", nil, cond, sync_data.zigbee_device_basic)
			end
			luci.util.exec("ubus call zha set \'%s\'" %{json.encode(setting)})
			local data_str = json.encode(sync_data)
			local cmd = "UCIM -data "..data_str
			local cmd_ret = {}
			sysutil.sendCommandToLocalServer(cmd, cmd_ret)
		else
			res = sferr.ERROR_NO_GW_DEVICE_NOT_EXIST
		end
	end
	return res
end

function createZigbeeGroup(name, group_ret)
	local name_table = {}
	if name then
		name_table.name = name
	else
		return
	end
	local group = {}
	local group_str = ""
	local cmd_str = string.format("ubus call zha group_create \'%s\' 2>/dev/null", json.encode(name_table))
	local group_fd = io.popen(cmd_str)
	if group_fd then
		local tmp = nil
		repeat
			tmp = group_fd:read("*l")
			if tmp then group_str = group_str..tmp end
		until(tmp == nil)
		group_fd:close()
	end
	group = json.decode(group_str)
	for k,v in pairs(group) do
		group_ret[k] = group[k]
	end
	socket.select(nil,nil,0.1)
end

function setZigbeeGroup(setting, groupid)
	local setting_param = {}
	setting_param["id"] = groupid
	setting_param["visible"] = "123"
	setting_param["device"] = {}
	for k,v in pairs(setting) do
		setting_param.device[k] = {}
		setting_param.device[k].id = setting[k].id
		setting_param.device[k].endpointid = setting[k].endpointid
	end

    local cmd_str = string.format("ubus call zha group_set \'%s\' 2>/dev/null", json.encode(setting_param))
    luci.util.exec(cmd_str)
    socket.select(nil,nil,0.1)
    local exec_param = {}
    exec_param["id"] = groupid

    if setting[1]["on"] or setting[1]["hue"] or setting[1]["sat"] or setting[1]["colortemp"] or setting[1]["bri"] then
        if setting[1].on then exec_param["on"] = setting[1].on end
        if setting[1].hue then exec_param["hue"] = setting[1].hue end
        if setting[1].sat then exec_param["sat"] = setting[1].sat end
        if setting[1].colortemp then exec_param["colortemp"] = setting[1].colortemp end
        if setting[1].bri then exec_param["bri"] = setting[1].bri end
    else
        exec_param["on"] = false
    end
    cmd_str = string.format("ubus call zha group_set \'%s\' 2>/dev/null", json.encode(exec_param))
    luci.util.exec(cmd_str)
    socket.select(nil,nil,0.1)
end

function delZigbeeGroup(groupid)
    local group_info = {}
    group_info.id = groupid
    local cmd_str = string.format("ubus call zha group_del \'%s\' 2>/dev/null", json.encode(group_info))
    luci.util.exec(cmd_str)
end


function fetchSetting(setting_param, id)
    local res = 0
    local setting = {}
    local status = {}
    if setting_param and id then
        local cond = {}
        local select_ret = {}
        cond.id = id
        db.sql_select_op("device_basic", nil, cond, select_ret)
        local item = nil
        if #select_ret == 1 then
            item = select_ret[1]
        end
        if item then
            if setting_param.data then
                setting = setting_param.data
                status.data = json.encode(setting_param.data)
                db.sql_update_op("device_status", status, cond)
            end
            if setting_param.location then
                setting["location"] = setting_param.location
            end
            setting["profileid"] = item.profileid
            setting["deviceid"] = item.deviceid
            setting["id"] = item.id
            setting["endpointid"] = item.endpointid
            if setting.profileid == ZCL_HA_PROFILE_ID then
                if setting.deviceid == ZCL_HA_DEVICEID_DIMMABLE_LIGHT or
                    setting.deviceid == ZCL_HA_DEVICEID_ON_OFF_LIGHT or
                    setting.deviceid == ZCL_HA_DEVICEID_COLORED_DIMMABLE_LIGHT then
                    if setting.on then
                        if setting.on == 1 then
                            setting.on = true
                        else
                            setting.on = false
                        end
                    end
                end
            elseif setting.profileid == ZLL_PROFILE_ID then
                if setting.deviceid == ZLL_DEVICEID_COLOR_LIGHT or
                    ZLL_DEVICEID_EXTENDED_COLOR_LIGHT or
                    ZLL_DEVICEID_DIMMABLE_LIGHT then
                    if setting.on then
                        if setting.on == 1 then
                            setting.on = true
                        else
                            setting.on = false
                        end
                    end
                end
            end
            local check_ret, newBasicInfo = checkBasicInfoChanges(setting, item)
            if check_ret == 1 then
                db.sql_update_op("device_basic", newBasicInfo, cond)
            end
            return setting
--            luci.util.exec("ubus call zha set \'%s\'" %{json.encode(setting)})
        else
            res = sferr.ERROR_NO_GW_DEVICE_NOT_EXIST
        end
    end
    return res
end

function getZigbeeEventRecord(id)
    local record_ret = {}
    local select_ret = {}
    local select_cond = {}
    local sf_device_record_key = {"event","create_time"}
    select_cond.id = id
    db.sql_select_op("device_record", nil, select_cond, select_ret)
    for select_ret_index,select_ret_item in pairs(select_ret) do
        record_ret[select_ret_index] = {}
        for sf_device_record_key_index, sf_device_record_key_item in pairs(sf_device_record_key) do
            if select_ret_item[sf_device_record_key_item] then record_ret[select_ret_index][sf_device_record_key_item] = select_ret_item[sf_device_record_key_item] end
        end
    end
    return record_ret
end

function checkZigbeeRuleRepeat(new_cond)
    local res = 1
    local get_rule_res = 0
    local rule_ret = {}
    local repeat_ruleid = {}
    if new_cond and #new_cond > 0 then
        get_rule_res, rule_ret = getZigbeeRuleById(new_cond[1].id)
        if get_rule_res == 0 then
            for i,rule_item in pairs(rule_ret) do
                if rule_item.rule then
                    --                    and rule_item.rule.cond then
                    local cond_count = 0
                    local equal_count = 0
                    for k=1,#rule_item.rule do
                        if rule_item.rule[k].cond and rule_item.rule[k].cond.event and rule_item.rule[k].id then
                            cond_count = cond_count + 1
                            for n, new_cond_item in pairs(new_cond) do
                                if new_cond_item.id
                                    and rule_item.rule[k].id == new_cond_item.id
                                    and new_cond_item.cond
                                    and new_cond_item.cond.event
                                    and rule_item.rule[k].cond.event == new_cond_item.cond.event then
                                    equal_count = equal_count + 1
                                end
                            end

--[=[                        if #rule_item.cond == #new_cond then
                            local equal_count = 0
                            for j,exist_cond_item in pairs(rule_itemi.rule[].cond) do
                                if exist_cond_item.id and exist_cond_item.cond and exist_cond_item.cond.event then
                                    for n, new_cond_item in pairs(new_cond) do
                                        if new_cond_item.id
                                            and exist_cond_item.id == new_cond_item.id
                                            and new_cond_item.cond
                                            and new_cond_item.cond.event
                                            and exist_cond_item.cond.event == new_cond_item.cond.event then
                                            equal_count = equal_count + 1
                                        end
                                    end
                                end
                            end
                            if #new_cond == equal_count then
                                res = 0
                                repeat_ruleid[#repeat_ruleid+1] = rule_item.objectid
                            end
                            ]=]
                        end
                    end
                    if cond_count == equal_count then
                        res = 0
                        repeat_ruleid[#repeat_ruleid+1] = rule_item.ruleid
                    end
                else
                    res = -1
                end
            end
        elseif get_rule_res == 1 then
            res = 1
        else
            res = -1
        end
    else
        res = -1
    end
    return res, repeat_ruleid
end

function createZigbeeRule(name, rule)
    local res = 0
    local ret = {}
	local sync_data = {}
	local rule_sync = {}
	local basic_sync = {}
    local rule_content = {}
    local rule_cond = {}
    local rule_act = {}
    if rule then
        for i=1,#rule do
            if rule[i].cond and rule[i].id then
                rule_cond[#rule_cond+1] = {}
                rule_cond[#rule_cond].cond = rule[i].cond
                rule_cond[#rule_cond].id = rule[i].id
            end
            if rule[i].act and rule[i].id then
                rule_act[#rule_act+1] = {}
                rule_act[#rule_act].act = rule[i].act
                rule_act[#rule_act].id = rule[i].id
            end
        end
        rule_content.cond = json.encode(rule_cond)
        rule_content.act = json.encode(rule_act)
        if name then rule_content.name = name end
        local check_repeat_res, check_repeat_ruleid = checkZigbeeRuleRepeat(rule_cond)
        if check_repeat_res and check_repeat_res == -1 then
            return -1, nil
        elseif check_repeat_res and check_repeat_res == 0 and check_repeat_ruleid then   --the cond is repeated
            for i=1,#check_repeat_ruleid do
                delZigbeeRule(check_repeat_ruleid[i])
            end
            --need to delete the old rule
        elseif check_repeat_res and check_repeat_res == 1 then   --the cond is new
            --need do nothing
        else
            return -1, nil
        end
        db.sql_insert_op("zigbee_rule", rule_content, ret)
		local select_rule_cond = {}
		select_rule_cond.objectid = ret.objectId
		db.sql_select_op("zigbee_rule", nil, select_rule_cond, rule_sync)

--        update_content.ruleid = ret.objectId
        local rule_cond_act_array = {}
        for rule_cond_index,rule_cond_item in pairs(rule_cond) do
            rule_cond_act_array[#rule_cond_act_array+1] = rule_cond_item
        end
        for rule_act_index,rule_act_item in pairs(rule_act) do
            rule_cond_act_array[#rule_cond_act_array+1] = rule_act_item
        end
        for i=1,#rule_cond_act_array do
            local select_cond = {}
            local select_item = {}
            local update_cond = {}
            local update_content = {}
            local ret_device_basic = {}
            local device_basic = {}
            local cur_device_basic_ruleid = {}

            select_cond.id = rule_cond_act_array[i].id
            update_cond.id = rule_cond_act_array[i].id
            select_item[#select_item+1] = "ruleid"

            db.sql_select_op("device_basic", select_item, select_cond, ret_device_basic)
            if #ret_device_basic == 1 then
                if ret_device_basic[1].ruleid and ret_device_basic[1].ruleid then
                    cur_device_basic_ruleid = json.decode(ret_device_basic[1].ruleid)
                    cur_device_basic_ruleid[#cur_device_basic_ruleid+1] = ret.objectId
--                    cur_device_basic_ruleid[#old_device_basic[1].ruleid+1] = ret.objectId
                else
                    cur_device_basic_ruleid[1] = ret.objectId
                end
                update_content.ruleid = json.encode(cur_device_basic_ruleid)
                db.sql_update_op("device_basic", update_content, update_cond)
				local tmp_select_ret = {}
				db.sql_select_op("device_basic", nil, update_cond, tmp_select_ret)
				if #tmp_select_ret==1 then
					basic_sync[#basic_sync+1] = tmp_select_ret[1]
				end
            else
                res = -1
            end
        end
		sync_data.zigbee_device_baisc = basic_sync
		sync_data.zigbee_rule = rule_sync
		local data_str = json.encode(sync_data)
		local cmd = "UCIM -data "..data_str
		local cmd_ret = {}
		sysutil.sendCommandToLocalServer(cmd, cmd_ret)
--[=[        for i=1,#rule_act do
            local update_cond = {}
            update_cond.id = rule_act[i].id
            db.sql_update_op("device_basic", update_content, update_cond)
        end
        ]=]
    else
        res = -1
    end
    return res, ret.objectId
end

function delZigbeeRule(ruleid)
    local res = 0
	local sync_data = {}
	local basic_sync = {}
    if ruleid then
        local select_cond = {}
        select_cond.objectid = ruleid
        rule = {}
        related_id = {}
        db.sql_select_op("zigbee_rule", nil, select_cond, rule)
        if #rule == 1 then
            if rule[1].cond then
                local cond_array = json.decode(rule[1].cond)
                for k,cond_item in pairs(cond_array) do
                    related_id[#related_id+1] = cond_item.id
                end
            end
            if rule[1].act then
                local act_array = json.decode(rule[1].act)
                for k,act_item in pairs(act_array) do
                    related_id[#related_id+1] = act_item.id
                end
            end
        else
            res = -1
        end

        for i=1,#related_id do
            local select_cond = {}
            local update_cond = {}
            select_cond.id = related_id[i]
            update_cond.id = related_id[i]
            local select_ret = {}
            local update_content_ruleid = {}
            db.sql_select_op("device_basic", nil, select_cond, select_ret)
            if #select_ret == 1 then
                if select_ret[1].ruleid then
                    device_ruleid_array = json.decode(select_ret[1].ruleid)
                    for k,device_ruleid_item in pairs(device_ruleid_array) do
                        if ruleid ~= device_ruleid_item then
                            update_content_ruleid[#update_content_ruleid+1] = device_ruleid_item
                        end
                    end
                end
                local update_content = {}
                update_content.ruleid = json.encode(update_content_ruleid)
                db.sql_update_op("device_basic", update_content, update_cond)
				local tmp_select_ret = {}
                db.sql_update_op("device_basic", update_content, update_cond)
				db.sql_select_op("device_basic", nil, update_cond, tmp_select_ret)
				if #tmp_select_ret==1 then
					basic_sync[#basic_sync+1] = tmp_select_ret[1]
				end
            else
                res = -1
            end
        end
        local delete_cond = {}
        delete_cond.objectid = ruleid
        db.sql_delete_op("zigbee_rule", delete_cond)
		sync_data.zigbee_rule = {}
		sync_data.zigbee_rule[1] = {}
		sync_data.zigbee_rule[1].objectid = ruleid
		sync_data.zigbee_rule[1].delete = 1

		sync_data.zigbee_device_basic = basic_sync
		local data_str = json.encode(sync_data)
		local cmd = "UCIM -data "..data_str
		local cmd_ret = {}
		sysutil.sendCommandToLocalServer(cmd, cmd_ret)
    else
        res = -1
    end
    return res
end

function getZigbeeAllRule()
    local res = 0
    local rule_ret = {}
    res, rule_ret = getZigbeeRuleByRuleid(nil)
    return res, rule_ret
end

function getZigbeeRuleByRuleid(ruleid)
    local res = 0
    local rule_ret = {}
    local select_ret = {}
    if ruleid then
        local select_cond = {}
        select_cond.objectid = ruleid
        db.sql_select_op("zigbee_rule", nil, select_cond, select_ret)
    else
        db.sql_select_op("zigbee_rule", nil, nil, select_ret)
    end
    local sf_rule_item_name_array = {"objectid", "cond", "act", "create_time", "update_time"}
    local sf_device_basic_item_name_array = {"id","profileid", "endpointid", "deviceid", "manufacturerName", "swversion", "hwversion", "type", "location"}
    local sf_device_status_item_name = {"online"}
    local sf_cond_act_name_array = {"cond", "act"}
    for rule_index,rule_item in pairs(select_ret) do          --decode the rule select result
        rule_ret[rule_index] = {}
        rule_ret[rule_index]["rule"] = {}
        for sf_rule_item_name_index,sf_rule_item_name in pairs(sf_rule_item_name_array) do
            if rule_item[sf_rule_item_name] then
                if sf_rule_item_name == "act" or sf_rule_item_name == "cond" then
--                    rule_ret[rule_index][sf_rule_item_name] = json.decode(rule_item[sf_rule_item_name])           --decode the rule-act or rule-cond
                    local rule_cond_act = json.decode(rule_item[sf_rule_item_name])
                    for rule_cond_act_index,rule_cond_act_item in pairs(rule_cond_act) do         --select device basic/status info by rule-act or rule-cond
                        local select_device_basic_cond = {}
                        local select_device_status_cond = {}
                        local select_device_basic_ret = {}
                        local select_device_status_ret = {}
                        select_device_basic_cond.id = rule_cond_act_item.id
                        select_device_status_cond.id = rule_cond_act_item.id
                        db.sql_select_op("device_basic", nil, select_device_basic_cond, select_device_basic_ret)
                        db.sql_select_op("device_status", nil, select_device_status_cond, select_device_status_ret)
                        local tmp_index = #rule_ret[rule_index]["rule"]+1
                        rule_ret[rule_index]["rule"][tmp_index] = {}
                        for cond_act_key,cond_act_val in pairs(rule_cond_act_item) do
                            if cond_act_key == "cond" then rule_ret[rule_index]["rule"][tmp_index]["cond"] = cond_act_val end
                            if cond_act_key == "act" then rule_ret[rule_index]["rule"][tmp_index]["act"] = cond_act_val end
                        end
                        if #select_device_basic_ret == 1 then
                            for device_basic_index, device_basic_item in pairs(select_device_basic_ret) do
                                for sf_device_basic_item_name_index,sf_device_basic_item_name in pairs(sf_device_basic_item_name_array) do
                                    if sf_device_basic_item_name == "manufacturerName" then
                                        rule_ret[rule_index]["rule"][tmp_index]["manufacturername"] = device_basic_item[sf_device_basic_item_name]
                                    else
                                        rule_ret[rule_index]["rule"][tmp_index][sf_device_basic_item_name] = device_basic_item[sf_device_basic_item_name]
                                    end
                                end
                            end
                        end
                        if #select_device_status_ret == 1 then
                            for device_status_index, device_status_item in pairs(select_device_status_ret) do
                                for sf_device_status_item_name_index,sf_device_status_item_name in pairs(sf_device_status_item_name) do
                                    rule_ret[rule_index]["rule"][tmp_index][sf_device_status_item_name] = select_device_status_ret[1][sf_device_status_item_name]
                                end
                            end
                        end
                    end
                elseif sf_rule_item_name == "objectid" then
                    rule_ret[rule_index]["ruleid"] = select_ret[rule_index][sf_rule_item_name]
                else
                    rule_ret[rule_index][sf_rule_item_name] = select_ret[rule_index][sf_rule_item_name]
                end
            end
        end
        local select_cond = {}
        select_cond.ruleid = ruleid
        local rule_record_ret = {}
        db.sql_select_op("rule_record", nil, select_cond, rule_record_ret)
        rule_ret[rule_index].trigger_count = #rule_record_ret
    end
    if ruleid then
        return res, rule_ret[1]
    else
        return res, rule_ret
    end
end


-----return:
--error           -1
--ret not empty   0
--ret is empty    1
function getZigbeeRuleById(id)
    local res = 0
    local rule_ret = {}
    local select_ret = {}
    if id then
        local select_cond = {}
        select_cond.id = id
        db.sql_select_op("device_basic", "nil", select_cond, select_ret)
    else
        res = -1
    end
    if #select_ret == 1 then
        if select_ret[1].ruleid then
            local ruleid_ret = json.decode(select_ret[1].ruleid)
            for i=1,#ruleid_ret do
                local get_rule_res = 0
                rule_ret[i] = {}
                local rule_tmp = nil
                get_rule_res, rule_tmp = getZigbeeRuleByRuleid(ruleid_ret[i])
                if get_rule_res ~= 0 then
                    res = -1
                else
                    if rule_tmp then
                        rule_ret[i] = rule_tmp
                    else
                        res = -1
                    end
                end
            end
        else
            res = -1
        end
    else
        res = 1
    end
    return res, rule_ret
end



function setZigbeeRule(name, ruleid, rule)
    local res = 0
	local basic_sync = {}
	local rule_sync = {}
	local sync_data = {}
    local rule_content = {}
    local rule_cond = {}
    local rule_act = {}
    local insert_id_array = {}
    local delete_id_array = {}
    if rule then
        local get_rule_res, old_rule_ret = getZigbeeRuleByRuleid(ruleid)
        for i=1,#rule do
            if rule[i].cond and rule[i].id then
                rule_cond[#rule_cond+1] = {}
                rule_cond[#rule_cond].cond = rule[i].cond
                rule_cond[#rule_cond].id = rule[i].id
            end
            if rule[i].act and rule[i].id then
                rule_act[#rule_act+1] = {}
                rule_act[#rule_act].act = rule[i].act
                rule_act[#rule_act].id = rule[i].id
            end
        end
        rule_content.cond = json.encode(rule_cond)
        rule_content.act = json.encode(rule_act)
        if name then rule_content.name = name end
        if get_rule_res == 0 then
            if old_rule_ret and old_rule_ret.rule then
                for old_rule_cond_act_index, old_rule_cond_act_item in pairs(old_rule_ret.rule) do
                    local delete_flag = 1
                    for i=1,#rule do
                        if old_rule_cond_act_item.id and old_rule_cond_act_item.id == rule[i].id then
                            delete_flag = 0
                        end
                    end
                    if delete_flag == 1 then
                        delete_id_array[#delete_id_array+1] = old_rule_cond_act_item.id
                    end
                end
                for new_rule_con_act_index, new_rule_cond_act_item in pairs(rule) do
                    local insert_flag = 1
                    for i=1,#old_rule_ret.rule do
                        if new_rule_cond_act_item.id and new_rule_cond_act_item.id == old_rule_ret.rule[i].id then
                            insert_flag = 0
                        end
                    end
                    if insert_flag == 1 then
                        insert_id_array[#insert_id_array+1] = new_rule_cond_act_item.id
                    end
                end
            end
        end

        for i=1,#delete_id_array do          --delete ruleid from device_basic
            local update_delete_cond = {}
            local device_basic_ret = {}
            local update_ruleid = {}
            local update_content = {}
            update_delete_cond.id = delete_id_array[i]
            db.sql_select_op("device_basic", nil, update_delete_cond, device_basic_ret)
            if #device_basic_ret == 1 then
                local device_basic_ruleid = {}
                if device_basic_ret[1].ruleid then
                    device_basic_ruleid = json.decode(device_basic_ret[1].ruleid)
                    for k=1,#device_basic_ruleid do
                        if device_basic_ruleid[k] ~= ruleid then
                            update_ruleid[#update_ruleid+1] = device_basic_ruleid[k]
                        end
                    end
                    update_content.ruleid = json.encode(update_ruleid)
                    db.sql_update_op("device_basic", update_content, update_delete_cond)
					local tmp_select_ret = {}
					db.sql_select_op("device_basic", nil, update_delete_cond, tmp_select_ret)
					if #tmp_select_ret == 1 then
						basic_sync[#basic_sync+1] = tmp_select_ret[1]
					end
                else
                    res = -1
                end
            else
                res = -1
            end
        end

        for i=1,#insert_id_array do
            local update_insert_cond = {}
            local device_basic_ret = {}
            local update_content = {}
            update_insert_cond.id = insert_id_array[i]
            db.sql_select_op("device_basic", nil, update_insert_cond, device_basic_ret)
            if #device_basic_ret == 1 then
                local device_basic_ruleid = {}
                if device_basic_ret[1].ruleid then
                    device_basic_ruleid = json.decode(device_basic_ret[1].ruleid)
                    device_basic_ruleid[#device_basic_ruleid+1] = ruleid
                    update_content.ruleid = json.encode(device_basic_ruleid)
                    db.sql_update_op("device_basic", update_content, update_insert_cond)
					local tmp_select_ret = {}
					db.sql_select_op("device_basic", nil, update_insert_cond, tmp_select_ret)
					if #tmp_select_ret == 1 then
						basic_sync[#basic_sync+1] = tmp_select_ret[1]
					end
                else
                    res = -1
                end
            else
                res = -1
            end
        end

        local update_cond = {}
        update_cond.objectid = ruleid
        db.sql_update_op("zigbee_rule", rule_content, update_cond)
		db.sql_select_op("zigbee_rule", nil, update_cond, rule_sync)

		sync_data.zigbee_device_basic = basic_sync
		sync_data.zigbee_rule = rule_sync

		local data_str = json.encode(sync_data)
		local cmd = "UCIM -data "..data_str
		local cmd_ret = {}
		sysutil.sendCommandToLocalServer(cmd, cmd_ret)

        -------TODO------------
        --update device_basic--
    else
        res = -1
    end
    return res
end



function getAllZigbeeBasic()
    local select_ret = {}
    db.sql_select_op("device_basic", nil, nil, select_ret)
    return select_ret
end

function getAllZigbeeStatus()
    local select_ret = {}
    db.sql_select_op("device_status", nil, nil, select_ret)
    return select_ret
end

function getAllZigbeeRule()
    local select_ret = {}
    db.sql_select_op("zigbee_rule", nil, nil, select_ret)
    return select_ret
end

function getAllDeviceRecord()
    local select_ret = {}
    db.sql_select_op("device_record", nil, nil, select_ret)
    return select_ret
end

function getAllRuleRecord()
    local select_ret = {}
    db.sql_select_op("rule_record", nil, nil, select_ret)
    return select_ret
end

