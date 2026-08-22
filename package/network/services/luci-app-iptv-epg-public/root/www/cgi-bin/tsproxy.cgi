#!/bin/sh
# ============================================================
# tsproxy.cgi — 回看 TS 分片代理 (平板 → A → 电信回看服务器)
# 用途: 平板(公网)访问不了专网回看服务器(124.75.26.15:6610),
#       play.cgi 把 m3u8 里的 TS/子流 URL 改写为 /cgi-bin/tsproxy.cgi?u=<base64url>
# 用法: /cgi-bin/tsproxy.cgi?u=<base64(原URL)>
# ============================================================

# 机顶盒 UA + 头 (回看服务器校验)
STB_UA='ADI Video On Damand Client/1.0'
STB_HEAD='Accept: */*'
# 机顶盒 GUID: 公共版不内置 (各机顶盒不同), 用户自行填写 iptv_epg.main.stb_guid;
# 未填则用 daemon 自动采集的 (/etc/epg_stb_info.txt); 都没有则不带 XClientGUID 头 (仅回看可能被拒)
STB_GUID=$(uci get iptv_epg.main.stb_guid 2>/dev/null)
if [ -z "$STB_GUID" ] && [ -f /etc/epg_stb_info.txt ]; then
  . /etc/epg_stb_info.txt 2>/dev/null
  STB_GUID=${STB_GUID:-}
fi
GUID_HEAD=""
[ -n "$STB_GUID" ] && GUID_HEAD="-H Pragma: XClientGUID=$STB_GUID"
# 本机地址 (动态获取, 设备 IP 变化后 m3u8 改写 URL 不失效)
HOST=$(/usr/bin/iptv_epg ip 2>/dev/null)
[ -z "$HOST" ] && HOST=$(uci get network.wan.ipaddr 2>/dev/null)
[ -z "$HOST" ] && HOST=$(uci get network.lan.ipaddr 2>/dev/null)

echo "Content-Type: application/octet-stream"
echo "Cache-Control: no-cache"
echo ""

