#!/bin/sh
# kgweb.sh - backend of the standalone web music page (served as /www/music.htm
# through the unauthenticated cgi /www/cgi-bin/music)
#
# actions (all print json, except "lyrics" which prints plain lrc text):
#   status                 what is playing right now
#   songs [force]          chart list from the autodl settings
#   search <keyword>       kugou song search
#   play <hash> [name] [idx]
#   stop | next | prev
#   lyrics [name]          lyric text of the current song
#   vol up|down|get
#
# settings come from the same uci config as the luci app (autodl.@autodl[0]),
# so chart / download directory / source stay in sync with the web ui.

UA="Mozilla/5.0 (Linux; Android 10)"
API_SONG="https://m.kugou.com/app/i/getSongInfo.php?cmd=playInfo&hash="
API_SEARCH="https://mobilecdn.kugou.com/api/v3/search/song?format=json&pagesize=30&keyword="
API_RANK="https://mobilecdn.kugou.com/api/v3/rank/song?version=9108&pagesize=30&format=json&rankid="
API_KUWO_BANG="https://kbangserver.kuwo.cn/ksong.s?from=pc&fmt=json&pn=0&rn=100&type=bang&data=content&show_copyright_off=0&pcmp4=1&isbang=1&id="
API_KUWO_URL="https://antiserver.kuwo.cn/anti.s?type=convert_url3&format=mp3&response=url&rid=MUSIC_"
API_KUWO_DUR="https://mobi.kuwo.cn/mobi.s?f=web&source=jiakong&type=convert_url_with_sign&br=128kmp3&rid="
API_KUWO_SEARCH="https://search.kuwo.cn/r.s?client=kt&pn=0&rn=30&uid=0&ver=kwplayer_ar_9.2.2.1&vipver=1&show_copyright_off=1&newver=1&ft=music&cluster=0&strategy=2012&encoding=utf8&rformat=json&vermerge=1&mobi=1&all="
API_RANKLIST="https://mobilecdn.kugou.com/api/v3/rank/list?version=9108&withsong=0&showtype=2&parentid=0&apiver=2"
API_CDN="https://trackercdn.kugou.com/i/v2/?appid=1005&pid=2&cmd=25&behavior=play&hash="
API_LRCQ="https://krcs.kugou.com/search?ver=1&man=yes&client=mobi&page=1&pagesize=5&keyword="
API_LRCQ_HASH="https://krcs.kugou.com/search?ver=1&man=yes&client=mobi&page=1&pagesize=5&hash="
API_LRCG="https://lyrics.kugou.com/download?ver=1&client=pc&fmt=lrc&charset=utf8&"
KGJSON="/usr/autodl/kgjson.lua"

URLFILE="/tmp/webmusic.tmp.url"    # shared with webmusicplay.sh and the luci status page
INFOFILE="/tmp/webmusic.tmp.info"
PLAYERLOG="/tmp/webmusic_kugou.log"
LISTFILE="/tmp/kgweb.list"
IDXFILE="/tmp/kgweb.idx"
STATEFILE="/tmp/kgweb.state"
LRCKEY="/tmp/kgweb.lrckey"
LRCFILE="/tmp/kgweb.lrc"
WORK="/tmp/kgweb.work"
PLIST="/etc/autodl.plist"          # custom playlist, on flash so it survives a reboot
LOOPFILE="/tmp/kgweb.loop"
THROT="/tmp/kgweb.throttle"
POSFILE="/tmp/kgweb.pos"
BUSYFILE="/tmp/kgweb.busy"
QUEUE="/tmp/kgweb.queue"

# kugou answers errcode 1002 ("too frequent") when it is queried in bursts. on
# the first hit a cooldown marker is written: every later call in that window
# fails fast instead of retrying for minutes (which used to blow uhttpd's
# script timeout and break playback with "bad gateway").
get() {
	mt=20
	rt=1
	rd=2
	# m.kugou.com answers 1002 for everybody right now (and often just hangs), the
	# other hosts are fine: keep the cooldown and the timeouts per host
	case "$1" in
		*//m.kugou.com/*)
			if [ -s "$THROT" ]; then
				t="$(head -n1 "$THROT" 2>/dev/null)"
				if is_num "$t" && [ $(( $(now) - t )) -lt 90 ]; then
					return 0
				fi
			fi
			mt=6
			rt=0
			rd=0
			;;
	esac
	tries=0
	while [ "$tries" -lt 2 ]; do
		out="$(curl -k -s --retry $rt --retry-delay $rd --connect-timeout 6 -m $mt -A "$UA" "$1")"
		case "$out" in
			*'"errcode":1002'*|*"太频繁"*)
				printf '%s' "$(now)" > "$THROT"
				tries=$((tries + 1))
				sleep 2
				continue
				;;
		esac
		printf '%s' "$out"
		return 0
	done
	# a hanging kugou api is as good as a throttled one: remember it so the next
	# calls fail fast instead of eating another timeout on a slow cpu
	case "$1" in
		*//m.kugou.com/*)
			[ -z "$out" ] && printf '%s' "$(now)" > "$THROT"
			;;
	esac
	printf '%s' "$out"
}

throttled() {
	[ -s "$THROT" ] || return 1
	t="$(head -n1 "$THROT" 2>/dev/null)"
	is_num "$t" || return 1
	[ $(( $(now) - t )) -lt 90 ]
}

now() { date +%s; }
mtime() { date -r "$1" +%s 2>/dev/null; }
uci_get() { uci get "autodl.@autodl[0].$1" 2>/dev/null; }

jstr() { printf '%s' "$1" | tr -d '"' | tr -d '\\' | tr '\n\r\t' '   '; }

is_hash() {
	case "$1" in
		*[!0-9a-fA-F]*) return 1 ;;
	esac
	[ ${#1} -eq 32 ]
}

is_num() {
	case "$1" in
		''|*[!0-9]*) return 1 ;;
	esac
	return 0
}

mixer_dev() {
	amixer 2>/dev/null | awk -F"'" '/^Simple mixer control/ && tolower($2) ~ /headphone|speaker|pcm|master/ { print $2; exit }'
}

mixer_vol() {
	dev="$(mixer_dev)"
	[ -n "$dev" ] || return
	amixer get "$dev" 2>/dev/null | awk 'match($0, /[0-9]+%/) { print substr($0, RSTART, RLENGTH - 1); exit }'
}

current_total() {
	if [ -s "$LISTFILE" ]; then
		wc -l < "$LISTFILE" | tr -d ' '
	else
		echo 0
	fi
}

current_idx() {
	i="$(head -n1 "$IDXFILE" 2>/dev/null)"
	is_num "$i" || i=0
	echo "$i"
}

# the url file is written right before a stream starts, so its mtime is the
# moment the current song began (works for the luci player and for us)
cur_url() { head -n1 "$URLFILE" 2>/dev/null; }

cur_state_url() { cut -d '|' -f1 "$STATEFILE" 2>/dev/null; }

cur_name() {
	su="$(cur_state_url)"
	if [ -n "$su" ] && [ "$su" = "$(cur_url)" ]; then
		sed -n 's/^[^|]*|[^|]*|[^|]*|[^|]*|//p' "$STATEFILE" | head -n1
	else
		head -n1 "$INFOFILE" 2>/dev/null
	fi
}

