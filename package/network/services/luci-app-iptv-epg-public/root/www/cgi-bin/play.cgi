#!/bin/sh
# ============================================================
# play.cgi — IPTV 直播/回看入口
# ============================================================
# 调试日志 (每次调用记录, 排查平板问题) — 限制 200KB, 防撑爆 /tmp
if [ -f /tmp/play_debug.log ]; then
  LC=$(wc -l < /tmp/play_debug.log 2>/dev/null)
  [ "${LC:-0}" -gt 100 ] && tail -100 /tmp/play_debug.log > /tmp/play_debug.log.tmp 2>/dev/null && mv /tmp/play_debug.log.tmp /tmp/play_debug.log
fi
echo "[$(date '+%F %T')] QS=$QUERY_STRING" >> /tmp/play_debug.log 2>/dev/null
# 清理上次可能残留的临时文件 (防 /tmp 撑爆, 61.5M tmpfs 很紧张)
rm -f /tmp/play_m1.txt /tmp/play_m2.txt /tmp/play_s1.txt /tmp/play_s2.txt /tmp/playbill_found.txt /tmp/tsproxy_body.txt 2>/dev/null
# 回看:  ?ch=<频道英文名>&playseek=<YYYYMMDDHHMMSS>-<YYYYMMDDHHMMSS>
#       → 按时间查节目ID → getTvodPlayUrl → 302 → 电信回看m3u8
# 频道源: 频道名,http://A/cgi-bin/play.cgi?ch=<英文名>&playseek=$start-$end
# ============================================================

CJ=/tmp/stb_cookie.txt
PROVIDER=$(uci get iptv_epg.main.provider 2>/dev/null)
[ -n "$PROVIDER" ] || PROVIDER=telecom
# EPG 服务器 (uci epg_host, 可配置防改 IP) → 按运营商默认
EPG_HOST=$(uci get iptv_epg.main.epg_host 2>/dev/null)
if [ -z "$EPG_HOST" ]; then
  if [ "$PROVIDER" = "unicom" ]; then
    EPG_HOST=10.223.2.76:33200
  else
    EPG_HOST=218.83.165.67:8084
  fi
fi
if [ "$PROVIDER" = "unicom" ]; then
  # 联通: EPG 门户路径 + 流服务器 (直播/回看 HLS 直通)
  AJAX_URL="http://$EPG_HOST/EPG/jsp/jkjiaoyutest/en/function/ajax/epg7getChannelByAjax.jsp"
  REF="http://$EPG_HOST/EPG/jsp/jkjiaoyutest/en/IPM/modules/channel/play_pro.html"
  UNICOM_SESS=/etc/epg_unicom_sess.txt
else
  AJAX_URL="http://$EPG_HOST/iptvepg/frame1413/function/ajax/epg7getChannelByAjax.jsp"
  REF="http://$EPG_HOST/iptvepg/frame1413/IPM/modules/channel/play_pro.html"
fi
UA='webkit;Resolution(PAL,720P,1080P)'

# ---------- 参数 ----------
QS="$QUERY_STRING"
CH=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^ch=/){sub(/^ch=/,"",$i);print $i;exit}}}')
PLAYSEEK=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^playseek=/){sub(/^playseek=/,"",$i);print $i;exit}}}')
# url 参数: DIYP 点击 EPG 节目时可能带 url=<直播源>&playseek=<时间> (自动切换直播/回看)
# url 参数: 联通 HLS URL 内含 & (fmt/rrsip/zoneoffset...), 不能按 & 简单切!
# 从 url= 取到 &ch= 或 &playseek= 之前 (列表拼接的后续参数), HLS 自身参数名不含 ch/playseek
URL_ARG=$(echo "$QS" | sed -n 's/^.*url=//p' | sed 's/&\(ch\|playseek\)=.*//' | head -1)
# 兼容 TVBox bug: 用 ? 而非 & 拼接 playseek → ch 值变成 "频道名?playseek=..."
# (TVBox LivePlayActivity: getUrl() + "?playseek=", 但 url 已含 ?url= 参数)
if [ -n "$CH" ]; then
  case "$CH" in
    *'?playseek='*)
      # 拆出 playseek (仅当 PLAYSEEK 尚未独立解析到时)
      [ -z "$PLAYSEEK" ] && PLAYSEEK=$(echo "$CH" | sed 's/.*?playseek=//')
      CH=$(echo "$CH" | sed 's/?playseek=.*//')
      ;;
  esac
