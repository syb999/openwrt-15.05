module("luci.controller.ffmpegtool",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ffmpegtool") then
		return
	end

	local page = entry({"admin", "services", "ffmpegtool"}, cbi("ffmpegtool"), _("FFMPEG-Tool"),20)
	page.dependent = true
	entry({"admin", "services", "ffmpegtool", "status"}, call("ffmpegtool_status")).leaf = true
end

function ffmpegtool_status()
	local duration, streaminfo, workinfo, cpuinfo

	if not nixio.fs.access("/tmp/ffmpeg.log") then
		duration = nil
		streaminfo = nil	
		workinfo = nil
		cpuinfo = nil
	else
		duration = luci.sys.exec("cat /tmp/ffmpeg.log | grep Duration | cut -d ',' -f1 | awk '{print$2}' 2>/dev/null ")
		streaminfo = luci.sys.exec("cat /tmp/ffmpeg.log | grep Audio 2>/dev/null ")
		workinfo = luci.sys.exec("cat /tmp/ffmpeg.log | tail -n1 2>/dev/null ")
		cpuinfo = luci.sys.exec("top -n 1 | grep ffmpeg | awk '{print$7}' ")
	end

	local e = {
		duration = duration ,
		streaminfo = streaminfo,
		workinfo = workinfo,
		cpuinfo = cpuinfo
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

