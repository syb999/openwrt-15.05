#!/bin/sh
# ============================================================
# epg_auth.sh - 上海电信 EPG 账号直登认证, 生成有效 cookie
# 用法: /usr/bin/epg_auth.sh
# 读取: iptv_epg.main.broadband_uid(宽带账号 adxxx) / stb_sn / stb_mac / auth_ip
# 输出: /tmp/stb_cookie.txt + config cookie_backup (getChannelList 200 验证通过才写)
# 参考: sh-tel-iptv-spider 认证流程 (4kLogAuth -> r4k -> ottAuth -> portal)
# ============================================================

# 🔴 单实例锁: 认证慢时 (每步 -m 10) 多次触发 (如多次 restart) 会堆积进程
AUTH_PID=/var/run/epg_auth.pid
if [ -f "$AUTH_PID" ] && kill -0 "$(cat "$AUTH_PID" 2>/dev/null)" 2>/dev/null; then
  exit 0
fi
echo $$ > "$AUTH_PID" 2>/dev/null
trap 'rm -f "$AUTH_PID"' EXIT

RSAPEM=/etc/iptv_epg_rsa.pem
LOG=/tmp/epg_auth.log
# 日志轮转: 保留最近 100 行 (防止 /tmp 61.5M 被日志撑爆)
if [ -f "$LOG" ]; then
  LC=$(wc -l < "$LOG" 2>/dev/null)
  [ "${LC:-0}" -gt 100 ] && tail -100 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
fi
echo "[$(date '+%F %T')] ==== epg_auth 开始 ====" >> "$LOG"

# ---------- 读取配置 (uci 手动配置优先, 空则用 daemon 自动采集) ----------
UID_RAW=`uci get iptv_epg.main.broadband_uid 2>/dev/null`
SN_RAW=`uci get iptv_epg.main.stb_sn 2>/dev/null`
MAC_RAW=`uci get iptv_epg.main.stb_mac 2>/dev/null`
IP_BIND=`uci get iptv_epg.main.auth_ip 2>/dev/null`
# 公共版零配置: daemon 抓到机顶盒身份后写 /etc/epg_stb_info.txt, 这里补缺 (uci 值永远优先)
if [ -f /etc/epg_stb_info.txt ]; then
  . /etc/epg_stb_info.txt 2>/dev/null
  [ -z "$UID_RAW" ] && UID_RAW=${BROADBAND_UID:-}
  [ -z "$SN_RAW" ] && SN_RAW=${STB_SN:-}
  [ -z "$MAC_RAW" ] && MAC_RAW=${STB_MAC:-}
  [ -z "$IP_BIND" ] && IP_BIND=${AUTH_IP:-}
fi
# 公共版不内置机顶盒绑定 IP (各用户环境不同); 为空时仅警告 (认证源 IP 不匹配可能失败)
[ -n "$IP_BIND" ] || echo "[$(date '+%F %T')] 警告: 未配置 auth_ip (机顶盒专网绑定IP), 认证可能失败" >> "$LOG"
[ -n "$UID_RAW" ] || { echo "[$(date '+%F %T')] ERR: 未配置宽带账号 (broadband_uid)" >> "$LOG"; echo "ERR: 未配置宽带账号"; exit 1; }
[ -n "$SN_RAW" ] || { echo "[$(date '+%F %T')] ERR: 未配置机顶盒 SN (stb_sn)" >> "$LOG"; echo "ERR: 未配置机顶盒 SN"; exit 1; }
# 🔴 公共版不带 RSA 私钥: 有凭证(抓包保存)时完全不需要私钥; 无凭证时才需要私钥
#    缺失时自动从 GitHub 提取 (epg_getkey.sh, 纯 curl 免 git)
if [ ! -f "$RSAPEM" ] && [ ! -f /etc/epg_credential.txt ]; then
  echo "未发现 RSA 私钥, 尝试自动获取..."
  /usr/bin/epg_getkey.sh >/dev/null 2>&1
  [ -f "$RSAPEM" ] || { echo "[$(date '+%F %T')] ERR: 私钥获取失败 (需能访问 api.github.com, 或手动放置 $RSAPEM)" >> "$LOG"; echo "ERR: 私钥获取失败 (需能访问 api.github.com, 或手动放置 $RSAPEM)"; exit 1; }
