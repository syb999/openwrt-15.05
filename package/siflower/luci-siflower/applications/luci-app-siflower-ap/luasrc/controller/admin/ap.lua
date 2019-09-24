--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/7/17
-- Time: 13:58
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.ap", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require "luci.json"
local sferr = require "luci.siwifi.sf_error"
local sysutil = require "luci.siwifi.sf_sysutil"
local bit = require "bit"
local DEVICE_STATUS_OK = 1

function index()
	entry({"admin", "ap"}, template("siflower-ap/ap") , _("AP SET"), 64).logo = "ap";
	--AP分组相关的接口
	entry({"admin", "ap", "get_ap_groups"}, call("get_ap_groups")).leaf = true;
	--添加和设置ap分组都是用本接口
	entry({"admin", "ap", "set_ap_group"}, call("set_ap_group")).leaf = true;
	entry({"admin", "ap", "set_ap_freq_inter"}, call("set_ap_freq_inter")).leaf = true;
	entry({"admin", "ap", "get_ap_freq_inter"}, call("get_ap_freq_inter")).leaf = true;
	entry({"admin", "ap", "remove_ap_group"}, call("remove_ap_group")).leaf = true;
	entry({"admin", "ap", "import_ap_group_config"}, call("import_ap_group_config")).leaf = true;
	entry({"admin", "ap", "export_ap_group_config"}, call("export_ap_group_config")).leaf = true;
	--AP相关的接口
	entry({"admin", "ap", "get_ap_list"}, call("get_ap_list")).leaf = true;
	entry({"admin", "ap", "set_ap"}, call("set_ap")).leaf = true;
	entry({"admin", "ap", "delete_ap"}, call("delete_ap")).leaf = true;
end

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

function excute_with_return(params)
	local error_num = {}
	error_num[-1] = sferr.ERROR_INPUT_PARAM_ERROR
	error_num[0] = 0
	error_num[5] = sferr.ERROR_NO_FILE_OPERATE_FAILED
	error_num[11] = sferr.ERROR_NO_TRY_AGAIN
	error_num[12] = sferr.ERROR_NO_STORAGE_NOT_ENOUGH
	error_num[14] = sferr.ERROR_NO_UNKNOWN_ERROR
	error_num[16] = sferr.ERROR_NO_DEVICE_BUSY
	error_num[19] = sferr.ERROR_NO_DEVICE_NOT_FOUND
	error_num[22] = sferr.ERROR_INPUT_PARAM_ERROR
	error_num[35] = sferr.ERROR_NO_AP_VERSION_NOT_NEWEST
	error_num[65] = sferr.ERROR_AP_NO_RESPONSE
	local ret = os.execute(tostring(params))
	ret = bit.band(ret, 0xff00)
	local a = error_num[math.floor(ret / 256)]
	if (a == nil) then
		a = sferr.ERROR_NO_UNKNOWN_ERROR
	end
	return a
end

function get_ifaces(s)
	if (s) then
		local ifaces = {}
		local iface_2G = {}
		iface_2G["band"] = 0
		iface_2G["enable"] = s["2G_enabled"]
		iface_2G["ssid"] = s["2G_ssid"]
		iface_2G["isolation"] = s["2G_isolation"]
		iface_2G["hide"] = s["2G_hide"]
		iface_2G["band_width_limit"] = {}
		iface_2G["band_width_limit"]["enable"] = s["2G_bandwidth_limit"]
		iface_2G["band_width_limit"]["upload"] = s["2G_bandwidth_upload"]
		iface_2G["band_width_limit"]["download"] = s["2G_bandwidth_download"]
		iface_2G["encryption"] = s["2G_encryption"]
		iface_2G["password"] = s["2G_password"]
		iface_2G["channel"] = s["2G_channel"]
		iface_2G["bandwidth"] = s["2G_bandwidth"]
		iface_2G["enable_prevent"] = s["2G_prohibit_sta_signal_enable"]
		iface_2G["sta_min_dbm"] = s["2G_prohibit_sta_signal"]
		iface_2G["enable_kick"] = s["2G_weak_sta_signal_enable"]
		iface_2G["weak_sta_signal"] = s["2G_weak_sta_signal"]
		table.insert(ifaces, iface_2G)
		local iface_5G = {}
		iface_5G["band"] = 1
		iface_5G["enable"] = s["5G_enabled"]
		iface_5G["ssid"] = s["5G_ssid"]
		iface_5G["isolation"] = s["5G_isolation"]
		iface_5G["hide"] = s["5G_hide"]
		iface_5G["band_width_limit"] = {}
		iface_5G["band_width_limit"]["enable"] = s["5G_bandwidth_limit"]
		iface_5G["band_width_limit"]["upload"] = s["5G_bandwidth_upload"]
		iface_5G["band_width_limit"]["download"] = s["5G_bandwidth_download"]
		iface_5G["encryption"] = s["5G_encryption"]
		iface_5G["password"] = s["5G_password"]
		iface_5G["channel"] = s["5G_channel"]
		iface_5G["bandwidth"] = s["5G_bandwidth"]
		iface_5G["enable_prevent"] = s["5G_prohibit_sta_signal_enable"]
		iface_5G["sta_min_dbm"] = s["5G_prohibit_sta_signal"]
		iface_5G["enable_kick"] = s["5G_weak_sta_signal_enable"]
		iface_5G["weak_sta_signal"] = s["5G_weak_sta_signal"]
		table.insert(ifaces, iface_5G)
		return ifaces
	end
	return nil