fi
# 若 CH 为空但 url 是 play.cgi?ch=xxx 形式, 从 url 提取 ch (兼容)
if [ -z "$CH" ] && [ -n "$URL_ARG" ]; then
  CH=$(echo "$URL_ARG" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^ch=/){sub(/^ch=/,"",$i);print $i;exit}}}')
fi

# ---------- URL 解码 (UTF-8) ----------
url_decode() {
  local s="$1" out="" byte hex
  s=$(echo "$s" | sed 's/+/ /g')
  while [ -n "$s" ]; do
    case "$s" in
      %??*)
        hex=$(echo "$s" | cut -c2-3)
        byte=$(printf '%03o' "0x$hex")
        out="$out$(printf "\\$byte")"
        s=$(echo "$s" | cut -c4-)
        ;;
      *)
        out="$out$(echo "$s" | cut -c1)"
        s=$(echo "$s" | cut -c2-)
        ;;
    esac
  done
  echo "$out"
}
CH=$(url_decode "$CH")

# ---------- 频道表 (中文名|英文别名 → 组播地址|电信ID) ----------
# 统一从 /usr/share/iptv_epg/channel_map.txt 查询 (288 频道, 频道名|EPG_ID|组播地址)
get_channel() {
  # 从合并映射表查 (频道名|EPG_ID|组播地址), 支持 ch=中文名 或 ch=别名
  local LINE=$(grep "^$1|" /usr/share/iptv_epg/channel_map.txt 2>/dev/null | head -1)
  if [ -n "$LINE" ]; then
    local M_UDP=$(echo "$LINE" | cut -d'|' -f3)
    local M_ID=$(echo "$LINE" | cut -d'|' -f2)
    [ -n "$M_UDP" ] && [ -n "$M_ID" ] && echo "$M_UDP|$M_ID"
  fi
}

[ -z "$CH" ] && [ -z "$URL_ARG" ] && { echo "Status: 400"; echo "Content-Type: text/plain"; echo ""; echo "no ch"; exit 0; }

# url 参数直播源: 无 playseek 时直接 302 到 url (DIYP 的 url+playseek 模式)
if [ -z "$PLAYSEEK" ] || [ "$PLAYSEEK" = "-" ] || [ "$PLAYSEEK" = "{utc:YmdHMS}-{utcend:YmdHMS}" ] || [ "$PLAYSEEK" = " " ] || [ "$PLAYSEEK" = "%20" ]; then
  if [ -n "$URL_ARG" ]; then
    # url 是直播源地址, 直接 302 (有 ch 也优先 url, 保证直播)
    echo "Status: 302 Found"
    echo "Location: $URL_ARG"
    echo "Content-Type: text/plain"
    echo ""
    echo "redirect to url: $URL_ARG"
    exit 0
  fi
fi

