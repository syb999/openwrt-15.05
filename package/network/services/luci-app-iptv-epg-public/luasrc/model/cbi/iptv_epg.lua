-- luci-app-iptv-epg 设置页 (CBI)
-- OpenWrt 15.05 兼容 (参考 msd_lite / i2c-ssd1306 CBI)

m = Map("iptv_epg", translate("IPTV EPG 管理"),
	translate("上海电信 IPTV 节目单管理服务: 路由 / Cookie 保活 / CGI / 定时拉取."))

-- 保存并应用后自动重启服务, 让 daemon 立即读取新配置 (stb_side/stb_iface 等)
function m.on_after_commit(self)
	luci.sys.call("/etc/init.d/iptv-epg restart >/dev/null 2>&1")
end

-- ===== 服务控制 =====
s = m:section(NamedSection, "main", "iptv_epg", translate("服务控制"))
s.addremove = false

o = s:option(Flag, "service_enabled", translate("启用服务 (init.d)"))
o.default = "1"
o.rmempty = false

o = s:option(Flag, "cookie_daemon", translate("Cookie 保活 daemon"))
o.default = "1"
o.rmempty = false

o = s:option(Flag, "cgi_enabled", translate("启用 CGI 服务 (epg.cgi)"))
o.default = "1"
o.rmempty = false

-- ===== 基本设置 =====
s2 = m:section(NamedSection, "main", "iptv_epg", translate("基本设置"))
s2.addremove = false

o = s2:option(Value, "epg_host", translate("EPG 服务器"))
o.default = "218.83.165.67:8084"
o.rmempty = false

o = s2:option(Value, "cookie_file", translate("Cookie 文件"))
o.default = "/tmp/stb_cookie.txt"
o.rmempty = false

o = s2:option(Value, "cate_id", translate("频道分类 ID"))
o.default = "000406"
o.rmempty = false

o = s2:option(Value, "cache_dir", translate("缓存目录"))
o.default = "/tmp"
o.rmempty = false

-- ===== 专网路由 =====
s3 = m:section(NamedSection, "main", "iptv_epg", translate("专网路由 (电信EPG)"))
s3.addremove = false

o = s3:option(Value, "route_target", translate("路由目标 IP"))
o.default = "218.83.165.67"
o.rmempty = false

o = s3:option(Value, "iptv_gateway", translate("IPTV 网关"))
o.default = "30.170.0.1"
o.rmempty = false

o = s3:option(Value, "iptv_iface", translate("IPTV 接口 (专网路由)"))
o.default = "iptv"
o.description = translate("IP 专网接口名 (如 iptv / br-iptv / vxlan_iptv / eth0.2)。程序自动读取该接口的网段与网关添加电信专网路由; 留空则自动探测 (优先有 30.170.x 地址的接口)。daemon 还会从机顶盒流量自动学习服务器 IP 并补路由, 电信更换服务器 IP 后无需改配置")

o = s3:option(ListValue, "stb_side", translate("机顶盒位置 (Cookie 抓包接口)"))
o:value("B", translate("B面 (经VXLAN隧道, 抓 vxlan_iptv)"))
o:value("A", translate("A面 (直连A设备, 抓 br-lan)"))
o:value("C", translate("自定义接口 (主路由/无 vxlan 环境)"))
o.default = "B"

o = s3:option(Value, "stb_iface", translate("自定义抓包接口"))
o:depends("stb_side", "C")
o.default = "br-lan"
o.description = translate("部署在主路由等无 vxlan/br-iptv 环境时, 手动指定抓包接口 (如 br-lan / eth0.2 / br-wan)。接口不存在时自动回退 br-lan→br-wan")

o = s3:option(Value, "broadband_uid", translate("宽带账号 (EPG 认证用)"))
o.default = ""
o.placeholder = "adXXXXXXXX 或 XXXX@etv1"
o.description = translate("输入宽带 PPPoE 账号(如 adXXXXXXXX)。系统自动去掉 ad 前缀拼 @etv1 作为 EPG 认证账号; 也可直接填完整账号(如 XXXXXXXX@etv1)")

o = s3:option(Value, "stb_sn", translate("机顶盒 SN (EPG 认证用)"))
o.default = ""
o.placeholder = "机顶盒背面 SN 序列号"
o.description = translate("机顶盒背面标签的 SN 序列号。认证时自动在前面补 0 到 32 位")

o = s3:option(Value, "stb_mac", translate("机顶盒 MAC (自动发现/认证用)"))
o.default = ""
o.placeholder = "AA:BB:CC:DD:EE:FF"
o.description = translate("换机顶盒后修改为此新机顶盒的 MAC 地址")

o = s3:option(Value, "getkey_url", translate("私钥下载直链 (可选)"))
o.default = ""
o.placeholder = "https://example.com/iptv_epg_rsa.pem"
o.description = translate("账号直登需要 RSA 私钥 (公共版不内置)。填私钥文件的直链 (网盘/自建服务器, 国内可达) 后自动下载; 留空则尝试 GitHub 提取或手动放置 /etc/iptv_epg_rsa.pem")

o = s3:option(Value, "stb_ip", translate("机顶盒 IP (可选, 默认按 MAC 自动发现)"))
o.default = ""
o.placeholder = "192.168.1.100"
o.description = translate("留空或不用填: 系统按上面 stb_mac 从 ARP 自动发现当前 IP. 仅在自动发现失败时手动指定.")

o = s3:option(Value, "stb_guid", translate("机顶盒 GUID (可选, 回看用)"))
o.default = ""
o.placeholder = "{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}"
o.description = translate("机顶盒设备 GUID, 回看/TS 代理请求 XClientGUID 头用. 留空则不带该头 (抓包模式不受影响, 仅回看可能被电信拒绝). 可在设置页机顶盒信息或抓包中获取.")

-- ===== 定时预取 =====
s4 = m:section(NamedSection, "main", "iptv_epg", translate("定时预取 (每日更新)"))
s4.addremove = false

o = s4:option(Flag, "prefetch_enabled", translate("启用定时预取"))
o.default = "1"

o = s4:option(Value, "prefetch_hour", translate("预取小时 (0-23)"))
o.datatype = "range(0,23)"
o.default = "2"

o = s4:option(Value, "prefetch_minute", translate("预取分钟 (0-59)"))
o.datatype = "range(0,59)"
o.default = "30"

o = s4:option(Value, "prefetch_days", translate("预取天数 (保持记录)"))
o.datatype = "range(1,7)"
o.default = "7"
o.description = translate("只拉取下方频道列表中的频道, 从今天起 N 天")

-- ===== 频道列表 =====
s5 = m:section(TypedSection, "channel", translate("频道列表 (只拉取这些频道)"))
s5.addremove = true
s5.anonymous = true
s5.template = "cbi/tblsection"
s5.description = translate("手动录入要拉取 EPG 的频道; 也可在总览页点\"一键抓取频道表\"自动重建 (需有效 Cookie)")

o = s5:option(Value, "name", translate("频道名"))
o.rmempty = false

o = s5:option(Value, "udp", translate("组播地址"))
o.rmempty = false
o.placeholder = "233.0.0.1:5140"

o = s5:option(Value, "epg_id", translate("EPG ID"))
o.rmempty = false
o.placeholder = "ch00000000000000001485"

return m