fi

# 宽带账号: adXXXXXXXX -> XXXXXXXX -> XXXXXXXX@etv1 (自动过滤 ad 前缀, 兼容直接填完整账号)
UID=`echo "$UID_RAW" | sed 's/^[aA][dD]//; s/@.*//'`
UID="${UID}@etv1"

# SN 补零到 32 位
SN=`printf '%032s' "$SN_RAW" | tr ' ' '0'`

# MAC 大写
MAC=`echo "$MAC_RAW" | tr 'a-f' 'A-F'`
echo "[$(date '+%F %T')] UID=$UID SN=$SN MAC=$MAC IP_BIND=$IP_BIND" >> "$LOG"

# ---------- 网络准备 ----------
# ① 专网路由统一交给 iptv_epg route (复用系统验证过的逻辑: 智能选接口 + 带src降级 + 持久化)
#    iptv_epg route 会添加 route_target + route_extra (uci 可配置)
/usr/bin/iptv_epg route >/dev/null 2>&1 || true
# ② 认证源 IP (机顶盒绑定 IP 作为 secondary) — 需要知道专网接口
#    接口选择优先级: network.iptv.ifname -> 有 30.170.x IP 的接口 -> iptv/br-iptv/br-lan
IPIF=$(uci get network.iptv.ifname 2>/dev/null)
if [ -z "$IPIF" ] || [ ! -d "/sys/class/net/$IPIF" ]; then
  IPIF=""
  for I in $(ip -o addr show 2>/dev/null | awk '$4 ~ /^30\.170\./ {print $2}'); do
    IPIF="$I"
    break
  done
fi
[ -z "$IPIF" ] && IPIF=iptv
[ -d "/sys/class/net/$IPIF" ] || IPIF=br-iptv
[ -d "/sys/class/net/$IPIF" ] || IPIF=br-lan
[ -d "/sys/class/net/$IPIF" ] || { echo "ERR: 找不到专网接口"; exit 1; }
# 加认证源 IP (幂等, 失败仅警告不中断 — 部分环境无需源IP匹配)
if [ -n "$IP_BIND" ] && ! ip addr show "$IPIF" 2>/dev/null | grep -q " $IP_BIND/"; then
  ip addr add $IP_BIND/16 dev "$IPIF" 2>/dev/null \
    && echo "[$(date '+%F %T')] 已添加认证源IP $IP_BIND -> $IPIF" >> "$LOG" \
    || echo "[$(date '+%F %T')] 警告: 添加源IP $IP_BIND 失败 (忽略)" >> "$LOG"
fi
# ③ 验证认证服务器可达 (走专网), 失败仅警告
A1_IP=`uci get iptv_epg.main.auth_host 2>/dev/null | cut -d: -f1`
[ -n "$A1_IP" ] || A1_IP=222.68.208.73
if ! ip route get $A1_IP 2>/dev/null | grep -q "dev $IPIF"; then
  echo "[$(date '+%F %T')] 警告: $A1_IP 未走 $IPIF (ip route get 结果: $(ip route get $A1_IP 2>&1 | head -1))" >> "$LOG"
fi
echo "[$(date '+%F %T')] 网络准备完成 (接口=$IPIF)" >> "$LOG"

UA='webkit;Resolution(PAL,720P,1080P,2106P,4K)'
CKJ=/tmp/auth_cookies.txt
rm -f $CKJ

# ---------- 1. 4kLogAuth ----------
# 🔴 账号直登仅上海电信 (4kLogAuth/私钥/RSA 协议); 联通模式请用机顶盒抓包模式
if [ "$(uci get iptv_epg.main.provider 2>/dev/null)" = "unicom" ]; then
  echo "[$(date '+%F %T')] ERR: 账号直登仅支持上海电信; 上海联通请用机顶盒抓包模式 (配置 stb_side, 勿填账号/SN)" >> "$LOG"
  echo "ERR: 账号直登仅上海电信; 联通用抓包模式"
  exit 1