end

function get_groups(flag)
	local groups = { }
	_uci_real:foreach("ap_groups", "group", function(s)
		local group = {}
		group["name"] = s[".name"]
		group["index"] = tonumber(s[".index"]) + 1
		local ifaces = get_ifaces(s)
		group["ifaces"] = ifaces
		local total = 0
		local alive = 0
		local unworkable = 0
		local devices = {}
		_uci_real:foreach("capwap_devices", "device", function(s)
			local device = {}
			if ( s["group"] == group["name"] ) then
				total = total + 1
				if ( tonumber(s["status"]) == DEVICE_STATUS_OK ) then
					alive = alive + 1
				else
					unworkable = unworkable + 1
				end
				if (tonumber(flag) == 0) then
					device["mac"] = s[".name"]
					device["name"] = s["name"]
					device["group"] = s["group"]
					device["model"] = s["model"]
					device["hardware_version"] = s["hardware_version"]
					device["firmware_version"] = s["firmware_version"]
					device["status"] = s["status"]
					device["ap_alive_time"] = s["ap_alive_time"]
					device["client_alive_time"] = s["client_alive_time"]
					device["client_idle_time"] = s["client_idle_time"]
					device["led"] = s["led"]
					if (s["custom_wifi"] == "group") then
						device["ifaces"] = ifaces
					else
						device["ifaces"] = get_ifaces(s)
					end
					table.insert(devices, device)
				end
			end
		end)
		if (tonumber(flag) == 0) then
			group["devices"] = devices
		end
		group["info"] = {}
		group["info"]["total"] = total
		group["info"]["alive"] = alive
		group["info"]["unworkable"] = unworkable
		table.insert(groups, group)
	end)
	--reverse groups from 2 for the recent edit or add group on top
	local group_len = #groups
	for i=2, group_len do
		local tmp_group = {}
		local tmp_index,tmp_index_2
		if i  < group_len + 2 -i then
			tmp_group = groups[i]
			tmp_index = groups[i].index
			tmp_index_2 = groups[group_len + 2 -i].index
			groups[i] = groups[group_len + 2 -i]
			groups[i].index = tmp_index

			groups[group_len + 2 -i]  = tmp_group
			groups[group_len + 2 -i].index = tmp_index_2
		end
	end

	return groups
end

function get_devices()
	local groups = get_groups(0)
	local devices = {}
	for i = 1, #groups do
		for j = 1, #groups[i]["devices"] do
			table.insert(devices, groups[i]["devices"][j])
		end
	end
	return devices
end

function get_ap_groups()
	local result = {}
	local code = 0
	result["ap_group_list"] = get_groups(1)
	sysutil.set_easy_return(code, result)
end

