# luci-app-ndpi

kmod-ipt-ndpi（内核态 nDPI 应用识别）的 LuCI 前端。用"预设 / 应用 / 自定义域名"
匹配流量，命中后打 mark（给 ip rule / mwan3 / tc 分流）或直接丢弃。

## 四个页面

    nDPI
      Identification   识别状态：自检 + 每条规则的命中包数
      Rules            规则：用哪个预设/应用/域名，挂哪个链，打 mark 还是丢弃
      Presets          预设：域名和/或 nDPI 协议的组合（26 个自带预设，可增删改）
      Settings         设置：总开关、flow-info

规则只指向"预设"，所以改预设（比如给 bilibili 再加个域名）会同时作用于所有用到它的规则。

## 和 SFE（fast-classifier / 快路径）的关系

不影响识别。fast-classifier 默认 `offload_at_pkts = 128`：一条连接的前 128 个包
全部走完整 netfilter，nDPI 在第 1~4 个包就拿到 TLS SNI / HTTP Host / 证书域名，
所以 `--proto` 和 `--host` 都能正常命中；128 包之后连接才交给快路径。
唯一差别是字节/包统计被截断（只算前 128 包），本插件不依赖它。
`cat /sys/fast_classifier/offload_at_pkts` 可查、可写。

## 自带的 26 个预设

    视频/社区  bilibili douyin iqiyi youku kuaishou xiaohongshu weibo zhihu
    电商/生活  taobao jd pinduoduo meituan ximalaya netease_music
    社交/搜索  wechat qq baidu
    AI         doubao deepseek kimi zhipu
    游戏       steam epic mihoyo
    语音/视频  voip（SIP RTP RTCP MGCP H323 Skype）、iptv（MPEG_TS RTSP）

- 域名子串匹配（内核 strstr）：`bilivideo.com` 能命中 `upos-sz-mirrorcos.bilivideo.com`
- 协议名必须和 `/proc/net/xt_ndpi/proto` 第三列一致（大小写不敏感），MPEG-TS 在
  nDPI 里叫 **`MPEG_TS`**
- RTP 没放进 iptv（Voip 也在用）；IPTV 若是裸 RTP 无 TS 头，自己往 iptv 里加 RTP
- nDPI 2.8 没有 IGMP，组播 join/leave 认不到

## 看不到识别时先看"自检"

Identification 页顶部四行就是排错起点：

    xt_ndpi 模块     缺失 → kmod-ipt-ndpi 没装/没加载，规则必然全失败
    /proc 接口       缺失 → 模块没起来
    已安装规则      0    → 看"最近日志"，通常是 iptables 报错
    最近日志              /etc/init.d/ndpi 的 logger 输出（logread | grep ndpi）

规则都在但命中计数长期为 0，通常是：

- 规则挂在 PREROUTING（转发流量），但你测的是路由器自己发出的流量（走 OUTPUT，
  本机流量另建 output 规则的）
- 测的流量不属于预设里的域名/协议
- 认不出的加密流量：域名靠 TLS SNI / HTTP Host，QUIC 或 ECH 可能拿不到域名

计数来源是 `iptables-save -c`（`iptables -S` 不带计数器，别拿它看）。

## 生效与自证

    /etc/init.d/ndpi reload

    # 1) 规则进去了（预设会展开成多条 --host / --proto）
    iptables -t mangle -S | grep NDPI_
    # 2) 命中计数（-v 是唯一可信的"识别成功"证据）
    iptables -t mangle -L NDPI_PREROUTING -v -n

## 翻译

界面文字全部是英文源码 + `po/zh-cn/`（`luci-i18n-ndpi-zh-cn` 包）。
msgid 一律避开 luci-base 已有的通用词（Status/General/Match/Packets/disabled…），
免得覆盖全站的翻译。

## 注意

`/etc/init.d/firewall restart` 会清 mangle 表里的自定义链，之后要
`/etc/init.d/ndpi reload` 重新挂上（本包 START=99，开机在 firewall 之后跑）。
