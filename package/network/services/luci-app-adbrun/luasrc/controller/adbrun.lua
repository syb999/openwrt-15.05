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
	local adblist = io.popen("adb devices | sed '1d;$d' 2>/dev/null")
	if adblist then
		infolist = { }
		local num = 0
		local deviceid, port, model, rmodel, getmodel, apk, rapk, runapk, script, rscript, kscript
		while true do
			local ln = adblist:read("*l")
			if not ln then
				break
			elseif ln:match("(%S-):(%d+).-") then
				deviceid, port = ln:match("(%S-):(%d+).-")
				if num and deviceid and port then
					num = num + 1
					model = io.popen("adb -s " .. deviceid .. ":" .. port .." shell getprop ro.product.model | sed 's/ //g' 2>/dev/null")
					rmodel = model:read("*a")
					if rmodel then
						getmodel = string.gsub(rmodel,"\n","")
					else
						getmodel = "checking"
					end

					apk = io.popen("adb -s " .. deviceid .. ":" .. port .." shell dumpsys activity activities | grep -i run | grep -v miui. | grep -v android.systemui | grep -v recent | grep -e 'SplashActivity' -e 'MainActivity' -e 'AudioPlayActivity' -e 'NewMapActivity' -e 'NewMainActivity' -e 'LauncherUI' -e 'MainFrameActivity' -e 'AlipayLogin' -e 'InnerUCMobile' -e 'MediaActivity' -e 'Camera' -e 'BrowserActivity' -e 'lgame' -e 'WelcomeActivity' -e 'HomeActivity' -e 'HomePageEntry' | head -n 1 | awk '{print $5}' | cut -d '/' -f 1 2>/dev/null")
					rapk = apk:read("*a")
					if rapk then
						runapk = string.gsub(rapk,"\n","")
					else
						runapk = "checking"
					end

					script = io.popen("busybox ps | grep ADBRUN$(uci show adbrun | grep " ..deviceid .. " | cut -d '.' -f 2) | grep -v grep | head -n 1 | awk '{print $1}' 2>/dev/null")
					rscript = script:read("*a")
					if rscript then
						kscript = string.gsub(rscript,"\n","")
					else
						kscript = ""
					end
				end
			elseif ln:match("^(%w+).-device") then
				deviceid = ln:match("^(%w+).-device")
				if num and deviceid then
					num = num + 1
					getmodel = "UnKnown"
					port = "USB-Cable"
					runapk = "init_adbrun"
					kscript = ""
				end
			end

			infolist[#infolist+1] = {
				num = num,
				model = getmodel,
				deviceid = deviceid .. ":" .. port,
				port = port,
				apk = runapk,
				kscript = kscript
			}
		end
	end
	adblist:close()

	luci.http.prepare_content("application/json")	
	luci.http.write_json(infolist);
end

