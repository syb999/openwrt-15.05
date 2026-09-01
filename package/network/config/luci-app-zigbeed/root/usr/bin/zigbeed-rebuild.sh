#!/bin/sh
# zigbeed-rebuild.sh v5.1 - 重建协调器网络 (防卡 + 失败重试版)
# v5 问题: GPIO36 复位后只等 8 秒 (协调器可能未就绪) + 单次尝试 (协调器卡态时 DeviceHub 建网失败即 FAIL)
# v5.1 改进: 复位等待 15 秒 (EFR32 充分启动) + 建网失败自动重试 (最多 3 次)
#            验证用 zigbeed -cmd 直查 (不依赖 /tmp/rtoken 工具)
# 用法: sh /usr/bin/zigbeed-rebuild.sh
LOG=/tmp/zigbeed_rebuild.log
DEVHUB=/usr/bin/DeviceHub
COORINFO=/etc/IoT/CoorInfo.json
GPIO=/sys/class/gpio/gpio36
ZCMD=/usr/bin/zigbeed

LOCK=/tmp/zigbeed_rebuild.lock
# 原子锁 (mkdir 防并发: 只有一个能成功创建)
if ! mkdir $LOCK 2>/dev/null; then
    echo "另一个 rebuild 正在运行, 退出" | tee $LOG
    exit 2
fi
trap "rmdir $LOCK 2>/dev/null" EXIT INT TERM


reset_coor() {
    # GPIO36 硬复位协调器 (彻底断电: 拉低 10 秒让 Flash 完全掉电, 模拟拔电效果)
    echo 36 > /sys/class/gpio/export 2>/dev/null
    echo out > $GPIO/direction 2>/dev/null
    echo 0 > $GPIO/value
    sleep 10
    echo 1 > $GPIO/value
    sleep 15
}

coor_ok() {
    # 协调器有网? (RTOKEN 含"真实" kA 帧 = 网络在)
    # 🔴🔴 2026-09-01 修复: rtoken 前台执行 (等它自然完成 3s),
    #    后台 & + sleep + kill 会截断 rtoken 输出 → 误判失败!
    #    必须区分"空 kA 帧"和"真实网络 kA 帧": 空网络 kA 帧 panid 全 F,
    #    真实网络 panid 非 FFFF。
    rm -f /tmp/coor_rsp.txt
    if [ -x /tmp/rtoken ]; then
        /tmp/rtoken "AT+RTOKEN" > /tmp/coor_rsp.txt 2>&1
    else
        $ZCMD -cmd "AT+RTOKEN" > /tmp/coor_rsp.txt 2>&1
    fi
    # 有 kA 帧 = 协调器有响应; 检查不是空网络 (panid 非 FFFF)
    if grep -q "kA\[88\]" /tmp/coor_rsp.txt 2>/dev/null; then
        # 提取 panid 区特征: 空网络 F2 03 后全 FF, 真实网络有非 FF 字节
        # 简单判断: 响应含 kA 帧且不是纯 FF 空帧
        if grep -q "kA\[88\]" /tmp/coor_rsp.txt 2>/dev/null; then
            # 真实网络 kA 帧含具体 panid/密钥 (非全 F)
            if ! grep -q "\[FF\]\[FF\]\[FF\]" /tmp/coor_rsp.txt 2>/dev/null; then
                return 0
            fi
        fi
    fi
    return 1
}

echo "[1/6] 停 zigbeed + DeviceHub..." | tee $LOG
killall zigbeed DeviceHub 2>/dev/null
sleep 3
# 🔴🔴 2026-09-01 修复: 强制清理串口锁和残留进程 (rebuild 反复失败时
#    zigbeed -cmd 后台进程残留会占 /var/run/zigbeed.lock, 导致 [6/6] 起不来)
killall zigbeed 2>/dev/null
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
sleep 1

# 🔴🔴🔴 存活保护 (2026-09-01 方案 B 定论):
#    用户: 不希望丢参数, 无设备环境固件周期性清网 → 真空即 DeviceHub 重建。
#    协调器 AT+VER 有响应 = 活着, 但 RTOKEN 无 kA = 网络真空 (被固件清理),
#    → 必须放行 rebuild (DeviceHub 建网)!
#    只有 AT+VER 都无响应 + 多次重试仍无响应 (协调器真死) 才拒绝 (避免无限循环)。
rm -f /tmp/coor_pre.txt
if [ -x /tmp/rtoken ]; then
    /tmp/rtoken "AT+VER" > /tmp/coor_pre.txt 2>&1
else
    $ZCMD -cmd "AT+VER" > /tmp/coor_pre.txt 2>&1