cur_hash() {
	su="$(cur_state_url)"
	if [ -n "$su" ] && [ "$su" = "$(cur_url)" ]; then
		cut -d '|' -f2 "$STATEFILE" 2>/dev/null | head -n1
	else
		# webmusicplay.sh keeps the raw answer of its last song lookup here
		sed -n 's/.*"hash":"\([0-9A-Fa-f]\{32\}\)".*/\1/p' /tmp/kugou.tmp.2 2>/dev/null | head -n1
	fi
}

cur_dur_ms() {
	d=0
	su="$(cur_state_url)"
	if [ -n "$su" ] && [ "$su" = "$(cur_url)" ]; then
		d="$(cut -d '|' -f4 "$STATEFILE" 2>/dev/null)"
	else
		# the luci player leaves its last api answer here
		d="$(sed -n 's/.*"timeLength":\([0-9]*\).*/\1/p' /tmp/kugou.tmp.2 2>/dev/null | head -n1)"
	fi
	is_num "$d" || d=0
	echo $(( d * 1000 ))
}

# the page can play from kugou or from kuwo (uci webpagesrc)
page_src() {
	case "$(uci_get webpagesrc)" in
		kuwo) echo kuwo ;;
		*) echo kugou ;;
	esac
}

kuwo_ids() {
	case "$1" in
		kuwo-soaring) echo 93 ;;
		kuwo-hot) echo 16 ;;
		kuwo-new) echo 17 ;;
		kuwo-shortvideo) echo 158 ;;
		kuwo-monthly) echo 79 ;;
		kuwo-cantonese) echo 182 ;;
		all) echo "93 16 17 158 79 182" ;;
	esac
}

KWDUR="/tmp/kgweb.kwdur"
DEAD="/tmp/kgweb.dead"
SUBST="/tmp/kgweb.subst"

# the chart api field "duration" is NOT the song length (it lies), the mobi api
# reports the real one: {"code":200,"data":{"duration":268,..}}
# tracks that just failed to resolve: prev/next skip them instantly instead of
# paying another resolve (they expire so a temporary failure is not forever)
dead_recent() {
	[ -s "$DEAD" ] || return 1
	t="$(awk -F'|' -v h="$1" '$1 == h { print $2; exit }' "$DEAD")"
	is_num "$t" || return 1
	[ $(( $(now) - t )) -lt 21600 ]
}

mark_dead() {
	[ -s "$DEAD" ] && grep -v "^$1|" "$DEAD" > "$WORK.dead" 2>/dev/null
	cp "$WORK.dead" "$DEAD" 2>/dev/null
	printf '%s|%s\n' "$1" "$(now)" >> "$DEAD"
}

kuwo_dur_api() {
	get "${API_KUWO_DUR}$1" | $KGJSON kuwodur
}

kuwo_dur_cached() {
	[ -s "$KWDUR" ] || return 0
	awk -F'|' -v r="$1" '$1 == r { print $2; exit }' "$KWDUR"
}

kuwo_dur_store() {
	printf '%s|%s\n' "$1" "$2" >> "$KWDUR"
}

# rewrite a kw list on stdin with the durations we know about
kuwo_apply_dur() {
	[ -s "$KWDUR" ] || { cat; return 0; }
	awk -F'\t' 'BEGIN { OFS = "\t" }
		NR == FNR { split($0, a, "|"); d[a[1]] = a[2]; next }
		{
			rid = $1
			sub(/^kw:/, "", rid)
			if (d[rid] != "" && d[rid] + 0 > 0) {
				# a known member sample must not be offered
				if (d[rid] + 0 < 20) next
				$3 = d[rid]
			}
			print
		}' "$KWDUR" - 
}

kuwo_stream() {
	get "${API_KUWO_URL}$1" | $KGJSON kuwourl
}

# byte length of the stream -> seconds at 128 kbps (kuwo does not report it)
kuwo_dur() {
	l="$(curl -k -s -I -A "$UA" --connect-timeout 8 -m 15 "$1" 2>/dev/null | tr -d '\r' | sed -n 's/^[Cc]ontent-[Ll]ength: //p' | head -n1)"
	is_num "$l" || l=0
	[ "$l" -gt 0 ] && printf '%s' $((l / 16000))
	return 0
}

chart_ids() {
	case "$1" in
		[0-9]*) echo "$1" ;;
		hummingbird-pop-music-chart) echo 59703 ;;
		tiktok-hot-song-chart) echo 52144 ;;
		kwai-hot-song-chart) echo 52767 ;;
		western-golden-melody-chart) echo 33166 ;;
		acg-new-song-chart) echo 33162 ;;
		mainland-song-chart) echo 31308 ;;
		hongkong-song-chart) echo 31313 ;;
		japanese-song-chart) echo 31312 ;;
		billboard-chart) echo 4681 ;;
		kugou-top500) echo 8888 ;;
		all) echo "59703 52144 52767 33166 8888 33162 31308 31313 31312 4681" ;;
	esac
}

kill_players() {
	killall -9 mpg123 >/dev/null 2>&1
	pids="$(ps -w | grep webmusicplay.sh | grep -v grep | awk '{print $1}')"
	if [ -n "$pids" ]; then
		kill -9 $pids >/dev/null 2>&1
	fi
}

start_player() {
	# detached on purpose: must not hold the cgi pipes open and must survive
	# the cgi process exit
	nohup sh -c "curl -k -s \"$1\" --connect-timeout 5 | mpg123 --timeout 2 --no-resync -" \
		</dev/null >/dev/null 2>&1 &
}