CHINFO=$(get_channel "$CH")
[ -z "$CHINFO" ] && [ -z "$URL_ARG" ] && { echo "Status: 404"; echo "Content-Type: text/plain"; echo ""; echo "unknown channel: $CH"; exit 0; }
UDP=${CHINFO%%|*}
CHID=${CHINFO##*|}

# ---------- 无 playseek = 直播: 302 到本机 7088 ----------
if [ -z "$PLAYSEEK" ] || [ "$PLAYSEEK" = "-" ] || [ "$PLAYSEEK" = "{utc:YmdHMS}-{utcend:YmdHMS}" ] || [ "$PLAYSEEK" = " " ] || [ "$PLAYSEEK" = "%20" ]; then
  if [ "$PROVIDER" = "unicom" ]; then
    # 联通: 直播 = HLS 单播, 频道表第三列存完整 m3u8 URL → 直接 302 直通
    [ -n "$UDP" ] || { echo "Status: 404"; echo "Content-Type: text/plain"; echo ""; echo "no live url for: $CH"; exit 0; }
    echo "Status: 302 Found"
    echo "Location: $UDP"
    echo "Content-Type: text/plain"
    echo ""
    echo "redirect to unicom live: $UDP"
    exit 0
  fi
  # 本机 IP: 统一走 /usr/bin/iptv_epg ip (按 stb_side 智能选择, 兼容多设备部署)
  LOCAL_IP=$(/usr/bin/iptv_epg ip 2>/dev/null)
  [ -z "$LOCAL_IP" ] && LOCAL_IP="127.0.0.1"
  echo "Status: 302 Found"
  echo "Location: http://$LOCAL_IP:7088/udp/$UDP"
  echo "Content-Type: text/plain"
  echo ""
  echo "redirect to live: $UDP"
  exit 0
fi

# ---------- 有 playseek = 回看 ----------
# playseek 格式:
#   YYYYMMDDHHMMSS-YYYYMMDDHHMMSS  固定时段
#   last-1h / last-30m              最近 N 小时/分钟 (自动计算, 回看频道永不过期!)
if [ "$PROVIDER" = "unicom" ]; then
  # 联通回看: TVOD HLS (需节目ID+accountinfo, 待频道数据实测后适配)
  # 临时: 若频道表第三列已是 TVOD 模板(含 {playseek} 占位)则替换直通
  if [ -n "$UDP" ] && echo "$UDP" | grep -q '{playseek}'; then
    PS=$(echo "$PLAYSEEK" | tr -d '{}' )
    PS_ENC=$(echo "$PS" | sed 's/:/%3A/g')
    TARGET=$(echo "$UDP" | sed "s/{playseek}/$PS_ENC/g")
    echo "Status: 302 Found"
    echo "Location: $TARGET"
    echo "Content-Type: text/plain"
    echo ""
    echo "redirect to unicom tvod: $TARGET"
    exit 0
  fi
  echo "Status: 501"
  echo "Content-Type: text/plain"
  echo ""
  echo "unicom tvod: 回看待频道数据实测后适配"
  exit 0
fi
[ -f "$CJ" ] || { echo "Status: 500"; echo "Content-Type: text/plain"; echo ""; echo "no cookie"; exit 0; }
COOKIE=$(cat "$CJ")

# 相对时段解析: last-Nh / last-Nm → 当前时间往前推
case "$PLAYSEEK" in
  last-*)
    N=$(echo "$PLAYSEEK" | sed 's/last-//;s/[hm]//')
    UNIT=$(echo "$PLAYSEEK" | grep -o '[hm]$')
    NOW_EPOCH=$(date +%s)
    if [ "$UNIT" = "h" ]; then
      START_EPOCH=$((NOW_EPOCH - N * 3600))
    else
      START_EPOCH=$((NOW_EPOCH - N * 60))
    fi
    END_EPOCH=$NOW_EPOCH
    # 标记已解析, 跳过下方 to_epoch
    REL_DONE=1
    ;;
esac

if [ -z "$REL_DONE" ]; then
START14=$(echo "$PLAYSEEK" | cut -d'-' -f1)
END14=$(echo "$PLAYSEEK" | cut -d'-' -f2)

# YYYYMMDDHHMMSS → epoch
to_epoch() {
  # busybox date 支持 -d "YYYY-MM-DD HH:MM:SS"
  local s="$1" Y M D H M2 S2
  Y=$(echo "$s" | cut -c1-4); M=$(echo "$s" | cut -c5-6); D=$(echo "$s" | cut -c7-8)
  H=$(echo "$s" | cut -c9-10); M2=$(echo "$s" | cut -c11-12); S2=$(echo "$s" | cut -c13-14)
  date -d "$Y-$M-$D $H:$M2:$S2" +%s 2>/dev/null
}
START_EPOCH=$(to_epoch "$START14")
END_EPOCH=$(to_epoch "$END14")
fi

# 时区修正: 电信接口按北京时间 epoch 解释
# A 设备是 CST(+8)时 date -d 已返回正确 epoch; 若是 UTC 设备需 +8h
# 用 date %z 动态修正 (POSIX 兼容): 电信要"北京墙上时钟", 本地date算的是本地墙上时钟
TZOFF=$(date +%z)
TZH=$(echo "$TZOFF" | cut -c2-3 | awk '{print $1+0}')   # 时区小时 (UTC=0, CST=8)
[ -n "$START_EPOCH" ] && START_EPOCH=$((START_EPOCH - (TZH - 8) * 3600))
[ -n "$END_EPOCH" ] && END_EPOCH=$((END_EPOCH - (TZH - 8) * 3600))

[ -z "$START_EPOCH" ] && { echo "Status: 400"; echo "Content-Type: text/plain"; echo ""; echo "bad playseek"; exit 0; }

# 1. 按时间查节目 → 拿 playbillID (该时间段内的节目)
RESP=$(curl -s --max-time 8 "$AJAX_URL" -H "Cookie: $COOKIE" -H "User-Agent: $UA" -H "Referer: $REF" \
  -d "action=getPreCurNextProg&channelID=$CHID&time=${START_EPOCH}000" 2>/dev/null)

