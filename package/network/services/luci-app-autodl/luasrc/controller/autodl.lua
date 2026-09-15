module("luci.controller.autodl",package.seeall)

function index()
	if not nixio.fs.access("/etc/config/autodl") then
		return
	end

	local page = entry({"admin", "services", "autodl"}, cbi("autodl"), _("Autodl"),3)
	page.dependent = true
	entry({"admin", "services", "autodl", "status"}, call("autodl_status")).leaf = true
end

function autodl_status()
	local mpg123 = ""
	local playing = luci.sys.exec("ps -w | grep -E 'mpg123|webmusicplay' | grep -v grep | head -n1") or ""

	if string.match(playing, "%S") then
		-- url of the track being streamed right now, kept up to date by
		-- webmusicplay.sh. never parse it out of the ps command line: the
		-- old awk '{$7}' trick returned curl's -s flag instead of the url.
		local url = luci.sys.exec("head -n1 /tmp/webmusic.tmp.url 2>/dev/null") or ""
		mpg123 = string.gsub(url, "%s+$", "")
		if not string.match(mpg123, "^http") then
			-- sources that do not publish the url in that file: take the
			-- first http argument of the streaming curl process
			url = luci.sys.exec("ps -w | grep curl | grep -v grep | head -n1 | tr ' ' '\\n' | grep '^http' | head -n1") or ""
			mpg123 = string.gsub(url, "%s+$", "")
			if not string.match(mpg123, "^http") then
				mpg123 = ""
			end
		end
	end

	local e = {
		running = luci.sys.exec("ps -w | grep \/usr\/online_server\/dexmly.py | grep -v grep | awk '{print$1}' "),
		mpg123 = mpg123
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end