# stdin: "hash<TAB>name<TAB>duration<TAB>privilege" lines, prints the json and
# installs the very same order as the playlist used by next/prev. one awk pass:
# the old per line pipeline spawned several hundred processes on this board.
emit_list() {
	# the hash column of the list identifies it: the page uses this to tell
	# whether the list it displays is the one that is currently playing.
	# it is computed from the installed list (below) so both sides use the
	# very same "hash|name" format.
	awk -F'	' -v chart="$1" -v subn="${2:-0}" -v hid0="${3:-0}" -v pl="$WORK.list" '
	function esc(s) { gsub(/"/, "", s); gsub(/\\/, "", s); gsub(/[\r\n\t]/, " ", s); return s }
	BEGIN {
		printf "{\"ok\":1,\"chart\":\"%s\",\"songs\":[", esc(chart)
		first = 1
		hidden = 0
	}
	{
		h = $1; nm = $2; d = $3 + 0; p = $4 + 0
		if (h !~ /^kw:[0-9]+$/ && (length(h) != 32 || h !~ /^[0-9A-Fa-f]+$/)) next
		if (nm == "") next
		if (!first) printf ","
		first = 0
		printf "{\"h\":\"%s\",\"n\":\"%s\",\"d\":%d,\"p\":%d}", h, esc(nm), d, p
		print h "|" nm > pl
	}
	END {
		print "],\"hidden\":" hidden + hid0 ",\"sub\":" subn ",\"lmd5\":\"@@LMD5@@\"}"
		close(pl)
	}' > "$WORK.json0"
	lmd5="$(cut -d'|' -f1 "$WORK.list" 2>/dev/null | md5sum | cut -d' ' -f1)"
	sed "s/@@LMD5@@/$lmd5/" "$WORK.json0"
	# install this order as the active list, next/prev walk it
	if [ -s "$WORK.list" ]; then
		cp "$WORK.list" "$LISTFILE"
	fi
}

# resolve <hash> <fallback name> -> RES_URL RES_HASH RES_NAME RES_INFO RES_DUR
# tracker cdn: another host, works while m.kugou.com is rate limiting
cdn_url() {
	h="$(printf '%s' "$1" | tr 'A-Z' 'a-z')"
	k="$(printf '%s' "${h}kgcloudv2" | md5sum | cut -d' ' -f1)"
	get "${API_CDN}${h}&key=${k}" | $KGJSON cdnget
}

resolve() {
	RES_HASH="$1"
	RES_NAME="$2"
	RES_INFO=""
	RES_URL=""
	RES_DUR=0
	RES_MSG=""

	case "$RES_HASH" in
		kw:*)
			# kuwo track: the stream comes straight from the kuwo api
			RES_URL="$(kuwo_stream "${RES_HASH#kw:}")"
			case "$RES_URL" in
				http://*|https://*) ;;
				*) RES_URL="" ;;
			esac
			if [ -n "$RES_URL" ]; then
				rid="${RES_HASH#kw:}"
				RES_DUR="$(kuwo_dur_cached "$rid")"
				if ! is_num "$RES_DUR" || [ "$RES_DUR" -le 0 ]; then
					RES_DUR="$(kuwo_dur_api "$rid")"
				fi
				if is_num "$RES_DUR" && [ "$RES_DUR" -gt 0 ]; then
					kuwo_dur_store "$rid" "$RES_DUR"
				else
					# last resort: derivate it from the stream size
					RES_DUR="$(kuwo_dur "$RES_URL")"
				fi
				is_num "$RES_DUR" || RES_DUR=0
				# kuwo hands out a few seconds only for member tracks
				if [ "$RES_DUR" -gt 0 ] && [ "$RES_DUR" -lt 20 ]; then
					RES_URL=""
					RES_MSG="会员曲，酷我只有试听片段（${RES_DUR}s），已跳过"
				fi
			fi
			return 0
			;;
	esac

	info="$(get "${API_SONG}${RES_HASH}" | $KGJSON songinfo)"
	RES_URL="$(printf '%s' "$info" | cut -f1)"
	RES_DUR="$(printf '%s' "$info" | cut -f2)"
	song="$(printf '%s' "$info" | cut -f3)"
	singer="$(printf '%s' "$info" | cut -f4)"
	size="$(printf '%s' "$info" | cut -f5)"
	is_num "$RES_DUR" || RES_DUR=0
	if [ -n "$song" ] || [ -n "$singer" ]; then
		RES_NAME="$singer - $song"
		RES_INFO="${song}_${singer}"
	fi
	if [ "$RES_DUR" -le 0 ] && is_num "$size" && [ "$size" -gt 0 ]; then
		RES_DUR=$((size / 16000))
	fi

	if [ -z "$RES_URL" ]; then
		# the mobile api is rate limited or the track is pay only: the tracker
		# cdn sits on another host and still hands out the stream
		cd="$(cdn_url "$RES_HASH")"
		u="$(printf '%s' "$cd" | cut -f1)"
		sz="$(printf '%s' "$cd" | cut -f2)"
		if [ -n "$u" ]; then
			RES_URL="$u"
			RES_SIZE="$sz"
			if [ "$RES_DUR" -le 0 ] && is_num "$sz" && [ "$sz" -gt 0 ]; then
				RES_DUR=$((sz / 16000))
			fi
		fi
	fi

	if [ -z "$RES_URL" ]; then
		# the track itself cannot be streamed: look for another version of the
		# same title, but only accept a candidate whose name really contains
		# that title (kugou search also returns unrelated matches, and playing
		# one of those looks like playing a random song)
		# a member track keeps the same playable substitute: remember it so the
		# next skip does not have to search again
		if [ -s "$SUBST" ]; then
			sline="$(awk -F'|' -v h="$RES_HASH" '$1 == h { print $2 "|" $3; exit }' "$SUBST" 2>/dev/null)"
			sh="$(printf '%s' "$sline" | cut -d'|' -f1)"
			sn="$(printf '%s' "$sline" | cut -d'|' -f2)"
			if is_hash "$sh"; then
				cd="$(cdn_url "$sh")"
				u="$(printf '%s' "$cd" | cut -f1)"
				sz="$(printf '%s' "$cd" | cut -f2)"
				if [ -n "$u" ]; then
					RES_URL="$u"
					RES_HASH="$sh"
					[ -n "$sn" ] && RES_NAME="$sn"
					RES_INFO="$(printf '%s' "$RES_NAME" | sed 's/^[^ ]* - //')_$(printf '%s' "$RES_NAME" | sed 's/ - .*$//')"
					RES_DUR="$(printf '%s' "$sz" | awk '{print int($1 / 16000)}')"
					RES_SIZE="$sz"
				fi
			fi
		fi
		title="$(printf '%s' "$RES_NAME" | sed 's/^[^ ]* - //')"
		kw="$(printf '%s' "$2" | sed 's/_/ /g;s/ - / /g' | $KGJSON urlenc)"
		if [ -z "$RES_URL" ] && [ -n "$kw" ] && [ -n "$title" ]; then
			raw=""
			try=0
			while [ "$try" -lt 3 ]; do
				raw="$(get "${API_SEARCH}${kw}&page=1")"
				case "$raw" in
					*'"errcode":1002'*|*"太频繁"*)
						try=$((try + 1))
						sleep 3
						continue
						;;
				esac
				break
			done
			printf '%s' "$raw" | $KGJSON search | head -n 20 > "$WORK.cand.0"
			awk -F'\t' '$4 + 0 < 10' "$WORK.cand.0" > "$WORK.cand"
			awk -F'\t' '$4 + 0 >= 10' "$WORK.cand.0" >> "$WORK.cand"
			while IFS= read -r cline; do
				h="$(printf '%s' "$cline" | cut -f1)"
				cn="$(printf '%s' "$cline" | cut -f2)"
				is_hash "$h" || continue
				[ "$h" = "$RES_HASH" ] && continue
				case "$cn" in
					*"$title"*) ;;
					*) continue ;;
				esac
				cd="$(cdn_url "$h")"
				u2="$(printf '%s' "$cd" | cut -f1)"
				sz2="$(printf '%s' "$cd" | cut -f2)"
				if [ -n "$u2" ]; then
					RES_URL="$u2"
					RES_HASH="$h"
					RES_NAME="$cn"
					printf '%s|%s|%s\n' "$1" "$h" "$cn" >> "$SUBST" 2>/dev/null
					RES_INFO="$(printf '%s' "$cn" | sed 's/^[^ ]* - //')_$(printf '%s' "$cn" | sed 's/ - .*$//')"
					RES_DUR="$(printf '%s' "$sz2" | awk '{print int($1 / 16000)}')"
					RES_SIZE="$sz2"
					break
				fi
			done < "$WORK.cand"
		fi
	fi

	# never hand a questionable string to the player
	case "$RES_URL" in
		http://*|https://*) ;;
		*) RES_URL="" ;;
	esac
	case "$RES_URL" in
		*'"'*|*"'"*|*'$'*|*'`'*|*' '*|*'\'*) RES_URL="" ;;
	esac
	[ -z "$RES_NAME" ] && RES_NAME="$2"
	return 0
}