fi
# 认证服务器: uci auth_host / auth_host2 (可配置, 电信公共基础设施) → 电信默认
SRV1=`uci get iptv_epg.main.auth_host 2>/dev/null`
[ -n "$SRV1" ] || SRV1=222.68.208.73:7001
SRV2=`uci get iptv_epg.main.auth_host2 2>/dev/null`
[ -n "$SRV2" ] || SRV2=124.75.29.176:7001
IP2=${SRV2%:*}
curl -s -m 10 -c $CKJ -b $CKJ -o /tmp/a1.html \
  "http://$SRV1/iptv3a/4kLogAuth.do?Action=Login&UserID=${UID}&SN=${SN}&Type=iptv4k&Mode=MENU.SMG-4K&FCCSupport=1" \
  -H "User-Agent: $UA"
A1_URL=`grep -oE 'action="http://[^"]+' /tmp/a1.html | sed 's/action="//'`
[ -z "$A1_URL" ] && { echo "[$(date '+%F %T')] ERR: 4kLogAuth 失败" >> "$LOG"; echo "ERR: 4kLogAuth 失败"; exit 1; }

# ---------- 2. r4kLogAuth ----------
curl -s -m 10 -c $CKJ -b $CKJ -o /tmp/a2.html "$A1_URL" -H "User-Agent: $UA" \
  --data-urlencode "UserID=$UID" --data-urlencode 'Action=Login' \
  --data-urlencode "DynamicAuthIP=$IP2" --data-urlencode "Mode=MENU.SMG-4K" \
  --data-urlencode "SN=$SN" --data-urlencode 'FCCSupport=1'
ENC=`grep -oE 'encrytoken="[^"]+"' /tmp/a2.html | sed 's/encrytoken="//;s/"//'`
[ -z "$ENC" ] && { echo "[$(date '+%F %T')] ERR: r4kLogAuth 失败" >> "$LOG"; echo "ERR: r4kLogAuth 失败"; exit 1; }

# ---------- 3. ottAuth (AES authenticator) ----------
RANDON=`awk 'BEGIN{srand(); for(i=0;i<8;i++) printf "%d", int(rand()*10)}'`
IP1=`echo $IP_BIND | cut -d. -f1`; IP2=`echo $IP_BIND | cut -d. -f2`; IP3=`echo $IP_BIND | cut -d. -f3`; IP4=`echo $IP_BIND | cut -d. -f4`
IPP="`printf '%03d' $IP1`,`printf '%03d' $IP2`,`printf '%03d' $IP3`,`printf '%03d' $IP4`"
UPDT='20230301175307'
JSON="{\"Randon\":\"$RANDON\",\"EncryToken\":\"$ENC\",\"UserID\":\"$UID\",\"SN\":\"$SN\",\"IP\":\"$IPP\",\"MAC\":\"$MAC\",\"MagicCode\":\"CTC\",\"UpdateTime\":\"$UPDT\"}"
SIGHEX=`printf '%s' "$JSON" | openssl enc -aes-128-ecb -K e10adc3949ba59abbe56e057f20f883e | xxd -p | tr -d '\n'`
A1_BASE=`echo "$A1_URL" | sed 's|\(http://[^/]*\).*|\1|'`
curl -s -m 10 -c $CKJ -b $CKJ -o /tmp/a3.html "$A1_BASE/iptv3a/ottauth" -H "User-Agent: $UA" \
  --data-urlencode "authenticator=$SIGHEX" --data-urlencode "userid=$UID" \
  --data-urlencode "stbid=$SN" --data-urlencode 'mode=MENU.SMG' \
  --data-urlencode 'modeurl=' --data-urlencode 'miniplatform=' --data-urlencode 'fccsupport=1'
grep -q 'epgform' /tmp/a3.html || { echo "[$(date '+%F %T')] ERR: ottAuth 失败 (2999)" >> "$LOG"; echo "ERR: ottAuth 失败 (2999)"; exit 1; }

