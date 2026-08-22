#!/bin/sh
# epg_getkey.sh — 获取 EPG 认证 RSA 私钥 (多源, 不依赖 GitHub)
# 来源优先级:
#   ① LuCI 配置的直链 getkey_url (网盘/自建服务器直链 PEM, 国内可达)
#   ② GitHub git blobs API (原版私钥, 兜底)
# 用法: /usr/bin/epg_getkey.sh
RSAPEM=/etc/iptv_epg_rsa.pem
REPO=denymz/sh-tel-iptv-spider
BRANCH=main

# ---------- 源 ①: 配置直链 (直接下载 PEM) ----------
URL=$(uci get iptv_epg.main.getkey_url 2>/dev/null)
if [ -n "$URL" ]; then
  echo "== 从配置直链下载: $URL =="
  curl -s -m 20 "$URL" > "$RSAPEM" 2>/dev/null
  if openssl rsa -in "$RSAPEM" -check -noout 2>/dev/null; then
    chmod 600 "$RSAPEM"
    echo "OK: 私钥已部署 $RSAPEM ($(wc -c < "$RSAPEM") 字节)"
    exit 0
  else
    rm -f "$RSAPEM"
    echo "警告: 直链下载的私钥无效, 尝试 GitHub 源..."
  fi
fi

# ---------- 源 ②: GitHub git blobs API (原版私钥, 免 git) ----------
echo "== 从 GitHub 提取 (api.github.com) =="
CMTSHA=$(curl -s -m 10 "https://api.github.com/repos/$REPO/commits/$BRANCH" | grep -oE '"sha": "[a-f0-9]{40}"' | head -1 | cut -d'"' -f4)
[ -z "$CMTSHA" ] && { echo "ERR: GitHub 不可达 (可配置 getkey_url 直链, 或手动放置 $RSAPEM)"; exit 1; }
TREE=$(curl -s -m 15 "https://api.github.com/repos/$REPO/git/trees/$CMTSHA?recursive=1")
BLOBSHA=$(echo "$TREE" | awk 'BEGIN{RS="},"} /utils\/rsa\.go/{print}' | grep -oE '"sha": "[a-f0-9]{40}"' | head -1 | cut -d'"' -f4)
[ -z "$BLOBSHA" ] && { echo "ERR: 未找到 utils/rsa.go"; exit 1; }
CONTENT=$(curl -s -m 15 "https://api.github.com/repos/$REPO/git/blobs/$BLOBSHA" | sed -n 's/.*"content": "\([^"]*\)".*/\1/p')
echo "$CONTENT" | sed 's/\\n/\n/g' | base64 -d 2>/dev/null | sed -n '/const priKey/,/^`/p' | sed 's/const priKey = `//;s/`$//' > "$RSAPEM"
if openssl rsa -in "$RSAPEM" -check -noout 2>/dev/null; then
  chmod 600 "$RSAPEM"
  echo "OK: 私钥已部署 $RSAPEM ($(wc -c < "$RSAPEM") 字节)"
  exit 0
else
  rm -f "$RSAPEM"
  echo "ERR: 私钥提取失败 (可配置 getkey_url 直链, 或手动放置 $RSAPEM)"
  exit 1
fi