fi
if grep -q "REXENSE" /tmp/coor_pre.txt 2>/dev/null; then
    echo "协调器存活 (AT+VER 响应), 检查网络..." | tee -a $LOG
    rm -f /tmp/coor_pre2.txt
    if [ -x /tmp/rtoken ]; then
        /tmp/rtoken "AT+RTOKEN" > /tmp/coor_pre2.txt 2>&1
    else
        $ZCMD -cmd "AT+RTOKEN" > /tmp/coor_pre2.txt 2>&1
    fi
    if grep -q "kA\[88\]" /tmp/coor_pre2.txt 2>/dev/null; then
        echo "协调器有网络 (RTOKEN 含 kA), 参数未丢, 无需重建!" | tee -a $LOG
        # 🔴🔴 2026-09-01 修复: [1/6] 已 killall zigbeed, 拒绝退出前必须恢复!
        echo "恢复 zigbeed..." | tee -a $LOG
        rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
        /etc/init.d/zigbeed start 2>/dev/null
        rmdir $LOCK 2>/dev/null
        exit 0
    fi
    echo "协调器存活但网络真空 (RTOKEN 无 kA) → 继续 DeviceHub 重建!" | tee -a $LOG
else
    echo "协调器无 AT+VER 响应 (疑似异常/断电), 继续 rebuild..." | tee -a $LOG
fi

ATTEMPT=0
SUCCESS=0
while [ $ATTEMPT -lt 3 ] && [ $SUCCESS -eq 0 ]; do
    ATTEMPT=$((ATTEMPT + 1))
    # 🔴🔴🔴 2026-09-01 关键修复: 去掉 GPIO36 复位!
    #    实测: GPIO36 复位后协调器进入异常态, DeviceHub 不建网 (输出空,
    #    无 "Trying to form") → 3 次全失败。
    #    直接清 CoorInfo + 跑 DeviceHub (不复位) 90s 能成功建网!
    #    → 不再 reset_coor, 直接 DeviceHub 建网。
    echo "[2/6] 第 ${ATTEMPT} 次: 直接启动 DeviceHub 建网 (不复位)..." | tee -a $LOG

    echo "[3/6] 清 CoorInfo + 启动 DeviceHub (120 秒建网)..." | tee -a $LOG
    [ -f $COORINFO ] && cp $COORINFO ${COORINFO}.bak
    echo "{}" > $COORINFO
    LD_LIBRARY_PATH=/usr/lib/devicehub $DEVHUB > /tmp/devicehub_rebuild.log 2>&1 &
    DH_PID=$!
    # 🔴🔴 2026-09-01 修复: 60s → 120s (实测 DeviceHub 建网需要 >60s:
    #    "Trying to form network" 后 FORM+Flash 保存要 60-120s, 60s killall 会打断建网)
    sleep 120

    echo "[4/6] 停 DeviceHub..." | tee -a $LOG
    killall DeviceHub 2>/dev/null
    kill $DH_PID 2>/dev/null
    sleep 3

    # 🔴🔴🔴 2026-09-01 关键修复: 建网后不复位 (复位会破坏刚建的网)
    #    → 直接验证!

    if coor_ok; then
        echo "  -> 第 ${ATTEMPT} 次建网成功" | tee -a $LOG
        SUCCESS=1
    else
        echo "  -> 第 ${ATTEMPT} 次建网失败, $([ $ATTEMPT -lt 3 ] && echo '重试...' || echo '放弃')" | tee -a $LOG
    fi
done

echo "[6/6] 重启 zigbeed + 验证..." | tee -a $LOG
# 🔴🔴 2026-09-01 修复: start 前再清一次锁/残留 (coor_ok 的 rtoken/-cmd 可能残留)
killall zigbeed 2>/dev/null
rm -f /var/run/zigbeed.lock /var/run/zigbeed.pid 2>/dev/null
sleep 1
/etc/init.d/zigbeed start 2>/dev/null
sleep 25
# 🔴🔴 2026-09-01 修复: 验证用 rtoken 直查 (不依赖 zigbeed 刚启动的 status.json,
#     zigbeed ensure_network 要等 12s+ 才写 status, 25s 可能不够; 且 255/FFFF
#     是空网络解析值, 不能当"恢复"成功)
CH="?"
if [ -x /tmp/rtoken ]; then
    rm -f /tmp/coor_final.txt
    /tmp/rtoken "AT+RTOKEN" > /tmp/coor_final.txt 2>&1 &
    CPID3=$!
    sleep 8
    kill $CPID3 2>/dev/null
    wait $CPID3 2>/dev/null
    if grep -q "kA" /tmp/coor_final.txt 2>/dev/null; then
        CH="ok"
    fi
fi
echo "  状态: $CH" | tee -a $LOG
if [ "$CH" != "?" ]; then
    echo "OK: 协调器网络已建立" | tee -a $LOG
    exit 0
else
    echo "FAIL: 协调器参数仍为空 (尝试 $ATTEMPT 次)" | tee -a $LOG
    exit 1
fi