pos_base() {
	if [ -s "$POSFILE" ]; then
		b="$(cut -d '|' -f1 "$POSFILE" 2>/dev/null)"
		is_num "$b" || b=0
		printf '%s' "$b"
	else
		printf '0'
	fi
}

pos_paused() {
	if [ -s "$POSFILE" ]; then
		p="$(cut -d '|' -f2 "$POSFILE" 2>/dev/null)"
		is_num "$p" || p=0
		printf '%s' "$p"
	else
		printf '0'
	fi
}

# epoch the current position is counted from: our own state when we started the
# stream, the modification time of the shared url file for the luci player
pos_start() {
	su="$(cur_state_url)"
	if [ -n "$su" ] && [ "$su" = "$(cur_url)" ]; then
		cut -d '|' -f3 "$STATEFILE" 2>/dev/null
	else
		mtime "$URLFILE"
	fi
}

cur_pos() {
	b="$(pos_base)"
	p="$(pos_paused)"
	st="$(pos_start)"
	is_num "$b" || b=0
	is_num "$st" || st="$(now)"
	if is_num "$p" && [ "$p" -gt 0 ]; then
		printf '%s' $((b + p - st))
	else
		printf '%s' $((b + $(now) - st))
	fi
}

# restart the position counter from here (our state, or the url file for luci)
set_start() {
	t="$1"
	is_num "$t" || t="$(now)"
	su="$(cur_state_url)"
	if [ -n "$su" ] && [ "$su" = "$(cur_url)" ]; then
		awk -F'|' -v t="$t" 'BEGIN { OFS = "|" } { $3 = t; print }' "$STATEFILE" > "$WORK.st"
		cp "$WORK.st" "$STATEFILE"
	else
		touch "$URLFILE"
	fi
}

# the curl that feeds mpg123 (identified by the url in its command line)
stream_pids() {
	u="$(cur_url)"
	[ -z "$u" ] && return 0
	ps -w | grep "$u" | grep curl | grep -v grep | awk '{print $1}'
}

# (re)start the stream of the current track at <seconds>, used by seek/resume
restart_stream() {
	off="$1"
	url="$2"
	[ -z "$url" ] && return 1
	is_num "$off" || off=0
	[ "$off" -lt 0 ] && off=0
	byte=$((off * 16000))
	killall -9 mpg123 >/dev/null 2>&1
	nohup sh -c "curl -k -s -r ${byte}- --connect-timeout 8 \"$url\" | mpg123 --timeout 2 -" \
		</dev/null >/dev/null 2>&1 &
	printf '%s|0\n' "$off" > "$POSFILE"
	set_start "$(now)"
	printf '%s\n' "$url" > "$URLFILE"
}

do_pause() {
	if [ -z "$(pidof mpg123 2>/dev/null)" ]; then
		printf '{"ok":0,"msg":"nothing is playing"}\n'
		return
	fi
	if [ "$(pos_paused)" -gt 0 ] 2>/dev/null; then
		printf '{"ok":1,"paused":1}\n'
		return
	fi
	printf '%s|%s\n' "$(pos_base)" "$(now)" > "$POSFILE"
	kill -STOP $(pidof mpg123) >/dev/null 2>&1
	sp="$(stream_pids)"
	[ -n "$sp" ] && kill -STOP $sp >/dev/null 2>&1
	printf '{"ok":1,"paused":1}\n'
}

do_resume() {
	p="$(pos_paused)"
	if [ -z "$(pidof mpg123 2>/dev/null)" ]; then
		# stopped: start the same track again at the position it was left
		url="$(cur_url)"
		if [ -z "$url" ]; then
			printf '{"ok":0,"msg":"nothing to resume"}\n'
			return
		fi
		restart_stream "$(pos_base)" "$url"
		printf '{"ok":1,"paused":0,"pos":%s}\n' "$(pos_base)"
		return
	fi
	if is_num "$p" && [ "$p" -gt 0 ]; then
		st="$(pos_start)"
		is_num "$st" || st="$p"
		new=$(( $(pos_base) + p - st ))
		[ "$new" -lt 0 ] && new=0
		killall -9 mpg123 >/dev/null 2>&1
		sp="$(stream_pids)"
		[ -n "$sp" ] && kill -9 $sp >/dev/null 2>&1
		restart_stream "$new" "$(cur_url)"
		printf '{"ok":1,"paused":0,"pos":%s}\n' "$new"
		return
	fi
	printf '{"ok":1,"paused":0}\n'
}

do_seek() {
	d="$1"
	url="$(cur_url)"
	[ -z "$url" ] && { printf '{"ok":0,"msg":"nothing is playing"}\n'; return; }
	case "$d" in
		-*)
			sign=-1
			dn="$(printf '%s' "$d" | tr -d '-')"
			;;
		*)
			sign=1
			dn="$d"
			;;
	esac
	is_num "$dn" || dn=15
	d=$((sign * dn))
	pos="$(cur_pos)"
	is_num "$pos" || pos=0
	dur="$(current_dur)"
	is_num "$dur" || dur=0
	new=$((pos + d))
	[ "$new" -lt 0 ] && new=0
	if [ "$dur" -gt 0 ] && [ "$new" -ge "$dur" ]; then
		do_step 1
		return
	fi
	restart_stream "$new" "$url"
	printf '{"ok":1,"pos":%s,"dur":%s}\n' "$new" "$dur"
}

