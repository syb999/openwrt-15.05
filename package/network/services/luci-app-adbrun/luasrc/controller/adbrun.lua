local uci = require "luci.model.uci".cursor()

module("luci.controller.adbrun",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/adbrun") then
		return
	end

	local page = entry({"admin", "services", "adbrun"}, cbi("adbrun"), _("ADBrun"),3)
	page.dependent = true

	entry({"admin", "services", "adbrun", "status"}, call("xact_status")).leaf = true
	entry({"admin", "services", "adbrun", "getscreen"}, call("getscreen")).leaf = true
end

function get_apk(ip,port)
	local apk = io.popen("adb -s " .. ip .. ":" .. port .." shell dumpsys activity activities | grep mResumedActivity: | cut -d '/' -f 1 | awk '{print $4}' 2>/dev/null")
	if apk then
		local name = apk:read("*l")
		apk:close()
		return name
	end
	return "checking"
end

function get_pid(ip)
	local pid = luci.sys.exec("busybox ps | grep ADBRUN$(uci show adbrun | grep " ..ip .. " | cut -d '.' -f 2) | grep -v grep | head -n 1 | awk '{print $1}' 2>/dev/null")
	return pid
end

function get_starttime(name)
	local fpath = "/tmp/ADBRUN" .. name .. "_.sh"
	local F,err=io.open(fpath,"r+");
	if err == nil then
		local st_time = luci.sys.exec("cat " .. fpath .. " | grep starttime= | cut -d '=' -f 2 2>/dev/null")
		if st_time == "" then
			return 0
		else
			return st_time
		end
	else
		return 0
	end
end

function get_uhttpd()
	local uhttpd = io.popen("uci get uhttpd.main.listen_http | awk '/0.0.0.0/ {print $1}' | cut -d ':' -f 2")
	if uhttpd then
		local webport = uhttpd:read("*l")
		uhttpd:close()
		return webport
	end
	return "80"
end

function xact_status()
	local webport = get_uhttpd()
	local adblist = io.popen("adb devices | sed '1d;$d' 2>/dev/null")
	if adblist then
		infolist = { }
		local num = 0
		local deviceid, port, name, lowername, runtime, runhours, runmins, runsecs, apk, pid
		while true do
			local ln = adblist:read("*l")
			if not ln then
				break
			elseif ln:match("(%S-):(%d+).device") then
				deviceid, port = ln:match("(%S-):(%d+).device")
				if num and deviceid and port then
					num = num + 1
					uci:foreach("adbrun", "adbrun", function(e)
						if e.adbiplist == deviceid then
							name = string.upper(e[".name"])
							lowername = string.lower(e[".name"])
							runtime = get_starttime(lowername)
							if runtime == nil then
								runtime = 0
							elseif tonumber(runtime) > 0 then
								runtime = os.time() - tonumber(runtime)
								if runtime >= 3600 then
									runhours = (runtime - runtime%3600)/3600
									local x = runtime%3600
									if x  >= 60 then
										runmins = (x - x%60)/60
										runsecs = x%60
									else
										runmins = 0
										runsecs = x
									end
								elseif runtime >= 60 then
									runhours = 0
									runmins = (runtime - runtime%60)/60
									runsecs = runtime%60
								else
									runhours = 0
									runmins = 0
									runsecs = runtime
								end
							else
								runtime = 0
							end
							if runtime == 0 then
								runhours = 0
								runmins = 0
								runsecs = 0
							end
						end
					end)
					apk = get_apk(deviceid,port)
					pid = get_pid(deviceid)
				end
			elseif ln:match("^(%w+).") then
				deviceid = ln:match("^(%w+).-")
				port = "USB-Cable"
				if num and deviceid then
					num = num + 1
					name = "Android"
					apk = "init_adbrun"
					pid = ""
					runtime = ""
					runhours = ""
					runmins = ""
					runsecs = ""
				end
			end

			infolist[#infolist+1] = {
				num = num,
				name = name,
				deviceid = deviceid,
				port = port,
				apk = apk,
				pid = pid,
				uhttpd = webport,
				runtime = runtime,
				runhours = runhours,
				runmins = runmins,
				runsecs = runsecs
			}

		end
	end
	adblist:close()

	luci.http.prepare_content("application/json")	
	luci.http.write_json(infolist);
end

function getscreen()
	if luci.http.formvalue('sctime') ~= "" then
		local gettime= luci.http.formvalue('sctime')
		if gettime % 3 == 1 then
			if luci.http.formvalue('screenid') ~= "" then
				local vid = luci.http.formvalue('screenid')
				luci.sys.call("adb -s " .. vid .. ":5555 exec-out screencap -p > /tmp/" .. vid .. ".png 2>/dev/null && ln -s /tmp/" .. vid .. ".png /www 2>/dev/null")
			end
		end
	end
end

