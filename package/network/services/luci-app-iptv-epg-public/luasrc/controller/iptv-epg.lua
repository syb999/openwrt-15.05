module("luci.controller.iptv-epg", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/iptv_epg") then
		return
	end

	entry({"admin", "services", "iptv_epg"}, alias("admin", "services", "iptv_epg", "overview"), _("IPTV EPG"), 80).dependent = true
	entry({"admin", "services", "iptv_epg", "overview"}, template("iptv_epg/overview"), _("总览"), 1).leaf = true
	entry({"admin", "services", "iptv_epg", "channels"}, call("act_channels"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "fetch"}, call("act_fetch"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "status"}, call("act_status"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "service"}, call("act_service"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "settings"}, cbi("iptv_epg"), _("设置"), 2).leaf = true
	entry({"admin", "services", "iptv_epg", "txt"}, call("act_txt"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "channels_all"}, call("act_channels_all"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "save_selected"}, call("act_save_selected"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "selected"}, call("act_selected"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "select"}, template("iptv_epg/select"), _("频道选择"), 3).leaf = true
	entry({"admin", "services", "iptv_epg", "cookie_fetch"}, call("act_cookie_fetch"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "channels_fetch"}, call("act_channels_fetch"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "swap"}, call("act_swap"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "hostip"}, call("act_host_ip"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "selected_count"}, call("act_selected_count"), nil).leaf = true
	entry({"admin", "services", "iptv_epg", "fetch_log"}, call("act_fetch_log"), nil).leaf = true
end

-- 返回 fetch 日志尾部 (后台拉取进度轮询)
function act_fetch_log()
	local out = luci.sys.exec("tail -20 /tmp/iptv_epg.log 2>/dev/null")
	local e = {}
	for line in out:gmatch("[^\n]+") do
		e[#e+1] = line
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ lines = e })
end

-- 返回已选频道数量 (拉取前检查用)
function act_selected_count()
	local uci = require("luci.model.uci").cursor()
	local n = 0
	uci:foreach("iptv_epg", "selected", function(s) n = n + 1 end)
	luci.http.prepare_content("application/json")
	luci.http.write('{"count":' .. n .. '}')
end

-- 返回本机可访问 IP (播放器用, 与 get_host_ip 同逻辑)
function act_host_ip()
	local uci = require("luci.model.uci").cursor()
	local side = uci:get("iptv_epg", "main", "stb_side")
	local ip
	local function ifip(ifname)
		return luci.sys.exec("ip addr show " .. ifname .. " 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | head -1"):gsub("%s+", "")
	end
	if side == "A" then
		ip = uci:get("network", "lan", "ipaddr")
		if not ip or ip == "" then ip = ifip("br-lan") end
		if ip == "" then ip = ifip("br-wan") end
	else
		ip = ifip("br-wan")
		if ip == "" then ip = uci:get("network", "wan", "ipaddr") end
		if not ip or ip == "" then ip = ifip("br-lan") end
		if ip == "" then ip = uci:get("network", "lan", "ipaddr") end
	end
	if not ip or ip == "" then
		ip = luci.sys.exec("ip -o addr show 2>/dev/null | awk '$4 ~ /^inet/ && $2 != \"lo\" && $2 !~ /^(docker|veth|br-|tun|wg)/ {print $4}' | cut -d/ -f1 | head -1"):gsub("%s+", "")
	end
	luci.http.prepare_content("text/plain")
	luci.http.write(ip)
end

-- 交换 selected 段位置 (上移/下移频道顺序)
-- 用法: /swap/<方向 up|down>/<段序号 idx>
function act_swap(dir, idx)
	local uci = require("luci.model.uci").cursor()
	idx = tonumber(idx)
	if not idx or not dir then
		luci.http.prepare_content("text/plain")
		luci.http.write("bad args")
		return
	end
	local target = (dir == "up") and (idx - 1) or (idx + 1)
	if target < 1 then
		luci.http.prepare_content("text/plain")
		luci.http.write("already first")
		return
	end
	local a_name = uci:get("iptv_epg", "sel" .. idx, "ch" .. idx)
	local a_id = uci:get("iptv_epg", "sel" .. idx, "id" .. idx)
	local b_name = uci:get("iptv_epg", "sel" .. target, "ch" .. target)
	local b_id = uci:get("iptv_epg", "sel" .. target, "id" .. target)
	if not a_name then
		luci.http.prepare_content("text/plain")
		luci.http.write("missing sel")
		return
	end
	-- 交换 ch/id: 把对方的写到自己段 (段内用对方的编号, 保证读取一致)
	uci:set("iptv_epg", "sel" .. idx, "ch" .. idx, b_name)
	uci:set("iptv_epg", "sel" .. idx, "id" .. idx, b_id)
	uci:set("iptv_epg", "sel" .. target, "ch" .. target, a_name)
	uci:set("iptv_epg", "sel" .. target, "id" .. target, a_id)
	uci:commit("iptv_epg")
	rebuild_channels(uci)
	luci.http.prepare_content("text/plain")
	luci.http.write("ok")