function set_ap_group_impl(arg_list_table)
	local groups = get_groups(0)
	local s_name
	local index = 0
	if (arg_list_table["index"]) then
		index = tonumber(arg_list_table["index"])
		s_name = groups[index]["name"]
	else
		if (arg_list_table["name"] ) then
			_uci_real:set("ap_groups", arg_list_table["name"], "group")
			s_name = arg_list_table["name"]
			--set default channel if channel is nil
			if arg_list_table["ifaces"] then
				for i = 1, #arg_list_table["ifaces"] do
					if ( arg_list_table["ifaces"][i]["band"] == 0) then
						if (not arg_list_table["ifaces"][i]["channel"] ) then
							_uci_real:set("ap_groups", s_name, "2G_channel", "1")
						end
					else
						if (not arg_list_table["ifaces"][i]["channel"] ) then
							_uci_real:set("ap_groups", s_name, "5G_channel", "161")
						end
					end
				end
			end
		else
			return sferr.ERROR_INPUT_PARAM_ERROR
		end
	end

	if arg_list_table["ifaces"] then
		for i = 1, #arg_list_table["ifaces"] do
			if ( arg_list_table["ifaces"][i]["band"] == 0) then
				if (arg_list_table["ifaces"][i]["enable"] ) then
					_uci_real:set("ap_groups", s_name, "2G_enabled", arg_list_table["ifaces"][i]["enable"])
				end
				if (arg_list_table["ifaces"][i]["ssid"] ) then
					_uci_real:set("ap_groups", s_name, "2G_ssid", arg_list_table["ifaces"][i]["ssid"])
				end
				if (arg_list_table["ifaces"][i]["isolation"] ) then
					_uci_real:set("ap_groups", s_name, "2G_isolation", arg_list_table["ifaces"][i]["isolation"])
				end
				if (arg_list_table["ifaces"][i]["hide"] ) then
					_uci_real:set("ap_groups", s_name, "2G_hide", arg_list_table["ifaces"][i]["hide"])
				end
				if (arg_list_table["ifaces"][i]["encryption"] ) then
					_uci_real:set("ap_groups", s_name, "2G_encryption", arg_list_table["ifaces"][i]["encryption"])
				end
				if (arg_list_table["ifaces"][i]["password"] ) then
					_uci_real:set("ap_groups", s_name, "2G_password", arg_list_table["ifaces"][i]["password"])
				end
				if (arg_list_table["ifaces"][i]["channel"] ) then
					_uci_real:set("ap_groups", s_name, "2G_channel", arg_list_table["ifaces"][i]["channel"])
				end
				if (arg_list_table["ifaces"][i]["bandwidth"] ) then
					_uci_real:set("ap_groups", s_name, "2G_bandwidth", arg_list_table["ifaces"][i]["bandwidth"])
				end
				if (arg_list_table["ifaces"][i]["enable_prevent"] ) then
					_uci_real:set("ap_groups", s_name, "2G_prohibit_sta_signal_enable", arg_list_table["ifaces"][i]["enable_prevent"])
				end
				if (arg_list_table["ifaces"][i]["sta_min_dbm"] ) then
					_uci_real:set("ap_groups", s_name, "2G_prohibit_sta_signal", arg_list_table["ifaces"][i]["sta_min_dbm"])
				end
				if (arg_list_table["ifaces"][i]["enable_kick"] ) then
					_uci_real:set("ap_groups", s_name, "2G_weak_sta_signal_enable", arg_list_table["ifaces"][i]["enable_kick"])
				end
				if (arg_list_table["ifaces"][i]["weak_sta_signal"] ) then
					_uci_real:set("ap_groups", s_name, "2G_weak_sta_signal", arg_list_table["ifaces"][i]["weak_sta_signal"])
				end

				if (arg_list_table["ifaces"][i]["band_width_limit"] ) then
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["enable"] ) then
						_uci_real:set("ap_groups", s_name, "2G_bandwidth_limit", arg_list_table["ifaces"][i]["band_width_limit"]["enable"] )
					end
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["upload"] ) then
						_uci_real:set("ap_groups", s_name, "2G_bandwidth_upload", arg_list_table["ifaces"][i]["band_width_limit"]["upload"] )
					end
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["download"] ) then
						_uci_real:set("ap_groups", s_name, "2G_bandwidth_download", arg_list_table["ifaces"][i]["band_width_limit"]["download"])
					end
				end
				_uci_real:set("ap_groups", s_name, "2G_country_code", "CN")
			else
				if (arg_list_table["ifaces"][i]["enable"] ) then
					_uci_real:set("ap_groups", s_name, "5G_enabled", arg_list_table["ifaces"][i]["enable"])
				end
				if (arg_list_table["ifaces"][i]["ssid"] ) then
					_uci_real:set("ap_groups", s_name, "5G_ssid", arg_list_table["ifaces"][i]["ssid"])
				end
				if (arg_list_table["ifaces"][i]["isolation"] ) then
					_uci_real:set("ap_groups", s_name, "5G_isolation", arg_list_table["ifaces"][i]["isolation"])
				end
				if (arg_list_table["ifaces"][i]["hide"] ) then
					_uci_real:set("ap_groups", s_name, "5G_hide", arg_list_table["ifaces"][i]["hide"])
				end
				if (arg_list_table["ifaces"][i]["encryption"] ) then
					_uci_real:set("ap_groups", s_name, "5G_encryption", arg_list_table["ifaces"][i]["encryption"])
				end
				if (arg_list_table["ifaces"][i]["password"] ) then
					_uci_real:set("ap_groups", s_name, "5G_password", arg_list_table["ifaces"][i]["password"])
				end
				if (arg_list_table["ifaces"][i]["channel"] ) then
					_uci_real:set("ap_groups", s_name, "5G_channel", arg_list_table["ifaces"][i]["channel"])
				end
				if (arg_list_table["ifaces"][i]["bandwidth"] ) then
					_uci_real:set("ap_groups", s_name, "5G_bandwidth", arg_list_table["ifaces"][i]["bandwidth"])
				end
				if (arg_list_table["ifaces"][i]["enable_prevent"] ) then
					_uci_real:set("ap_groups", s_name, "5G_prohibit_sta_signal_enable", arg_list_table["ifaces"][i]["enable_prevent"])
				end
				if (arg_list_table["ifaces"][i]["sta_min_dbm"] ) then
					_uci_real:set("ap_groups", s_name, "5G_prohibit_sta_signal", arg_list_table["ifaces"][i]["sta_min_dbm"])
				end
				if (arg_list_table["ifaces"][i]["enable_kick"] ) then
					_uci_real:set("ap_groups", s_name, "5G_weak_sta_signal_enable", arg_list_table["ifaces"][i]["enable_kick"])
				end
				if (arg_list_table["ifaces"][i]["weak_sta_signal"] ) then
					_uci_real:set("ap_groups", s_name, "5G_weak_sta_signal", arg_list_table["ifaces"][i]["weak_sta_signal"])
				end

				if (arg_list_table["ifaces"][i]["band_width_limit"] ) then
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["enable"] ) then
						_uci_real:set("ap_groups", s_name, "5G_bandwidth_limit", arg_list_table["ifaces"][i]["band_width_limit"]["enable"] )
					end
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["upload"] ) then
						_uci_real:set("ap_groups", s_name, "5G_bandwidth_upload", arg_list_table["ifaces"][i]["band_width_limit"]["upload"] )
					end
					if ( arg_list_table["ifaces"][i]["band_width_limit"]["download"] ) then
						_uci_real:set("ap_groups", s_name, "5G_bandwidth_download", arg_list_table["ifaces"][i]["band_width_limit"]["download"])
					end
				end
				_uci_real:set("ap_groups", s_name, "5G_country_code", "CN")
			end
		end
	end

	if (arg_list_table["index"]) then
		if ( arg_list_table["name"] ~= s_name ) and ( tonumber( arg_list_table["index"]) ~= 1 ) then
			local values = _uci_real:get_all("ap_groups", s_name)
			_uci_real:section("ap_groups", "group", arg_list_table["name"], values)
			_uci_real:delete("ap_groups", s_name)

			_uci_real:save("ap_groups")
			_uci_real:commit("ap_groups")
			--set ap deivces group name
			local devices = groups[index]["devices"]
			for i = 1, #devices do
				local json_params = {}
				json_params["command"] = "set_group_name"
				json_params["device"] = devices[i]["mac"]
				json_params["name_of_group"] = arg_list_table["name"]
				local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
				if ( tonumber(excute_ret) ~= 0) then
					nixio.syslog("crit", "set ap groups :"..myprint(excute_ret))
					return tonumber(excute_ret)
				end
			end
			s_name = arg_list_table["name"]
		else
			_uci_real:save("ap_groups")
			_uci_real:commit("ap_groups")
		end

		local json_params = {}
		json_params["command"] = "ap_group_change"
		json_params["name_of_group"] = s_name
		local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
		if ( tonumber(excute_ret) ~= 0) then
			nixio.syslog("crit", "set device to ap groups :"..myprint(excute_ret))
			return tonumber(excute_ret)
		end
	else
		_uci_real:save("ap_groups")
		_uci_real:commit("ap_groups")
	end
	return 0
