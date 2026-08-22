# luci-app-iptv-epg — IPTV EPG 管理服务 (OpenWrt 15.05)

上海电信 IPTV 节目单(EPG)管理服务,配合 DIYP 播放器使用。

## 功能

- **init.d 服务**: `service_enabled=1` 时开机自动启动; 启动时自动完成路由/Cookie/CGI/定时配置
- **路由自动添加**: 电信 EPG 服务器 218.83.165.67 自动走 br-iptv 专网路由 (via 30.170.0.1), 并持久化到 network.epgroute
- **Cookie 保活 daemon**: 监听 br-iptv 上到电信 EPG 的流量 + 每5分钟主动心跳(heartbeat.jsp), 持续刷新 cookie, 保证长期有效
- **CGI 服务**: 内置 epg.cgi (DIYP 兼容格式), 安装到 /www/cgi-bin/, 带名字索引快速路径(0.1s)
- **自定义时间每日拉取**: crontab 按设置的时间每天执行 (默认 02:30)
- **只拉取 UCI 设定频道, 保持 7 天记录**: 只处理设置页频道列表中的频道, 从今天起 N 天(默认 7)
- **手动一键拉取**: LuCI 总览页一键拉取全部/单频道
- **直播 + EPG 点击回看 (v2.3)**: play.cgi (TVOD 路径) + tsproxy.cgi, DIYP 5.2.0 点击节目自动回看

## v2.3 迭代改进 (2026-08-17)

- **🔥 EPG 点击回看突破**: 频道源 URL 路径含 `TVOD` → DIYP 5.2.0 点击 EPG 节目自动附加 `playseek=<节目时间>`! 源格式: `http://A/cgi-bin/TVOD/play.cgi?url=<组播>&ch=<别名>`
- **play.cgi**: 直播/回看入口 (无 playseek → 302 直播; 有 → 电信 getTvodPlayUrl 回看), 绕过负载均衡直连 6610 + 机顶盒 UA
- **tsproxy.cgi**: TS 分片代理 (路径直传, exec curl 流式, 跟随 302)
- **TVOD 符号链接**: /www/cgi-bin/TVOD/play.cgi → ../play.cgi (init.d ensure_cgi 自动确保)
- **epg.cgi 提速**: 168 频道 CHID 硬编码 (getChannelList 兜底) + awk 一次性提取替代 while+sed, 冷启动 15s → 0.17s
- **EPG 日期过滤**: 电信节目日 = 16:00-次日15:59, 按北京自然日过滤 (strftime %F), CST 直接 strftime 不需 -tzadj

## v2.2 迭代改进 (2026-08-16)

- **getChannelProg 接口**: 一次拉取全天节目单(参考 sh-tel-iptv-spider), 替代 getPreCurNextProg 16次并行
- **时区修正**: 兼容 UTC(busybox)和 CST 设备, 请求/显示统一转北京时间
- **busybox 兼容**: 修复 echo -e(busybox不解析)、paste(不存在)、${var:x}(bashism) 等问题, 全部改用 printf/sed/cut
- **字段提取鲁棒**: 电信响应字段顺序不固定, 改用 sed 宽松提取(不再依赖固定顺序正则)
- **服务控制**: service_enabled/cookie_daemon/cgi_enabled 独立开关, 首次拉取仅在启用且有cookie时执行
- **cookie daemon 增强**: 抓所有到EPG的流量(不限于机顶盒MAC) + 心跳响应Set-Cookie更新 + POSIX兼容

## 目录结构

```
luci-app-iptv-epg/
├── Makefile                      # OpenWrt 包构建 (v2.0.0)
├── luasrc/
│   ├── controller/iptv-epg.lua   # LuCI 控制器 (总览/频道/拉取/状态/服务控制/设置)
│   ├── model/cbi/iptv-epg.lua    # 设置页 CBI
│   └── view/iptv_epg/overview.htm# 总览页 (服务控制+频道表+一键拉取)
├── root/
│   ├── etc/init.d/iptv-epg       # init.d 服务 (start/stop/enabled)
│   ├── usr/bin/iptv_epg          # 后端工具 (channels/fetch/status/route/cookie)
│   ├── usr/bin/epg_cookie_daemon.sh # Cookie 保活守护
│   ├── www/cgi-bin/epg.cgi       # DIYP 兼容 EPG 接口
│   ├── etc/config/iptv_epg       # UCI 默认配置
│   └── etc/uci-defaults/iptv-epg # 首次安装初始化+启用服务
└── po/zh-cn/iptv-epg.po          # 中文翻译
```

## 构建

```bash
cd myopenwrt  # 构建树
cp -r /path/to/luci-app-iptv-epg package/
./scripts/feeds update -i
make package/luci-app-iptv-epg/compile V=s
# 产物: bin/<target>/packages/luci-app-iptv-epg_2.0.0-1_all.ipk
```

## 安装

```bash
opkg install luci-app-iptv-epg_2.0.0-1_all.ipk
/etc/init.d/iptv-epg enable
/etc/init.d/iptv-epg start
```

安装后 LuCI 菜单: **服务 → IPTV EPG**。

## 服务管理

```bash
/etc/init.d/iptv-epg start    # 加路由 + 启cookie daemon + 部署CGI + 设crontab + 首次拉取
/etc/init.d/iptv-epg stop     # 停 daemon + 停 crontab
/etc/init.d/iptv-epg enabled  # 检查是否启用 (根据 service_enabled)
```

## 后端工具

```bash
iptv_epg channels          # 列出全部频道 (名称|ID|mixNo)
iptv_epg categories        # 列分类
iptv_epg fetch             # 一键拉取 UCI 频道 7 天节目单
iptv_epg fetch 新闻综合    # 拉取指定频道
iptv_epg status            # 状态 (cookie/缓存/路由/CGI/crontab)
iptv_epg route             # 手动添加/修复路由
iptv_epg cookie            # cookie 状态
```

## 与 DIYP 播放器配合

- 频道源: web界面 IPTV.txt 纯TXT (每行 频道名,URL)
- 应用内"节目地址": **留空**
- EPG接口: `http://<A-IP>/cgi-bin/epg.cgi`
- 预取生成的缓存 `/tmp/epg_cache_<ID>_<日期>.json` 与 epg.cgi 共用

## 依赖

- `luci-base`, `curl`, `tcpdump`
- 机顶盒(AA:BB:CC:DD:EE:FF)接在 A 路由 br-iptv 上 (cookie daemon 需要机顶盒流量)

## 备注

- 电信接口需专网路由 (init.d 自动处理); A 重启后服务自动恢复
- A 路由 /tmp 仅 61.5M, 缓存按天数清理
- 该插件基于 A 设备现有 `/usr/bin/epg` 工具逻辑封装