# ---------- 解析目标 ----------
# 两种模式:
#   1. 路径直传 (play.cgi 主 m3u8 改写): /cgi-bin/tsproxy.cgi/SHDXFH_live/... → http://124.75.26.15:6610/SHDXFH_live/...
#   2. hex 参数 (旧兼容): ?u=<hex> → 解码
# 回看服务器 (uci tvod_host, 可配置防电信改 IP) → 电信默认
TVOD_HOST=$(uci get iptv_epg.main.tvod_host 2>/dev/null)
[ -n "$TVOD_HOST" ] || TVOD_HOST=124.75.26.15:6610
LB_HOST="http://$TVOD_HOST"
TARGET=""
case "$PATH_INFO" in
  /*)
    # 路径直传: PATH_INFO 是 /SHDXFH_live/... 拼 6610, 必须带 QUERY_STRING (AuthInfo 等参数!)
    TARGET="${LB_HOST}${PATH_INFO}"
    [ -n "$QUERY_STRING" ] && TARGET="${TARGET}?${QUERY_STRING}"
    ;;
esac
if [ -z "$TARGET" ]; then
  QS="$QUERY_STRING"
  U_RAW=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^u=/){sub(/^u=/,"",$i);print $i;exit}}}')
  [ -z "$U_RAW" ] && exit 0
  # hex 字符串 → 原始字节 (sed 加 \x 前缀 + printf %b, 快)
  url_hexdec() {
    local s="$1"
    local HEXSTR=$(echo "$s" | sed 's/\(..\)/\\x\1/g')
    printf '%b' "$HEXSTR"
  }
  TARGET=$(url_hexdec "$U_RAW")
fi

# 安全: 只允许回看服务器域名
case "$TARGET" in
  http://124.75.*:6610/*|http://124.75.*:6410/*|http://124.75.*:6060/*|http://124.75.*:8006/*|http://124.75.*:8112/*) ;;
  *) echo "bad target"; exit 0 ;;
esac

# ---------- 转发请求 (机顶盒 UA + Range 支持) ----------
# TS 分片 (.ts): 直接流式转发 (不经文件缓冲, 3倍提速!)
# m3u8 (.m3u8): 需要跟随 302 (6610 规范化)
RANGE=""
# 播放器的 Range 是 HTTP 头, uhttpd 传给 CGI 为 HTTP_RANGE 环境变量
if [ -n "$HTTP_RANGE" ]; then
  RANGE="$HTTP_RANGE"
else
  R_RAW=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^r=/){sub(/^r=/,"",$i);print $i;exit}}}')
  [ -n "$R_RAW" ] && RANGE=$(url_hexdec "$R_RAW")
fi

case "$TARGET" in
  *.ts*|*.ts)
    # TS 分片: 流式转发, 一次 curl 直接输出 (性能关键!)
    if [ -n "$RANGE" ]; then
      exec curl -s --max-time 30 -H "User-Agent: $STB_UA" -H "$STB_HEAD" -H "Range: $RANGE" \
        $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" "$TARGET"
    else
      exec curl -s --max-time 30 -H "User-Agent: $STB_UA" -H "$STB_HEAD" -H "Range: bytes=0-" \
        $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" "$TARGET"
    fi
    ;;
esac

# 跟随 302 链 (最多 3 跳) — 仅 m3u8
URL="$TARGET"
HOP=0
while [ $HOP -lt 3 ]; do
  HOP=$((HOP+1))
  if [ -n "$RANGE" ]; then
    RESP=$(curl -s --max-time 20 -D - -o /tmp/tsproxy_body.txt \
      -H "User-Agent: $STB_UA" -H "$STB_HEAD" -H "Range: $RANGE" \
      $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" "$URL" 2>/dev/null)
  else
    RESP=$(curl -s --max-time 20 -D - -o /tmp/tsproxy_body.txt \
      -H "User-Agent: $STB_UA" -H "$STB_HEAD" -H "Range: bytes=0-" \
      $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" "$URL" 2>/dev/null)
  fi
  CODE=$(echo "$RESP" | grep -oE 'HTTP/[0-9.]+ [0-9]+' | head -1 | grep -oE '[0-9]+$')
  LOC=$(echo "$RESP" | grep -i '^Location' | sed 's/Location: //' | tr -d '\r')
  if [ "$CODE" = "302" ] && [ -n "$LOC" ]; then
    # 相对 Location 转绝对
    case "$LOC" in
      http://*) URL="$LOC" ;;
      /*) URL="${LB_HOST}${LOC}" ;;
      *) URL="${LB_HOST}/${LOC}" ;;
    esac
    continue
  fi
  # 非 302: 输出内容 (若是 m3u8, 改写里面的 URL → tsproxy, 让平板能访问)
  if grep -q 'EXTM3U' /tmp/tsproxy_body.txt 2>/dev/null; then
    # 改写: http:// URL → tsproxy?u=<hex>
    while IFS= read -r LINE; do
      case "$LINE" in
        http://*)
          ORIG=$(echo "$LINE" | tr -d '\r')
          # busybox xxd -p 输出尾随空格! 必须 tr -d ' \n'
          ENC=$(printf '%s' "$ORIG" | xxd -p | tr -d ' \n' | tr 'a-f' 'A-F')
          echo "http://$HOST/cgi-bin/tsproxy.cgi?u=$ENC"
          ;;
        *)
          echo "$LINE"
          ;;
      esac
    done < /tmp/tsproxy_body.txt
    rm -f /tmp/tsproxy_body.txt
    exit 0
  fi
  cat /tmp/tsproxy_body.txt 2>/dev/null
  rm -f /tmp/tsproxy_body.txt
  exit 0
done
# 3 跳后还有 302: 输出最后内容
cat /tmp/tsproxy_body.txt 2>/dev/null
rm -f /tmp/tsproxy_body.txt
exit 0