end

function set_ap_group()
	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)

	local result = {}

	code = set_ap_group_impl(arg_list_table)

	sysutil.set_easy_return(code, nil)
end

function remove_ap_group_impl(arg_list_table)
	local groups = get_groups(0)
	if (arg_list_table["index"]) then
		--TODO: check index
		local index_list = {}
		if type(arg_list_table["index"]) == "table" then
			index_list = arg_list_table["index"]
		else
			index_list[1] = arg_list_table["index"]
		end

		for j = 1, #index_list do
			_uci_real:delete("ap_groups", groups[tonumber(index_list[j])]["name"])
			local json_params = {}
			json_params["command"] = "ap_group_delete"
			json_params["name_of_group"] = groups[tonumber(index_list[j])]["name"]
			local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
			if ( excute_ret ~= 0) then
				return  excute_ret
			end
		end
	end

	_uci_real:save("ap_groups")
	_uci_real:commit("ap_groups")
	return 0
end

function remove_ap_group()
	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)

	code = remove_ap_group_impl(arg_list_table)

	sysutil.set_easy_return(code, nil)
end

function import_ap_group_config()
	--文件名为：ap_group_config
	local restore_cmd = "/tmp/ap_capwap.tar.gz"
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
	--TODO: check ap_groups here
	local err = luci.util.exec("sh /usr/sbin/ac_import.sh")
	local code = tonumber(err)
	if code ~= 0 then
		code = sferr.ERROR_ILLEGAL_FILE
	end
	sysutil.set_easy_return(code, nil)
