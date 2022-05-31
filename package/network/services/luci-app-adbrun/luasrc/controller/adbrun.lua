module("luci.controller.adbrun",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/adbrun") then
		return
	end

	local page = entry({"admin", "services", "adbrun"}, cbi("adbrun"), _("ADBrun"),3)
	page.dependent = true

	entry({"admin", "services", "adbrun", "status"}, call("xact_status")).leaf = true
end



function xact_status()
	local json = require "luci.jsonc"
	luci.http.prepare_content("application/json")

	local adblist = io.popen("adb devices | sed '1d;$d'")

	if adblist then
		infolist = { }
		local num = 0
		local deviceip, port, apk, rapk
		while true do
			local ln = adblist:read("*l")
			if not ln then
				break
			elseif ln:match("(%S-):(%d+).-") then
				deviceip, port = ln:match("(%S-):(%d+).-")

				if num and deviceip and port then
					apk = io.popen("adb -s " .. deviceip .. ":" .. port .." shell dumpsys activity activities | grep -i run | grep -e 'SplashActivity' -e 'MainActivity' -e 'AudioPlayActivity' -e 'NewMapActivity' -e 'NewMainActivity' | grep -v miui. | grep -v android.systemui | grep -v recent | awk '{print $5}' | cut -d '/' -f 1")
					rapk = apk:read("*l")
					num = num + 1
				end
			end

			infolist[#infolist+1] = {
				num = num,
				deviceip = deviceip,
				port = port,
				apk = rapk
			}

		end

	end

	adblist:close()
	
	luci.http.write_json(infolist);
end

