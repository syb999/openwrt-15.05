module("luci.controller.zigbeed", package.seeall)

function index()
	entry({"admin", "services", "zigbeed"}, alias("admin", "services", "zigbeed", "status"), _("Zigbee Gateway"), 60).dependent = false
	entry({"admin", "services", "zigbeed", "status"}, template("zigbeed/status"), _("Status"), 10).leaf = true
	entry({"admin", "services", "zigbeed", "devices"}, template("zigbeed/devices"), _("Devices"), 20).leaf = true
	entry({"admin", "services", "zigbeed", "control"}, template("zigbeed/control"), _("Control"), 30).leaf = true
	entry({"admin", "services", "zigbeed", "settings"}, cbi("zigbeed"), _("Settings"), 40).leaf = true
	entry({"admin", "services", "zigbeed", "debug"}, template("zigbeed/debug"), _("Debug"), 50).leaf = true
	entry({"admin", "services", "zigbeed", "link"}, template("zigbeed/link"), _("Gateway Link"), 60).leaf = true

	entry({"admin", "services", "zigbeed", "actions"}, call("act_dispatch"), nil).leaf = true
end

local function json_resp(obj)
	luci.http.prepare_content("application/json")
	luci.http.write_json(obj)
end

-- 读取 zigbeed 状态文件, 缺失则现场查询
local function read_status()
	local st = luci.sys.exec("cat /tmp/zigbeed_status.json 2>/dev/null")
	if not st:find("{") then
		luci.sys.call("/usr/bin/zigbeed -status >/dev/null 2>&1")
		st = luci.sys.exec("cat /tmp/zigbeed_status.json 2>/dev/null")
	end
	return st
end

local function read_devices()
	local st = luci.sys.exec("cat /tmp/zigbeed_devices.json 2>/dev/null")
	if not st:find("{") then
		luci.sys.call("/usr/bin/zigbeed -devices >/dev/null 2>&1")
		st = luci.sys.exec("cat /tmp/zigbeed_devices.json 2>/dev/null")
	end
	return st
end

-- 读 UCI 配置
local function uci_get(name)
	return luci.sys.exec("uci get zigbeed.options." .. name .. " 2>/dev/null"):gsub("%s+", "")
end

