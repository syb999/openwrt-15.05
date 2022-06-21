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
					rmodel = model:read("*l")
					if not rmodel then
						getmodel = "checking"
					else
						getmodel = string.gsub(rmodel,"\n","")
					end
					model:close()

					apk = io.popen("adb -s " .. deviceid .. ":" .. port .." shell dumpsys activity activities | grep -i run | grep ActivityRecord | head -n 1 | cut -d '/' -f 1 | awk '{print $5}' 2>/dev/null")
					rapk = apk:read("*l")
					if not rapk then
						apk = io.popen("adb -s " .. deviceid .. ":" .. port .." shell dumpsys activity activities | grep -i Activities= | head -n 1 | cut -d '/' -f 1 | awk '{print $3}' 2>/dev/null")
						rapk = apk:read("*l")
						if not rapk then
							runapk = "checking"
						else
							runapk = string.gsub(rapk,"\n","")
						end
					else
						runapk = string.gsub(rapk,"\n","")
					end
					apk:close()

					script = io.popen("busybox ps | grep ADBRUN$(uci show adbrun | grep " ..deviceid .. " | cut -d '.' -f 2) | grep -v grep | head -n 1 | awk '{print $1}' 2>/dev/null")
					rscript = script:read("*l")
					if rscript then
						kscript = string.gsub(rscript,"\n","")
					else
						kscript = ""
					end
					script:close()
				end
			elseif ln:match("^(%w+).-device") then
				deviceid = ln:match("^(%w+).-device")
				port = "USB-Cable"
				if num and deviceid then
					num = num + 1
					model = io.popen("adb -s " .. deviceid .. " shell getprop ro.product.model | sed 's/ //g' 2>/dev/null")
					rmodel = model:read("*l")
					if not rmodel then
						getmodel = "checking"
					else
						getmodel = string.gsub(rmodel,"\n","")
					end
					model:close()
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