do_status() {
	url="$(head -n1 "$URLFILE" 2>/dev/null)"
	stateurl="$(cut -d '|' -f1 "$STATEFILE" 2>/dev/null)"
	playing=0
	if [ -n "$(pidof mpg123 2>/dev/null)" ]; then
		playing=1
	fi
	pos="$(cur_pos)"
	is_num "$pos" || pos=0
	[ "$pos" -lt 0 ] && pos=0
	if [ "$playing" = "0" ]; then
		pos=0
	fi
	paused=0
	if [ "$(pos_paused)" -gt 0 ] 2>/dev/null; then
		paused=1
	fi
	busy=0
	[ -f "$BUSYFILE" ] && busy=1
	if [ "$(page_src)" = "kuwo" ]; then
		chartv="$(uci_get webkuwolist)"
		chartn="$(uci_get webkuwoname)"
	else
		chartv="$(uci_get webkugoulist)"
		chartn="$(uci_get webkugoulistname)"
	fi
	qmd5="$(cut -d'|' -f1 "$QUEUE" 2>/dev/null | md5sum | cut -d' ' -f1)"
	totalfile="$QUEUE"
	[ -s "$totalfile" ] || totalfile="$LISTFILE"
	vol="$(mixer_vol)"
	is_num "$vol" || vol=0
	loop="$(head -n1 "$LOOPFILE" 2>/dev/null)"
	case "$loop" in
		off|list|one) ;;
		*) loop="off" ;;
	esac

	# the rest is assembled by a single awk: this board is slow enough that one
	# process per field made the 3 second status poll take seconds
	awk -v playing="$playing" -v pos="$pos" -v vol="$vol" -v loop="$loop" \
		-v url="$url" -v stateurl="$stateurl" -v paused="$paused" \
		-v src="$(page_src)" -v chart="$chartv" -v chartn="$chartn" \
		-v infofile="$INFOFILE" -v statefile="$STATEFILE" -v lrcfile="$LRCFILE" \
		-v lrckey="$LRCKEY" -v idxfile="$IDXFILE" -v listfile="$totalfile" -v qmd5="$qmd5" -v busy="$busy" \
		-v ktmp="/tmp/kugou.tmp.2" '
	function esc(s) { gsub(/"/, "", s); gsub(/\\/, "", s); gsub(/[\r\n\t]/, " ", s); return s }
	function lines(f,   n, l) { n = 0; while ((getline l < f) > 0) { n++; if (n > 5000) break }; close(f); return n }
	BEGIN {
		name = ""; hash = ""; dur = 0
		if (stateurl != "" && stateurl == url && (getline sline < statefile) > 0) {
			nf = split(sline, a, "|")
			hash = a[2]; dur = a[4] + 0
			name = ""
			for (i = 5; i <= nf; i++) {
				sep = (i > 5) ? "|" : ""
				name = name sep a[i]
			}
		}
		if (name == "" && (getline il < infofile) > 0) name = il
		close(infofile)
		gsub(/\r$/, "", name)
		if (name != "" && index(name, " - ") == 0) {
			p = index(name, "_")
			if (p > 0) name = substr(name, p + 1) " - " substr(name, 1, p - 1)
		}
		if (dur == 0 && (getline kl < ktmp) > 0 && match(kl, /"timeLength":[0-9]+/)) dur = substr(kl, RSTART + 13, RLENGTH - 13) + 0
		close(ktmp)
		lrc = 0
		if ((getline lk < lrckey) > 0) { gsub(/\r$/, "", lk); if (lk == name) lrc = 1 }
		close(lrckey)
		total = 0
		if ((getline tl < listfile) > 0) { close(listfile); total = lines(listfile) }
		idx = 0
		if ((getline il2 < idxfile) > 0) idx = il2 + 0
		close(idxfile)
		if (playing == 0) { name = ""; hash = ""; pos = 0; dur = 0; lrc = 0 }
		printf "{\"ok\":1,\"playing\":%d,\"name\":\"%s\",\"url\":\"%s\",\"hash\":\"%s\",\"pos\":%d,\"dur\":%d,\"paused\":%d,\"idx\":%d,\"total\":%d,\"lrc\":%d,\"vol\":%d,\"src\":\"%s\",\"chart\":\"%s\",\"chartn\":\"%s\",\"loop\":\"%s\",\"qmd5\":\"%s\",\"busy\":%d}\n", \
			playing, esc(name), url, hash, pos, dur, paused, idx, total, lrc, vol, esc(src), esc(chart), esc(chartn), loop, qmd5, busy
	}'
}

do_kuwo_songs() {
	sel="$(uci_get webkuwolist)"
	ids="$(kuwo_ids "$sel")"
	if [ -z "$ids" ]; then
		printf '{"ok":0,"msg":"no kuwo chart selected in the autodl settings"}\n'
		return
	fi
	cache="/tmp/kgweb.kw.$(printf '%s' "$sel" | tr -c 'a-zA-Z0-9' '_')"
	meta="$cache.meta"
	if [ "$1" != "force" ] && [ -s "$cache" ] && [ -s "$meta" ]; then
		age="$(mtime "$cache")"
		if is_num "$age" && [ $(( $(now) - age )) -lt 600 ]; then
			kuwo_apply_dur < "$cache" > "$WORK.emit"
			emit_list "$sel" 0 "$(cut -f1 "$meta")" "$WORK.emit" < "$WORK.emit"
			return
		fi
	fi
	: > "$WORK.raw"
	: > "$WORK.kwmem"
	for id in $ids; do
		get "${API_KUWO_BANG}${id}" | $KGJSON kuwobang | while IFS='|' read -r rid nm ar dmins pay; do
			[ -z "$rid" ] && continue
			is_num "$pay" || pay=0
			# pay 0xff.... means member only: kuwo hands out an 11 second sample
			if [ $((pay / 65536)) -eq 255 ]; then
				printf 'x\n' >> "$WORK.kwmem"
				continue
			fi
			printf 'kw:%s	%s - %s	0	0\n' "$rid" "$ar" "$nm"
		done >> "$WORK.raw"
	done
	awk -F'	' '!seen[$1]++' "$WORK.raw" > "$WORK.uniq"
	cp "$WORK.uniq" "$cache"
	kwhidden="$(wc -l < "$WORK.kwmem" 2>/dev/null | tr -d ' ')"
	is_num "$kwhidden" || kwhidden=0
	printf '%s\n' "$kwhidden" > "$meta"
	kuwo_apply_dur < "$cache" > "$WORK.emit"
	emit_list "$sel" 0 "$kwhidden" "$WORK.emit" < "$WORK.emit"
}

do_kuwo_search() {
	kw="$1"
	if [ -z "$kw" ]; then
		printf '{"ok":0,"msg":"empty keyword"}\n'
		return
	fi
	ckey="$(printf '%s' "$kw" | md5sum | cut -c1-16)"
	cache="/tmp/kgweb.kwsearch.$ckey"
	meta="$cache.meta"
	if [ -s "$cache" ] && [ -s "$meta" ]; then
		age="$(mtime "$cache")"
		if is_num "$age" && [ $(( $(now) - age )) -lt 300 ]; then
			kuwo_apply_dur < "$cache" > "$WORK.emit"
			emit_list "$kw" 0 "$(cut -f1 "$meta")" "$WORK.emit" < "$WORK.emit"
			return
		fi
	fi
	: > "$WORK.kwmem"
	get "${API_KUWO_SEARCH}$(printf '%s' "$kw" | $KGJSON urlenc)" | $KGJSON kuwosearch \
		| while IFS='|' read -r rid nm ar du pay; do
			[ -z "$rid" ] && continue
			is_num "$du" || du=0
			is_num "$pay" || pay=0
			if [ $((pay / 65536)) -eq 255 ]; then
				printf 'x\n' >> "$WORK.kwmem"
				continue
			fi
			printf 'kw:%s	%s - %s	%s	0\n' "$rid" "$ar" "$nm" "$du"
		done > "$WORK.raw"
	if [ ! -s "$WORK.raw" ]; then
		# everything found was member only: say how many were dropped
		kwhidden="$(wc -l < "$WORK.kwmem" 2>/dev/null | tr -d ' ')"
		is_num "$kwhidden" || kwhidden=0
		printf '{"ok":1,"chart":"%s","songs":[],"hidden":%s,"sub":0}\n' "$(jstr "$kw")" "$kwhidden"
		return
	fi
	awk -F'	' '!seen[$1]++' "$WORK.raw" > "$cache"
	kwhidden="$(wc -l < "$WORK.kwmem" 2>/dev/null | tr -d ' ')"
	is_num "$kwhidden" || kwhidden=0
	printf '%s\n' "$kwhidden" > "$meta"
	kuwo_apply_dur < "$cache" > "$WORK.emit"
	emit_list "$kw" 0 "$kwhidden" "$WORK.emit" < "$WORK.emit"
}

do_songs() {
	if [ "$(page_src)" = "kuwo" ]; then
		do_kuwo_songs "$1"
		return
	fi
	sel="$(uci_get webkugoulist)"
	ids="$(chart_ids "$sel")"
	if [ -z "$ids" ]; then
		printf '{"ok":0,"msg":"no kugou chart selected in the autodl settings"}\n'
		return
	fi

	cache="/tmp/kgweb.songs.$(printf '%s' "$sel" | tr -c 'a-zA-Z0-9' '_')"
	meta="$cache.meta"
	if [ "$1" != "force" ] && [ -s "$cache" ] && [ -s "$meta" ]; then
		age="$(mtime "$cache")"
		if is_num "$age" && [ $(( $(now) - age )) -lt 600 ]; then
			emit_list "$sel" 0 "$(cut -f1 "$meta")" "$cache" < "$cache"
			return
		fi
	fi

	if [ "$sel" = "all" ]; then
		pages="1"
	else
		pages="1 2 3 4"
	fi
	: > "$WORK.raw"
	for id in $ids; do
		for p in $pages; do
			get "${API_RANK}${id}&page=${p}" | $KGJSON rank >> "$WORK.raw"
		done
	done
	awk -F'\t' '!seen[$1]++' "$WORK.raw" > "$WORK.uniq"
	mv "$WORK.uniq" "$WORK.raw"

	cp "$WORK.raw" "$WORK.ok"
	hidden=0
	sort -u "$WORK.ok" > "$WORK.uniq"
	mv "$WORK.uniq" "$cache"
	printf '%s\n' "$hidden" > "$meta"
	emit_list "$sel" 0 "$hidden" "$cache" < "$cache"
}

do_search() {
	if [ "$(page_src)" = "kuwo" ]; then
		do_kuwo_search "$1"
		return
	fi
	kw="$1"
	if [ -z "$kw" ]; then
		printf '{"ok":0,"msg":"empty keyword"}\n'
		return
	fi
	ckey="$(printf '%s' "$kw" | md5sum | cut -c1-16)"
	cache="/tmp/kgweb.search.$ckey"
	if [ -s "$cache" ]; then
		age="$(mtime "$cache")"
		if is_num "$age" && [ $(( $(now) - age )) -lt 300 ]; then
			emit_list "$kw" 0 0 "$cache" < "$cache"
			return
		fi
	fi

	kwe="$(printf '%s' "$kw" | $KGJSON urlenc)"
	: > "$WORK.raw"
	for p in 1 2; do
		r="$(get "${API_SEARCH}${kwe}&page=${p}")"
		case "$r" in
			*'"errcode":1002'*|*"太频繁"*)
				printf '{"ok":0,"msg":"酷狗接口限流中，等 1-2 分钟再搜"}\n'
				return
				;;
		esac
		printf '%s' "$r" | $KGJSON search >> "$WORK.raw"
		if [ "$p" = "1" ]; then
			sleep 1
		fi
	done
	awk -F'\t' '!seen[$1]++' "$WORK.raw" > "$WORK.uniq"
	cp "$WORK.uniq" "$cache"
	emit_list "$kw" 0 0 "$cache" < "$cache"
}

