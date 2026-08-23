#!/bin/sh
# ============================================================
# epg_cookie_daemon.sh — 电信 EPG 会话 Cookie 保活守护
# 原理: 监听机顶盒(br-iptv)到电信 EPG 服务器(8084)的流量,
#       从 HTTP 响应头提取 Set-Cookie, 写入 /tmp/stb_cookie.txt
# 保证长期有效: 机顶盒只要在播(EPG/回看), cookie 就持续刷新
# 启动: /etc/init.d/iptv-epg start (由服务管理)
# ============================================================

COOKIE_FILE=${EPG_COOKIE:-/tmp/stb_cookie.txt}
PROVIDER=$(uci get iptv_epg.main.provider 2>/dev/null)
[ -n "$PROVIDER" ] || PROVIDER=telecom
# EPG 服务器: uci epg_host → 按运营商默认 (telecom=上海电信, unicom=上海联通实测地址)
EPG_SRV=$(uci get iptv_epg.main.epg_host 2>/dev/null)
if [ -z "$EPG_SRV" ]; then
  case "$PROVIDER" in
    unicom) EPG_SRV=10.223.2.76:33200 ;;
    *) EPG_SRV=218.83.165.67:8084 ;;
  esac
fi
[ -n "$EPG_SRV" ] || EPG_SRV=218.83.165.67:8084
EPG_HOST=${EPG_SRV%:*}
EPG_PORT=${EPG_SRV##*:}
HEARTBEAT_URL="http://$EPG_HOST:$EPG_PORT/iptvepg/heartbeat.jsp"
CH_URL="http://$EPG_HOST:$EPG_PORT/iptvepg/frame1413/function/ajax/epg7getChannelByAjax.jsp"
UA='webkit;Resolution(PAL,720P,1080P)'
REF="http://$EPG_HOST:$EPG_PORT/iptvepg/frame1413/portal/play_pro.html"
# 监听接口: 按机顶盒位置自动适配
# B面: 优先 vxlan_iptv (隧道接口, A+光猫场景), 无则 br-iptv, 再则 br-wan
# A面: 优先 br-lan, 无则 br-wan
# 联通: vxlan_inet (A/B 拓扑单隧道) 或 br-lan (机顶盒直连)
# 主路由部署 (无 vxlan/br-iptv): 自动回退到 br-lan/br-wan (机顶盒直连)
IFACE=$(uci get iptv_epg.main.stb_side 2>/dev/null)
if [ "$IFACE" = "A" ]; then
  IFACE=br-lan
  [ -d /sys/class/net/br-lan ] || IFACE=br-wan
elif [ "$IFACE" = "C" ]; then
  # 自定义接口 (主路由部署/无 vxlan 环境)
  IFACE=$(uci get iptv_epg.main.stb_iface 2>/dev/null)
  [ -n "$IFACE" ] && [ -d "/sys/class/net/$IFACE" ] || IFACE=br-lan
  [ -d /sys/class/net/br-lan ] || IFACE=br-wan
else
  if [ "$PROVIDER" = "unicom" ]; then
    IFACE=vxlan_inet
    [ -d /sys/class/net/vxlan_inet ] || IFACE=br-lan
    [ -d /sys/class/net/br-lan ] || IFACE=br-wan
  else
    IFACE=vxlan_iptv
    [ -d /sys/class/net/vxlan_iptv ] || IFACE=br-iptv
    [ -d /sys/class/net/br-iptv ] || IFACE=br-wan
  fi
fi
# 机顶盒 MAC (自动发现用; 换机顶盒后改 config 的 stb_mac)
STB_MAC=$(uci get iptv_epg.main.stb_mac 2>/dev/null)
[ -n "$STB_MAC" ] || STB_MAC=''
# 机顶盒 IP 自动发现 (按 STB_MAC 从 ARP 找), 找不到则用配置或不限 IP
STB_IP=$(cat /proc/net/arp 2>/dev/null | grep -i "$STB_MAC" | awk '{print $1}' | head -1)
[ -n "$STB_IP" ] || STB_IP=$(uci get iptv_epg.main.stb_ip 2>/dev/null)
PIDFILE=/var/run/epg_cookie_daemon.pid

log() {
  # 日志轮转: 保留最近 100 行 (防止 /tmp 61.5M 被日志撑爆, 长时间运行不爆盘)
  if [ -f /tmp/epg_cookie_daemon.log ]; then
    local LC=$(wc -l < /tmp/epg_cookie_daemon.log 2>/dev/null)
    [ "${LC:-0}" -gt 100 ] && tail -100 /tmp/epg_cookie_daemon.log > /tmp/epg_cookie_daemon.log.tmp 2>/dev/null && mv /tmp/epg_cookie_daemon.log.tmp /tmp/epg_cookie_daemon.log
  fi
  echo "[$(date '+%F %T')] $*" >> /tmp/epg_cookie_daemon.log
}

# ---------- 联通会话采集 (机顶盒流量 → /etc/epg_unicom_sess.txt) ----------
# 从机顶盒 EPG 流量提取:
#   JSESSIONID (EPG 门户会话) / TEMPKEY+USERTOKEN (getchannellistHWCU 三件套)
#   AUTHENTICATOR+userToken (ValidAuthenticationHWCU 登录, 重放用) / STBID / USERID / MAC
collect_unicom_sess() {
  local CAP=/tmp/epg_cookie_cap.txt
  local SESS=/etc/epg_unicom_sess.txt
  [ -f "$CAP" ] || return 0
  # JSESSIONID: 请求 Cookie 优先, 其次登录响应 Set-Cookie
  local NEW_SID=$(grep -oE 'JSESSIONID=[A-Z0-9]{20,}' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  [ -z "$NEW_SID" ] && NEW_SID=$(grep -oE 'Set-Cookie: JSESSIONID=[A-Z0-9]{20,}' "$CAP" 2>/dev/null | head -1 | grep -oE '[A-Z0-9]{20,}')
  # getchannellistHWCU 三件套 (请求体参数)
  local NEW_TK=$(grep -oE 'tempKey=[A-F0-9]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  local NEW_UT=$(grep -oE '[?&]UserToken=[A-Za-z0-9+/=]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  [ -z "$NEW_UT" ] && NEW_UT=$(grep -oE '^UserToken=[A-Za-z0-9+/=]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  # ValidAuthenticationHWCU 登录参数 (重放用)
  local NEW_AUTH=$(grep -oE 'Authenticator=[A-F0-9]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  local NEW_UTOKEN=$(grep -oE 'userToken=[A-F0-9]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  local NEW_STBID=$(grep -oE 'STBID=[0-9A-Z]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  local NEW_UID=$(grep -oE 'UserID=[A-Z0-9]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2)
  local NEW_MAC=$(grep -oE 'mac=[0-9A-Fa-f:%]+' "$CAP" 2>/dev/null | head -1 | cut -d= -f2 | tr '[:lower:]' '[:upper:]')
  # 合并旧值 (部分字段可能本次没抓到) — 注意: . "$SESS" 加载的是 JSESSIONID/TEMPKEY 等名, 不是 OLD_*
  [ -f "$SESS" ] && . "$SESS" 2>/dev/null
  [ -n "$NEW_SID" ] || NEW_SID="$JSESSIONID"
  [ -n "$NEW_TK" ] || NEW_TK="$TEMPKEY"
  [ -n "$NEW_UT" ] || NEW_UT="$USERTOKEN"
  [ -n "$NEW_AUTH" ] || NEW_AUTH="$AUTHENTICATOR"
  [ -n "$NEW_UTOKEN" ] || NEW_UTOKEN="$USERTOKEN_EPG"
  [ -n "$NEW_STBID" ] || NEW_STBID="$STBID"
  [ -n "$NEW_UID" ] || NEW_UID="$USERID"
  [ -n "$NEW_MAC" ] || NEW_MAC="$MAC"
  [ -n "$NEW_SID" ] || [ -n "$NEW_TK" ] || [ -n "$NEW_AUTH" ] || return 0
  local TMP=/tmp/epg_unicom_sess.tmp
  : > "$TMP"
  [ -n "$NEW_SID" ] && echo "JSESSIONID='$NEW_SID'" >> "$TMP"
  [ -n "$NEW_TK" ] && echo "TEMPKEY='$NEW_TK'" >> "$TMP"
  [ -n "$NEW_UT" ] && echo "USERTOKEN='$NEW_UT'" >> "$TMP"
  [ -n "$NEW_AUTH" ] && echo "AUTHENTICATOR='$NEW_AUTH'" >> "$TMP"
  [ -n "$NEW_UTOKEN" ] && echo "USERTOKEN_EPG='$NEW_UTOKEN'" >> "$TMP"
  [ -n "$NEW_STBID" ] && echo "STBID='$NEW_STBID'" >> "$TMP"
  [ -n "$NEW_UID" ] && echo "USERID='$NEW_UID'" >> "$TMP"
  [ -n "$NEW_MAC" ] && echo "MAC='$NEW_MAC'" >> "$TMP"
  if [ -f "$SESS" ] && cmp -s "$SESS" "$TMP"; then
    rm -f "$TMP"
  else
    mv "$TMP" "$SESS"
    log "联通会话已采集: SID=${NEW_SID:-无} TEMPKEY=${NEW_TK:-无} AUTH=${NEW_AUTH:+有}"
  fi
}

# 更新 cookie
# 优先级: ① 机顶盒请求里的完整 Cookie 头 (机顶盒已认证, 含全部字段)
#          ② 响应 Set-Cookie (会话建立/刷新时)
update_cookie() {
  local RAW="$1"
  local COOKIES=""

  # ① 请求方向: Cookie: 头 (机顶盒认证后的完整会话, 最可靠)
  #    格式: Cookie: PRE_ADVERTISEMENT_FLAG=1; JSESSIONID=xxx; BimsAuth...=yyy
  #    取最长的一行 (最完整); 不用 ^ 锚定 (tcpdump -A 可能带时间戳前缀)
  COOKIES=$(echo "$RAW" | grep -oE 'Cookie: [^\r\n]+' | sed 's/^.*Cookie: //' | awk '{ if (length > max) { max = length; line = $0 } } END { print line }')

  # ② 响应方向: Set-Cookie 值拼接 (仅当没有完整 Cookie 头时)
  if [ -z "$COOKIES" ]; then
    COOKIES=$(echo "$RAW" | grep -oE '(JSESSIONID|bims_user_token|UserToken|SESSIONID|BimsAuth[a-zA-Z]*)=[A-Za-z0-9%._=-]+' | tr '\n' ';' | sed 's/;$//')
  fi

  [ -z "$COOKIES" ] && return 1
  # 去重: 同名 cookie 只保留最后一个 (防止叠加重复 JSESSIONID)
  # busybox awk 支持关联数组, 用 seen 数组去重
  COOKIES=$(echo "$COOKIES" | tr ';' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$' | awk -F'=' '!seen[$1]++')
  # 兜底: 若 awk 失败 (空结果), 保留原始
  [ -z "$COOKIES" ] && COOKIES=$(echo "$1" | grep -oE '[A-Za-z0-9_%]+=[A-Za-z0-9%._=-]+' | tr '\n' ';' | sed 's/;$//')
  COOKIES=$(echo "$COOKIES" | tr '\n' ';' | sed 's/;;*/;/g;s/; *$//')
  [ -z "$COOKIES" ] && return 1
  # 只接受足够长的 cookie (完整会话 ≥ 40 字节; 防止短 JSESSIONID 覆盖完整会话)
  local CLEN=$(echo "$COOKIES" | wc -c)
  local OLD_LEN=0
  [ -f "$COOKIE_FILE" ] && OLD_LEN=$(wc -c < "$COOKIE_FILE")
  if [ "$CLEN" -lt 40 ] && [ "$OLD_LEN" -ge "$CLEN" ]; then
    log "跳过短 cookie ($CLEN 字节 < 现有 $OLD_LEN), 保留完整会话"
    return 0
  fi
  # 🔴 有效性验证: 新 cookie 先 curl 测 getChannelList, 200 才写入
  # 防止无效心跳会话覆盖有效手动写入的 JSESSIONID (机顶盒关机时)
  local TEST_CODE=$(curl -s --max-time 8 -o /dev/null -w '%{http_code}' "$CH_URL" \
    -H "Cookie: $COOKIES" -H "User-Agent: $UA" -H "Referer: $REF" -d 'action=getChannelList&cateID=000406&type=' 2>/dev/null)
  if [ "$TEST_CODE" != "200" ]; then
    log "新 cookie 验证失败 (HTTP $TEST_CODE), 保留现有: $(echo "$COOKIES" | cut -c1-40)..."
    return 0
  fi
  echo "$COOKIES" > "$COOKIE_FILE"
  # 🔴 固化到 uci cookie_backup (公共版无账号直登, 这是唯一持久化途径!)
  #    重启后 restore_cookie 恢复 → 不用重新开机顶盒抓包
  local BK=$(uci get iptv_epg.main.cookie_backup 2>/dev/null)
  if [ "$BK" != "$COOKIES" ]; then
    uci set iptv_epg.main.cookie_backup="$COOKIES"
    uci commit iptv_epg 2>/dev/null
  fi
  log "cookie 已更新 (验证通过 HTTP 200, $CLEN 字节): $(echo "$COOKIES" | cut -c1-60)..."
  return 0
}

# 单实例检查
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
  if kill -0 "$OLD_PID" 2>/dev/null; then
    log "已在运行 (pid $OLD_PID)"
    exit 0
  fi
  rm -f "$PIDFILE"
fi
echo $$ > "$PIDFILE"
log "启动 (pid $$)"

# 认证模式: 配置了宽带账号+SN → 用账号直登续期 (不依赖机顶盒, 不刷抓包噪音)
# 未配置(机顶盒场景/其他地区) → 保留抓包模式
AUTH_MODE=""
[ -n "$(uci get iptv_epg.main.broadband_uid 2>/dev/null)" ] && [ -n "$(uci get iptv_epg.main.stb_sn 2>/dev/null)" ] && AUTH_MODE=1
CH_URL="http://$EPG_HOST:$EPG_PORT/iptvepg/frame1413/function/ajax/epg7getChannelByAjax.jsp"

# 循环: 认证模式(续期) 或 抓包模式(机顶盒流量)
LAST_HEARTBEAT=0
LAST_AUTH=0
while true; do
  NOW=$(date +%s)

  if [ -n "$AUTH_MODE" ]; then
    # ---------- 认证模式: 每 300 秒检查 cookie, 失效则账号直登续期 ----------
    if [ $((NOW - LAST_AUTH)) -ge 300 ]; then
      LAST_AUTH=$NOW
      TEST=000
      if [ -s "$COOKIE_FILE" ]; then
        TEST=$(curl -s --max-time 8 -o /dev/null -w '%{http_code}' "$CH_URL" \
          -H "Cookie: $(cat "$COOKIE_FILE")" -H 'User-Agent: webkit' \
          -d 'action=getChannelList&cateID=000406&type=' 2>/dev/null)
      fi
      if [ "$TEST" = "200" ]; then
        :
        # cookie 有效, 静默 (不刷日志)
      else
        log "cookie 失效 (HTTP $TEST), 账号直登续期..."
        /usr/bin/epg_auth.sh >/dev/null 2>&1 || log "账号直登失败"
      fi
    fi
    sleep 60
    continue
  fi

  # ---------- 抓包模式 (机顶盒流量) ----------
  # 主动心跳保活: 每 5 分钟, 且响应中的 Set-Cookie 也更新
  if [ $((NOW - LAST_HEARTBEAT)) -ge 300 ]; then
    LAST_HEARTBEAT=$NOW
    # 即使无 cookie 也尝试 (心跳可能返回 Set-Cookie 建立会话)
    CK=""
    [ -f "$COOKIE_FILE" ] && CK=$(cat "$COOKIE_FILE")
    if [ -n "$CK" ]; then
      HBRESP=$(curl -s --max-time 5 -D - -o /dev/null "$HEARTBEAT_URL" \
        -H "Cookie: $CK" -H "User-Agent: webkit;Resolution(PAL,720P,1080P)" 2>/dev/null)
    else
      HBRESP=$(curl -s --max-time 5 -D - -o /dev/null "$HEARTBEAT_URL" \
        -H "User-Agent: webkit;Resolution(PAL,720P,1080P)" 2>/dev/null)
    fi
    # 心跳响应若带新 cookie 则更新
    echo "$HBRESP" | grep -qi 'Set-Cookie' && update_cookie "$HBRESP"
    log "心跳保活完成"
  fi

  # 抓 EPG 流量: 机顶盒 到 EPG 服务器的双向流量
  # ① 请求方向: Cookie: 头 (机顶盒认证会话) ② 响应方向: Set-Cookie (刷新)
  # busybox 无 timeout 命令, tcpdump 无流量会一直等 → 用后台 + sleep + kill 实现限时
  # 最多等 20 秒; -c 20 抓足够包 (提高拿到完整 Cookie 头的概率)
  # 抓包范围: cap_ports (uci, 空格分隔) — 电信默认 8084/7001/6610; 联通按实际抓包改; 留空抓全部
  CAP_PORTS=$(uci get iptv_epg.main.cap_ports 2>/dev/null)
  CAP_FILTER=""
  for P in $CAP_PORTS; do
    [ -n "$CAP_FILTER" ] && CAP_FILTER="$CAP_FILTER or "
    CAP_FILTER="${CAP_FILTER}tcp port $P"
  done
  [ -n "$CAP_FILTER" ] || CAP_FILTER="tcp"
  [ -n "$STB_IP" ] && CAP_FILTER="($CAP_FILTER) and host $STB_IP"
  tcpdump -i "$IFACE" -nn -s 0 -A -c 20 \
    "$CAP_FILTER" > /tmp/epg_cookie_cap.txt 2>/dev/null &
  TCAP_PID=$!
  # 最多等 20 秒 (无流量也继续循环, 保证心跳能执行)
  i=0
  while kill -0 "$TCAP_PID" 2>/dev/null && [ $i -lt 20 ]; do
    sleep 1
    i=$((i+1))
  done
  kill -9 "$TCAP_PID" 2>/dev/null
  if [ "$PROVIDER" = "unicom" ]; then
    # 联通: 采集 EPG 会话 (JSESSIONID/tempKey/UserToken/Authenticator), 不做电信 cookie/路由学习
    collect_unicom_sess
  else
  # 提取: Cookie 请求头 (优先) + Set-Cookie 响应
  # 只取最长的一个 Cookie 头 (多段/多包会重复, 全取会叠加!)
  RESULT=$(grep -oE 'Cookie: [^\r\n]+' /tmp/epg_cookie_cap.txt 2>/dev/null | awk '{ print length($0), $0 }' | sort -rn | head -1 | cut -d' ' -f2-)
  if [ -z "$RESULT" ]; then
    RESULT=$(grep -oE 'Set-Cookie: [^;\r\n]+' /tmp/epg_cookie_cap.txt 2>/dev/null | head -3)
  fi
  # 🔴 凭证模式: 捕获 funcportalauth 请求的 (UserToken, stbinfo) 对 → 保存供凭证重放
  #    (RSA 签名确定性: 相同 token 的 stbinfo 不变 → 之后认证可绕过私钥直接重放)
  if grep -q 'funcportalauth' /tmp/epg_cookie_cap.txt 2>/dev/null; then
    UT_SAVED=$(grep -oE 'UserToken=[^&" ]+' /tmp/epg_cookie_cap.txt 2>/dev/null | head -1 | cut -d= -f2)
    SI_SAVED=$(grep -oE 'stbinfo=[^&" ]+' /tmp/epg_cookie_cap.txt 2>/dev/null | head -1 | cut -d= -f2)
    if [ -n "$UT_SAVED" ] && [ -n "$SI_SAVED" ]; then
      echo "UserToken=$UT_SAVED" > /etc/epg_credential.txt
      echo "stbinfo=$SI_SAVED" >> /etc/epg_credential.txt
      log "已保存认证凭证 /etc/epg_credential.txt (凭证重放备用)"
    fi
  fi

  # ---------- 机顶盒身份自动采集 (公共版零配置) ----------
  # 从机顶盒流量提取 GUID/SN/账号/MAC → /etc/epg_stb_info.txt
  # 只写文件不写 uci: 不磨损 flash, 不误触发 AUTH_MODE (uci 手动配置永远优先)
  INFO_FILE=/etc/epg_stb_info.txt
  NEW_GUID=$(grep -oE 'XClientGUID[=: ]*\{[0-9A-Fa-f-]+\}' /tmp/epg_cookie_cap.txt 2>/dev/null | head -1 | grep -oE '\{[0-9A-Fa-f-]+\}' | head -1)
  NEW_SN=$(grep -oE '[?&]SN=[0-9A-Za-z]+' /tmp/epg_cookie_cap.txt 2>/dev/null | head -1 | cut -d= -f2)
  NEW_UID=$(grep -oE '[?&]UserID=[^&" ]+' /tmp/epg_cookie_cap.txt 2>/dev/null | head -1 | cut -d= -f2)
  # 机顶盒源 IP: 取第一个非服务器 IP (请求方向) → 查 ARP 得 MAC; 30.170.x 视为专网绑定 IP
  # 注意: tcpdump -nn 端口用 . 分隔 (IP 1.2.3.4.54321), 必须精确 4 段匹配避免吞端口
  CAP_SRC=$(grep -oE 'IP [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /tmp/epg_cookie_cap.txt 2>/dev/null | awk '{print $2}' | grep -vE '^(218\.83\.165\.67|222\.68\.208\.73|124\.75\.29\.176)$' | head -1)
  NEW_MAC=""
  # ARP 行: "IP 0x1 0x2 MAC ..." (IP 在行首无前导空格) → 匹配 行首IP 或 空格IP
  [ -n "$CAP_SRC" ] && NEW_MAC=$(cat /proc/net/arp 2>/dev/null | grep -E "(^| )$CAP_SRC " | awk '{print $4}' | head -1)
  NEW_AUTHIP=""
  case "$CAP_SRC" in 30.170.*) NEW_AUTHIP="$CAP_SRC";; esac
  if [ -n "$NEW_GUID" ] || [ -n "$NEW_SN" ] || [ -n "$NEW_UID" ] || [ -n "$NEW_MAC" ] || [ -n "$NEW_AUTHIP" ]; then
    # 生成新内容, 与现有比较, 变化才写 (防 flash 磨损)
    INFO_TMP=/tmp/epg_stb_info.tmp
    : > "$INFO_TMP"
    [ -n "$NEW_GUID" ] && echo "STB_GUID='$NEW_GUID'" >> "$INFO_TMP"
    [ -n "$NEW_MAC" ] && echo "STB_MAC='$NEW_MAC'" >> "$INFO_TMP"
    [ -n "$NEW_SN" ] && echo "STB_SN='$NEW_SN'" >> "$INFO_TMP"
    [ -n "$NEW_UID" ] && echo "BROADBAND_UID='$NEW_UID'" >> "$INFO_TMP"
    [ -n "$NEW_AUTHIP" ] && echo "AUTH_IP='$NEW_AUTHIP'" >> "$INFO_TMP"
    if [ -f "$INFO_FILE" ] && cmp -s "$INFO_FILE" "$INFO_TMP"; then
      rm -f "$INFO_TMP"
    else
      mv "$INFO_TMP" "$INFO_FILE"
      log "机顶盒身份已采集: GUID=${NEW_GUID:-无} MAC=${NEW_MAC:-无} SN=${NEW_SN:-无} UID=${NEW_UID:-无} AUTH_IP=${NEW_AUTHIP:-无}"
    fi
    # 🔴 同步到 config (LuCI 设置页显示真实值, 不再空/误导)
    #    仅当 config 为空时写 (手动配置优先), 值变化才 commit (防 flash 磨损)
    local UCI_CHANGED=0
    [ -n "$NEW_GUID" ] && [ -z "$(uci get iptv_epg.main.stb_guid 2>/dev/null)" ] && { uci set iptv_epg.main.stb_guid="$NEW_GUID"; UCI_CHANGED=1; }
    [ -n "$NEW_MAC" ] && [ -z "$(uci get iptv_epg.main.stb_mac 2>/dev/null)" ] && { uci set iptv_epg.main.stb_mac="$NEW_MAC"; UCI_CHANGED=1; }
    [ -n "$NEW_SN" ] && [ -z "$(uci get iptv_epg.main.stb_sn 2>/dev/null)" ] && { uci set iptv_epg.main.stb_sn="$NEW_SN"; UCI_CHANGED=1; }
    [ -n "$NEW_UID" ] && [ -z "$(uci get iptv_epg.main.broadband_uid 2>/dev/null)" ] && { uci set iptv_epg.main.broadband_uid="$NEW_UID"; UCI_CHANGED=1; }
    if [ "$UCI_CHANGED" = "1" ]; then
      uci commit iptv_epg 2>/dev/null
      log "机顶盒身份已同步到 config (LuCI 设置页显示)"
    fi
  fi
  # ---------- 路由学习 (电信改服务器 IP 后自动适配) ----------
  # 从抓包提取目标 IP (请求方向=服务器), 排除机顶盒/本机/网关, 自动加专网路由
  # 学到的 IP 记入 /etc/epg_routes.txt, iptv_epg route 启动时重放
  GW_IP=$(uci get iptv_epg.main.iptv_gateway 2>/dev/null)
  [ -n "$GW_IP" ] || GW_IP=30.170.0.1
  RIF=$(uci get iptv_epg.main.iptv_iface 2>/dev/null)
  [ -n "$RIF" ] && [ -d "/sys/class/net/$RIF" ] || RIF=""
  if [ -z "$RIF" ]; then
    for i in /sys/class/net/*; do
      IN=${i#/sys/class/net/}
      [ "$IN" = "lo" ] && continue
      ip addr show "$IN" 2>/dev/null | grep -q 'inet 30\.170\.' && { RIF="$IN"; break; }
    done
  fi
  [ -z "$RIF" ] && RIF=br-iptv
  [ -d "/sys/class/net/$RIF" ] || RIF=br-lan
  MY_IPS=$(ip -o addr show 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | tr '\n' ' ')
  for D in $(grep -oE '> [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' /tmp/epg_cookie_cap.txt 2>/dev/null | awk '{print $2}' | sort -u); do
    [ -n "$D" ] || continue
    case " $MY_IPS $GW_IP $CAP_SRC " in *" $D "*) continue;; esac
    ip route show 2>/dev/null | grep -q "^$D " && continue
    ip route add $D/32 via $GW_IP dev $RIF 2>/dev/null && {
      grep -qx "$D" /etc/epg_routes.txt 2>/dev/null || echo "$D" >> /etc/epg_routes.txt
      log "自动学习路由: $D via $GW_IP dev $RIF (电信 IP 变化自动适配)"
    }
  done
  rm -f /tmp/epg_cookie_cap.txt

  if [ -n "$RESULT" ]; then
    update_cookie "$RESULT" || log "抓到 cookie 但无关键字段"
  fi
  fi


  # 每次循环间隔, 避免 tcpdump 连续重启
  sleep 2
done
