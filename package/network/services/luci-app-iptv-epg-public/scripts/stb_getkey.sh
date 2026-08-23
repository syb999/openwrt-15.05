#!/bin/sh
# stb_getkey.sh — 从 IPTV 机顶盒提取 EPG 认证 RSA 私钥 (ADB)
# 原理: 机顶盒认证 funcportalauth 时本地用私钥签名 stbinfo → 私钥必然在机顶盒系统里
# 用法:
#   adb connect <机顶盒IP>:5555
#   ./stb_getkey.sh
# 输出: ./iptv_epg_rsa.pem (验证通过后)
OUT=iptv_epg_rsa.pem
TMPD=/tmp/stbkey_scan
rm -rf "$TMPD"; mkdir -p "$TMPD"

echo "== 确保 root =="
adb root 2>/dev/null
adb wait-for-device 2>/dev/null
adb shell "id" 2>/dev/null | grep -q uid=0 || echo "警告: 非 root, 部分目录不可读"

echo "== 1. 直接搜索 PRIVATE KEY 文件 =="
adb shell "grep -rl 'BEGIN PRIVATE KEY' /data /system /mnt /sdcard 2>/dev/null" 2>/dev/null | head -20 > "$TMPD/hits.txt"
cat "$TMPD/hits.txt"
echo "== 2. 搜索常见密钥文件名 =="
adb shell "find /data /system /mnt /sdcard -name '*.pem' -o -name '*.key' -o -name '*.pkcs8' -o -name '*.priv' -o -name '*auth*key*' 2>/dev/null" 2>/dev/null | head -20 > "$TMPD/cands.txt"
cat "$TMPD/cands.txt"

echo "== 3. 拉取并验证 =="
FOUND=""
for F in $(cat "$TMPD/hits.txt" "$TMPD/cands.txt" | sort -u | head -40); do
  adb pull "$F" "$TMPD/file" 2>/dev/null
  # 文件可能含多个候选, 提取 BEGIN PRIVATE KEY 块
  if grep -q 'BEGIN PRIVATE KEY' "$TMPD/file" 2>/dev/null; then
    awk '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/' "$TMPD/file" > "$TMPD/pem" 2>/dev/null
    if openssl rsa -in "$TMPD/pem" -check -noout 2>/dev/null; then
      cp "$TMPD/pem" "$OUT"
      echo "✓ 私钥提取成功: $OUT (来自 $F)"
      openssl rsa -in "$OUT" -check -noout 2>/dev/null
      exit 0
    fi
  fi
  rm -f "$TMPD/file"
done

echo "== 4. 未直接找到, 扫描认证 APK =="
adb shell "pm list packages 2>/dev/null" 2>/dev/null | grep -iE 'auth|epg|iptv|zte|ctv|vod|media' | head -10 > "$TMPD/pkgs.txt"
cat "$TMPD/pkgs.txt"
for P in $(sed 's/package://' "$TMPD/pkgs.txt" | head -5); do
  APK=$(adb shell "pm path $P 2>/dev/null" | sed 's/package://' | head -1)
  [ -z "$APK" ] && continue
  echo "  检查 $P ($APK)"
  adb pull "$APK" "$TMPD/app.apk" 2>/dev/null
  # 解包搜 key (unzip 可用时)
  if command -v unzip >/dev/null 2>&1; then
    unzip -l "$TMPD/app.apk" 2>/dev/null | grep -iE '\.pem|\.key|\.pkcs8|\.priv|auth' | head -10
  fi
  # 直接 strings 搜 apk
  strings "$TMPD/app.apk" 2>/dev/null | grep -B1 -A1 'BEGIN PRIVATE KEY' | head -5
  rm -f "$TMPD/app.apk"
done

echo "== 结果 =="
[ -f "$OUT" ] && { echo "✓ 已生成 $OUT, 部署: scp $OUT root@路由器:/etc/iptv_epg_rsa.pem"; exit 0; }
echo "✗ 未找到私钥。可能位置: 认证APK的 assets/so, /data/zte/conf/。"
echo "  可手动: adb shell 'ls /data/zte/conf/' 查看配置文件"
exit 1