do_play() {
	hash="$1"
	name="$2"
	idx="$3"
	case "$hash" in
		kw:[0-9]*)
			# kuwo track id
			;;
		*)
			if ! is_hash "$hash"; then
				printf '{"ok":0,"msg":"bad hash"}\n'
				return
			fi
			;;
	esac

	kill_players
	# remember which list this track belongs to *before* playing it: a member
	# only track cannot be played but next/prev must still walk its own list
	set_queue "$hash" "$idx"
	resolve "$hash" "$name"
	if [ -z "$RES_URL" ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') ${hash} not playable" >> "$PLAYERLOG"
		mark_dead "$hash"
		if [ -n "$RES_MSG" ]; then
			printf '{"ok":0,"msg":"%s"}\n' "$(jstr "$RES_MSG")"
		elif throttled; then
			printf '{"ok":0,"msg":"酷狗接口限流中（等 1-2 分钟再试）"}\n'
		else
			printf '{"ok":0,"msg":"no playable source for this track"}\n'
		fi
		return
	fi

	printf '%s|%s|%s|%s|%s\n' "$RES_URL" "$RES_HASH" "$(now)" "$RES_DUR" "$RES_NAME" > "$STATEFILE"
	if is_num "$idx" && [ "$idx" -gt 0 ]; then
		printf '%s\n' "$idx" > "$IDXFILE"
	fi
	printf '0|0\n' > "$POSFILE"
	printf '%s\n' "$RES_URL" > "$URLFILE"
	printf '%s\n' "$RES_INFO" > "$INFOFILE"
	start_player "$RES_URL"
	printf '{"ok":1,"hash":"%s","name":"%s","url":"%s","dur":%s}\n' \
		"$RES_HASH" "$(jstr "$RES_NAME")" "$RES_URL" "$RES_DUR"
}

# remember which list a track belongs to: a track of the custom playlist follows the
# playlist order, anything else the list it was picked from. KEEPQ=1 means we are
# stepping inside the queue already, so only the index is refreshed.
set_queue() {
	if [ "$KEEPQ" = "1" ]; then
		# stepping inside the queue: the index is written by do_play only when
		# the track really starts, so a skipped one cannot move it
		return 0
	fi
	: > "$WORK.qidx"
	if [ -f "$PLIST" ] && [ -s "$PLIST" ]; then
		awk -F'\t' -v h="$(printf '%s' "$1" | tr 'A-Z' 'a-z')" -v qf="$WORK.qidx" '
			BEGIN { OFS = "|" }
			length($1) == 32 && $2 != "" {
				n++
				if (tolower($1) == h) hit = n
				print $1, $2
			}
			END { if (hit > 0) printf "%d\n", hit > qf; close(qf) }' "$PLIST" > "$WORK.q" 2>/dev/null
	fi
	if [ -s "$WORK.qidx" ]; then
		cp "$WORK.q" "$QUEUE"
		cp "$WORK.qidx" "$IDXFILE"
	elif [ -s "$LISTFILE" ]; then
		cp "$LISTFILE" "$QUEUE"
		if is_num "$2" && [ "$2" -gt 0 ]; then
			printf '%s\n' "$2" > "$IDXFILE"
		fi
	fi
}

do_stop() {
	kill_players
	rm -f "$STATEFILE"
	printf '{"ok":1}\n'
}