# ---------- 4. epgIndex: POST epgform (提取表单参数) ----------
EPG_ACT=`grep -oE '<form id="epgform" action="[^"]+"' /tmp/a3.html | sed 's/.*action="//;s/"//'`
[ -z "$EPG_ACT" ] && { echo "[$(date '+%F %T')] ERR: epgform 未找到" >> "$LOG"; echo "ERR: epgform 未找到"; exit 1; }
UT=`grep -oE 'name="UserToken" value="[^"]*"' /tmp/a3.html | sed 's/.*value="//;s/"//'`
UGN=`grep -oE 'name="UserGroupNMB" value="[^"]*"' /tmp/a3.html | sed 's/.*value="//;s/"//'`
EGN=`grep -oE 'name="EPGGroupNMB" value="[^"]*"' /tmp/a3.html | sed 's/.*value="//;s/"//'`
DAIP=`grep -oE 'name="DynamicAuthIP" value="[^"]*"' /tmp/a3.html | sed 's/.*value="//;s/"//'`
[ -z "$UT" ] && { echo "[$(date '+%F %T')] ERR: UserToken 未找到" >> "$LOG"; echo "ERR: UserToken 未找到"; exit 1; }
curl -s -m 10 -c /tmp/e1_cookies.txt -b /tmp/e1_cookies.txt -o /tmp/e1.html "$EPG_ACT" -H "User-Agent: $UA" \
  --data-urlencode "UserID=$UID" --data-urlencode 'Action=Login' \
  --data-urlencode "UserToken=$UT" --data-urlencode "UserGroupNMB=$UGN" \
  --data-urlencode "EPGGroupNMB=$EGN" --data-urlencode 'stbid=0' \
  --data-urlencode 'Mode=MENU.SMG' --data-urlencode 'EPGProviderDomain=' \
  --data-urlencode "DynamicAuthIP=$DAIP"

# ---------- 5. epgLoadBalance: 跟随 top.document.location ----------
LB_URL=`grep -oE "top.document.location = '[^']*'" /tmp/e1.html | sed "s/top.document.location = '//;s/'//"`
[ -z "$LB_URL" ] && { echo "[$(date '+%F %T')] ERR: 负载均衡跳转未找到" >> "$LOG"; echo "ERR: 负载均衡跳转未找到"; exit 1; }
curl -s -m 10 -c /tmp/e2_cookies.txt -b /tmp/e2_cookies.txt -o /tmp/e2.html "$LB_URL" -H "User-Agent: $UA"

# ---------- 6. epgPortalAuth: 凭证重放(免私钥) 或 RSA 签名 ----------
UT2=`grep -oE 'name="UserToken" value="[^"]*"' /tmp/e2.html | sed 's/.*value="//;s/"//'`
EASIP=`grep -oE 'name="easip" value=?[^ >]*' /tmp/e2.html | sed 's/.*value=?//;s/[">]//g'`
NWID=`grep -oE 'name="networkid" value=?[^ >]*' /tmp/e2.html | sed 's/.*value=?//;s/[">]//g'`
[ -z "$UT2" ] && { echo "[$(date '+%F %T')] ERR: portal UserToken 未找到" >> "$LOG"; echo "ERR: portal UserToken 未找到"; exit 1; }
# 🔴 凭证重放: daemon 抓包保存的 (UserToken, stbinfo) 对 - RSA 签名确定性, 相同 token 的 stbinfo 不变
#    -> 有凭证时完全绕过私钥! (公共版有机顶盒用户: 抓一次包即获永久凭证)
CRED_FILE=/etc/epg_credential.txt
STBINFO=""
UT_FINAL="$UT2"
if [ -f "$CRED_FILE" ]; then
  UT_SAVED=`grep '^UserToken=' "$CRED_FILE" 2>/dev/null | cut -d= -f2`
  SI_SAVED=`grep '^stbinfo=' "$CRED_FILE" 2>/dev/null | cut -d= -f2`
  if [ -n "$UT_SAVED" ] && [ -n "$SI_SAVED" ]; then
    STBINFO="$SI_SAVED"
    UT_FINAL="$UT_SAVED"
    echo "[$(date '+%F %T')] 使用凭证重放 (非私钥签名)" >> "$LOG"
  fi