end

function export_ap_group_config()
	luci.util.exec("tar -C /etc/config/ -zcvf /tmp/ap_capwap.tar.gz ap_groups capwap_devices")
	if sysutil.checkFileExist("/tmp/ap_capwap.tar.gz") then
		local reader = nixio.fs.readfile("/tmp/ap_capwap.tar.gz")
		luci.http.header('Content-Disposition', 'attachment; filename="apconfig-%s-%s.tar.gz"' % {luci.sys.hostname(), os.date("%Y-%m-%d")})
		luci.http.prepare_content("text/plain")
		luci.http.write(reader)
	else
		nixio.syslog("crit", "export config error!")
		return
	end
	luci.util.exec("rm /tmp/ap_capwap.tar.gz")

end

function get_ap_list()
	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)
	local result = {}
	local code = 0
	local msg = "OK"
	local groups = get_groups(0)
	if (arg_list_table["index"]) then
		result["ap_list"] = groups[tonumber(arg_list_table["index"])]["devices"]
	else
		code = sferr.ERROR_INPUT_PARAM_ERROR
	end

	sysutil.set_easy_return(code, result)
end

function set_ap_impl(arg_list_table)

	local devices = get_devices()
	local groups = get_groups(1)

	if (arg_list_table["macs"] == nil) then
		return 0
	end
	local macs = arg_list_table["macs"]
	for i = 1, #macs do
		if (_uci_real:get("capwap_devices", macs[i], "status") == nil) then
			return 0
		end
		local json_params = {}
		json_params["device"] = macs[i]
		if (arg_list_table["ap_group_index"]) then
			--_uci_real:set("capwap_devices", macs[i], "group", groups[tonumber(arg_list_table["ap_group_index"])]["name"])
			json_params["command"] = "set_device_to_group"
			json_params["name_of_group"] = groups[tonumber(arg_list_table["ap_group_index"])]["name"]
		else
			json_params["command"] = "set_device_config"
			json_params["dev_config"] = {}
			if (arg_list_table["name"]) then
				--_uci_real:set("capwap_devices", macs[i], "name", arg_list_table["name"])
				json_params["dev_config"]["name"] = arg_list_table["name"]
			end
			if (arg_list_table["ap_alive_time"]) then
				--_uci_real:set("capwap_devices", macs[i], "ap_alive_time", arg_list_table["ap_alive_time"])
				json_params["dev_config"]["ap_alive_time"] = arg_list_table["ap_alive_time"]
			end
			if (arg_list_table["client_idle_time"]) then
				--_uci_real:set("capwap_devices", macs[i], "client_idle_time", arg_list_table["client_idle_time"])
				json_params["dev_config"]["client_idle_time"] = arg_list_table["client_idle_time"]
			end
			if (arg_list_table["client_idle_time"]) then
				--_uci_real:set("capwap_devices", macs[i], "client_idle_time", arg_list_table["client_idle_time"])
				json_params["dev_config"]["client_idle_time"] = arg_list_table["client_idle_time"]
			end
			if (arg_list_table["led"]) then
				--_uci_real:set("capwap_devices", macs[i], "led", arg_list_table["led"])
				json_params["dev_config"]["led"] = arg_list_table["led"]
			end
			if (arg_list_table["ifaces"]) then
				local wifi_config = {}
				wifi_config[0] = "wifi_2g_config"
				wifi_config[1] = "wifi_5g_config"
				--_uci_real:set("capwap_devices", macs[i], "custom_wifi", 1)
				for k = 1, #arg_list_table["ifaces"] do
					local band = arg_list_table["ifaces"][k]["band"]
					local wifi_json = {}
					if(arg_list_table["ifaces"][k]["enable"]) then
						wifi_json["enabled"] = arg_list_table["ifaces"][k]["enable"]
						--_uci_real:set("capwap_devices", macs[i], "2G_enabled", arg_list_table["ifaces"][k]["enable"])
					end
					if(arg_list_table["ifaces"][k]["ssid"]) then
						wifi_json["ssid"] = arg_list_table["ifaces"][k]["ssid"]
						--_uci_real:set("capwap_devices", macs[i], "2G_ssid", arg_list_table["ifaces"][k]["ssid"])
					end
					if(arg_list_table["ifaces"][k]["hide"]) then
						wifi_json["hide"] = arg_list_table["ifaces"][k]["hide"]
						--_uci_real:set("capwap_devices", macs[i], "2G_hide", arg_list_table["ifaces"][k]["hide"])
					end
					if(arg_list_table["ifaces"][k]["isolation"]) then
						wifi_json["isolation"] = arg_list_table["ifaces"][k]["isolation"]
						--_uci_real:set("capwap_devices", macs[i], "2G_isolation", arg_list_table["ifaces"][k]["isolation"])
					end
					if(arg_list_table["ifaces"][k]["encryption"]) then
						--_uci_real:set("capwap_devices", macs[i], "2G_encryption", arg_list_table["ifaces"][k]["encryption"])
						wifi_json["encryption"] = arg_list_table["ifaces"][k]["encryption"]
					end
					if(arg_list_table["ifaces"][k]["password"]) then
						wifi_json["password"] = arg_list_table["ifaces"][k]["password"]
						--_uci_real:set("capwap_devices", macs[i], "2G_password", arg_list_table["ifaces"][k]["password"])
					end
					if(arg_list_table["ifaces"][k]["channel"]) then
						wifi_json["channel"] = arg_list_table["ifaces"][k]["channel"]
						--_uci_real:set("capwap_devices", macs[i], "2G_channel", arg_list_table["ifaces"][k]["channel"])
					end
					if(arg_list_table["ifaces"][k]["bandwidth"]) then
						wifi_json["bandwidth"] = arg_list_table["ifaces"][k]["bandwidth"]
						--_uci_real:set("capwap_devices", macs[i], "2G_bandwidth", arg_list_table["ifaces"][k]["bandwidth"])
					end

					if(arg_list_table["ifaces"][k]["enable_prevent"]) then
						wifi_json["prohibit_sta_signal_enable"] = arg_list_table["ifaces"][k]["enable_prevent"]
						--_uci_real:set("capwap_devices", macs[i], "2G_channel", arg_list_table["ifaces"][k]["channel"])
					end
					if(arg_list_table["ifaces"][k]["sta_min_dbm"]) then
						wifi_json["prohibit_sta_signal"] = arg_list_table["ifaces"][k]["sta_min_dbm"]
						--_uci_real:set("capwap_devices", macs[i], "2G_channel", arg_list_table["ifaces"][k]["channel"])
					end
					if(arg_list_table["ifaces"][k]["enable_kick"]) then
						wifi_json["weak_sta_signal_enable"] = arg_list_table["ifaces"][k]["enable_kick"]
						--_uci_real:set("capwap_devices", macs[i], "2G_channel", arg_list_table["ifaces"][k]["channel"])
					end
					if(arg_list_table["ifaces"][k]["weak_sta_signal"]) then
						wifi_json["weak_sta_signal"] = arg_list_table["ifaces"][k]["weak_sta_signal"]
						--_uci_real:set("capwap_devices", macs[i], "2G_channel", arg_list_table["ifaces"][k]["channel"])
					end

					if (arg_list_table["ifaces"][k]["band_width_limit"]) then
						if(arg_list_table["ifaces"][k]["band_width_limit"]["enable"]) then
							wifi_json["bandwidth_limit"] = arg_list_table["ifaces"][k]["band_width_limit"]["enable"]
							--_uci_real:set("capwap_devices", macs[i], "2G_bandwidth_limit", arg_list_table["ifaces"][k]["band_width_limit"]["enable"])
						end
						if(arg_list_table["ifaces"][k]["band_width_limit"]["upload"]) then
							wifi_json["bandwidth_upload"] = arg_list_table["ifaces"][k]["band_width_limit"]["upload"]
							--_uci_real:set("capwap_devices", macs[i], "2G_bandwidth_upload", arg_list_table["ifaces"][k]["band_width_limit"]["upload"])
						end
						if(arg_list_table["ifaces"][k]["band_width_limit"]["download"]) then
							wifi_json["bandwidth_download"] = arg_list_table["ifaces"][k]["band_width_limit"]["download"]
							--_uci_real:set("capwap_devices", macs[i], "2G_bandwidth_download", arg_list_table["ifaces"][k]["band_width_limit"]["download"])
						end
					end
					json_params[wifi_config[band]] = wifi_json
				end
			end
		end
		local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
		if ( excute_ret ~= 0) then
			return excute_ret
		end
	end
	return 0