do_step() {
	step="$1"
	reflist="$QUEUE"
	[ -s "$reflist" ] || reflist="$LISTFILE"
	total="$(wc -l < "$reflist" | tr -d ' ')"
	if [ "$total" -lt 1 ]; then
		printf '{"ok":0,"msg":"playlist empty"}\n'
		return
	fi
	idx="$(current_idx)"
	tries=0
	out=""
	while [ "$tries" -lt 3 ]; do
		idx=$((idx + step))
		if [ "$idx" -lt 1 ]; then idx=$total; fi
		if [ "$idx" -gt "$total" ]; then idx=1; fi
		line="$(sed -n "${idx}p" "$reflist")"
		[ -z "$line" ] && break
		if dead_recent "${line%%|*}"; then
			tries=$((tries + 1))
			continue
		fi
		KEEPQ=1
		out="$(do_play "${line%%|*}" "${line#*|}" "$idx")"
		case "$out" in
			*'"ok":1'*)
				printf '%s\n' "$out"
				return
				;;
		esac
		# unplayable (member only preview for example): continue in the same direction
		tries=$((tries + 1))
	done
	printf '%s\n' "${out:-{\"ok\":0,\"msg\":\"nothing playable in this direction\"}}"
}

do_play_idx() {
	i="$1"
	total="$(current_total)"
	if [ "$total" -lt 1 ]; then
		printf '{"ok":0,"msg":"playlist empty"}\n'
		return
	fi
	is_num "$i" || i=1
	if [ "$i" -lt 1 ]; then i=1; fi
	if [ "$i" -gt "$total" ]; then i=$total; fi
	line="$(sed -n "${i}p" "$LISTFILE")"
	do_play "${line%%|*}" "${line#*|}" "$i"
}

do_lyrics() {
	key="$1"
	force="$2"
	[ -z "$key" ] && key="$(cur_name)"
	[ -z "$key" ] && return
	if [ "$force" != "force" ] && [ "$(head -n1 "$LRCKEY" 2>/dev/null)" = "$key" ]; then
		cat "$LRCFILE"
		return
	fi

	: > "$WORK.lrcq"
	# exact hash first: the keyword search of krcs answers empty for many
	# perfectly normal songs, the hash lookup almost always hits
	kh="$(cur_hash)"
	if is_hash "$kh"; then
		get "${API_LRCQ_HASH}$kh" | $KGJSON lrcq > "$WORK.lrcq"
	fi
	if [ ! -s "$WORK.lrcq" ]; then
		lrcq_url="${API_LRCQ}$(printf '%s' "$key" | sed 's/_/ /g;s/ - / /g;s/|/ /g' | $KGJSON urlenc)"
		get "$lrcq_url" | $KGJSON lrcq > "$WORK.lrcq"
		rtries=0
		while [ ! -s "$WORK.lrcq" ] && [ "$rtries" -lt 2 ]; do
			rtries=$((rtries + 1))
			sleep 2
			get "$lrcq_url" | $KGJSON lrcq > "$WORK.lrcq"
		done
	fi

	durnow="$(cur_dur_ms)"
	: > "$WORK.lcand"
	while IFS= read -r line; do
		cid="$(printf '%s' "$line" | cut -f1)"
		cak="$(printf '%s' "$line" | cut -f2)"
		cd="$(printf '%s' "$line" | cut -f3)"
		is_num "$cid" || continue
		[ -z "$cak" ] && continue
		is_num "$cd" || cd=0
		diff="$cd"
		if [ "$durnow" -gt 0 ]; then
			diff=$((cd > durnow ? cd - durnow : durnow - cd))
		fi
		printf '%06d|%s|%s\n' "$diff" "$cid" "$cak" >> "$WORK.lcand"
	done < "$WORK.lrcq"

	# nearest duration first, and keep trying the next candidate if one of them
	# answers with an empty file (the lyric service is not always consistent)
	sort "$WORK.lcand" > "$WORK.lcand.s"
	: > "$LRCFILE"
	tries=0
	while IFS='|' read -r ddiff cid cak; do
		tries=$((tries + 1))
		if [ "$tries" -gt 3 ]; then
			break
		fi
		get "${API_LRCG}id=${cid}&accesskey=${cak}" | $KGJSON lrcg | tr -d '\r' > "$WORK.lrc.try"
		if [ -s "$WORK.lrc.try" ]; then
			cp "$WORK.lrc.try" "$LRCFILE"
			break
		fi
	done < "$WORK.lcand.s"

	printf '%s' "$key" > "$LRCKEY"
	cat "$LRCFILE"
}

do_vol() {
	mode="$1"
	dev="$(mixer_dev)"
	cur="$(mixer_vol)"
	is_num "$cur" || cur=0
	if [ -n "$dev" ] && { [ "$mode" = "up" ] || [ "$mode" = "down" ]; }; then
		case "$mode" in
			up) n=$((cur + 10)) ;;
			down) n=$((cur - 10)) ;;
			*) n=$cur ;;
		esac
		if [ "$n" -gt 100 ]; then n=100; fi
		if [ "$n" -lt 0 ]; then n=0; fi
		amixer -q set "$dev" "${n}%" >/dev/null 2>&1
		cur="$(mixer_vol)"
		is_num "$cur" || cur=$n
	fi
	printf '{"ok":1,"dev":"%s","vol":%s}\n' "$(jstr "$dev")" "$cur"
}

# ---- url/name of the current track, for a download to the client -------------
do_charts() {
	if [ "$(page_src)" = "kuwo" ]; then
		printf '{"ok":1,"src":"kuwo","cur":"%s","charts":[' "$(uci_get webkuwolist)"
		first=1
		for e in "kuwo-soaring:kuwo soaring chart" "kuwo-hot:kuwo hot song chart" \
			"kuwo-new:kuwo new song chart" "kuwo-shortvideo:kuwo short video chart" \
			"kuwo-monthly:kuwo monthly new chart" "kuwo-cantonese:kuwo cantonese chart"; do
			if [ "$first" = "1" ]; then
				first=0
			else
				printf ","
			fi
			printf '{"id":"%s","n":"%s"}' "${e%%:*}" "${e#*:}"
		done
		printf ']}'
		return
	fi
	ck="/tmp/kgweb.charts"
	fresh=0
	if [ -s "$ck" ]; then
		a="$(mtime "$ck")"
		if is_num "$a" && [ $(( $(now) - a )) -lt 86400 ]; then
			fresh=1
		fi
	fi
	if [ "$fresh" = "0" ]; then
		raw="$(get "$API_RANKLIST")"
		case "$raw" in
			*'"errcode":1002'*|*"太频繁"*)
				printf '{"ok":0,"msg":"酷狗接口限流中，等 1-2 分钟再试"}\n'
				return
				;;
		esac
		printf '%s' "$raw" | $KGJSON ranks > "$ck"
	fi
	if [ ! -s "$ck" ]; then
		printf '{"ok":0,"msg":"没有取到榜单列表"}\n'
		return
	fi
	awk -F'\t' -v cur="$(uci_get webkugoulist)" '
		function esc(s) { gsub(/"/, "", s); gsub(/\\/, "", s); return s }
		BEGIN { printf "{\"ok\":1,\"cur\":\"%s\",\"charts\":[", esc(cur); first = 1 }
		{ if (!first) printf ","; first = 0; printf "{\"id\":\"%s\",\"n\":\"%s\"}", $1, esc($2) }
		END { print "]}" }' < "$ck"
}

do_setchart() {
	id="$1"
	name="$2"
	case "$id" in
		kuwo-*)
			case "$(kuwo_ids "$id")" in
				"") printf '{"ok":0,"msg":"bad kuwo chart"}\n'; return ;;
			esac
			uci set autodl.@autodl[0].webkuwolist="$id" && uci set autodl.@autodl[0].webkuwoname="$name" && uci commit autodl || {
				printf '{"ok":0,"msg":"uci write failed"}\n'
				return
			}
			rm -f /tmp/kgweb.kw.*
			printf '{"ok":1,"id":"%s"}\n' "$id"
			return
			;;
	esac
	case "$id" in
		[0-9]*) ;;
		*) printf '{"ok":0,"msg":"bad chart id"}\n'; return ;;
	esac
	uci set autodl.@autodl[0].webkugoulist="$id" && uci set autodl.@autodl[0].webkugoulistname="$name" && uci commit autodl || {
		printf '{"ok":0,"msg":"uci write failed"}\n'
		return
	}
	rm -f /tmp/kgweb.songs.*
	printf '{"ok":1,"id":"%s"}\n' "$id"
}

