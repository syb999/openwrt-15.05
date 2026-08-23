#!/bin/sh
# ============================================================
# epg.cgi — DIYP 影音兼容的 EPG 节目单 HTTP 接口 (v3 打包版)
# 部署: /www/cgi-bin/epg.cgi (uhttpd CGI, 由 iptv-epg 服务确保)
# 用法: http://<A>/cgi-bin/epg.cgi?ch=新闻综合&date=2026-08-16
#        ch=频道名或频道ID, date=YYYY-MM-DD (默认今天)
# 返回 (DIYP 5.2.0 兼容格式):
#   {"channel_name":"...","date":"...","epg_data":[{"start":"HH:MM","end":"HH:MM","title":"..."}]}
# 快速路径: "$CACHE_DIR/epg_by_name"/<URL编码频道名>/<date>.json (预取生成, 0.1s)
# ============================================================

CJ=/tmp/stb_cookie.txt
PROVIDER=$(uci get iptv_epg.main.provider 2>/dev/null)
[ -n "$PROVIDER" ] || PROVIDER=telecom
# 本机地址 (动态获取, 设备 IP 变化后回看 URL 不失效)
HOST=$(/usr/bin/iptv_epg ip 2>/dev/null)
[ -z "$HOST" ] && HOST=$(uci get network.wan.ipaddr 2>/dev/null)
[ -z "$HOST" ] && HOST=$(uci get network.lan.ipaddr 2>/dev/null)
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
  CH_URL="http://$EPG_HOST/EPG/jsp/jkjiaoyutest/en/function/ajax/epg7getChannelByAjax.jsp"
  REF="http://$EPG_HOST/EPG/jsp/jkjiaoyutest/en/IPM/modules/channel/play_pro.html"
else
  CH_URL="http://$EPG_HOST/iptvepg/frame1413/function/ajax/epg7getChannelByAjax.jsp"
  REF="http://$EPG_HOST/iptvepg/frame1413/IPM/modules/channel/channellist_trailer_pro.html"
fi
UA='webkit;Resolution(PAL,720P,1080P)'
ORIGIN="http://$EPG_HOST"
CACHE_TTL=86400
CACHE_DIR=/tmp/epg_cache
mkdir -p "$CACHE_DIR" 2>/dev/null

echo "Content-Type: application/json; charset=utf-8"
echo "Cache-Control: no-cache"
echo ""

# ---------- 参数解析 (兼容 ch= 和 channel=) ----------
QS="$QUERY_STRING"
CH_RAW=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^(ch|channel)=/){sub(/^(ch|channel)=/,"",$i);print $i;exit}}}')
DATE_RAW=$(echo "$QS" | awk -F'[&;]' '{for(i=1;i<=NF;i++){if($i~/^date=/){sub(/^date=/,"",$i);print $i;exit}}}')
[ -z "$DATE_RAW" ] && DATE_RAW=$(date +%F)

# ---------- URL 解码 ----------
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
CH=$(url_decode "$CH_RAW")
DATE=$(url_decode "$DATE_RAW")
# 🔴 兼容 TvBox 的 date 格式: YYYYMMDD (无横杠) → YYYY-MM-DD (否则缓存查不到, TvBox 全部无 EPG!)
case "$DATE" in
  [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) DATE=$(echo "$DATE" | sed 's/\(....\)\(..\)\(..\)/\1-\2-\3/') ;;
esac

[ -z "$CH" ] && { echo '{"channel_name":"未提供","date":"'$(date +%F)'","epg_data":[]}'; exit 0; }
[ -z "$DATE" ] && DATE=$(date +%F)
# 电信模式: 无 cookie 无法拉 EPG → 快速返回空; 联通模式: 走缓存/JSESSIONID 会话, 不需要电信 cookie
if [ "$PROVIDER" != "unicom" ] && [ ! -f "$CJ" ]; then
  echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[]}"
  exit 0
fi
COOKIE=$(cat "$CJ" 2>/dev/null)