fi
if [ -z "$STBINFO" ]; then
  # 私钥签名路径 (无凭证时)
  # InsertStrInUserToken: token[:7] + "37AE" + token[7:]
  PLAIN=`printf '%s' "$UT_FINAL" | cut -c1-7`37AE`printf '%s' "$UT_FINAL" | cut -c8-`
  printf '%s' "$PLAIN" > /tmp/auth_plain.txt
  openssl rsautl -sign -inkey $RSAPEM -in /tmp/auth_plain.txt -out /tmp/auth_sig.bin 2>/dev/null || { echo "[$(date '+%F %T')] ERR: RSA 签名失败" >> "$LOG"; echo "ERR: RSA 签名失败"; exit 1; }
  STBINFO=`xxd -p /tmp/auth_sig.bin | tr -d ' 
' | tr 'a-f' 'A-F'`
fi
# 🔴 portal 认证必须发到负载均衡后的主机 (e2 跳转的 host), 不是 epgform 的 host!
#    (epgIndex 是 218.83.165.50, 负载均衡后会话在 218.83.165.67, 用错主机 -> funcportalauth.jsp 无响应)
A3_BASE=`echo "$LB_URL" | sed 's|\(http://[^/]*\).*|\1|'`
curl -s -m 10 -c /tmp/e3_cookies.txt -b /tmp/e2_cookies.txt -o /tmp/e3.html "$A3_BASE/iptvepg/function/funcportalauth.jsp" -H "User-Agent: $UA" \
  --data-urlencode "UserToken=$UT_FINAL" --data-urlencode "UserID=$UID" \
  --data-urlencode 'STBID=0' --data-urlencode "stbinfo=$STBINFO" \
  --data-urlencode 'prmid=' --data-urlencode "easip=$EASIP" \
  --data-urlencode "networkid=$NWID" --data-urlencode 'stbtype=B860A' \
  --data-urlencode 'drmsupplier='

SESSION=`grep -oE "jsSetConfig\('SessionID','[^']*'" /tmp/e3.html | sed "s/.*,'//;s/'//"`
[ -z "$SESSION" ] && { echo "[$(date '+%F %T')] ERR: portal 认证失败" >> "$LOG"; echo "ERR: portal 认证失败"; exit 1; }

# ---------- 7. portal.jsp 激活会话 (必须! 否则 getChannelProg 返回 051002) ----------
curl -s -m 10 -o /dev/null -w '%{http_code}' "$A3_BASE/iptvepg/frame1413/portal.jsp" -H "Cookie: JSESSIONID=$SESSION" -H "User-Agent: $UA" > /tmp/portal_code.txt 2>/dev/null

# ---------- 8. 验证 getChannelList + 写 cookie ----------
EPG_SRV=$(uci get iptv_epg.main.epg_host 2>/dev/null)
[ -n "$EPG_SRV" ] || EPG_SRV=218.83.165.67:8084
VCODE=`curl -s -m 10 -o /dev/null -w '%{http_code}' "http://$EPG_SRV/iptvepg/frame1413/function/ajax/epg7getChannelByAjax.jsp" -H "Cookie: JSESSIONID=$SESSION" -H 'User-Agent: webkit' -d 'action=getChannelList&cateID=000406&type=' 2>/dev/null`
if [ "$VCODE" = "200" ]; then
  echo "JSESSIONID=$SESSION" > /tmp/stb_cookie.txt
  uci set iptv_epg.main.cookie_backup="JSESSIONID=$SESSION"
  uci commit iptv_epg
  echo "[$(date '+%F %T')] OK: cookie 已生成并验证 (HTTP 200)" >> "$LOG"
  echo "OK: cookie=$SESSION"
  exit 0
else
  echo "[$(date '+%F %T')] ERR: 验证失败 HTTP=$VCODE" >> "$LOG"
  echo "ERR: 验证失败 HTTP=$VCODE"
  exit 1
fi