# 2. 找 playbillID
PLAYBILL_ID=""
# last-* 相对时段: 快速路径, 直接用 curr.ID (startTime 落在当前节目, 无需逐块匹配)
if [ -n "$REL_DONE" ]; then
  PLAYBILL_ID=$(echo "$RESP" | grep -oE '"curr":\{[^}]*"ID":"[0-9]+"' | grep -oE '[0-9]{15,}' | head -1)
fi

# 完整路径: 从 prev/curr/next 里找包含 START_EPOCH 的节目
if [ -z "$PLAYBILL_ID" ]; then
# 提取节目块(按key分块), 再取 ID/startTime/endTime (字段顺序不固定)
# 用 sed 把 {"key":{ 转成换行, 便于逐块处理
BLOCKS=$(echo "$RESP" | sed 's/},/}\n/g' | grep -oE '\{"name":"[^"]*","startTime":[0-9]+,"ID":"[0-9]+","endTime":[0-9]+\}' 2>/dev/null)
# 同时支持字段乱序: 通用提取 — 先找所有含 ID 的块 (busybox 无 paste/tr 管道脆弱, 用纯 read)
if [ -z "$BLOCKS" ]; then
  BLOCKS=$(echo "$RESP" | sed 's/,/\n/g' | grep -E '"(name|startTime|ID|endTime)"' | while IFS= read -r L; do printf '%s ' "$L"; done)
fi
echo "$BLOCKS" | while IFS= read -r ITEM; do
  [ -z "$ITEM" ] && continue
  ITEM_ID=$(echo "$ITEM" | grep -oE '"ID":"[0-9]+"' | head -1 | sed 's/"ID":"//;s/"//')
  ITEM_ST=$(echo "$ITEM" | grep -oE '"startTime":[0-9]+' | head -1 | sed 's/"startTime"://')
  ITEM_ET=$(echo "$ITEM" | grep -oE '"endTime":[0-9]+' | head -1 | sed 's/"endTime"://')
  [ -z "$ITEM_ID" ] && continue
  ST_S=$((ITEM_ST / 1000)); ET_S=$((ITEM_ET / 1000))
  if [ "$START_EPOCH" -ge "$ST_S" ] 2>/dev/null && [ "$START_EPOCH" -lt "$ET_S" ] 2>/dev/null; then
    echo "$ITEM_ID" > /tmp/playbill_found.txt
    break
  fi
done

[ -f /tmp/playbill_found.txt ] && PLAYBILL_ID=$(cat /tmp/playbill_found.txt) && rm -f /tmp/playbill_found.txt
fi

# 兜底: 用 curr 的 ID (接口返回的当前节目)
if [ -z "$PLAYBILL_ID" ]; then
  PLAYBILL_ID=$(echo "$RESP" | grep -oE '"curr":\{[^}]*"ID":"[0-9]+"' | grep -oE '[0-9]{15,}' | head -1)
fi

[ -z "$PLAYBILL_ID" ] && { echo "Status: 404"; echo "Content-Type: text/plain"; echo ""; echo "no playbill for time"; exit 0; }

# 3. getTvodPlayUrl → playURL
TVOD=$(curl -s --max-time 8 "$AJAX_URL" -H "Cookie: $COOKIE" -H "User-Agent: $UA" -H "Referer: $REF" \
  -d "action=getTvodPlayUrl&channelID=$CHID&playbillID=$PLAYBILL_ID&startTime=$START_EPOCH&endTime=$END_EPOCH" 2>/dev/null)

PLAYURL=$(echo "$TVOD" | grep -oE '"playURL":"[^"]*"' | head -1 | sed 's/"playURL":"//;s/"$//')

