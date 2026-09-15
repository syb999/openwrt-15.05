#!/usr/bin/lua
-- kgjson.lua - json / base64 helper for the autodl web music page
--
-- usage: kgjson.lua <mode>  (reads stdin, writes plain tab separated lines)
--   rank      hash \t name(singer - song) \t duration_sec \t privilege
--   search    hash \t name(singer - song) \t duration_sec \t privilege
--   songinfo  url \t timeLength \t songName \t singerName \t fileSize   (one line)
--   lrcq      id \t accesskey \t duration_ms                            (per candidate)
--   lrcg      decoded lyric text of the "content" field
--   b64       raw base64 decoded
--
-- self contained on purpose: busybox on these boards has no base64 applet and
-- no python, but lua is always there because luci needs it.

local mode = arg[1] or ""
local data = io.read("*a") or ""

-- minimal json decoder (object/array/string/number/true/false/null) -----------
local function json_decode(s)
	local pos = 1

	local function skip_ws()
		local _, e = s:find("^[ \t\r\n]*", pos)
		pos = (e or pos - 1) + 1
	end

	local parse_value

	local function utf8_char(cp)
		if cp < 0x80 then
			return string.char(cp)
		elseif cp < 0x800 then
			return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
		elseif cp < 0x10000 then
			return string.char(0xE0 + math.floor(cp / 4096),
				0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
		end
		return string.char(0xF0 + math.floor(cp / 262144),
			0x80 + math.floor(cp / 4096) % 64,
			0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
	end

	local function parse_string()
		pos = pos + 1
		local buf = {}
		while true do
			local c = s:sub(pos, pos)
			if c == "" then break end
			if c == '"' then pos = pos + 1; break end
			if c == "\\" then
				local e = s:sub(pos + 1, pos + 1)
				pos = pos + 2
				if e == "u" then
					local cp = tonumber(s:sub(pos, pos + 3), 16) or 63
					pos = pos + 4
					if cp >= 0xD800 and cp <= 0xDBFF and s:sub(pos, pos + 1) == "\\u" then
						local lo = tonumber(s:sub(pos + 2, pos + 5), 16) or 0
						if lo >= 0xDC00 and lo <= 0xDFFF then
							cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
							pos = pos + 6
						end
					end
					buf[#buf + 1] = utf8_char(cp)
				elseif e == "n" then buf[#buf + 1] = "\n"
				elseif e == "t" then buf[#buf + 1] = "\t"
				elseif e == "r" then buf[#buf + 1] = "\r"
				elseif e == "b" then buf[#buf + 1] = "\b"
				elseif e == "f" then buf[#buf + 1] = "\f"
				else buf[#buf + 1] = e
				end
			else
				buf[#buf + 1] = c
				pos = pos + 1
			end
		end
		return table.concat(buf)
	end

	local function parse_array()
		pos = pos + 1
		local res = {}
		skip_ws()
		if s:sub(pos, pos) == "]" then pos = pos + 1; return res end
		while true do
			res[#res + 1] = parse_value()
			skip_ws()
			local c = s:sub(pos, pos)
			pos = pos + 1
			if c == "]" or c == "" then break end
		end
		return res
	end

	local function parse_object()
		pos = pos + 1
		local res = {}
		skip_ws()
		if s:sub(pos, pos) == "}" then pos = pos + 1; return res end
		while true do
			skip_ws()
			if s:sub(pos, pos) ~= '"' then break end
			local key = parse_string()
			skip_ws()
			pos = pos + 1 -- ':'
			skip_ws()
			res[key] = parse_value()
			skip_ws()
			local c = s:sub(pos, pos)
			pos = pos + 1
			if c == "}" or c == "" then break end
		end
		return res
	end

	parse_value = function()
		skip_ws()
		local c = s:sub(pos, pos)
		if c == "{" then return parse_object() end
		if c == "[" then return parse_array() end
		if c == '"' then return parse_string() end
		if c == "t" then pos = pos + 4; return true end
		if c == "f" then pos = pos + 5; return false end
		if c == "n" then pos = pos + 4; return nil end
		local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
		if num and num ~= "" then
			pos = pos + #num
			return tonumber(num)
		end
		pos = pos + 1
		return nil
	end

	local ok, res = pcall(parse_value)
	if not ok then return nil end
	return res
end

-- base64 ---------------------------------------------------------------------
local function b64_decode(str)
	local map = {}
	local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	for i = 1, #alphabet do
		map[alphabet:sub(i, i)] = i - 1
	end
	str = str:gsub("[^%w%+/=]", "")
	local res = {}
	for i = 1, #str, 4 do
		local v1 = map[str:sub(i, i)]
		local v2 = map[str:sub(i + 1, i + 1)]
		local v3 = map[str:sub(i + 2, i + 2)]
		local v4 = map[str:sub(i + 3, i + 3)]
		if v1 and v2 then
			res[#res + 1] = string.char(v1 * 4 + math.floor(v2 / 16))
			if v3 then
				res[#res + 1] = string.char((v2 % 16) * 16 + math.floor(v3 / 4))
			end
			if v3 and v4 then
				res[#res + 1] = string.char((v3 % 4) * 64 + v4)
			end
		end
	end
	return table.concat(res)
end

local function tab(...)
	local f = { ... }
	local out = {}
	for i = 1, #f do
		out[i] = tostring(f[i] or "")
	end
	return table.concat(out, "\t")
end

local function seconds(v, fallback)
	local n = tonumber(v)
	if not n or n <= 0 then
		return fallback or 0
	end
	if n > 10000 then -- some endpoints answer in milliseconds
		n = math.floor(n / 1000)
	end
	return n
end

-- modes ----------------------------------------------------------------------
if mode == "b64" then
	io.write(b64_decode(data))
	return
end

-- percent encoding: done here on purpose, the urlencode package on these boards
-- allocates a buffer of the input length and corrupts the heap whenever a byte
-- needs to expand (every chinese character)
if mode == "urlenc" then
	io.write((data:gsub("[^A-Za-z0-9%-%._~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end)))
	return
end

local obj = json_decode(data)

if type(obj) ~= "table" then
	return
end

if mode == "songinfo" then
	io.write(tab(obj.url, obj.timeLength or 0, obj.songName, obj.singerName,
		obj.fileSize or 0) .. "\n")
	return
end

if mode == "rank" or mode == "search" then
	local d = obj.data
	local info = type(d) == "table" and d.info or nil
	if type(info) ~= "table" then return end
	for _, r in ipairs(info) do
		if type(r) == "table" and r.hash then
			local name = r.filename
			if not name or name == "" then
				name = tostring(r.singername or "") .. " - " .. tostring(r.songname or "")
			end
			io.write(tab(r.hash, name, seconds(r.duration), r.privilege or 0) .. "\n")
		end
	end
	return
end

if mode == "cdnget" then
	local d = obj or {}
	if d.status == 1 and type(d.url) == "table" and d.url[1] then
		print(tab(d.url[1], tostring(d.fileSize or 0)))
	end
	return
end

if mode == "kuwodur" then
	local d = (obj or {}).data
	if type(d) == "table" and d.duration then
		print(tostring(d.duration))
	end
	return
end

if mode == "kuwobang" then
	local ml = (obj or {}).musiclist
	if type(ml) ~= "table" then
		return
	end
	for _, m in ipairs(ml) do
		if m.id and m.name then
			print(tostring(m.id) .. "|" .. m.name .. "|" .. (m.artist or "") .. "|" .. (m.duration or "0") .. "|" .. (m.pay or "0"))
		end
	end
	return
end

if mode == "kuwosearch" then
	local ml = (obj or {}).abslist
	if type(ml) ~= "table" then
		return
	end
	for _, m in ipairs(ml) do
		local rid = tostring(m.MUSICRID or ""):gsub("^MUSIC_", "")
		if rid ~= "" and m.NAME then
			print(rid .. "|" .. m.NAME .. "|" .. (m.ARTIST or "") .. "|" .. (m.DURATION or "0") .. "|" .. (m.PAY or "0"))
		end
	end
	return
end

if mode == "kuwourl" then
	local d = obj or {}
	if d.code == 200 and d.url then
		print(d.url)
	end
	return
end

if mode == "ranks" then
	local info = (obj or {}).data and obj.data.info
	if type(info) ~= "table" then
		return
	end
	for _, r in ipairs(info) do
		if r.rankid and r.rankname then
			print(tab(tostring(r.rankid), r.rankname))
		end
	end
	return
end

if mode == "lrcq" then
	local cands = obj.candidates
	if type(cands) ~= "table" then return end
	for _, c in ipairs(cands) do
		if type(c) == "table" and c.id and c.accesskey then
			io.write(tab(c.id, c.accesskey, c.duration or 0) .. "\n")
		end
	end
	return
end

if mode == "lrcg" then
	io.write(b64_decode(obj.content or ""))
	return
end