end
--设置ap设备，包括修改分组
--除了macs所有的参数都是可选项
--[[local params =
{--AP的数组
{
macs = {"11:22:33:44:55:66", "aa:bb:cc:dd:ee:ff"}, --序号
ap_group_index = 2,  --目标分组
name = "xxxx", --名字
led = false, --led的显示状态
ifaces = { --此处不赘述，请参考get_ap_groups中的描述
},
ap_alive_time = 30, --AP保活时间 单位：秒
client_alive_time = 300, --客户端保活时间 单位：秒
client_idle_time = 3600, --客户端限制时间 单位：秒
vlan_id = 1, --有限LAN VLAN ID 取值范围（1-4094）
self_management = false --离线自管理
}
}]]
function set_ap()

	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)

	code = set_ap_impl(arg_list_table)

	sysutil.set_easy_return(code, nil)
end

--当前的定义：可以删除离线的device
function delete_ap_impl(arg_list_table)
	if (arg_list_table["macs"]) then
		local macs = arg_list_table["macs"]
		for j =1, #macs do
			local status = _uci_real:get("capwap_devices", macs[j], "status")
			if( status ~= nil and status ~= DEVICE_STATUS_OK) then
				local json_params = {}
				json_params["command"] = "delete_device"
				json_params["device"] = macs[j]
				local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
				if ( excute_ret ~= 0) then
					return excute_ret
				end
			end
		end
	end
	return 0