if [ -n "$PLAYURL" ]; then
  # ============================================================
  # 回看代理 v5: 绕过负载均衡(直连6610) + 机顶盒头拉主m3u8
  # + 改写 URL 指向 tsproxy (平板访问不了专网6610)
  # ============================================================
  STB_UA='ADI Video On Damand Client/1.0'
  # 机顶盒 GUID: 公共版不内置 (各机顶盒不同), 用户自行填写 iptv_epg.main.stb_guid;
  # 未填则用 daemon 自动采集的 (/etc/epg_stb_info.txt); 都没有则不带该头 (仅回看可能被拒)
  STB_GUID=$(uci get iptv_epg.main.stb_guid 2>/dev/null)
  if [ -z "$STB_GUID" ] && [ -f /etc/epg_stb_info.txt ]; then
    . /etc/epg_stb_info.txt 2>/dev/null
    STB_GUID=${STB_GUID:-}
  fi
  GUID_HEAD=""
  [ -n "$STB_GUID" ] && GUID_HEAD="-H Pragma: XClientGUID=$STB_GUID"
  # 回看服务器 (uci tvod_host, 可配置防电信改 IP) → 电信默认
  TVOD_HOST=$(uci get iptv_epg.main.tvod_host 2>/dev/null)
  [ -n "$TVOD_HOST" ] || TVOD_HOST=124.75.26.15:6610
  LB_HOST="http://$TVOD_HOST"

  # a. 替换 playURL 服务器为 6610 (绕过负载均衡 8112/401)
  URL6610=$(echo "$PLAYURL" | sed "s#http://[0-9.]*:[0-9]*#$LB_HOST#")

  # b. 请求主 m3u8 (机顶盒头) → 跟随规范化 302 → 拿 m3u8
  R1=$(curl -s --max-time 10 -D - -o /tmp/play_m1.txt \
    -H "User-Agent: $STB_UA" -H "Accept: */*" -H "Range: bytes=0-" \
    $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" \
    "$URL6610" 2>/dev/null)
  URL2=$(echo "$R1" | grep -i '^Location' | sed 's/Location: //' | tr -d '\r')
  if [ -n "$URL2" ]; then
    curl -s --max-time 10 -o /tmp/play_m2.txt \
      -H "User-Agent: $STB_UA" -H "Accept: */*" -H "Range: bytes=0-" \
      $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" \
      "$URL2" 2>/dev/null
  else
    cp /tmp/play_m1.txt /tmp/play_m2.txt
  fi

  # c. 检查是否拿到 m3u8
  if grep -q 'EXTM3U' /tmp/play_m2.txt 2>/dev/null; then
    # 若是主 m3u8 (EXT-X-STREAM-INF), 跟随到子流 (1000.m3u8) — DIYP 可能不支持 m3u8嵌m3u8
    if grep -q 'EXT-X-STREAM-INF' /tmp/play_m2.txt 2>/dev/null; then
      SUB_URL=$(grep -E '^http' /tmp/play_m2.txt | head -1 | tr -d '\r')
      if [ -n "$SUB_URL" ]; then
        R3=$(curl -s --max-time 10 -D - -o /tmp/play_s1.txt \
          -H "User-Agent: $STB_UA" -H "Accept: */*" -H "Range: bytes=0-" \
          $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" \
          "$SUB_URL" 2>/dev/null)
        URL3=$(echo "$R3" | grep -i '^Location' | sed 's/Location: //' | tr -d '\r')
        if [ -n "$URL3" ]; then
          curl -s --max-time 10 -o /tmp/play_s2.txt \
            -H "User-Agent: $STB_UA" -H "Accept: */*" -H "Range: bytes=0-" \
            $GUID_HEAD -H "Accept-Charset: UTF-8" -H "Connection: Keep-Alive" \
            "$URL3" 2>/dev/null
        else
          cp /tmp/play_s1.txt /tmp/play_s2.txt
        fi
        # 子流也改写 (TS URL → tsproxy 路径直传)
        if grep -q 'EXTM3U' /tmp/play_s2.txt 2>/dev/null; then
          cp /tmp/play_s2.txt /tmp/play_m2.txt
        fi
        rm -f /tmp/play_s1.txt /tmp/play_s2.txt
      fi
    fi
    # 改写 m3u8: http:// URL → tsproxy 路径直传 (零编码, 快!)
    #   http://124.75.26.15:6610/SHDXFH_live/... → http://<本机IP>/cgi-bin/tsproxy.cgi/SHDXFH_live/...
    echo "Content-Type: application/vnd.apple.mpegurl; charset=utf-8"
    echo "Cache-Control: no-cache"
    echo ""
    # 本机 IP (回看 TS 流走本机 tsproxy)
    LOCAL_IP2=$(/usr/bin/iptv_epg ip 2>/dev/null)
    [ -z "$LOCAL_IP2" ] && LOCAL_IP2="127.0.0.1"
    sed "s#http://124\\.75\\.26\\.15:6610/#http://$LOCAL_IP2/cgi-bin/tsproxy.cgi/#g" /tmp/play_m2.txt
    rm -f /tmp/play_m1.txt /tmp/play_m2.txt
    exit 0
  fi

  # d. 兜底: 直接 302 到 6610 (调试用)
  echo "Status: 302 Found"
  echo "Location: $URL6610"
  echo "Content-Type: text/plain"
  echo ""
  echo "lookback redirect"
  exit 0
fi

echo "Status: 404"
echo "Content-Type: text/plain"
echo ""
echo "lookback failed: ch=$CH playseek=$PLAYSEEK"