# fill in missing kuwo durations, a few per call (called from the page in the
# background; durations do not change, so the cache is permanent)
do_durs() {
	list="$LISTFILE"
	if [ ! -s "$list" ]; then
		printf '{"ok":1,"filled":0,"left":0,"durs":{}}\n'
		return
	fi
	: > "$WORK.kwdur.new"
	tried=0
	unknown=0
	while IFS='|' read -r h nm; do
		case "$h" in
			kw:*) ;;
			*) continue ;;
		esac
		rid="${h#kw:}"
		d="$(kuwo_dur_cached "$rid")"
		if is_num "$d" && [ "$d" -ge 0 ] 2>/dev/null; then
			continue
		fi
		unknown=$((unknown + 1))
		if [ "$tried" -ge 8 ]; then
			continue
		fi
		tried=$((tried + 1))
		d="$(kuwo_dur_api "$rid")"
		is_num "$d" || d=0
		kuwo_dur_store "$rid" "$d"
		if [ "$d" -gt 0 ]; then
			printf '%s|%s\n' "$rid" "$d" >> "$WORK.kwdur.new"
		fi
	done < "$list"
	left=$((unknown - tried))
	[ "$left" -lt 0 ] && left=0
	printf '{"ok":1,"filled":%d,"left":%d,"durs":{' "$tried" "$left"
	first=1
	while IFS='|' read -r r d; do
		if [ "$first" = "1" ]; then
			first=0
		else
			printf ","
		fi
		printf '"%s":%s' "$r" "$d"
	done < "$WORK.kwdur.new"
	printf '}}\n'
}

do_setsrc() {
	case "$1" in
		kuwo|kugou) ;;
		*) printf '{"ok":0,"msg":"bad source"}\n'; return ;;
	esac
	uci set autodl.@autodl[0].webpagesrc="$1" && uci commit autodl || {
		printf '{"ok":0,"msg":"uci write failed"}\n'
		return
	}
	rm -f /tmp/kgweb.kw.* /tmp/kgweb.songs.*
	printf '{"ok":1,"src":"%s"}\n' "$1"
}

do_saveurl() {
	u="$(cur_url)"
	case "$u" in
		http://*|https://*) ;;
		*) u="" ;;
	esac
	printf '%s\n' "$u"
}

do_savename() {
	n="$(head -n1 "$INFOFILE" 2>/dev/null)"
	case "$n" in
		*_*) ;;
		*) n="" ;;
	esac
	[ -z "$n" ] && n="kugou_$(date +%Y%m%d-%H%M%S)"
	printf '%s\n' "$(printf '%s' "$n" | tr -d '/\\:*?"<>|').mp3"
}

# ---- loop mode --------------------------------------------------------------
do_loop() {
	m="$(head -n1 "$LOOPFILE" 2>/dev/null)"
	case "$m" in
		off|list|one) ;;
		*) m="off" ;;
	esac
	case "$1" in
		off|list|one) m="$1" ;;
		*)
			case "$m" in
				off) m="list" ;;
				list) m="one" ;;
				one) m="off" ;;
			esac
			;;
	esac
	printf '%s' "$m" > "$LOOPFILE"
	printf '{"ok":1,"loop":"%s"}\n' "$m"
}

# ---- custom playlist (persistent) -------------------------------------------
pl_clean() {
	# stdin -> stdout, keeps only valid "hash<TAB>name<TAB>dur" lines
	awk -F'	' 'length($1) == 32 && $1 ~ /^[0-9A-Fa-f]+$/ && $2 != "" { printf "%s	%s	%d\n", $1, $2, $3 + 0 }'
}

do_pladd() {
	h="$1"
	n="$2"
	d="$3"
	if ! is_hash "$h"; then
		printf '{"ok":0,"msg":"bad hash"}\n'
		return
	fi
	[ -z "$n" ] && n="$h"
	is_num "$d" || d=0
	[ -f "$PLIST" ] || : > "$PLIST"
	if grep -q "^${h}$(printf '	')" "$PLIST" 2>/dev/null; then
		printf '{"ok":1,"msg":"already in playlist","count":%s}\n' "$(wc -l < "$PLIST" | tr -d ' ')"
		return
	fi
	printf '%s	%s	%s\n' "$h" "$n" "$d" >> "$PLIST"
	printf '{"ok":1,"msg":"added","count":%s}\n' "$(wc -l < "$PLIST" | tr -d ' ')"
}

do_pldel() {
	h="$1"
	if ! is_hash "$h"; then
		printf '{"ok":0,"msg":"bad hash"}\n'
		return
	fi
	if [ -f "$PLIST" ]; then
		grep -v "^${h}$(printf '	')" "$PLIST" > "$WORK.pl" 2>/dev/null
		cp "$WORK.pl" "$PLIST"
	fi
	printf '{"ok":1,"count":%s}\n' "$(wc -l < "$PLIST" 2>/dev/null | tr -d ' ')"
}

do_plclear() {
	: > "$PLIST"
	printf '{"ok":1,"count":0}\n'
}

do_plist() {
	if [ -s "$PLIST" ]; then
		pl_clean < "$PLIST" > "$WORK.raw"
		emit_list "playlist" 0 0 "$WORK.raw" < "$WORK.raw"
	else
		printf '{"ok":1,"chart":"playlist","songs":[]}\n'
	fi
}

case "$1" in
	status) do_status ;;
	songs) do_songs "$2" ;;
	search) do_search "$2" ;;
	play) do_play "$2" "$3" "$4" ;;
	stop) do_stop ;;
	pause) do_pause ;;
	resume) do_resume ;;
	seek) do_seek "$2" ;;
	next) do_step 1 ;;
	prev) do_step -1 ;;
	lyrics) do_lyrics "$2" "$3" ;;
	vol) do_vol "$2" ;;
	saveurl) do_saveurl ;;
	charts) do_charts "$2" ;;
	setchart) do_setchart "$2" "$3" ;;
	setsrc) do_setsrc "$2" ;;
	durs) do_durs ;;
	savename) do_savename ;;
	loop) do_loop "$2" ;;
	plist) do_plist ;;
	plstart) do_play_idx "$2" ;;
	pladd) do_pladd "$2" "$3" "$4" ;;
	pldel) do_pldel "$2" ;;
	plclear) do_plclear ;;
	*) printf '{"ok":0,"msg":"unknown action"}\n' ;;
esac