-- URL 编码 (供 wget 转发给 zigbeed serve)
local function urlencode(s)
	return (s:gsub("([^%w%-_%.%~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

local function uci_set(name, val)
	luci.sys.call("uci set zigbeed.options." .. name .. "='" .. val .. "' 2>/dev/null")
end

-- 动作白名单
local ACTIONS = {
	-- 状态 JSON
	status = function()
		return read_status()
	end,
	-- 服务状态 (进程 + 协调器 + 修复模式)
	svcstatus = function()
		-- 端口检测 (读 /proc/net/tcp, 无 fork): 8888=zigbeed 8890=gw-link
		local function port_up(port)
			local f = io.open("/proc/net/tcp", "r")
			if not f then return false end
			local hex = string.format("%04X", port)
			for line in f:lines() do
				if line:find(":" .. hex) then f:close(); return true end
			end
			f:close()
			return false
		end
		local zb = port_up(8888) and "running" or "down"
		local gl = port_up(8890) and "running" or "down"
		local st = read_status()
		local mac = st:match('"coordinator_mac"%s*:%s*"([^"]+)"') or "?"
		local ch  = st:match('"channel"%s*:%s*"([^"]+)"') or "?"
		local pan = st:match('"panid"%s*:%s*"([^"]+)"') or "?"
		-- 修复模式: 参数为空 或 DeviceHub 运行中
		local repairing = 0
		if ch == "?" or mac == "?" or ch == "" then repairing = 1 end
		if luci.sys.exec("pgrep -x DeviceHub 2>/dev/null") ~= "" then repairing = 1 end
		return {
			zigbeed = zb,
			gw_link = gl,
			repairing = repairing,
			coordinator_mac = mac,
			channel = ch,
			panid = pan,
		}
	end,-- 设备自定义名称
	setname = function(arg)
		-- arg = <key>/<url-encoded name>
		local key, name = arg:match("^([^/]+)/(.*)$")
		if not key or not name then return '{"error":"bad args"}' end
		name = name:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
		name = name:gsub("[^%w%p ]", "")
		if #name > 40 then name = name:sub(1, 40) end
		luci.sys.call("mkdir -p /etc/zigbeed 2>/dev/null")
		luci.sys.call("grep -v '^" .. key .. " ' /etc/zigbeed/devices.conf 2>/dev/null > /tmp/dc.tmp; mv /tmp/dc.tmp /etc/zigbeed/devices.conf 2>/dev/null")
		if name ~= "" then
			luci.sys.exec("echo '" .. key .. " " .. name .. "' >> /etc/zigbeed/devices.conf")
		end
		return '{"ok":true,"key":"' .. key .. '","name":"' .. name .. '"}'
	end,
	-- 配对窗口: join/<秒> (0=关闭), 经 zigbeed serve 8888 触发 (守护进程内串行访问串口)
	join = function(arg)
		local sec = tonumber(arg or "60")
		if not sec or sec < 0 or sec > 600 then sec = 60 end
		local out = luci.sys.exec("wget -q -T 20 -O - 'http://127.0.0.1:8888/pair?sec=" .. sec .. "' 2>&1")
		if out == "" then out = '{"error":"zigbeed serve down (8888)"}' end
		return out
	end,
	-- 设备控制: control/<url-encoded json>, 经 zigbeed serve 8888
	control = function(arg)
		local j = arg or ""
		if j == "" or j:find("[;&|]") then return '{"error":"bad json"}' end
		local out = luci.sys.exec("wget -q -T 20 -O - 'http://127.0.0.1:8888/control/" .. urlencode(j) .. "' 2>&1")
		if out == "" then out = '{"error":"zigbeed serve down (8888)"}' end
		return out
	end,
	-- 重建协调器网络 (兜底: 临时起 DeviceHub 建网, 后台执行避免 LuCI 挂起)
	rebuild = function(arg)
		luci.sys.call("sh /usr/bin/zigbeed-rebuild.sh > /tmp/zigbeed_rebuild_run.log 2>&1 &")
		return '{"rebuild":"started","log":"/tmp/zigbeed_rebuild.log"}'
	end,
	-- 重建进度: 读 rebuild 日志尾部 (JS 轮询用)
	rebuild_status = function()
		local out = luci.sys.exec("tail -6 /tmp/zigbeed_rebuild.log 2>/dev/null")
		if out == "" then out = "no log yet" end
		return out
	end,
	-- gw-link 代理 (LuCI 页面跨域调用 127.0.0.1:8890 的桥梁)
	gwlink = function(arg)
		-- arg = <path>, 如 status / rules / control/self/%7B...%7D
		local path = arg or ""
		path = path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
		if path == "" or path:find("%.%.") or path:find("[;&|]") then
			return '{"error":"bad path"}'
		end
		local out = luci.sys.exec("wget -q -T 15 -O - 'http://127.0.0.1:8890/" .. path .. "' 2>&1")
		if out == "" then out = '{"error":"gw-link down"}' end
		return out
	end,
	-- 本机 IPv4 列表 (告知对端用, IP 是 DHCP 动态的)
	myip = function()
		local out = luci.sys.exec("ip -4 -o addr show 2>/dev/null | awk '{print $2, $4}' | grep -v '^lo '")
		local ips = {}
		for line in out:gmatch("[^\n]+") do
			local iface, addr = line:match("^(%S+)%s+(%S+)")
			if iface and addr then
				ips[#ips + 1] = { iface = iface, addr = addr }
			end
		end
		return ips
	end,
	-- 网关互联列表: 读 peers.conf
	peers_conf = function()
		local f = io.open("/etc/gw-link/peers.conf", "r")
		if not f then return '{"error":"no peers.conf"}' end
		local content = f:read("*a")
		f:close()
		return content
	end,
	-- 网关互联列表: 添加/删除 peer (arg = add/<ip>:<port>/<label> 或 del/<line>)
	peers_edit = function(arg)
		local cmd, rest = arg:match("^([^/]+)/(.*)$")
		if not cmd or not rest then return '{"error":"bad args"}' end
		local f = io.open("/etc/gw-link/peers.conf", "r")
		if not f then return '{"error":"no peers.conf"}' end
		local content = f:read("*a")
		f:close()
		-- 去掉注释行和空行保留
		local lines = {}
		for line in content:gmatch("[^\n]+") do
			lines[#lines+1] = line
		end
		if cmd == "add" then
			local host, port, label = rest:match("^([^:]+):(%d+)(.*)$")
			if not host or not port then return '{"error":"bad ip:port"}' end
			label = label:gsub("^%s*/", ""):gsub("^%s+", "")
			if #label == 0 then label = "GW" end
			-- 去重 (同 host 不重复加)
			for _, l in ipairs(lines) do
				if l:find(host, 1, true) then
					return '{"error":"already exists: ' .. host .. '"}'
				end
			end
			lines[#lines+1] = host .. ":" .. port .. " " .. label
			luci.sys.call("/etc/init.d/gw-link stop >/dev/null 2>&1")
			local out = io.open("/etc/gw-link/peers.conf", "w")
			if out then
				out:write("# gw-link peer list\n")
				for _, l in ipairs(lines) do
					out:write(l .. "\n")
				end
				out:close()
			end
			luci.sys.call("/etc/init.d/gw-link start >/dev/null 2>&1 &")
			return '{"ok":true,"action":"add","host":"' .. host .. '"}'
		elseif cmd == "del" then
			local host = rest:gsub("^%s+", ""):gsub("%s+$", "")
			if not host:match("^[%d%.:]+$") then return '{"error":"bad host"}' end
			local newlines = {}
			local removed = false
			for _, l in ipairs(lines) do
				if l:find(host, 1, true) then
					removed = true
				else
					newlines[#newlines+1] = l
				end
			end
			if not removed then return '{"error":"not found: ' .. host .. '"}' end
			luci.sys.call("/etc/init.d/gw-link stop >/dev/null 2>&1")
			local out = io.open("/etc/gw-link/peers.conf", "w")
			if out then
				out:write("# gw-link peer list\n")
				for _, l in ipairs(newlines) do
					out:write(l .. "\n")
				end
				out:close()
			end
			luci.sys.call("/etc/init.d/gw-link start >/dev/null 2>&1 &")
			return '{"ok":true,"action":"del","host":"' .. host .. '"}'
		end
		return '{"error":"unknown cmd"}'
	end,
	-- 只读 AT
	raw = function(arg)
		local cmd = arg:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
		if not cmd:match("^AT%+") then return '{"error":"AT only"}' end
		if cmd:match("RESET") or cmd:match("LEAVE") or cmd:match("FORM")
		   or cmd:match("SETMAC") or cmd:match("BOOTLOADER") then
			return '{"error":"command blocked (dangerous)"}'
		end
		return luci.sys.exec("/usr/bin/zigbeed -cmd '" .. cmd .. "' 2>&1")
	end,
	-- 设置页: 保存
	save = function(arg)
		local params = arg:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
		local function g(k, def)
			local v = params:match(k .. "=([^&]*)")
			return (v and v ~= "") and v or def
		end
		uci_set("enabled", g("enabled", "0"))
		uci_set("device", g("device", "/dev/ttyS1"))
		uci_set("baud", g("baud", "115200"))
		uci_set("channel", g("channel", "11"))
		uci_set("panid", g("panid", "4710"))
		uci_set("extpanid", g("extpanid", ""))
		uci_set("network_key", g("network_key", ""))
		uci_set("poll_interval", g("poll", "30"))
		uci_set("mqtt", g("mqtt", "0"))
		luci.sys.call("uci commit zigbeed 2>/dev/null")
		if g("enabled", "0") == "1" then
			luci.sys.call("/etc/init.d/zigbeed enable >/dev/null 2>&1")
			luci.sys.call("/etc/init.d/zigbeed restart >/dev/null 2>&1 &")
		else
			luci.sys.call("/etc/init.d/zigbeed stop >/dev/null 2>&1")
			luci.sys.call("/etc/init.d/zigbeed disable >/dev/null 2>&1")
			luci.sys.call("killall zigbeed 2>/dev/null")
		end
		return '{"ok":true,"saved":true}'
	end,
	-- 设置页: 读取
	getconf = function()
		local conf = {
			enabled = uci_get("enabled"),
			device = uci_get("device"),
			baud = uci_get("baud"),
			channel = uci_get("channel"),
			panid = uci_get("panid"),
			extpanid = uci_get("extpanid"),
			network_key = uci_get("network_key"),
			poll = uci_get("poll_interval"),
			mqtt = uci_get("mqtt"),
		}
		local parts = {}
		for k, v in pairs(conf) do
			parts[#parts + 1] = string.format('"%s":"%s"', k, v)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end,
}

function act_dispatch(...)
	local args = {...}
	local action = args[1] or ""
	-- 把剩余参数用 / 拼接 (支持 key/name 等多段路径)
	local arg = ""
	for i = 2, #args do
		if i > 2 then arg = arg .. "/" end
		arg = arg .. tostring(args[i] or "")
	end

	if ACTIONS[action] then
		local out = ACTIONS[action](arg)
		-- table 直接编码; 字符串保持原样 (页面端已有两层解析)
		if type(out) == "table" then
			json_resp({ ok = true, action = action, data = out })
		else
			json_resp({ ok = true, action = action, data = out })
		end
	else
		json_resp({ ok = false, error = "unknown action: " .. tostring(action) })
	end
end