# ---------- 频道名别名映射 ----------
# 兼容 TVBox 内置 epg_data.json 的 epgid (EpgUtil.getEpgInfo 用 epgid 请求)
alias_map() {
  case "$1" in
    五星体育) echo "体育频道" ;;
    # TVBox 内置 epg_data.json 把"新闻综合"映射到 CDTV1 (成都新闻综合, 内置表第一个匹配)
    # 但我们的是上海新闻综合, 别名回新闻综合
    CDTV1|CDTV-1) echo "新闻综合" ;;
    CCTV1|CCTV-1综合|CCTV1综合) echo "CCTV-1" ;;
    CCTV2) echo "CCTV-2" ;;
    CCTV3) echo "CCTV-3" ;;
    CCTV4) echo "CCTV-4" ;;
    CCTV5|CCTV5体育) echo "CCTV-5" ;;
    CCTV6|CCTV6电影) echo "CCTV-6" ;;
    CCTV7) echo "CCTV-7" ;;
    CCTV8) echo "CCTV-8" ;;
    CCTV9) echo "CCTV-9" ;;
    CCTV10|CCTV10科教) echo "CCTV-10" ;;
    CCTV11) echo "CCTV-11" ;;
    CCTV12) echo "CCTV-12" ;;
    CCTV13) echo "CCTV-13" ;;
    CCTV14) echo "CCTV-14" ;;
    CCTV15) echo "CCTV-15" ;;
    CCTV16) echo "CCTV-16" ;;
    CCTV17) echo "CCTV-17" ;;
    CGTN) echo "CGTN" ;;
    # HD 频道节目与标清相同 → 去掉 HD 后缀复用标清 CHID/缓存 (拉取量减半+快速命中)
    *HD) echo "${1%HD}" ;;
    *) echo "$1" ;;
  esac
}
CH_ALIAS=$(alias_map "$CH")

