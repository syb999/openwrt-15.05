--
-- Created by IntelliJ IDEA.
-- User: tommy
-- Date: 2018/6/7
-- Time: 11:00
-- To change this template use File | Settings | File Templates.
--
module("luci.controller.admin.mainp", package.seeall)
local uci = require "luci.model.uci"
local _uci_real  = cursor or _uci_real or uci.cursor()
local nixio = require "nixio"
local json = require "luci.json"
local fs  = require "nixio.fs"
local zones = require "luci.sys.zoneinfo"
ipc = require "luci.ip"
wirep = require "luci.controller.admin.wirelessp"

function index()
    entry({"admin", "mainp"}, template("86v/main"), _("Main"), 60).attrid = "mainp";
    entry({"admin", "mainp", "get_device_info"}, call("get_device_info")).leaf = true;
    entry({"admin", "mainp", "get_wireless_client"}, call("get_wireless_client")).leaf = true;
    entry({"admin", "mainp", "get_wireless_params"}, call("get_wireless_params")).leaf = true;
end

function getHardware()
	local cpuinfo = fs.readfile("/etc/openwrt_release")
	local model = cpuinfo:match("DISTRIB_CODENAME='([^']+)")
	model = string.gsub(model, "%c", "")
	local a,t
	t = io.popen("cat /sys/devices/factory-read/hw_ver_flag | awk -F \"\" ' {for(i=1; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\" ) && (length($i) == 1)) a=a$i }} END{print a}'")
	if not t  then
		t = io.popen("hexdump -c -n2 -s 27 /dev/mtdblock2 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END{print a}'")
	end
	if t  then
		a = t:read("*all")
		t:close()
		if string.find(a,"hv") then
	         t = io.popen("cat /sys/devices/factory-read/hw_ver | awk -F \"\" '{for(i=1; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\" ) && (length($i) == 1)) a=a$i }} END {print a}'");
			 if not t  then
				t = io.popen("hexdump -c -n32 -s 29 /dev/mtdblock2 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END {print a}'");
		     end 
	         if t  then
	            a = t:read("*all")
	            model = a
	            t:close()
	         end
	      end
	   end
	   return model
end

function getModel()
	local cpuinfo = fs.readfile("/etc/openwrt_release")
	local model = cpuinfo:match("DISTRIB_CODENAME='([^']+)")
	model = string.gsub(model, "%c", "")
	local a,t
	t = io.popen("cat /sys/devices/factory-read/model_ver_flag | awk -F \"\" ' {for(i=1; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END{print a}'")
	if not t  then	
		t = io.popen("hexdump -c -n2 -s 63 /dev/mtdblock2 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END{print a}'")
	end
	if t  then
		a = t:read("*all")
		t:close()
		if string.find(a,"mv") then
			 t = io.popen("cat /sys/devices/factory-read/model_ver | awk -F \"\" ' {for(i=1; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END {print a}'");
	         if not t  then
				t = io.popen("hexdump -c -n32 -s 65 /dev/mtdblock2 | awk ' {for(i=2; i<=NF; i++){ if (($i <= \"z\") && ( $i >= \"!\"   ) && (length($i) == 1)) a=a$i   }} END {print a}'");
			 end
			 if t  then
	            a = t:read("*all")
	            model = a
	            t:close()
	         end
	      end
	   end
	   return model
end

function get_device_info()
	local boardinfo = luci.util.ubus("system", "board")
	local strlist = luci.util.split(boardinfo.release.description, ' ')
	--hardware = getHardware()
	hardware = getModel()
	software = strlist[3] or {}
	local ntm = require "luci.model.network".init()
	local net = ntm:get_network("lan")
	local device = net and net:get_interface()
    local z2 = luci.sys.exec("cat /etc/TZ"):match("^([^%s]+)")
    local czones = {}
    for _, z in ipairs(zones.TZ_NEW) do
        table.insert(czones, z[1])
        if z[2] == z2 then z2 = z[1] end
    end

	local info = {
		device_mode = hardware,
		mac = device:mac(),
		ip = net:ipaddr(),
        zone = z2, --时区
        zones = czones,
		time = os.time(),
		start_time = tonumber(_uci_real:get("system","ntp","start"))
	}

	result = {
		code = 0,
		msg = "OK",
		info = info
    }

    nixio.syslog("crit", myprint(result))
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function get_wireless_client()
	local network = require("luci.model.network").init()
	local band2 = {}
	local band5 = {}
	local wifis = wirep.sf_wifinetworks()
	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)
		if wifidev:get("band") == "2.4G" then
			for _, nets in ipairs(dev.networks) do
				if nets.assoclist then
					for name, client in pairs(nets.assoclist) do
						band2[ #band2 + 1  ] = {
							mac=name,
							wireless_net= nets.ssid,
							connect_time = client.connected_time
						}
					end
				end
			end
		end
		if wifidev:get("band") == "5G" then
			for _, nets in ipairs(dev.networks) do
				if nets.assoclist then
					for name, client in pairs(nets.assoclist) do

						band5[ #band5 + 1  ] = {
							mac=name,
							wireless_net= nets.ssid,
							connect_time = client.connected_time
						}
					end
				end
			end
		end
	end

	result = {
		code = 0,
		msg = "OK",
		band2= band2,
		band5= band5
	}

	--nixio.syslog("crit", myprint(result))
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function get_wireless_params()
	local band2 = {}
	local band5 = {}
	local wifis = wirep.sf_wifinetworks()
	local network = require("luci.model.network").init()

	for i, dev in pairs(wifis) do
		wifidev = network:get_wifidev(dev.device)

		if wifidev:get("band") == "2.4G" then
			local htcoex = wifidev:get("ht_coex")
			if (htcoex == "1") then
				htmode = "auto"
			else
				htmode = wifidev:get("htmode")
			end

			local hwmode = wifidev:get("hwmode")
			if htmode == "HT20" or htmode == "HT40" or htmode == "auto" then
				hwmode = "11n"
			end

			band2 = {
				htmode = htmode,
				hwmode = hwmode,
			}

			local iw = luci.sys.wifi.getiwinfo("radio0")--从实际wifi信息中获取2.4G的channel
			if iw ~= nil and iw.channel ~= nil then
				band2["channel"] = iw.channel
			end
		elseif wifidev:get("band") == "5G" then
			local htcoex = wifidev:get("ht_coex")
			if (htcoex == "1") then
				htmode = "auto"
			else
				htmode = wifidev:get("htmode")
			end

			local hwmode = wifidev:get("hwmode")
			if htmode == "HT20" or htmode == "HT40" or htmode == "auto" then
				hwmode = "11n"
			elseif htmode == "VHT20" or htmode == "VHT40" or htmode == "VHT80" then
				hwmode = "11ac"
			end

			band5 = {
				htmode = htmode,
				hwmode = hwmode,
			}

			local iw = luci.sys.wifi.getiwinfo("radio1")--从实际wifi信息中获取5G的channel
			if iw ~= nil and iw.channel ~= nil then
				band5["channel"] = iw.channel
			end
		end
	end

	result = {
		code = 0,
		msg = "OK",
		band2= band2,
		band5= band5
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