end

--当前的定义：可以删除离线的device
--[[
local params = {
macs = {"aa_bb_cc_dd_ee_ff","11_22_33_44_55_66"}
}
]]
function delete_ap()
	--参考参数
	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)


	code = delete_ap_impl(arg_list_table)

	sysutil.set_easy_return(code, nil)
end

function set_ap_freq_inter_impl(arg_list_table)

	local l_enable = _uci_real:get("basic_setting","ac", "freq_inter")
	local g_name = {}
	nixio.syslog("crit", "set enable"..tostring(arg_list_table.enable).." local  :"..l_enable)
	if arg_list_table.enable  ~= tonumber(l_enable) then
		_uci_real:set("basic_setting","ac", "freq_inter", tostring(arg_list_table.enable))
		_uci_real:save("basic_setting")
		_uci_real:commit("basic_setting")
		_uci_real:foreach("ap_groups", "group", function(s)
			if arg_list_table.enable  == 1 then
				g_name[#g_name + 1] = s[".name"]
				if string.sub(s["5G_ssid"],-3)  == "-5G" then
					_uci_real:set("ap_groups",s[".name"], "5G_ssid", string.sub(s["5G_ssid"],1,-4))
					s["5G_ssid"] = string.sub(s["5G_ssid"],1,-4)
				end

				nixio.syslog("crit", "5g ssid "..s["5G_ssid"])
				_uci_real:set("ap_groups",s[".name"], "2G_enabled", s["5G_enabled"])
				_uci_real:set("ap_groups",s[".name"], "2G_ssid", s["5G_ssid"])
				_uci_real:set("ap_groups",s[".name"], "2G_encryption", s["5G_encryption"])

				if s["5G_hide"] == '1' or s["2G_hide"] == '1' then
					_uci_real:set("ap_groups",s[".name"], "2G_hide", '1')
					_uci_real:set("ap_groups",s[".name"], "5G_hide", '1')
				else
					_uci_real:set("ap_groups",s[".name"], "2G_hide", '0')
					_uci_real:set("ap_groups",s[".name"], "5G_hide", '0')
				end
				if s["5G_encryption"] ~= "open" then
					_uci_real:set("ap_groups",s[".name"], "2G_password", s["5G_password"])
				end

			else
				g_name[#g_name + 1] = s[".name"]
				_uci_real:set("ap_groups",s[".name"], "2G_ssid", s["5G_ssid"].."-2.4G")
			end
		end)

		_uci_real:save("ap_groups")
		_uci_real:commit("ap_groups")
		for i = 1, #g_name do
			local json_params = {}
			json_params["command"] = "ap_group_change"
			json_params["name_of_group"] = g_name[i]
			nixio.syslog("crit", "cmd :WUM -c json -j '%s'" %{json.encode(json_params)})
			local excute_ret = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params)})
			if ( excute_ret ~= 0) then
				return excute_ret
			end
		end
		_uci_real:foreach("capwap_devices", "device", function(c)
			local enabled_24g = _uci_real:get("capwap_devices", c[".name"], "5G_enabled")
			local ssid_24g = _uci_real:get("capwap_devices", c[".name"], "5G_ssid")
			local encryption_24g = _uci_real:get("capwap_devices", c[".name"], "5G_encryption")
			local password_24g = _uci_real:get("capwap_devices", c[".name"], "5G_password")
			local _device = _uci_real:get("capwap_devices", c[".name"], "mac")
			local custom_wifi = _uci_real:get("capwap_devices", c[".name"], "custom_wifi")

			local json_params_c = {}
			json_params_c["command"] = "set_device_config"
			json_params_c["device"] = _device
			json_params_c["wifi_2g_config"] = {}
			if custom_wifi == nil then
				if arg_list_table.enable == 1 then
					if(enabled_24g) then
						json_params_c["wifi_2g_config"]["enabled"] = enabled_24g
					end
					if(ssid_24g) then
						json_params_c["wifi_2g_config"]["ssid"] = ssid_24g
					end
					if(encryption_24g) then
						json_params_c["wifi_2g_config"]["encryption"] = encryption_24g
					end
					if(password_24g) then
						json_params_c["wifi_2g_config"]["password"] = password_24g
					end
				else
					if(enabled_24g) then
						json_params_c["wifi_2g_config"]["ssid"] = ssid_24g.."-2.4G"
					end
				end
				nixio.syslog("crit", "cmd :WUM -c json -j '%s'" %{json.encode(json_params_c)})
				local excute_ret_c = excute_with_return("WUM -c json -j '%s'" %{json.encode(json_params_c)})
				if ( excute_ret_c ~= 0) then
					return excute_ret_c
				end
			end
			return 0
		end)

	end
	return 0
end

function set_ap_freq_inter()
	local arg_list = luci.http.content()
	local arg_list_table = json.decode(arg_list)

	code = set_ap_freq_inter_impl(arg_list_table)

	sysutil.set_easy_return(code, nil)
end

function get_ap_freq_inter_impl()
	local result = {}
	result.enable =  _uci_real:get("basic_setting","ac", "freq_inter")
	return 0, result
end

function get_ap_freq_inter()
	code, result = get_ap_freq_inter_impl()

	sysutil.set_easy_return(code, result)
end