# ---------- 快速缓存命中 (增强): 按解码名 / alias名 / 模糊匹配 多路径查找 ----------
# 预取索引目录 = 频道名 URL 编码; 但 TVBox 用 epgid (如 CCTV1/CDTV1) 请求,
# 且索引可能是带 HD 后缀的高清频道名 (CCTV-11HD) → 需模糊匹配
quick_hit() {
  local qname="$1"
  [ -z "$qname" ] && return 1
  local ENC=$(printf '%s' "$qname" | xxd -p | tr -d ' \n' | tr 'a-f' 'A-F' | sed 's/\(..\)/%\1/g')
  local NCF="$CACHE_DIR/epg_by_name/${ENC}/${DATE}.json"
  if [ -f "$NCF" ]; then
    if [ $(( $(date +%s) - $(date -r "$NCF" +%s) )) -lt "$CACHE_TTL" ]; then
      cat "$NCF"
      return 0
    fi
  fi
  # 模糊匹配: 请求 CCTV-11 但索引只有 CCTV-11HD → 遍历目录找前缀/包含
  local QDEC=$(printf '%b' "$(echo "$ENC" | sed 's/%/\\x/g')" 2>/dev/null)
  [ -z "$QDEC" ] && QDEC="$qname"
  local dir
  for dir in "$CACHE_DIR/epg_by_name"/*/; do
    [ -d "$dir" ] || continue
    local DEN=$(basename "$dir")
    local DDEC=$(printf '%b' "$(echo "$DEN" | sed 's/%/\\x/g')" 2>/dev/null)
    # 索引名以请求名开头 (CCTV-11HD 以 CCTV-11 开头) 或 请求名以索引名开头
    case "$DDEC" in
      "$QDEC"*|"$QDEC"HD|"$QDEC"SD)
        local FN="${dir}${DATE}.json"
        if [ -f "$FN" ]; then
          if [ $(( $(date +%s) - $(date -r "$FN" +%s) )) -lt "$CACHE_TTL" ]; then
            # 修正响应里的 channel_name (索引是 HD 名, 请求是原名)
            sed "s/\"channel_name\":\"[^\"]*\"/\"channel_name\":\"$qname\"/" "$FN"
            return 0
          fi
        fi
        ;;
    esac
  done
  return 1
}
quick_hit "$CH" && exit 0
[ "$CH_ALIAS" != "$CH" ] && quick_hit "$CH_ALIAS" && exit 0

# ---------- 找 channelID (channel_map.txt 优先 → 硬编码兜底 → getChannelList 兜底) ----------
case "$CH" in
  ch[0-9a-f]*) CHID="$CH" ;;
  *)
    # ① 频道映射表优先 (联通=数字ID 20000030; 电信=ch...; channels-save 重建后自动适配)
    CHID=$(grep "^$CH_ALIAS|" /usr/share/iptv_epg/channel_map.txt 2>/dev/null | head -1 | cut -d'|' -f2)
    if [ -z "$CHID" ] && [ "$PROVIDER" != "unicom" ]; then
    # ② 硬编码全频道映射 (168 个, 电信频道 ID 固定; 2026-08-17 拉取) — 🔴 仅电信, 联通查不到则空 (防电信ID污染联通)
    case "$CH_ALIAS" in
      新闻综合) CHID="ch00000000000000001485" ;;
      东方卫视) CHID="ch00000000000000001058" ;;
      都市频道) CHID="ch00000000000000001143" ;;
      东方影视) CHID="ch00000000000000001462" ;;
      第一财经) CHID="ch00000000000000001028" ;;
      体育频道) CHID="ch00000000000000001346" ;;
      哈哈炫动) CHID="ch00000000000000001226" ;;
      东方购物-1) CHID="ch00000000000000001322" ;;
      东方购物-2) CHID="ch00000000000000001332" ;;
      上海教育) CHID="ch00000000000000001432" ;;
      法治天地) CHID="ch00000000000000001295" ;;
      游戏风云) CHID="ch00000000000000001472" ;;
      金色学堂) CHID="ch00000000000000001132" ;;
      央广购物) CHID="ch00000000000000001145" ;;
      好享购物) CHID="ch00000000000000001125" ;;
      CCTV-1) CHID="ch00000000000000001372" ;;
      CCTV-2) CHID="ch00000000000000001392" ;;
      CCTV-3) CHID="ch00000000000000001044" ;;
      CCTV-4) CHID="ch00000000000000001282" ;;
      CCTV-5) CHID="ch00000000000000001313" ;;
      CCTV-6) CHID="ch00000000000000001323" ;;
      CCTV-7) CHID="ch00000000000000001253" ;;
      CCTV-8) CHID="ch00000000000000001452" ;;
      CCTV-9) CHID="ch00000000000000001343" ;;
      CCTV-10) CHID="ch00000000000000001163" ;;
      CCTV-11) CHID="ch00000000000000001373" ;;
      CCTV-12) CHID="ch00000000000000001029" ;;
      CCTV-13) CHID="ch00000000000000001347" ;;
      CCTV-14) CHID="ch00000000000000001095" ;;
      CCTV-15) CHID="ch00000000000000001242" ;;
      CCTV-17) CHID="ch00000000000000001401" ;;
      CGTN) CHID="ch00000000000000001157" ;;
      央广购物HD) CHID="ch00000000000000001793" ;;
      财富天下) CHID="ch00000000000000001412" ;;
      CHC家庭影院HD) CHID="ch00000000000000001855" ;;
      CHC动作电影HD) CHID="ch00000000000000001865" ;;
      CHC影迷电影HD) CHID="ch00000000000000001856" ;;
      风云足球HD) CHID="ch00000000000000001866" ;;
      央视台球HD) CHID="ch00000000000000001875" ;;
      兵器科技HD) CHID="ch00000000000000001859" ;;
      世界地理HD) CHID="ch00000000000000001861" ;;
      快乐垂钓HD) CHID="ch00000000000000001431" ;;
      女性时尚HD) CHID="ch00000000000000001862" ;;
      高尔夫网球HD) CHID="ch00000000000000001885" ;;
      怀旧剧场HD) CHID="ch00000000000000001895" ;;
      风云剧场HD) CHID="ch00000000000000001863" ;;
      第一剧场HD) CHID="ch00000000000000001905" ;;
      风云音乐HD) CHID="ch00000000000000001915" ;;
      央视文化精品HD) CHID="ch00000000000000001886" ;;
      早期教育HD) CHID="ch00000000000000001864" ;;
      游戏风云HD) CHID="ch00000000000000001031" ;;
      生活时尚HD) CHID="ch00000000000000001021" ;;
      动漫秀场HD) CHID="ch00000000000000001011" ;;
      乐游HD) CHID="ch00000000000000001484" ;;
      都市剧场HD) CHID="ch00000000000000001077" ;;
      法治天地HD) CHID="ch00000000000000001032" ;;
      多彩文体HD) CHID="ch00000000000000001066" ;;
      东方卫视HD) CHID="ch00000000000000001067" ;;
      CCTV-1HD) CHID="ch00000000000000001062" ;;
      都市频道HD) CHID="ch00000000000000001215" ;;
      哈哈炫动HD) CHID="ch00000000000000001012" ;;
      东方影视HD) CHID="ch00000000000000001297" ;;
      新闻综合HD) CHID="ch00000000000000001403" ;;
      五星体育HD) CHID="ch00000000000000001182" ;;
      第一财经HD) CHID="ch00000000000000001057" ;;
      东方购物-1HD) CHID="ch00000000000000001041" ;;
      东方购物-2HD) CHID="ch00000000000000001061" ;;
      上海教育HD) CHID="ch00000000000000001583" ;;
      东方财经HD) CHID="ch00000000000000001623" ;;
      金色学堂HD) CHID="ch00000000000000001022" ;;
      CCTV-5+HD) CHID="ch00000000000000001783" ;;
      CCTV-4K) CHID="ch00000000000000001860" ;;
      CCTV-2HD) CHID="ch00000000000000001391" ;;
      CCTV-3HD) CHID="ch00000000000000001233" ;;
      CCTV-4HD) CHID="ch00000000000000001174" ;;
      CCTV-5HD) CHID="ch00000000000000001361" ;;
      CCTV-6HD) CHID="ch00000000000000001133" ;;
      CCTV-7HD) CHID="ch00000000000000001381" ;;
      CCTV-8HD) CHID="ch00000000000000001371" ;;
      CCTV-9HD) CHID="ch00000000000000001224" ;;
      CCTV-10HD) CHID="ch00000000000000001123" ;;
      CCTV-11HD) CHID="ch00000000000000001633" ;;
      CCTV-12HD) CHID="ch00000000000000001063" ;;
      CCTV-13HD) CHID="ch00000000000000001643" ;;
      CCTV-14HD) CHID="ch00000000000000001214" ;;
      CCTV-15HD) CHID="ch00000000000000001653" ;;
      CCTV-16HD) CHID="ch00000000000000001563" ;;
      CCTV-17HD) CHID="ch00000000000000001035" ;;
      浙江卫视HD) CHID="ch00000000000000001082" ;;
      江苏卫视HD) CHID="ch00000000000000001072" ;;
      湖南卫视HD) CHID="ch00000000000000001424" ;;
      北京卫视HD) CHID="ch00000000000000001333" ;;
      广东卫视HD) CHID="ch00000000000000001434" ;;
      深圳卫视HD) CHID="ch00000000000000001415" ;;
      黑龙江卫视HD) CHID="ch00000000000000001353" ;;
      山东卫视HD) CHID="ch00000000000000001158" ;;
      湖北卫视HD) CHID="ch00000000000000001146" ;;
      安徽卫视HD) CHID="ch00000000000000001151" ;;
      东南卫视HD) CHID="ch00000000000000001161" ;;
      江西卫视HD) CHID="ch00000000000000001131" ;;
      辽宁卫视HD) CHID="ch00000000000000001141" ;;
      天津卫视HD) CHID="ch00000000000000001121" ;;
      中国教育-1HD) CHID="ch00000000000000001091" ;;
      四川卫视HD) CHID="ch00000000000000001191" ;;
      重庆卫视HD) CHID="ch00000000000000001181" ;;
      贵州卫视HD) CHID="ch00000000000000001201" ;;
      海南卫视HD) CHID="ch00000000000000001042" ;;
      河北卫视HD) CHID="ch00000000000000001192" ;;
      金鹰纪实HD) CHID="ch00000000000000001052" ;;
      三沙卫视HD) CHID="ch00000000000000001854" ;;
      河南卫视HD) CHID="ch00000000000000001411" ;;
      云南卫视HD) CHID="ch00000000000000001001" ;;
      广西卫视HD) CHID="ch00000000000000001025" ;;
      吉林卫视HD) CHID="ch00000000000000001421" ;;
      卡酷少儿HD) CHID="ch00000000000000001344" ;;
      甘肃卫视HD) CHID="ch00000000000000001603" ;;
      中国教育-4HD) CHID="ch00000000000000001663" ;;
      青海卫视HD) CHID="ch00000000000000001823" ;;
      金鹰卡通HD) CHID="ch00000000000000001803" ;;
      山西卫视HD) CHID="ch00000000000000001998" ;;
      内蒙古卫视HD) CHID="ch00000000000000002007" ;;
      新疆卫视HD) CHID="ch00000000000000002057" ;;
      兵团卫视HD) CHID="ch00000000000000002058" ;;
      西藏卫视HD) CHID="ch00000000000000002011" ;;
      陕西卫视HD) CHID="ch00000000000000002037" ;;
      宁夏卫视HD) CHID="ch00000000000000002117" ;;
      财富天下HD) CHID="ch00000000000000002107" ;;
      高清导视频道) CHID="ch00000000000000001298" ;;
      宁夏卫视) CHID="ch00000000000000001481" ;;
      北京卫视) CHID="ch00000000000000001467" ;;
      湖南卫视) CHID="ch00000000000000001501" ;;
      江苏卫视) CHID="ch00000000000000001147" ;;
      浙江卫视) CHID="ch00000000000000001115" ;;
      海南卫视) CHID="ch00000000000000001037" ;;
      广西卫视) CHID="ch00000000000000001362" ;;
      四川卫视) CHID="ch00000000000000001293" ;;
      山东卫视) CHID="ch00000000000000001374" ;;
      辽宁卫视) CHID="ch00000000000000001252" ;;
      安徽卫视) CHID="ch00000000000000001435" ;;
      东南卫视) CHID="ch00000000000000001134" ;;
      天津卫视) CHID="ch00000000000000001413" ;;
      江西卫视) CHID="ch00000000000000001043" ;;
      吉林卫视) CHID="ch00000000000000001312" ;;
      山西卫视) CHID="ch00000000000000001055" ;;
      青海卫视) CHID="ch00000000000000001027" ;;
      西藏卫视) CHID="ch00000000000000001294" ;;
      陕西卫视) CHID="ch00000000000000001154" ;;
      云南卫视) CHID="ch00000000000000001014" ;;
      甘肃卫视) CHID="ch00000000000000001074" ;;
      广东卫视) CHID="ch00000000000000001046" ;;
      黑龙江卫视) CHID="ch00000000000000001302" ;;
      河北卫视) CHID="ch00000000000000001461" ;;
      内蒙古卫视) CHID="ch00000000000000001225" ;;
      湖北卫视) CHID="ch00000000000000001272" ;;
      重庆卫视) CHID="ch00000000000000001315" ;;
      贵州卫视) CHID="ch00000000000000001451" ;;
      河南卫视) CHID="ch00000000000000001054" ;;
      深圳卫视) CHID="ch00000000000000001345" ;;
      新疆卫视) CHID="ch00000000000000001471" ;;
      兵团卫视) CHID="ch00000000000000001064" ;;
      三沙卫视) CHID="ch00000000000000001422" ;;
      金鹰卡通) CHID="ch00000000000000001092" ;;
      嘉佳卡通) CHID="ch00000000000000001172" ;;
      卡酷卡通) CHID="ch00000000000000001102" ;;
      中国教育-1) CHID="ch00000000000000001112" ;;
      中国教育-2) CHID="ch00000000000000001122" ;;
      延边卫视) CHID="ch00000000000000001813" ;;
      家庭理财) CHID="ch00000000000000001593" ;;
    esac
    fi
    # 兜底: 电信更新 channel ID 时, 从 getChannelList 查 (awk 快速提取) — 🔴 仅电信接口
    if [ -z "$CHID" ] && [ "$PROVIDER" != "unicom" ]; then
      CHID=$(curl -s --max-time 10 "$CH_URL" -H "Cookie: $COOKIE" -H "User-Agent: $UA" -H "Referer: $REF" -H "Origin: $ORIGIN" -d 'action=getChannelList&cateID=000406&type=' 2>/dev/null | \
        tr '{' '\n' | grep '"name"' | awk -v want="$CH_ALIAS" '{
          if (match($0, /"name":"[^"]*"/)) { n=substr($0, RSTART+8, RLENGTH-9) }
          if (match($0, /"ID":"[^"]*"/)) { id=substr($0, RSTART+6, RLENGTH-7) }
          if (n == want) print id
        }' | head -1)
    fi
    ;;
esac
[ -z "$CHID" ] && { echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[]}"; exit 0; }

# ---------- 缓存检查 (按 CHID+日期) ----------
CACHE_FILE="$CACHE_DIR/epg_cache_${CHID}_${DATE}.json"
if [ -f "$CACHE_FILE" ]; then
  AGE=$(( $(date +%s) - $(date -r "$CACHE_FILE" +%s) ))
  if [ "$AGE" -lt "$CACHE_TTL" ]; then
    case "$CH" in
      ch[0-9a-f]*) cat "$CACHE_FILE" ;;
      *) sed "s/\"channel_name\":\"[^\"]*\"/\"channel_name\":\"$CH\"/" "$CACHE_FILE" ;;
    esac
    exit 0
  fi
fi

# ---------- 实时拉取防并发锁 (弱设备保护) ----------
# 缓存缺失/过期时, 只允许一个请求实时拉电信, 其他请求快速返回
# (防止 TvBox/DIYP 切台时 106 个频道并发实时拉取拖垮 MT7688 → 用户看到"好多频道没 EPG")
LOCKF=/tmp/epg_live.lock
exec 9>"$LOCKF" 2>/dev/null
if ! flock -n 9 2>/dev/null; then
  # 有请求正在拉: 快速返回旧缓存或空 (不阻塞, 不排队)
  if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
  else
    echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[]}"
  fi
  exit 0
fi
# 拿到锁后双检: 别的请求可能刚写好缓存
if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(date -r "$CACHE_FILE" +%s) )) -lt "$CACHE_TTL" ]; then
  cat "$CACHE_FILE"
  exit 0
fi

# ---------- 全天节目单: getChannelProg 一次拉取 (参考 sh-tel-iptv-spider) ----------
DAY_START=$(date -d "$DATE 00:00:00" +%s 2>/dev/null)
[ -n "$DAY_START" ] || { echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[]}"; exit 0; }
# 时区修正: 电信接口按北京时间 epoch 解释; 用 date %z 偏移统一换算 (POSIX)
TZOFF=$(date +%z)
TZH=$(echo "$TZOFF" | cut -c2-3 | awk '{print $1+0}')   # 时区小时 (UTC=0, CST=8)
DAY_START=$((DAY_START - (TZH - 8) * 3600))
DAY_END=$((DAY_START + 86399))
TMP=$(mktemp /tmp/epg_cgi.XXXXXX)
if [ "$PROVIDER" = "unicom" ]; then
  # 联通: getChannelProg 兼容 (需 JSESSIONID 会话, daemon 采集 / iptv_epg login)
  if [ -f /etc/epg_unicom_sess.txt ]; then
    . /etc/epg_unicom_sess.txt 2>/dev/null
    curl -s --max-time 10 -X POST "$CH_URL" -H "Cookie: JSESSIONID=$JSESSIONID" -H "User-Agent: $UA" -H "Referer: $REF" -H "Origin: $ORIGIN" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "action=getChannelProg&channelID=$CHID&startTime=${DAY_START}000&endTime=${DAY_END}000&offset=0&limit=500" 2>/dev/null > "$TMP"
    # 🔴 会话失效自动保活: 无节目数据 → 重放 login 换新 JSESSIONID → 重试一次
    #    (login 凭抓包账号 token, 不依赖机顶盒; ⚠️ 会踢机顶盒会话, 机顶盒自动重认证)
    if ! grep -q '"name"' "$TMP" 2>/dev/null; then
      /usr/bin/iptv_epg login >/dev/null 2>&1
      . /etc/epg_unicom_sess.txt 2>/dev/null
      curl -s --max-time 10 -X POST "$CH_URL" -H "Cookie: JSESSIONID=$JSESSIONID" -H "User-Agent: $UA" -H "Referer: $REF" -H "Origin: $ORIGIN" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "action=getChannelProg&channelID=$CHID&startTime=${DAY_START}000&endTime=${DAY_END}000&offset=0&limit=500" 2>/dev/null > "$TMP"
    fi
  fi
else
  curl -s --max-time 10 "$CH_URL" -H "Cookie: $COOKIE" -H "User-Agent: $UA" -H "Referer: $REF" -H "Origin: $ORIGIN" \
    -d "action=getChannelProg&channelID=$CHID&startTime=${DAY_START}000&endTime=${DAY_END}000&offset=0&limit=500" 2>/dev/null > "$TMP"
fi

# 拉取失败/空 → 降级: 返回旧缓存(即使过期), 保证 DIYP 有数据
if ! grep -q '"name"' "$TMP" 2>/dev/null; then
  if [ -f "$CACHE_FILE" ]; then
    case "$CH" in
      ch[0-9a-f]*) cat "$CACHE_FILE" ;;
      *) sed "s/\"channel_name\":\"[^\"]*\"/\"channel_name\":\"$CH\"/" "$CACHE_FILE" ;;
    esac
    rm -f "$TMP"
    exit 0
  fi
  rm -f "$TMP"
  echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[]}"
  exit 0
fi

# ---------- 组装 JSON ----------
OUT=$(mktemp /tmp/epg_out.XXXXXX)
echo "{\"channel_name\":\"$CH\",\"date\":\"$DATE\",\"epg_data\":[" > "$OUT"
# 按 { 分块提取: name/startTime/endTime (字段顺序不固定)
# 优化: 用 awk 一次性提取 (替代 while+sed 逐行 fork, MT7688 上 4s → 0.1s)
tr '{' '\n' < "$TMP" | grep '"name"' | awk '
{
  n=""; st=""; et=""
  if (match($0, /"name":"[^"]*"/)) { n=substr($0, RSTART+8, RLENGTH-9) }
  if (match($0, /"startTime":[0-9]+/)) { st=substr($0, RSTART+12, RLENGTH-12) }
  if (match($0, /"endTime":[0-9]+/)) { et=substr($0, RSTART+10, RLENGTH-10) }
  if (n != "" && st != "" && et != "") printf "%d\t%d\t%s\n", st/1000, et/1000, n
}' | sort -n | awk -F'\t' -v want=$DATE -v chraw=$CH_RAW -v host=$HOST '!seen[$1]++ {
  st=$1; et=$2; name=$3
  # 电信节目日是 16:00-次日15:59, 必须按北京自然日过滤! 只保留 DATE 当天的节目
  # 实测(A=CST+0800): awk strftime 直接用系统时区, 电信假epoch strftime(%F) 即北京日期, 无需 -tzadj
  d=strftime("%F", st)
  if (d != want) next
  # 显示方向: 电信假epoch直接 strftime 即北京墙上时钟 (A 是 CST, awk 用本地时区)
  s=strftime("%H:%M", st); e=strftime("%H:%M", et)
  gsub(/\\/, "\\\\", name); gsub(/"/, "\\\"", name)
  # 附带回看播放地址 (DIYP 点击节目时若支持 url 字段则直接播放回看!)
  ps_start=strftime("%Y%m%d%H%M%S", st); ps_end=strftime("%Y%m%d%H%M%S", et)
  printf "{\"start\":\"%s\",\"end\":\"%s\",\"title\":\"%s\",\"url\":\"http://%s/cgi-bin/play.cgi?ch=%s&playseek=%s-%s\"}\n", s, e, name, host, chraw, ps_start, ps_end
}' >> "$OUT"
# 组装 JSON: 表头行(第1行)和最后一行不加逗号, 中间节目行加逗号 (修复实时拉取时表头被加逗号 bug)
awk 'NR==1 || NR==n {print; next} {print $0 ","}' n=$(wc -l < "$OUT") "$OUT" > "$OUT.new" && mv "$OUT.new" "$OUT"
echo "]}" >> "$OUT"

# 写缓存 + 名字索引
if grep -q '"title"' "$OUT"; then
  cp "$OUT" "$CACHE_FILE"
  # 轻量清理: 名字索引缓存文件数超阈值才触发 (正常 0 开销; 防止 fetch 不跑时 epg_by_name 无限累积)
  # 🔴 按文件名日期清理 (YYYY-MM-DD.json 早于今天-8天删除, 不依赖 mtime)
  if [ -d "$CACHE_DIR/epg_by_name" ]; then
    if [ $(find "$CACHE_DIR/epg_by_name" -name '*.json' 2>/dev/null | wc -l) -gt 2000 ]; then
      local DAYS2=$(uci get iptv_epg.main.prefetch_days 2>/dev/null)
      [ -n "$DAYS2" ] || DAYS2=7
      # 🔴 保留窗口含明天预告: 今天-(DAYS2-1) ~ 今天+1 (共 DAYS2+1 天 json)
      #    例如 8-23 保留 8-17~8-24, 8-24 删 8-17 保留 8-18~8-25
      local CUTOFF=$(date -d "@$(( $(date +%s) - (DAYS2-1)*86400 ))" +%F 2>/dev/null)
      [ -n "$CUTOFF" ] || CUTOFF=$(date +%F)
      find "$CACHE_DIR/epg_by_name" -name '*.json' 2>/dev/null | while read -r F2; do
        local FD=$(basename "$F2" .json)
        case "$FD" in
          20[0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            local FD_NUM=$(echo "$FD" | tr -d '-')
            local CUT_NUM=$(echo "$CUTOFF" | tr -d '-')
            [ "${FD_NUM:-0}" -lt "${CUT_NUM:-0}" ] && rm -f "$F2" 2>/dev/null
            ;;
        esac
      done
      find "$CACHE_DIR/epg_by_name" -type d -empty -delete 2>/dev/null
    fi
  fi
  if [ -n "$CH_RAW" ] && [ -n "$DATE_RAW" ]; then
    mkdir -p "$CACHE_DIR/epg_by_name/${CH_RAW}"
    cp "$OUT" "$CACHE_DIR/epg_by_name/${CH_RAW}/${DATE_RAW}.json"
  fi
fi
rm -f "$TMP"
cat "$OUT"
rm -f "$OUT"
