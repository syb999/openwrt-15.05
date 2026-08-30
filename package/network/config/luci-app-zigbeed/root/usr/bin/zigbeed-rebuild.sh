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
    # 协调器有网? (RTOKEN 含 kA 帧 = 网络在)
    # busybox 无 timeout: 后台执行 + sleep + kill 防 zigbeed -cmd 卡住
    rm -f /tmp/coor_rsp.txt
    $ZCMD -cmd "AT+RTOKEN" > /tmp/coor_rsp.txt 2>&1 &
    local CPID=$!
    sleep 12
    kill $CPID 2>/dev/null
    wait $CPID 2>/dev/null
    grep -q "kA" /tmp/coor_rsp.txt
}

echo "[1/6] 停 zigbeed + DeviceHub..." | tee $LOG
killall zigbeed DeviceHub 2>/dev/null
sleep 3

ATTEMPT=0
SUCCESS=0
while [ $ATTEMPT -lt 3 ] && [ $SUCCESS -eq 0 ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "[2/6] 第 ${ATTEMPT} 次: GPIO36 硬复位协调器..." | tee -a $LOG
    reset_coor

    echo "[3/6] 清 CoorInfo + 启动 DeviceHub (60 秒建网)..." | tee -a $LOG
    [ -f $COORINFO ] && cp $COORINFO ${COORINFO}.bak
    echo "{}" > $COORINFO
    LD_LIBRARY_PATH=/usr/lib/devicehub $DEVHUB > /tmp/devicehub_rebuild.log 2>&1 &
    DH_PID=$!
    sleep 60

    echo "[4/6] 停 DeviceHub..." | tee -a $LOG
    killall DeviceHub 2>/dev/null
    kill $DH_PID 2>/dev/null
    sleep 3

    echo "[5/6] GPIO36 再复位 + AT+RESTORE 恢复 Flash..." | tee -a $LOG
    reset_coor

    if coor_ok; then
        echo "  -> 第 ${ATTEMPT} 次建网成功" | tee -a $LOG
        SUCCESS=1
    else
        echo "  -> 第 ${ATTEMPT} 次建网失败, $([ $ATTEMPT -lt 3 ] && echo '重试...' || echo '放弃')" | tee -a $LOG
    fi
done

echo "[6/6] 重启 zigbeed + 验证..." | tee -a $LOG
/etc/init.d/zigbeed start 2>/dev/null
sleep 25
CH=$(grep -o '"channel": "[^"]*"' /tmp/zigbeed_status.json 2>/dev/null | head -1 | cut -d'"' -f4)
echo "  状态: $CH" | tee -a $LOG
if [ -n "$CH" ] && [ "$CH" != "?" ]; then
    echo "OK: 协调器参数恢复 \"$CH\"" | tee -a $LOG
    exit 0
else
    echo "FAIL: 协调器参数仍为空 (尝试 $ATTEMPT 次)" | tee -a $LOG
    exit 1
fi