end

-- 按 selected 段重建 channel 段 (设置页"频道列表"与频道选择页保持同步)
-- 频道选择页保存/交换后调用; channel 段是 selected 的镜像, 供 CBI 设置页展示
-- 注意: 定义为全局 (module seeall), 因为 act_swap 在其定义之前调用
function rebuild_channels(uci)
	-- 清空旧 channel 段 (先收集名字再删, 避免遍历中删除)
	local ch_names = {}
	uci:foreach("iptv_epg", "channel", function(s) ch_names[#ch_names + 1] = s[".name"] end)
	for _, n in ipairs(ch_names) do uci:delete("iptv_epg", n) end
	-- 组播地址映射表 (名 → udp)
	local map = {}
	local mf = io.open("/usr/share/iptv_epg/channel_map.txt", "r")
	if mf then
		for line in mf:lines() do
			local n, u = line:match("^([^|]+)|[^|]*|(.*)$")
			if n then map[n] = u or "" end
		end
		mf:close()
	end
	-- 按 selected 段顺序重建
	local i = 0
	uci:foreach("iptv_epg", "selected", function(s)
		for k, v in pairs(s) do
			local idx = k:match("^ch(%d+)$")
			if idx then
				local name = s["ch" .. idx]
				local id = s["id" .. idx]
				if name and name ~= "" then
					i = i + 1
					uci:set("iptv_epg", "ch" .. i, "channel")
					uci:set("iptv_epg", "ch" .. i, "name", name)
					uci:set("iptv_epg", "ch" .. i, "epg_id", id or "")
					uci:set("iptv_epg", "ch" .. i, "udp", map[name] or "")
				end
			end
		end
	end)
	uci:commit("iptv_epg")
end

-- 一键获取 cookie (手动抓包 + 验证)
function act_cookie_fetch()
	local out = luci.sys.exec("/usr/bin/iptv_epg cookie fetch 20 2>&1")
	luci.http.prepare_content("text/plain; charset=utf-8")
	luci.http.write(out)
end

-- 一键抓取频道 (需有效 cookie): 重建 channel_map.txt (名称|EPG_ID|组播地址)
function act_channels_fetch()
	local out = luci.sys.exec("/usr/bin/iptv_epg channels-save 2>&1")
	luci.http.prepare_content("text/plain; charset=utf-8")
	luci.http.write(out)
end

-- 下载 DIYP IPTV.txt (TVOD 格式, 直播+回看) — 基于 selected 频道
function act_txt()
	-- A 设备自己的地址: 统一走 /usr/bin/iptv_epg ip (get_host_ip, 按 stb_side 智能选择)
	local host = luci.sys.exec("/usr/bin/iptv_epg ip 2>/dev/null"):gsub("%s+", "")
	if host == "" then host = luci.sys.hostname() end
	local uci = require("luci.model.uci").cursor()
	-- selected 频道名列表
	local sel = {}
	uci:foreach("iptv_epg", "selected", function(s)
		for k, v in pairs(s) do
			if k:match("^ch%d+$") then sel[#sel+1] = v end
		end
	end)
	-- 合并映射表
	local cmap = {}
	local mf = io.open("/usr/share/iptv_epg/channel_map.txt", "r")
	if mf then
		for line in mf:lines() do
			local name, id, udp = line:match("^([^|]+)|([^|]*)|(.*)$")
			if name then cmap[name] = { id = id or "", udp = udp or "" } end
		end
		mf:close()
	end
	luci.http.prepare_content("text/plain; charset=utf-8")
	luci.http.header("Content-Disposition", "attachment; filename=IPTV.txt")
	local provider = uci:get("iptv_epg", "main", "provider") or "telecom"
	local wrote = 0
	if #sel > 0 then
		for _, name in ipairs(sel) do
			local info = cmap[name] or {}
			if info.udp ~= "" then
				if provider == "unicom" then
					-- 联通: HLS 单播直放 (不经 play.cgi, 无 udpxy)
					luci.http.write(name .. "," .. info.udp .. "\n")
				else
					luci.http.write(name .. ",http://" .. host .. "/cgi-bin/TVOD/play.cgi?url=http://" .. host .. ":7088/udp/" .. info.udp .. "&ch=" .. name .. "\n")
				end
				wrote = wrote + 1
			end
		end
	end
	if wrote == 0 then
		-- 无 selected 或无组播: 退回 UCI channel 段
		uci:foreach("iptv_epg", "channel", function(s)
			local name = s.name or ""
			local udp = s.udp or ""
			if name ~= "" and udp ~= "" then
				if provider == "unicom" then
					luci.http.write(name .. "," .. udp .. "\n")
				else
					luci.http.write(name .. ",http://" .. host .. "/cgi-bin/TVOD/play.cgi?url=http://" .. host .. ":7088/udp/" .. udp .. "&ch=" .. name .. "\n")
				end
			end
		end)
	end
end

-- 全部可用频道 (JSON: 从 channel_map.txt 读, 只显示有组播地址的)
function act_channels_all()
	local e = {}
	local mf = io.open("/usr/share/iptv_epg/channel_map.txt", "r")
	if mf then
		for line in mf:lines() do
			local name, id, udp = line:match("^([^|]+)|([^|]*)|(.*)$")
			if name and udp and udp ~= "" then
				e[#e+1] = { name = name, id = id or "", udp = udp }
			end
		end
		mf:close()
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

-- 保存选中的频道 (路径参数: /save_selected/<channels>[/append])
-- 支持分块: 第二个路径参数为 1 时追加 (不删旧), 默认覆盖
function act_save_selected(channels, append)
	-- 调试日志: 确认请求到达 (保留最近 100 行, 防 /tmp 撑爆)
	local lc = 0
	local lf = io.open("/tmp/save_selected.log", "r")
	if lf then
		for _ in lf:lines() do lc = lc + 1 end
		lf:close()
		if lc > 100 then
			os.execute("tail -100 /tmp/save_selected.log > /tmp/save_selected.log.tmp 2>/dev/null && mv /tmp/save_selected.log.tmp /tmp/save_selected.log")
		end
	end
	local f = io.open("/tmp/save_selected.log", "a")
	if f then f:write(os.date("%F %T") .. " arg1=" .. tostring(channels) .. " append=" .. tostring(append) .. "\n") f:close() end
	local uci = require("luci.model.uci").cursor()
	local body = channels or ""
	-- URL 解码
	body = body:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
	-- 覆盖模式: 先清空旧 selected (分块时只有第一块用覆盖)
	if append ~= "1" then
		uci:foreach("iptv_epg", "selected", function(s) uci:delete("iptv_epg", s[".name"]) end)
	end
	-- 计算现有 sel 编号起始
	local start_i = 1
	uci:foreach("iptv_epg", "selected", function(s)
		local idx = s[".name"]:match("^sel(%d+)$")
		if idx and tonumber(idx) >= start_i then start_i = tonumber(idx) + 1 end
	end)
	local i = start_i
	for pair in body:gmatch("[^,]+") do
		local name, id = pair:match("^([^:]+):(.*)$")
		if name and name ~= "" then
			uci:set("iptv_epg", "sel" .. i, "selected")
			uci:set("iptv_epg", "sel" .. i, "ch" .. i, name)
			uci:set("iptv_epg", "sel" .. i, "id" .. i, id or "")
			i = i + 1
		end
	end
	uci:commit("iptv_epg")
	-- 同步 channel 段 (设置页"频道列表"镜像 selected, 分块时每块都重建, 最终完整)
	rebuild_channels(uci)
	-- 保存成功后立即重新生成播放列表 (TVBox/DIYP 数据源同步更新, 不用等拉取)
	luci.sys.exec("/usr/bin/iptv_epg gen 2>/dev/null")
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ok = true, count = i - start_i })
end

-- 当前选中的频道 (JSON: 名称列表)
function act_selected()
	local uci = require("luci.model.uci").cursor()
	local e = {}
	uci:foreach("iptv_epg", "selected", function(s)
		for k, v in pairs(s) do
			if k:match("^ch%d+$") then
				e[#e+1] = v
			end
		end
	end)
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

-- 频道列表 (JSON: name/id/mix/udp/alias) — 优先 selected, 无则 UCI channel 段
function act_channels()
	local uci = require("luci.model.uci").cursor()
	local e = {}
	-- 读取 selected 段 (勾选的频道)
	local sel = {}
	uci:foreach("iptv_epg", "selected", function(s)
		for k, v in pairs(s) do
			if k:match("^ch%d+$") then
				sel[#sel+1] = v
			end
		end
	end)
	-- 读取合并映射表 (频道名|EPG_ID|组播地址)
	local cmap = {}
	local mf = io.open("/usr/share/iptv_epg/channel_map.txt", "r")
	if mf then
		for line in mf:lines() do
			local name, id, udp = line:match("^([^|]+)|([^|]*)|(.*)$")
			if name then cmap[name] = { id = id or "", udp = udp or "" } end
		end
		mf:close()
	end
	if #sel > 0 then
		-- 按 selected 频道名输出
		for _, name in ipairs(sel) do
			local info = cmap[name] or {}
			e[#e+1] = { name = name, id = info.id or "", mix = "", udp = info.udp or "", alias = name }
		end
	else
		-- 无 selected: 退回 UCI channel 段
		local out = luci.sys.exec("/usr/bin/iptv_epg channels 2>&1")
		for line in out:gmatch("[^\n]+") do
			local name, id, mix, code = line:match("^([^|]+)|([^|]+)|([^|]*)|?(.*)$")
			if name and id then
				local alias = name
				if code and code:match("CHAN/([^@]+)") then
					alias = code:match("CHAN/([^@]+)")
				end
				local udp = ""
				local u2 = require("luci.model.uci").cursor()
				u2:foreach("iptv_epg", "channel", function(s2)
					if s2.name == name and s2.udp then udp = s2.udp end
				end)
				e[#e+1] = { name = name, id = id, mix = mix or "", udp = udp, alias = alias }
			end
		end
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

-- 一键拉取 (JSON: 逐频道结果)
function act_fetch()
	local target = luci.http.formvalue("channel") or ""
	-- 防注入: 中文频道名/ID 合法, 只禁止 shell 特殊字符
	if target ~= "" then
		-- 去掉危险字符 (只保留 中文/字母/数字/下划线/@/./-/)
		target = target:gsub("[^%w%p\128-\255@._-]", "")
	end
	-- 后台分批拉取: 单批短任务(10频道), 防 uhttpd/浏览器超时; 自动续批直到全部完成
	-- 日志写 /tmp/iptv_epg.log, 页面轮询 fetch_log 看进度
	local cmd = "nohup /usr/bin/iptv_epg fetch_bg " .. luci.util.shellquote(target) .. " >> /tmp/iptv_epg.log 2>&1 &"
	os.execute(cmd)
	luci.http.prepare_content("application/json")
	luci.http.write_json({ lines = { "分批拉取已后台启动 (每批10个频道), 页面将自动刷新进度" } })
end

-- 服务状态 (JSON)
function act_status()
	local out = luci.sys.exec("/usr/bin/iptv_epg status 2>&1")
	local e = {}
	for line in out:gmatch("[^\n]+") do
		e[#e+1] = line
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({ lines = e })
end

-- 服务控制 (start/stop/restart)
function act_service()
	local action = luci.http.formvalue("action") or ""
	if action == "start" then
		luci.sys.call("/etc/init.d/iptv-epg start >/dev/null 2>&1")
	elseif action == "stop" then
		luci.sys.call("/etc/init.d/iptv-epg stop >/dev/null 2>&1")
	elseif action == "restart" then
		luci.sys.call("/etc/init.d/iptv-epg restart >/dev/null 2>&1")
	end
	-- 用 pidfile 判断 daemon 是否运行 (pgrep -f 会误匹配自身 shell)
	local running = nixio.fs.access("/var/run/epg_cookie_daemon.pid")
	local enabled = luci.sys.call("/etc/init.d/iptv-epg enabled >/dev/null 2>&1") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json({ running = running, enabled = enabled })
end
