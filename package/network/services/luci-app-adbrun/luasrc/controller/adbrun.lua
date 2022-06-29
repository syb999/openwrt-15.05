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

function get_model(ip,port)
	local model = luci.sys.exec("adb -s " .. ip .. ":" .. port .." shell getprop ro.product.model | sed 's/ //g' 2>/dev/null")
	if not model then
		model = luci.sys.exec("adb -s " .. ip .. ":" .. port .." shell getprop ro.product.model | sed 's/ //g' 2>/dev/null")
	end
	return model
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
		local deviceid, port, model, apk, pid
		while true do
			local ln = adblist:read("*l")
			if not ln then
				break
			elseif ln:match("(%S-):(%d+).-") then
				deviceid, port = ln:match("(%S-):(%d+).-")
				if num and deviceid and port then
					num = num + 1
					model = get_model(deviceid,port)
					apk = get_apk(deviceid,port)
					pid = get_pid(deviceid)
				end
			elseif ln:match("^(%w+).-device") then
				deviceid = ln:match("^(%w+).-device")
				port = "USB-Cable"
				if num and deviceid then
					num = num + 1
					model = "Android"
					apk = "init_adbrun"
					pid = ""
				end
			end

			infolist[#infolist+1] = {
				num = num,
				model = model,
				deviceid = deviceid,
				port = port,
				apk = apk,
				pid = pid,
				uhttpd = webport
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
				luci.sys.call("adb -s " .. vid .. ":5555 exec-out screencap -p > /tmp/" .. vid .. ".jpg && ln -s /tmp/" .. vid .. ".jpg /www 2>/dev/null")
			end
		end
	end
end

