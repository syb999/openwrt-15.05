/*
 * zigbeed.c - 独立 Zigbee 网关守护进程 (替代原厂 DeviceHub)
 * 硬件: MT7688 + EFR32MG1B 协调器 @ /dev/ttyS1 115200
 * 复位: GPIO36 (拉低复位, 拉高运行)
 *
 * 功能:
 *   - 初始化协调器 (GPIO36 复位 + AT 握手)
 *   - 建网/查网 (AT+VER/SHOWADDR/SCANCHMASK/SETCH/SETPID/SETEXPID/SETNWKKEY)
 *   - 配对窗口 (JSON {"Duration":"N"})
 *   - 设备枚举 (解析 *xA 88 帧)
 *   - 设备控制 (JSON State/Level/HUE/Saturation 等)
 *   - CLI 交互模式 + 后台守护模式
 *
 * 用法:
 *   zigbeed                    # 守护模式
 *   zigbeed -c                 # CLI 交互模式
 *   zigbeed -cmd 'AT+VER'      # 单条命令
 *   zigbeed -json '{"Duration":"60"}'  # 单条 JSON
 *
 * 编译: mipsel-openwrt-linux-uclibc-gcc -std=gnu99 -static -o zigbeed zigbeed.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>
#include <time.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/types.h>
#include "zigbeed_mqtt.h"
#include "dev_models.h"

#define TTY_DEV     "/dev/ttyS1"
#define TTY_BAUD    115200
#define GPIO_RST    "/sys/class/gpio/gpio36"
#define RESP_MAX    8192

static int tty_fd = -1;
static volatile int running = 1;
static const char *g_dev = TTY_DEV;
static int g_baud = TTY_BAUD;

static void msleep(int ms) { usleep(ms * 1000); }

/* ---------- GPIO36 复位 ---------- */
static void gpio_write(const char *path, const char *val)
{
    int fd = open(path, O_WRONLY);
    if (fd < 0) { perror(path); return; }
    write(fd, val, strlen(val));
    close(fd);
}

static void reset_coordinator(void)
{
    gpio_write("/sys/class/gpio/export", "36");
    msleep(100);
    gpio_write(GPIO_RST "/direction", "out");
    msleep(50);
    gpio_write(GPIO_RST "/value", "0");   /* 拉低复位 */
    msleep(300);
    gpio_write(GPIO_RST "/value", "1");   /* 拉高运行 */
    msleep(800);
}

/* ---------- 串口 ---------- */
static int open_serial(const char *dev, int baud)
{
    int fd = open(dev, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd < 0) { perror("open serial"); return -1; }
    struct termios t;
    memset(&t, 0, sizeof(t));
    tcgetattr(fd, &t);
    cfmakeraw(&t);
    t.c_cflag &= ~(CSIZE | PARENB | CSTOPB);
    t.c_cflag |= CS8 | CLOCAL | CREAD;
    speed_t sp;
    switch (baud) {
        case 9600:   sp = B9600; break;
        case 19200:  sp = B19200; break;
        case 38400:  sp = B38400; break;
        case 57600:  sp = B57600; break;
        case 115200: sp = B115200; break;
        default:     sp = B115200;
    }
    cfsetispeed(&t, sp);
    cfsetospeed(&t, sp);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 2;
    tcsetattr(fd, TCSANOW, &t);
    tcflush(fd, TCIOFLUSH);
    return fd;
}

/* ---------- 命令收发 ---------- */
/* 串口收发日志 (诊断: 定位协调器何时/如何出错) */
static FILE *g_slog = NULL;

/* 🔴🔴 独立会话命令 (2026-09-01 根治"守护进程读不到 kA"):
   协调器固件对"长会话重复 RTOKEN"只回 Default 段 (330/441B 无 kA),
   但每次"新串口会话"的 RTOKEN 返回完整响应 (Default + *kA 网络参数)。
   实测: rtoken/-cmd (短会话) 每次都能读到 kA, 守护进程 (长会话) 读不到。
   → 轮询用独立 fd 打开串口 (模拟短会话) 发命令, 读完关闭。
   flock 与 serve 子进程的 tty_fd 互斥, 安全。 */
static int send_cmd_session(const char *cmd, char *resp, int rlen, int wait_s)
{
    /* 🔴🔴 2026-09-01 修复: SESS 用阻塞 fd (和 rtoken 一致)!
       之前 open_serial 用 O_NONBLOCK — 协调器固件对非阻塞串口会话
       响应行为不同 (read 立即 EAGAIN, 多段响应间隔长时错过 kA 帧)。
       实测: rtoken (阻塞) 每次能读到 kA, zigbeed SESS (非阻塞) 读不到 →
       channel 永远 "?" → 误判真空 → 误触发 rebuild!
       → 独立短会话必须用阻塞 fd。 */
    int pfd = open(g_dev, O_RDWR | O_NOCTTY);
    if (pfd < 0) {
        /* 🔴🔴 外部占用容错: 串口被外部工具 (rtoken/minicom/echo) 占用时
           open/配置可能失败 — 记录并返回 -1, 调用方跳过本次轮询不累计 miss */
        if (g_slog) {
            fprintf(g_slog, "[%ld] SESS !! 串口打开失败 (外部占用?), 跳过本次\n", (long)time(NULL));
            fflush(g_slog);
        }
        return -1;
    }
    /* 配置串口 (阻塞模式, 与 rtoken 一致) */
    struct termios t;
    memset(&t, 0, sizeof(t));
    tcgetattr(pfd, &t);
    cfmakeraw(&t);
    t.c_cflag &= ~(CSIZE | PARENB | CSTOPB);
    t.c_cflag |= CS8 | CLOCAL | CREAD;
    speed_t sp;
    switch (g_baud) {
        case 9600:   sp = B9600; break;
        case 19200:  sp = B19200; break;
        case 38400:  sp = B38400; break;
        case 57600:  sp = B57600; break;
        case 115200: sp = B115200; break;
        default:     sp = B115200;
    }
    cfsetispeed(&t, sp);
    cfsetospeed(&t, sp);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 2;
    tcsetattr(pfd, TCSANOW, &t);
    /* 串口互斥锁: 与 serve 子进程的 tty_fd flock 互斥 */
    flock(pfd, LOCK_EX);
    tcflush(pfd, TCIOFLUSH);
    if (!g_slog) g_slog = fopen("/tmp/zigbeed_serial.log", "a");
    if (g_slog) {
        fprintf(g_slog, "[%ld] SESS-TX: %s", (long)time(NULL), cmd);
        fflush(g_slog);
    }
    int n = write(pfd, cmd, strlen(cmd));
    if (n < 0) { perror("write"); close(pfd); return -1; }
    int total = 0;
    time_t start = time(NULL);
    while (total < rlen - 1 && time(NULL) - start < wait_s) {
        int r = read(pfd, resp + total, rlen - 1 - total);
        if (r > 0) total += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
        else msleep(10);
    }
    resp[total] = 0;
    if (g_slog) {
        int show = total > 160 ? 160 : total;
        fprintf(g_slog, "[%ld] SESS-RX(%d): %.*s\n", (long)time(NULL), total, show, resp);
        if (total <= 0)
            fprintf(g_slog, "[%ld] !! SESS 无响应/超时 (%s)\n", (long)time(NULL), cmd);
        fflush(g_slog);
    }
    flock(pfd, LOCK_UN);
    close(pfd);
    return total;
}

/* 发送命令并读取响应 (最长 wait_s 秒), 返回字节数 */
static int send_cmd(const char *cmd, char *resp, int rlen, int wait_s)
{
    /* 串口互斥锁: 多模式 (serve子进程/mqtt/daemon) 共享 ttyS1 */
    flock(tty_fd, LOCK_EX);
    /* 🔴🔴 修复 (异步 kA 帧被 tcflush 冲掉):
       协调器会异步推送 *kA 网络参数帧 (如会话建立后 ~10s), 原代码
       tcflush(TCIOFLUSH) 在发命令前清空接收缓冲 → kA 被冲掉 →
       守护进程永远读不到 kA → channel 永远 "?" (出厂信任网络误判丢)。
       → 先非阻塞读一次缓冲 (捕获已推送的 kA), 再 tcflush + 发命令。 */
    char prebuf[512];
    int pren = read(tty_fd, prebuf, sizeof(prebuf) - 1);
    if (pren > 0) {
        prebuf[pren] = 0;
        if (g_slog) {
            fprintf(g_slog, "[%ld] PRE-RX(%d): %.*s\n", (long)time(NULL), pren, pren > 160 ? 160 : pren, prebuf);
            fflush(g_slog);
        }
        /* 预读有数据 (含异步 kA) → 作为响应前缀, 继续发命令读完整响应 */
        int total = pren;
        if (total >= rlen) total = rlen - 1;
        memcpy(resp, prebuf, total);
        tcflush(tty_fd, TCIOFLUSH);
        if (!g_slog) g_slog = fopen("/tmp/zigbeed_serial.log", "a");
        if (g_slog) {
            fprintf(g_slog, "[%ld] TX: %s", (long)time(NULL), cmd);
            fflush(g_slog);
        }
        int n = write(tty_fd, cmd, strlen(cmd));
        if (n < 0) { perror("write"); return -1; }
        time_t start = time(NULL);
        while (total < rlen - 1 && time(NULL) - start < wait_s) {
            int r = read(tty_fd, resp + total, rlen - 1 - total);
            if (r > 0) total += r;
            else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
            else msleep(10);
        }
        resp[total] = 0;
        if (g_slog) {
            int show = total > 160 ? 160 : total;
            fprintf(g_slog, "[%ld] RX(%d): %.*s\n", (long)time(NULL), total, show, resp);
            if (total <= 0)
                fprintf(g_slog, "[%ld] !! 无响应/超时 (%s)\n", (long)time(NULL), cmd);
            else if (strstr(resp, "Default configuration restored") && !strstr(resp, "kA"))
                fprintf(g_slog, "[%ld] !! 网络参数空 (Default, 无 kA) - %s\n", (long)time(NULL), cmd);
            fflush(g_slog);
        }
        flock(tty_fd, LOCK_UN);
        return total;
    }
    tcflush(tty_fd, TCIOFLUSH);
    if (!g_slog) g_slog = fopen("/tmp/zigbeed_serial.log", "a");
    if (g_slog) {
        fprintf(g_slog, "[%ld] TX: %s", (long)time(NULL), cmd);
        fflush(g_slog);
    }
    int n = write(tty_fd, cmd, strlen(cmd));
    if (n < 0) { perror("write"); return -1; }
    int total = 0;
    time_t start = time(NULL);
    while (total < rlen - 1 && time(NULL) - start < wait_s) {
        int r = read(tty_fd, resp + total, rlen - 1 - total);
        if (r > 0) total += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
        else msleep(10);  /* 非阻塞无数据, 让出 CPU */
    }
    resp[total] = 0;
    if (g_slog) {
        int show = total > 160 ? 160 : total;
        fprintf(g_slog, "[%ld] RX(%d): %.*s\n", (long)time(NULL), total, show, resp);
        if (total <= 0)
            fprintf(g_slog, "[%ld] !! 无响应/超时 (%s)\n", (long)time(NULL), cmd);
        else if (strstr(resp, "Default configuration restored") && !strstr(resp, "kA"))
            fprintf(g_slog, "[%ld] !! 网络参数空 (Default, 无 kA) - %s\n", (long)time(NULL), cmd);
        fflush(g_slog);
    }
    flock(tty_fd, LOCK_UN);
    return total;
}

/* ---------- 响应打印 (ASCII + hex) ---------- */
static void print_resp(const char *resp, int n)
{
    for (int i = 0; i < n; i++) {
        unsigned char c = resp[i];
        if (c >= 0x20 && c < 0x7F) putchar(c);
        else if (c == 0x0D || c == 0x0A) putchar('\n');
        else printf("[%02X]", c);
    }
    printf("\n");
}

/* ---------- 初始化 ---------- */
/* 串口单实例锁: 防止多个 zigbeed 进程并发访问 ttyS1 (抢串口会导致协调器响应混乱/参数读成 ?) */
static int g_lock_fd = -1;
static int lock_serial(void)
{
    g_lock_fd = open("/var/run/zigbeed.lock", O_RDWR | O_CREAT, 0644);
    if (g_lock_fd < 0) return -1;
    if (flock(g_lock_fd, LOCK_EX | LOCK_NB) != 0) {
        fprintf(stderr, "[锁] 另一个 zigbeed 进程正在访问串口 (/var/run/zigbeed.lock)\n");
        fprintf(stderr, "[锁] 单次命令请先停止守护进程: killall zigbeed; 再重试\n");
        return -1;
    }
    return 0;
}

static int init_gateway(void)
{
    char resp[RESP_MAX];

    /* 获取串口独占锁 (守护进程持锁常驻, 单次命令拿不到锁则退出) */
    if (lock_serial() < 0) return -1;

    /* 先打开串口, 尝试直接握手 (不复位, 避免搞乱已建好的网络) */
    tty_fd = open_serial(g_dev, g_baud);
    if (tty_fd < 0) return -1;

    /* AT+VER 重试 3 次 (协调器可能忙/串口有残留, 避免误判复位破坏网络) */
    int n = 0;
    for (int attempt = 0; attempt < 3; attempt++) {
        if (attempt > 0) msleep(1000);  /* 重试间隔 */
        n = send_cmd("AT+VER\r\n", resp, sizeof(resp), 3);
        if (n > 0 && strstr(resp, "REXENSE")) break;
    }
    if (n <= 0 || !strstr(resp, "REXENSE")) {
        /* 3 次都失败, 才 GPIO36 复位重试 (保守: 复位可能影响已建网络) */
        fprintf(stderr, "协调器 3 次握手失败, 执行 GPIO36 复位...\n");
        close(tty_fd);
        reset_coordinator();
        tty_fd = open_serial(g_dev, g_baud);
        if (tty_fd < 0) return -1;
        n = send_cmd("AT+VER\r\n", resp, sizeof(resp), 3);
        if (n <= 0 || !strstr(resp, "REXENSE")) {
            fprintf(stderr, "协调器握手失败 (AT+VER 无响应)\n");
            return -1;
        }
    }
    printf("[OK] 协调器: ");
    /* 提取版本行 */
    char *p = strstr(resp, "REXENSE");
    if (p) { char *e = strchr(p, '\r'); if (e) *e = 0; printf("%s\n", p); }
    else printf("%s\n", resp);

    /* 查询地址 */
    n = send_cmd("AT+SHOWADDR\r\n", resp, sizeof(resp), 3);
    if (n > 0) {
        char *m = strstr(resp, "MAC=");
        if (m) { char *e = strchr(m, '\r'); if (e) *e = 0; printf("[OK] %s\n", m); }
    }
    return 0;
}


/* 前向声明 */
static void write_status_json(const char *resp, int n);

/* ---------- 自建网 ---------- */
/* 协调器参数丢失时, 用配置/默认参数重建网络
 * 命令序列: SETCH + SETPID + SETEXPID + SETNWKKEY + FORM
 */
static int form_network(const char *channel, const char *panid,
                        const char *extpanid, const char *nwkkey)
{
    char resp[RESP_MAX];
    char cmd[256];

    printf("[建网] 使用 channel=%s panid=%s extpanid=%s\n", channel, panid, extpanid);
    fflush(stdout);

    /* 设置信道 */
    snprintf(cmd, sizeof(cmd), "AT+SETCH=%s\r\n", channel);
    send_cmd(cmd, resp, sizeof(resp), 2);
    msleep(200);

    /* 设置 PAN ID */
    snprintf(cmd, sizeof(cmd), "AT+SETPID=%s\r\n", panid);
    send_cmd(cmd, resp, sizeof(resp), 2);
    msleep(200);

    /* 设置扩展 PAN ID */
    if (extpanid && extpanid[0]) {
        snprintf(cmd, sizeof(cmd), "AT+SETEXPID=%s\r\n", extpanid);
        send_cmd(cmd, resp, sizeof(resp), 2);
        msleep(200);
    }

    /* 设置网络密钥 */
    if (nwkkey && nwkkey[0]) {
        snprintf(cmd, sizeof(cmd), "AT+SETNWKKEY=%s\r\n", nwkkey);
        send_cmd(cmd, resp, sizeof(resp), 2);
        msleep(200);
    }

    /* 建网 */
    snprintf(cmd, sizeof(cmd), "AT+FORM\r\n");
    int n = send_cmd(cmd, resp, sizeof(resp), 5);
    printf("[建网] AT+FORM 响应 %d 字节\n", n);
    fflush(stdout);
    msleep(1500);

    /* 验证 */
    n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
    if (n > 0) {
        write_status_json(resp, n);
        FILE *f = fopen("/tmp/zigbeed_status.json", "r");
        char body[1024];
        int bl = 0;
        if (f) { bl = fread(body, 1, sizeof(body)-1, f); fclose(f); }
        body[bl] = 0;
        printf("%s\n", body);
        fflush(stdout);
        if (strstr(body, "\"channel\": \"?")) return 1;
        return 0;
    }
    return 1;
}

/* 检查协调器网络参数是否有效 (只读检查, 绝不自动干预) */
static int ensure_network(void)
{
    char resp[RESP_MAX];

    /* 🔴🔴 关键: 协调器在串口会话建立后 ~10s 才异步推送 *kA 网络参数帧
       (实测: 会话建立后第一次 AT+SHOWADDR RX(197) 含 kA, 之后轮询不带)。
       启动后先等 12s 让 kA 推送到达, send_cmd 的 PRE-RX 预读能捕获它。 */
    msleep(12000);
    /* 重试 3 次读取 (用独立短会话 RTOKEN — 长会话读不到 kA, 短会话能读到) */
    for (int attempt = 0; attempt < 3; attempt++) {
        int n = send_cmd_session("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
        if (n <= 0) { msleep(1000); continue; }

        write_status_json(resp, n);
        FILE *f = fopen("/tmp/zigbeed_status.json", "r");
        if (!f) return -1;
        char body[1024];
        int bl = fread(body, 1, sizeof(body)-1, f);
        fclose(f);
        body[bl] = 0;

        /* 参数正常, 无需任何操作 */
        if (!strstr(body, "\"channel\": \"?")) return 0;

        printf("[检测] 第 %d 次读取: 协调器网络参数为空, 重试...\n", attempt + 1);
        fflush(stdout);
        msleep(1500);
    }

    /* v16 铁律: 确认丢失也绝不自动 LEAVE/复位/起 DeviceHub — 只提示, 由用户手动"重建网络" */
    printf("[检测] 协调器网络参数丢失 (3 次读取为空)!\n");
    printf("[检测] 铁律: 不自动干预。请在 LuCI Settings/Status 页点击\"重建网络\"(临时起 DeviceHub 建网)。\n");
    fflush(stdout);
    return 0;
}

/* ---------- 配对窗口 ---------- */
static int allow_join(int seconds)
{
    char cmd[64], resp[RESP_MAX];
    snprintf(cmd, sizeof(cmd), "{\"Duration\":\"%d\"}\n", seconds);
    printf("[配对] 打开 %d 秒配对窗口\n", seconds);
    int n = send_cmd(cmd, resp, sizeof(resp), 3);
    print_resp(resp, n);
    return 0;
}

/* ---------- 设备枚举 (解析 *xA 88 帧) ---------- */
static void dump_device_table(const char *resp, int n)
{
    printf("[设备表]\n");
    int in_frame = 0;
    unsigned char frame[256];
    int flen = 0;
    int found = 0;
    for (int i = 0; i < n; i++) {
        unsigned char c = resp[i];
        if (c == '*' && i + 1 < n) {  /* 帧头 */
            in_frame = 1; flen = 0;
            frame[flen++] = c;
            continue;
        }
        if (in_frame) {
            if (c == '#' && flen > 5) {  /* 帧尾 */
                frame[flen++] = c;
                /* 解析: [0]* [1]t1 [2]t2 [3]0x88 [4-9]pad [10-17]MAC [18-27]pad [28-31]0x20B8 [32+]数据 */
                if (flen > 32) {
                    found++;
                    printf("  类型=*%c%c 协调器MAC=", frame[1], frame[2]);
                    for (int k = 17; k >= 10; k--) printf("%02X%s", frame[k], k > 10 ? ":" : "");
                    /* 数据区: 邻居槽位 D0 07 NN 00 XX */
                    if (frame[32] == 0xD0 && frame[33] == 0x07 && flen >= 37) {
                        printf(" 槽位=%d 状态=0x%02X", frame[34], frame[36]);
                    } else if (frame[32] == 0xF2 && frame[33] == 0x03) {
                        printf(" [网络参数块]");
                    } else if (frame[32] == 0x10 && frame[33] == 0x00) {
                        printf(" [版本块]");
                    } else {
                        printf(" [数据 0x%02X%02X...]", frame[32], frame[33]);
                    }
                    printf("\n");
                }
                in_frame = 0;
            } else if (flen < 255) {
                frame[flen++] = c;
            } else {
                in_frame = 0;
            }
        }
    }
    if (!found) printf("  (未解析到帧, 原始 %d 字节)\n", n);
}

/* ---------- 状态 JSON 输出 (供 LuCI/脚本读取) ---------- */
/* 解码协调器响应中的 *xA 88 帧, 输出 /tmp/zigbeed_status.json */
static void write_status_json(const char *resp, int n)
{
    FILE *f = fopen("/tmp/zigbeed_status.json", "w");
    if (!f) return;

    char coor_mac[64] = "unknown";
    char channel[8] = "?";
    char panid[8] = "?";
    char extpanid[32] = "?";
    char nwkkey[64] = "?";
    int neighbor_slots[8] = {0};
    int slot_cnt = 0;
    int coor_found = 0;

    int in_frame = 0;
    unsigned char frame[256];
    int flen = 0;
    for (int i = 0; i < n; i++) {
        unsigned char c = resp[i];
        if (c == '*' && i + 1 < n) { in_frame = 1; flen = 0; frame[flen++] = c; continue; }
        if (in_frame) {
            if (c == '#' && flen > 5) {
                frame[flen++] = c;
                if (flen > 32) {
                    /* 协调器 MAC @ [10..17] 小端 */
                    if (!coor_found) {
                        sprintf(coor_mac, "%02X:%02X:%02X:%02X:%02X:%02X:%02X:%02X",
                                frame[17], frame[16], frame[15], frame[14],
                                frame[13], frame[12], frame[11], frame[10]);
                        coor_found = 1;
                    }
                    /* *kA 网络参数块 — 🔴🔴 动态定位 F2 03!
                       2026-09-01 实测: 协调器 kA 帧的 F2 03 偏移不稳定
                       (有时 [31][32], 有时 [33][34], 差 2 字节 = 响应可能带
                       CRLF/前导差异) → 固定偏移必然出错!
                       → 在帧内扫描 F2 03, 找到后从该位置解析 (实测精确定位):
                       F2 03 之后: [0]=00 [1]=00 [2]=48 [3]=2C [4..11]=MAC
                       [12..13]=00 00 [14..15]=00 00? [16..17]=PANID 小端
                       [18..25]=扩展PANID [26..41]=网络密钥16B [42]=信道 */
                    for (int k = 3; k < flen - 44; k++) {
                        if (frame[k] == 0xF2 && frame[k+1] == 0x03
                            && k + 42 < flen) {
                            /* 🔴🔴 实测微调: 密钥 [k+25..40] 16B, 信道 [k+41]
                               (v18 用 [k+26..41] 密钥 + [k+42] 信道差 1:
                               密钥首字节吞了信道值, channel 少 1) */
                            sprintf(panid, "%02X%02X", frame[k+16], frame[k+15]);
                            sprintf(extpanid, "%02X%02X%02X%02X%02X%02X%02X%02X",
                                    frame[k+25], frame[k+24], frame[k+23], frame[k+22],
                                    frame[k+21], frame[k+20], frame[k+19], frame[k+18]);
                            sprintf(nwkkey, "%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                                    frame[k+40], frame[k+39], frame[k+38], frame[k+37],
                                    frame[k+36], frame[k+35], frame[k+34], frame[k+33],
                                    frame[k+32], frame[k+31], frame[k+30], frame[k+29],
                                    frame[k+28], frame[k+27], frame[k+26], frame[k+25]);
                            sprintf(channel, "%d", frame[k+41]);
                            break;
                        }
                    }
                    /* 邻居槽位: [32..35]=D0 07 NN 00 */
                    if (frame[32] == 0xD0 && frame[33] == 0x07 && flen >= 37) {
                        int slot = frame[34];
                        int st = frame[36];
                        if (slot >= 1 && slot <= 8) {
                            neighbor_slots[slot-1] = st;
                            if (slot > slot_cnt) slot_cnt = slot;
                        }
                    }
                }
                in_frame = 0;
            } else if (flen < 255) {
                frame[flen++] = c;
            } else in_frame = 0;
        }
    }

    fprintf(f, "{\n");
    fprintf(f, "  \"ts\": %ld,\n", (long)time(NULL));
    fprintf(f, "  \"coordinator_mac\": \"%s\",\n", coor_mac);
    fprintf(f, "  \"channel\": \"%s\",\n", channel);
    fprintf(f, "  \"panid\": \"%s\",\n", panid);
    fprintf(f, "  \"extpanid\": \"%s\",\n", extpanid);
    fprintf(f, "  \"network_key\": \"%s\",\n", nwkkey);
    fprintf(f, "  \"neighbor_slots\": [");
    for (int i = 0; i < slot_cnt; i++) {
        fprintf(f, "%s%d", i ? "," : "", neighbor_slots[i]);
    }
    fprintf(f, "],\n");
    fprintf(f, "  \"slot_count\": %d\n", slot_cnt);
    fprintf(f, "}\n");
    fclose(f);
    /* 🔴🔴 诊断: channel 解析失败 (?) 时保存原始响应供分析 */
    if (channel[0] == '?') {
        FILE *dbg = fopen("/tmp/zigbeed_raw_rx.txt", "w");
        if (dbg) {
            fwrite(resp, 1, n > 400 ? 400 : n, dbg);
            fclose(dbg);
        }
    }
    /* 🔴🔴 诊断: 每次解析都保存 (分析实际帧布局) */
    {
        FILE *dbg = fopen("/tmp/zigbeed_frame.txt", "w");
        if (dbg) {
            fwrite(resp, 1, n > 200 ? 200 : n, dbg);
            fclose(dbg);
        }
    }
}

/* ---------- 状态命令 ---------- */
static int status_cmd(void)
{
    char resp[RESP_MAX];
    int n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
    if (n <= 0) {
        printf("{\"error\": \"no response\"}\n");
        return 1;
    }
    write_status_json(resp, n);
    /* 打印状态文件内容 */
    FILE *f = fopen("/tmp/zigbeed_status.json", "r");
    if (f) {
        char buf[1024];
        size_t r;
        while ((r = fread(buf, 1, sizeof(buf), f)) > 0) fwrite(buf, 1, r, stdout);
        fclose(f);
    }
    return 0;
}


/* ---------- 设备自定义名称表 (/etc/zigbeed/devices.conf) ----------
 * 格式: <MAC或短地址> <名称>
 */
#define NAME_CONF "/etc/zigbeed/devices.conf"

static const char *dev_name_lookup(const char *key)
{
    static char namebuf[64];
    FILE *f = fopen(NAME_CONF, "r");
    if (!f) return NULL;
    char line[128];
    while (fgets(line, sizeof(line), f)) {
        char k[64], n[64];
        if (sscanf(line, "%63s %63[^\n]", k, n) == 2) {
            if (strcmp(k, key) == 0) {
                snprintf(namebuf, sizeof(namebuf), "%s", n);
                fclose(f);
                return namebuf;
            }
        }
    }
    fclose(f);
    return NULL;
}

/* 设置设备名称: zigbeed -devname <key> <name> */
static int devname_cmd(const char *key, const char *name)
{
    system("mkdir -p /etc/zigbeed 2>/dev/null");
    FILE *f = fopen(NAME_CONF, "a");
    if (!f) { printf("{\"devname\":false,\"error\":\"cannot open\"}\n"); return 1; }
    fprintf(f, "%s %s\n", key, name);
    fclose(f);
    printf("{\"devname\":true,\"key\":\"%s\",\"name\":\"%s\"}\n", key, name);
    return 0;
}

/* 设备类型名查找 (deviceModel.json 映射) */
static const char *dev_type_name(int model)
{
    for (int i = 0; DEV_MODELS[i].name; i++) {
        if (DEV_MODELS[i].model == model) return DEV_MODELS[i].name;
    }
    return NULL;
}

/* ---------- 设备列表 (解析邻居槽位, 输出 JSON) ---------- */
static int devices_cmd(void)
{
    char resp[RESP_MAX];
    int n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
    if (n <= 0) {
        printf("{\"error\": \"no response\"}\n");
        return 1;
    }

    FILE *f = fopen("/tmp/zigbeed_devices.json", "w");
    if (!f) return 1;

    /* 收集邻居槽位: D0 07 NN 00 状态 + 后续 FF 填充前的设备地址 */
    fprintf(f, "{\n");
    fprintf(f, "  \"ts\": %ld,\n", (long)time(NULL));
    fprintf(f, "  \"devices\": [\n");

    int in_frame = 0;
    unsigned char frame[256];
    int flen = 0;
    int dev_cnt = 0;
    int slot_seen[8] = {0};
    unsigned char slot_addr[8][8];
    int slot_addr_valid[8] = {0};

    for (int i = 0; i < n; i++) {
        unsigned char c = resp[i];
        if (c == '*' && i + 1 < n) { in_frame = 1; flen = 0; frame[flen++] = c; continue; }
        if (in_frame) {
            if (c == '#' && flen > 5) {
                frame[flen++] = c;
                if (flen > 32) {
                    /* 邻居槽位帧: [32..35]=D0 07 NN 00, [36]=状态 */
                    if (frame[32] == 0xD0 && frame[33] == 0x07 && flen >= 37) {
                        int slot = frame[34];
                        int st = frame[36];
                        if (slot >= 1 && slot <= 8) {
                            slot_seen[slot-1] = st;
                            /* 槽位后可能跟设备短地址 (FF 前), 从 [37..] 找非 FF 数据 */
                            for (int k = 37; k + 1 < flen; k++) {
                                if (frame[k] != 0xFF && frame[k] != 0x00) {
                                    /* 短地址 2 字节 (小端) */
                                    slot_addr[slot-1][0] = frame[k];
                                    slot_addr[slot-1][1] = frame[k+1];
                                    slot_addr_valid[slot-1] = 1;
                                    break;
                                }
                            }
                        }
                    }
                }
                in_frame = 0;
            } else if (flen < 255) {
                frame[flen++] = c;
            } else in_frame = 0;
        }
    }

    /* 邻居槽位帧里的"状态值"是空槽位标记, 不是设备地址。
       原厂看设备靠 REX_DEVICE_JOIN 事件 (设备入网时协调器推送)。
       这里只输出槽位占用情况, 提示需设备入网事件确认。 */
    for (int i = 0; i < 8; i++) {
        if (slot_seen[i]) {
            if (dev_cnt) fprintf(f, ",\n");
            fprintf(f, "    {\"slot\": %d, \"slot_status\": %d", i+1, slot_seen[i]);
            fprintf(f, ", \"occupied\": %s", slot_seen[i] != 0 ? "true" : "false");
            fprintf(f, ", \"note\": \"neighbor-slot\"");
            /* 尝试匹配自定义名称: 短地址或槽位号 */
            const char *nm = NULL;
            char keybuf[32];
            snprintf(keybuf, sizeof(keybuf), "slot%d", i+1);
            nm = dev_name_lookup(keybuf);
            if (nm) fprintf(f, ", \"name\": \"%s\"", nm);
            /* 尝试匹配设备类型 (slot_status 高位可能是设备类型码) */
            const char *tn = dev_type_name(slot_seen[i]);
            if (tn) fprintf(f, ", \"type\": \"%s\"", tn);
            fprintf(f, "}");
            dev_cnt++;
        }
    }
    if (dev_cnt == 0) {
        fprintf(f, "    {\"slot\": 0, \"slot_status\": 0, \"occupied\": false, \"note\": \"none\"}");
        dev_cnt = 1;
    }
    fprintf(f, "\n  ],\n");
    fprintf(f, "  \"count\": %d\n", dev_cnt);
    fprintf(f, "}\n");
    fclose(f);

    FILE *out = fopen("/tmp/zigbeed_devices.json", "r");
    if (out) {
        char buf[1024];
        size_t r;
        while ((r = fread(buf, 1, sizeof(buf), out)) > 0) fwrite(buf, 1, r, stdout);
        fclose(out);
    }
    return 0;
}

/* ---------- 设备控制 (发送 JSON 控制命令) ---------- */
/* 用法: zigbeed -control '<json>' */

/* 设备数检查: 无已入网设备时拒绝控制命令
   (协调器固件对无设备时的 JSON 控制命令有 bug, 可能触发配置恢复) */
static int has_devices(void)
{
    FILE *f = fopen("/tmp/zigbeed_devices.json", "r");
    if (!f) return 0;
    char buf[1024];
    size_t r = fread(buf, 1, sizeof(buf) - 1, f);
    fclose(f);
    buf[r] = 0;
    return strstr(buf, "\"occupied\": true") != NULL;
}
static int control_cmd(const char *json)
{
    char cmd[512], resp[RESP_MAX];
    /* 同步缓冲 */
    send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
    msleep(200);
    tcflush(tty_fd, TCIOFLUSH);

    snprintf(cmd, sizeof(cmd), "%s\n", json);
    printf("{\"cmd\": \"%s\"}\n", json);
    int n = send_cmd(cmd, resp, sizeof(resp), 6);
    /* 输出响应 (ASCII 可读 + 截断) */
    printf("{\"resp_len\": %d, \"resp\": \"", n);
    for (int i = 0; i < n && i < 400; i++) {
        unsigned char c = resp[i];
        if (c >= 0x20 && c < 0x7F && c != '"' && c != '\\') putchar(c);
        else if (c == '\r' || c == '\n') printf("\\n");
        else printf("\\x%02X", c);
    }
    printf("\"}\n");
    return 0;
}

/* ---------- CLI ---------- */
static void cli_loop(void)
{
    char line[256], resp[RESP_MAX];
    printf("\nZigbee 网关 CLI (输入命令, quit 退出)\n");
    printf("  支持: AT+XXX / JSON / help / devices / join <秒>\n");
    for (;;) {
        printf("zigbee> "); fflush(stdout);
        if (!fgets(line, sizeof(line), stdin)) break;
        line[strcspn(line, "\n")] = 0;
        if (!strcmp(line, "quit") || !strcmp(line, "exit")) break;
        if (!strcmp(line, "help")) {
            printf("  AT+VER / AT+SHOWADDR / AT+SCANCHMASK=07FFF800\n");
            printf("  join 60        打开配对窗口\n");
            printf("  devices        枚举设备\n");
            printf("  state 1        开关控制 (State=1)\n");
            printf("  level 128      亮度控制\n");
            printf("  hue 100        色调\n");
            printf("  sat 200        饱和度\n");
            printf("  json {...}     发送 JSON 命令\n");
            continue;
        }
        if (!strcmp(line, "devices")) {
            int n = send_cmd("AT+SHOWADDR\r\n", resp, sizeof(resp), 3);
            dump_device_table(resp, n);
            continue;
        }
        if (!strncmp(line, "join", 4)) {
            int s = atoi(line + 5);
            allow_join(s > 0 ? s : 60);
            continue;
        }
        if (!strncmp(line, "state", 5)) {
            char cmd[64];
            snprintf(cmd, sizeof(cmd), "{\"State\":\"%s\"}\n", line + 6);
            int n = send_cmd(cmd, resp, sizeof(resp), 3);
            print_resp(resp, n);
            continue;
        }
        if (!strncmp(line, "level", 5)) {
            char cmd[64];
            snprintf(cmd, sizeof(cmd), "{\"Level\":\"%s\"}\n", line + 6);
            int n = send_cmd(cmd, resp, sizeof(resp), 3);
            print_resp(resp, n);
            continue;
        }
        if (!strncmp(line, "hue", 3)) {
            char cmd[64];
            snprintf(cmd, sizeof(cmd), "{\"HUE\":\"%s\"}\n", line + 4);
            int n = send_cmd(cmd, resp, sizeof(resp), 3);
            print_resp(resp, n);
            continue;
        }
        if (!strncmp(line, "sat", 3)) {
            char cmd[64];
            snprintf(cmd, sizeof(cmd), "{\"Saturation\":\"%s\"}\n", line + 4);
            int n = send_cmd(cmd, resp, sizeof(resp), 3);
            print_resp(resp, n);
            continue;
        }
        if (!strncmp(line, "json", 4)) {
            char cmd[256];
            snprintf(cmd, sizeof(cmd), "%s\n", line + 5);
            int n = send_cmd(cmd, resp, sizeof(resp), 4);
            print_resp(resp, n);
            continue;
        }
        /* 默认当 AT 命令发 */
        char cmd[256];
        snprintf(cmd, sizeof(cmd), "%s\r\n", line);
        int n = send_cmd(cmd, resp, sizeof(resp), 3);
        print_resp(resp, n);
    }
}


/* ---------- 配对模式: 开窗口 + 持续监听设备加入 ---------- */
/* 用法: zigbeed -pair <秒> */
static int pair_cmd(int seconds)
{
    char resp[RESP_MAX];
    unsigned char buf[2048];

    printf("[配对] 打开 %d 秒配对窗口, 监听设备加入...\n", seconds);

    /* 全信道扫描 (小米/涂鸦等设备可能在任意 Zigbee 信道) */
    send_cmd("AT+SCANCHMASK=07FFF800\r\n", resp, sizeof(resp), 3);
    msleep(200);

    /* 开配对窗口 */
    char cmd[64];
    snprintf(cmd, sizeof(cmd), "{\"Duration\":\"%d\"}\n", seconds);
    int n = send_cmd(cmd, resp, sizeof(resp), 3);
    printf("[配对] 窗口命令已发送 (%d 字节响应)\n", n);

    /* 持续监听串口, 捕获协调器推送 */
    int found = 0;
    unsigned char acc[512];
    int acc_len = 0;
    time_t start = time(NULL);
    printf("[配对] 监听中, 请将设备置于配对模式...\n");
    fflush(stdout);

    while (time(NULL) - start < seconds) {
        int r = read(tty_fd, buf, sizeof(buf));
        if (r > 0) {
            for (int i = 0; i < r; i++) {
                unsigned char c = buf[i];
                if (c == 0x0D || c == 0x0A) {
                    if (acc_len >= 4) {
                        /* 检查是否含设备 MAC (非协调器 MAC 的 *xA 帧或 ASCII 报告) */
                        /* 简单输出捕获内容 */
                        printf("[配对] 帧(%d): ", acc_len);
                        for (int k = 0; k < acc_len && k < 60; k++) {
                            unsigned char cc = acc[k];
                            if (cc >= 0x20 && cc < 0x7F) putchar(cc);
                            else printf("[%02X]", cc);
                        }
                        printf("\n");
                        fflush(stdout);
                        found++;
                    }
                    acc_len = 0;
                } else if (c >= 0x20 && c < 0x7F) {
                    if (acc_len < 500) acc[acc_len++] = c;
                } else {
                    if (acc_len < 500) acc[acc_len++] = c;
                }
            }
        } else {
            msleep(50);
        }
    }
    printf("[配对] 结束: 捕获 %d 个数据块%s\n", found,
           found ? ", 有新设备数据!" : ", 无设备加入 (确认设备已进入配对模式)");

    /* 关窗口 */
    send_cmd("{\"Duration\":\"0\"}\n", resp, sizeof(resp), 2);
    return 0;
}




/* ---------- HTTP 服务模式 (跨网关互联用) ---------- */
/* 用法: zigbeed -serve <port>
 * GET /status          -> 本机状态 JSON
 * GET /devices         -> 本机设备 JSON
 * GET /pair?sec=60     -> 打开配对窗口
 * GET /control/<urljson> -> 控制命令 (URL 编码 JSON)
 */
#include <sys/socket.h>
#include <sys/file.h>
#include <netinet/in.h>
#include <arpa/inet.h>

static void http_send(int fd, const char *body)
{
    char hdr[512];
    int blen = strlen(body);
    snprintf(hdr, sizeof(hdr),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n", blen);
    write(fd, hdr, strlen(hdr));
    write(fd, body, blen);
}

static void http_send_error(int fd, int code, const char *msg)
{
    char hdr[512];
    snprintf(hdr, sizeof(hdr),
        "HTTP/1.1 %d %s\r\n"
        "Content-Type: text/plain\r\n"
        "Content-Length: %d\r\n"
        "Connection: close\r\n"
        "\r\n", code, msg, (int)strlen(msg));
    write(fd, hdr, strlen(hdr));
    write(fd, msg, strlen(msg));
}

static void url_decode(char *dst, const char *src)
{
    int i = 0, j = 0;
    while (src[i]) {
        if (src[i] == '%' && i + 2 < (int)strlen(src)) {
            char hex[3] = {src[i+1], src[i+2], 0};
            dst[j++] = (char)strtol(hex, NULL, 16);
            i += 3;
        } else {
            dst[j++] = src[i++];
        }
    }
    dst[j] = 0;
}


/* 前向声明 */
static int serve_loop(int port);
static int mqtt_loop(const char *host, int port);
static void daemon_loop(void);

/* ================= 单进程 select 架构 (serve + mqtt 共存, 不 fork) ================= */
/* 关键: 串口命令在主循环内同步执行, 天然串行, 避免并发冲突 */

/* 创建 HTTP 监听 socket */
static int serve_create_listener(int port)
{
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0) return -1;
    int opt = 1;
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(lfd); return -1; }
    listen(lfd, 8);
    printf("[HTTP] 监听 0.0.0.0:%d\n", port);
    fflush(stdout);
    return lfd;
}

/* 处理单个 HTTP 连接 (同步, 在主循环内调用) */
static void serve_handle_conn(int cfd)
{
    char req[1024];
    int got = 0;
    time_t start = time(NULL);
    while (got < sizeof(req) - 1 && time(NULL) - start < 3) {
        int r = read(cfd, req + got, 1);
        if (r > 0) {
            got++;
            if (got >= 4 && req[got-4]=='\r' && req[got-3]=='\n'
                && req[got-2]=='\r' && req[got-1]=='\n') break;
        } else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
        else msleep(2);
    }
    req[got] = 0;

    char method[16], path[512];
    if (sscanf(req, "%15s %511s", method, path) == 2) {
        char resp[RESP_MAX];
        if (strncmp(path, "/status", 7) == 0) {
            /* 读主进程轮询的状态文件 (不直接发 AT, 避免频繁请求搞乱协调器) */
            char body[2048];
            FILE *f = fopen("/tmp/zigbeed_status.json", "r");
            int bl = 0;
            if (f) { bl = fread(body, 1, sizeof(body)-1, f); fclose(f); }
            if (bl > 0) { body[bl] = 0; http_send(cfd, body); }
            else http_send_error(cfd, 500, "{\"error\":\"status not ready\"}");
        } else if (strncmp(path, "/devices", 8) == 0) {
            /* 读设备文件 (由主进程轮询生成) */
            char body[2048];
            FILE *f = fopen("/tmp/zigbeed_devices.json", "r");
            int bl = 0;
            if (f) { bl = fread(body, 1, sizeof(body)-1, f); fclose(f); }
            if (bl > 0) { body[bl] = 0; http_send(cfd, body); }
            else http_send_error(cfd, 500, "{\"error\":\"devices not ready\"}");
        } else if (strncmp(path, "/pair", 5) == 0) {
            int sec = 60;
            char *p = strstr(path, "sec=");
            if (p) sec = atoi(p + 4);
            if (sec < 0) sec = 0;
            if (sec > 600) sec = 600;
            char cmd[64];
            snprintf(cmd, sizeof(cmd), "{\"Duration\":\"%d\"}\n", sec);
            /* 先同步串口缓冲 (防残留数据导致命令错乱) */
            send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
            msleep(150);
            tcflush(tty_fd, TCIOFLUSH);
            int n = send_cmd(cmd, resp, sizeof(resp), 3);
            char body[256];
            snprintf(body, sizeof(body), "{\"pair\":true,\"sec\":%d,\"resp_len\":%d}", sec, n);
            http_send(cfd, body);
        } else if (strncmp(path, "/control/", 9) == 0) {
            if (!has_devices()) {
                http_send(cfd, "{\"control\":false,\"error\":\"no devices joined\"}");
                close(cfd);
                return;
            }
            char jcmd[512];
            url_decode(jcmd, path + 9);
            char cmd[544];
            snprintf(cmd, sizeof(cmd), "%s\n", jcmd);
            send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
            msleep(150);
            tcflush(tty_fd, TCIOFLUSH);
            int n = send_cmd(cmd, resp, sizeof(resp), 5);
            char body[1024];
            snprintf(body, sizeof(body), "{\"control\":true,\"cmd\":\"%s\",\"resp_len\":%d}", jcmd, n);
            http_send(cfd, body);
        } else if (strncmp(path, "/ping", 5) == 0) {
            http_send(cfd, "{\"pong\":true}");
        } else {
            http_send_error(cfd, 404, "not found");
        }
    }
    close(cfd);
}

/* 前向声明: JSON 解析 helper + discovery (定义在 mqtt_loop 前) */
static int json_get_int(const char *msg, const char *key);
static void json_get_str(const char *msg, const char *key, char *out, int outlen);
static void mqtt_publish_all_discovery(mqtt_client *cli);

/* 主循环: select 调度 serve + mqtt + 周期轮询 */
/* 自动恢复: 轮询连续读空 → 自动 v5 rebuild (防循环: 文件时间戳 10 分钟间隔) */
static time_t get_last_auto_rebuild(void)
{
    FILE *f = fopen("/tmp/zigbeed_auto_rebuild.ts", "r");
    time_t t = 0;
    if (f) { fscanf(f, "%ld", &t); fclose(f); }
    return t;
}
static void set_last_auto_rebuild(time_t t)
{
    FILE *f = fopen("/tmp/zigbeed_auto_rebuild.ts", "w");
    if (f) { fprintf(f, "%ld", (long)t); fclose(f); }
}

/* 轮询主循环 (5s): 生成 status + devices 文件 + 自动恢复 */
static void poll_and_maybe_rebuild(mqtt_client *cli, int mqtt_fd)
{
    char resp[RESP_MAX];
    /* 🔴🔴 轮询用独立短会话读 RTOKEN (根治读不到 kA):
       协调器固件对长会话重复 RTOKEN 只回 Default 段 (无 kA),
       但新串口会话的 RTOKEN 返回完整响应 (Default + *kA)。
       实测: rtoken/-cmd 短会话每次都能读到 kA, 守护进程长会话读不到。
       → send_cmd_session 打开独立 fd (模拟 -cmd 新会话), 读完关闭。 */
    int n = send_cmd_session("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
    static int miss = 0;
    if (n < 0) {
        /* 🔴🔴 外部占用容错: 串口被外部工具占用时跳过本次, 不累计 miss,
           不触发任何误判 — 用户随时可以手动放命令, 守护进程必须容忍 */
        printf("[轮询] 串口被外部占用, 跳过本次轮询\n");
        fflush(stdout);
        return;
    }
    if (n > 0) {
        write_status_json(resp, n);
        devices_cmd();
        /* HA MQTT Discovery: 设备存在时发布 homeassistant/<component>/.../config */
        if (mqtt_fd >= 0) mqtt_publish_all_discovery(cli);
        FILE *f = fopen("/tmp/zigbeed_status.json", "r");
        if (f) {
            char body[1024];
            int bl = fread(body, 1, sizeof(body) - 1, f);
            fclose(f);
            body[bl] = 0;
            if (strstr(body, "\"channel\": \"?")) {
                /* 🔴🔴🔴 2026-09-01 用户定论: 放弃自动 rebuild!
                   每次检测到协调器参数丢失后, 暂停自动 rebuild (只提示)。
                   手动 rebuild 由用户/LuCI 按钮触发 (DeviceHub 建网可靠)。
                   → miss 累计只作提示计数, 绝不 system(rebuild)。 */
                miss++;
                if (miss == 1 || miss % 20 == 0) {
                    printf("[检测] 协调器网络参数丢失 (短会话 RTOKEN 无 kA), 已暂停自动 rebuild。\n");
                    printf("[检测] 请在 LuCI 设置页点击\"重建网络\"手动执行 DeviceHub 建网。\n");
                    fflush(stdout);
                }
            } else {
                miss = 0;
            }
        }
    } else {
        /* 短会话也无响应 = 协调器疑似异常 — 只提示, 不自动 rebuild (用户定论) */
        miss++;
        if (miss == 1 || miss % 20 == 0) {
            printf("[检测] 协调器短会话无响应, 已暂停自动 rebuild。请手动重建网络。\n");
            fflush(stdout);
        }
    }
}

static int gateway_main(int serve_port, const char *mqtt_host, int mqtt_port)
{
    int lfd = -1;
    int mqtt_fd = -1;
    mqtt_client cli;
    memset(&cli, 0, sizeof(cli));

    /* 检查协调器网络参数, 丢失则自动建网 (自编译固件无 DeviceHub 也能用) */
    ensure_network();

    /* 初始化 HTTP */
    if (serve_port > 0) {
        lfd = serve_create_listener(serve_port);
        if (lfd < 0) printf("[主] HTTP 监听失败\n");
    }

    /* 初始化 MQTT */
    if (mqtt_host) {
        char cid[32];
        snprintf(cid, sizeof(cid), "zigbeed-%ld", (long)time(NULL) % 100000);
        if (mqtt_connect(&cli, mqtt_host, mqtt_port, cid) == 0) {
            mqtt_fd = cli.fd;
            mqtt_subscribe(cli.fd, "zigbee2mqtt/+/set");
            mqtt_publish(cli.fd, "zigbee2mqtt/bridge/info",
                "{\"type\":\"zigbeed\",\"state\":\"online\"}", -1);
            printf("[主] MQTT 已连接, 订阅 zigbee2mqtt/+/set\n");
            fflush(stdout);
        } else {
            printf("[主] MQTT 连接失败 (将重试)\n");
            fflush(stdout);
        }
    }

    time_t last_poll = time(NULL);
    time_t last_mqtt_retry = time(NULL);

    while (running) {
        fd_set rfds;
        FD_ZERO(&rfds);
        int maxfd = 0;
        if (lfd >= 0) { FD_SET(lfd, &rfds); if (lfd > maxfd) maxfd = lfd; }
        if (mqtt_fd >= 0) { FD_SET(mqtt_fd, &rfds); if (mqtt_fd > maxfd) maxfd = mqtt_fd; }

        struct timeval tv = {1, 0};
        int sel = select(maxfd + 1, &rfds, NULL, NULL, &tv);
        if (sel < 0) {
            if (errno == EINTR) continue;
            /* EBADF: 某个 fd 失效 (如 mqtt_fd 被意外关闭) - 清理后继续, 不退出 */
            if (errno == EBADF) {
                if (mqtt_fd >= 0) { close(mqtt_fd); mqtt_fd = -1; }
                if (lfd >= 0) { close(lfd); lfd = -1; }
                printf("[主] select EBADF, 清理 fd 继续 (mqtt_fd=%d lfd=%d)\n", mqtt_fd, lfd);
                fflush(stdout);
                continue;
            }
            printf("[主] select 错误 errno=%d, 继续\n", errno);
            fflush(stdout);
            continue;
        }

        /* HTTP 新连接 */
        if (lfd >= 0 && FD_ISSET(lfd, &rfds)) {
            struct sockaddr_in caddr;
            socklen_t clen = sizeof(caddr);
            int cfd = accept(lfd, (struct sockaddr *)&caddr, &clen);
            if (cfd >= 0) serve_handle_conn(cfd);
        }

        /* MQTT 消息 */
        if (mqtt_fd >= 0 && FD_ISSET(mqtt_fd, &rfds)) {
            unsigned char pkt[1024];
            int plen = 0;
            int ptype = mqtt_read_packet(mqtt_fd, pkt, sizeof(pkt), &plen, 2);
            if (ptype == MQTT_PUBLISH) {
                char topic[128];
                const unsigned char *payload;
                int payload_len;
                mqtt_parse_publish(pkt, plen, topic, sizeof(topic), &payload, &payload_len);
                printf("[MQTT] 收到: %s = %.*s\n", topic, payload_len, payload);
                fflush(stdout);
                /* 命令映射 (zigbee2mqtt 标准 → 协调器 JSON, 支持组合命令) */
                char msg[256];
                int mlen = payload_len < 255 ? payload_len : 255;
                memcpy(msg, payload, mlen);
                msg[mlen] = 0;
                char cmds[8][256];
                int ccount = 0;
                char sv[16];
                json_get_str(msg, "state", sv, sizeof(sv));
                if (sv[0]) {
                    if (strcmp(sv, "ON") == 0 || strcmp(sv, "on") == 0 || strcmp(sv, "true") == 0 ||
                        strcmp(sv, "open") == 0 || strcmp(sv, "OPEN") == 0 ||
                        strcmp(sv, "LOCK") == 0 || strcmp(sv, "lock") == 0)
                        snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"State\":\"1\"}");
                    else
                        snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"State\":\"0\"}");
                }
                int b = json_get_int(msg, "brightness");
                if (b != -999) {
                    if (b < 0) b = 0; if (b > 255) b = 255;
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Level\":\"%d\"}", b);
                }
                int h = json_get_int(msg, "hue");
                if (h != -999) {
                    if (h < 0) h = 0; if (h > 360) h = 360;
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"HUE\":\"%d\"}", h);
                }
                int sat = json_get_int(msg, "saturation");
                if (sat != -999) {
                    if (sat < 0) sat = 0; if (sat > 100) sat = 100;
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Saturation\":\"%d\"}", sat);
                }
                int temp = json_get_int(msg, "temperature");
                if (temp != -999) {
                    if (temp < 0) temp = 0; if (temp > 50) temp = 50;
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Temperature\":\"%d\"}", temp);
                }
                int wm = json_get_int(msg, "work_mode");
                if (wm != -999) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"WorkMode\":\"%d\"}", wm);
                int fm = json_get_int(msg, "fan_mode");
                if (fm != -999) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"FanMode\":\"%d\"}", fm);
                char act[16];
                json_get_str(msg, "action", act, sizeof(act));
                if (act[0]) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Action\":\"%s\"}", act);
                if (ccount && !has_devices()) {
                    printf("[MQTT] 拒绝控制: 无已入网设备 (协调器固件对无设备控制命令有 bug)\n");
                    fflush(stdout);
                    ccount = 0;
                }
                for (int ci = 0; ci < ccount; ci++) {
                    char cmd[512];
                    snprintf(cmd, sizeof(cmd), "%s\n", cmds[ci]);
                    char r2[RESP_MAX];
                    send_cmd("AT+VER\r\n", r2, sizeof(r2), 2);
                    msleep(150);
                    tcflush(tty_fd, TCIOFLUSH);
                    int n = send_cmd(cmd, r2, sizeof(r2), 5);
                    printf("[MQTT] 控制: %s (resp %d)\n", cmds[ci], n);
                    fflush(stdout);
                }
            } else if (ptype < 0) {
                /* MQTT 断开, 标记重连 */
                close(mqtt_fd);
                mqtt_fd = -1;
                printf("[MQTT] 断开, 准备重连\n");
                fflush(stdout);
            }
        }
        /* 轮询 (15s) + 自动恢复 (协调器参数丢失时自动重建)
           🔴 间隔从 5s 提到 15s: 协调器 RTOKEN 完整响应 (含 kA 帧) 需要 ~10s,
           5s 间隔 + 4s 等待必然重叠且读不全 → 轮询永远读到 "?" 误判丢参数! */
        if (time(NULL) - last_poll > 15) {
            poll_and_maybe_rebuild(&cli, mqtt_fd);
            last_poll = time(NULL);
        }

        /* MQTT 重连 (若断开) */
        if (mqtt_host && mqtt_fd < 0 && time(NULL) - last_mqtt_retry > 10) {
            char cid[32];
            snprintf(cid, sizeof(cid), "zigbeed-%ld", (long)time(NULL) % 100000);
            if (mqtt_connect(&cli, mqtt_host, mqtt_port, cid) == 0) {
                mqtt_fd = cli.fd;
                mqtt_subscribe(cli.fd, "zigbee2mqtt/+/set");
                printf("[MQTT] 重连成功\n");
                fflush(stdout);
            }
            last_mqtt_retry = time(NULL);
        }
    }

    if (lfd >= 0) close(lfd);
    if (mqtt_fd >= 0) close(mqtt_fd);
    return 0;
}

/* 前向声明 */
static int serve_loop(int port);

/* ---------- 组合模式: serve + mqtt + daemon 轮询 共存 ---------- */
/* serve 在子进程 (fork), mqtt+轮询在主进程; 串口用 flock 互斥 */
static int combined_loop(int serve_port, const char *mqtt_host, int mqtt_port)
{
    /* 启动 HTTP serve 子进程 */
    pid_t serve_pid = -1;
    if (serve_port > 0) {
        serve_pid = fork();
        if (serve_pid == 0) {
            /* 子进程: 跑 HTTP serve */
            serve_loop(serve_port);
            _exit(0);
        }
        printf("[组合] HTTP serve 子进程 PID=%d (port %d)\n", serve_pid, serve_port);
    }

    /* 主进程: mqtt + daemon 轮询 (serve 子进程独立运行) */
    if (mqtt_host) {
        printf("[组合] MQTT bridge 模式 (主进程)\n");
        fflush(stdout);
        while (running) {
            if (mqtt_loop(mqtt_host, mqtt_port) == 0) break;
            printf("[组合] MQTT 连接失败, 5 秒后重试\n");
            fflush(stdout);
            for (int i = 0; i < 5 && running; i++) msleep(1000);
        }
    } else {
        printf("[组合] daemon 轮询模式 (主进程)\n");
        fflush(stdout);
        daemon_loop();
    }
    return 0;
}

static int serve_loop(int port)
{
    signal(SIGCHLD, SIG_IGN);  /* 自动回收 fork 子进程, 防僵尸 */
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0) { perror("socket"); return 1; }
    int opt = 1;
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        perror("bind"); close(lfd); return 1;
    }
    listen(lfd, 4);
    printf("[HTTP] 监听 0.0.0.0:%d\n", port);
    fflush(stdout);

    while (running) {
        struct sockaddr_in caddr;
        socklen_t clen = sizeof(caddr);
        int cfd = accept(lfd, (struct sockaddr *)&caddr, &clen);
        if (cfd < 0) { msleep(50); continue; }

        /* 读请求行 */
        char req[1024];
        int got = 0;
        time_t start = time(NULL);
        while (got < sizeof(req) - 1 && time(NULL) - start < 3) {
            int r = read(cfd, req + got, 1);
            if (r > 0) {
                got++;
                if (got >= 4 && req[got-4] == '\r' && req[got-3] == '\n'
                    && req[got-2] == '\r' && req[got-1] == '\n') break;
            } else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
            else msleep(5);
        }
        req[got] = 0;

        /* fork 处理连接, 避免慢请求 (AT 命令) 阻塞其他请求 */
        pid_t pid = fork();
        if (pid < 0) { close(cfd); continue; }
        if (pid > 0) { close(cfd); continue; }  /* 父进程继续 accept */

        /* 子进程处理请求 */
        char method[16], path[512];
        if (sscanf(req, "%15s %511s", method, path) == 2) {
            char resp[RESP_MAX];
            /* 提取路径和参数 */
            if (strncmp(path, "/status", 7) == 0) {
                int n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
                char body[2048];
                if (n > 0) {
                    write_status_json(resp, n);
                    FILE *f = fopen("/tmp/zigbeed_status.json", "r");
                    int bl = 0;
                    if (f) { bl = fread(body, 1, sizeof(body)-1, f); fclose(f); }
                    body[bl] = 0;
                    http_send(cfd, body);
                } else {
                    http_send_error(cfd, 500, "{\"error\":\"no response\"}");
                }
            } else if (strncmp(path, "/devices", 8) == 0) {
                devices_cmd();
                FILE *f = fopen("/tmp/zigbeed_devices.json", "r");
                char body[2048];
                int bl = 0;
                if (f) { bl = fread(body, 1, sizeof(body)-1, f); fclose(f); }
                body[bl] = 0;
                http_send(cfd, body);
            } else if (strncmp(path, "/pair", 5) == 0) {
                int sec = 60;
                char *p = strstr(path, "sec=");
                if (p) sec = atoi(p + 4);
                if (sec < 0) sec = 0;
                if (sec > 600) sec = 600;
                char cmd[64];
                snprintf(cmd, sizeof(cmd), "{\"Duration\":\"%d\"}\n", sec);
                /* 先同步串口缓冲 (防残留数据导致命令错乱) */
                send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
                msleep(150);
                tcflush(tty_fd, TCIOFLUSH);
                int n = send_cmd(cmd, resp, sizeof(resp), 3);
                char body[256];
                snprintf(body, sizeof(body), "{\"pair\":true,\"sec\":%d,\"resp_len\":%d}", sec, n);
                http_send(cfd, body);
            } else if (strncmp(path, "/control/", 9) == 0) {
                if (!has_devices()) {
                    http_send(cfd, "{\"control\":false,\"error\":\"no devices joined\"}");
                    continue;
                }
                char jcmd[512];
                url_decode(jcmd, path + 9);
                char cmd[544];
                snprintf(cmd, sizeof(cmd), "%s\n", jcmd);
                send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
                msleep(150);
                tcflush(tty_fd, TCIOFLUSH);
                int n = send_cmd(cmd, resp, sizeof(resp), 5);
                char body[1024];
                snprintf(body, sizeof(body), "{\"control\":true,\"cmd\":\"%s\",\"resp_len\":%d}", jcmd, n);
                http_send(cfd, body);
            } else if (strncmp(path, "/ping", 5) == 0) {
                http_send(cfd, "{\"pong\":true}");
            } else {
                http_send_error(cfd, 404, "not found");
            }
        }
        close(cfd);
        _exit(0);  /* 子进程结束 */
    }
    close(lfd);
    return 0;
}

/* ---------- MQTT bridge 模式 ---------- */
/* 用法: zigbeed -mqtt [host] [port]
 * 仿 zigbee2mqtt: 订阅 zigbee2mqtt/+/set 控制, 发布状态到 zigbee2mqtt/<addr>
 */

/* 简单 JSON 字段提取 (无 JSON 库依赖) */
static int json_get_int(const char *msg, const char *key)
{
    char k[32];
    snprintf(k, sizeof(k), "\"%s\"", key);
    const char *p = strstr(msg, k);
    if (!p) return -999;
    p = strchr(p, ':');
    if (!p) return -999;
    p++;
    while (*p == ' ' || *p == '\t') p++;
    if (*p == '"') p++;
    return atoi(p);
}
static void json_get_str(const char *msg, const char *key, char *out, int outlen)
{
    char k[32];
    snprintf(k, sizeof(k), "\"%s\"", key);
    const char *p = strstr(msg, k);
    out[0] = 0;
    if (!p) return;
    p = strchr(p, ':');
    if (!p) return;
    p++;
    while (*p == ' ' || *p == '\t') p++;
    if (*p == '"') {
        p++;
        int i = 0;
        while (*p && *p != '"' && i < outlen - 1) out[i++] = *p++;
        out[i] = 0;
    } else {
        int i = 0;
        while (*p && *p != ',' && *p != '}' && i < outlen - 1) out[i++] = *p++;
        out[i] = 0;
    }
}

/* 发布 HA MQTT Discovery config (设备存在时, 按类型映射组件) */
static void mqtt_publish_discovery(mqtt_client *cli, int slot, const char *type_name)
{
    char component[16] = "switch";
    const char *cls = NULL;
    if (!type_name || !type_name[0]) type_name = "switch";
    if (strstr(type_name, "空调")) { strcpy(component, "climate"); }
    else if (strstr(type_name, "窗帘")) { strcpy(component, "cover"); }
    else if (strstr(type_name, "门锁")) { strcpy(component, "lock"); }
    else if (strstr(type_name, "温湿度")) { strcpy(component, "sensor"); cls = "temperature"; }
    else if (strstr(type_name, "传感器") || strstr(type_name, "人体") || strstr(type_name, "门磁") ||
             strstr(type_name, "水浸") || strstr(type_name, "烟雾") || strstr(type_name, "SOS")) {
        strcpy(component, "binary_sensor"); cls = "occupancy";
    }
    else if (strstr(type_name, "面板") || strstr(type_name, "插座")) { strcpy(component, "switch"); }
    else if (strstr(type_name, "灯")) { strcpy(component, "light"); }

    char config[600];
    if (strcmp(component, "light") == 0) {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"state_topic\":\"zigbee2mqtt/slot%d\",\"command_topic\":\"zigbee2mqtt/slot%d/set\",\"brightness\":true,\"schema\":\"json\",\"pl_on\":\"ON\",\"pl_off\":\"OFF\"}",
            type_name, slot, slot, slot, slot);
    } else if (strcmp(component, "climate") == 0) {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"mode_state_topic\":\"zigbee2mqtt/slot%d\",\"mode_command_topic\":\"zigbee2mqtt/slot%d/set\",\"temp_state_topic\":\"zigbee2mqtt/slot%d\",\"temp_command_topic\":\"zigbee2mqtt/slot%d/set\"}",
            type_name, slot, slot, slot, slot, slot, slot);
    } else if (strcmp(component, "cover") == 0) {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"state_topic\":\"zigbee2mqtt/slot%d\",\"command_topic\":\"zigbee2mqtt/slot%d/set\",\"payload_open\":\"OPEN\",\"payload_close\":\"CLOSE\",\"payload_stop\":\"STOP\"}",
            type_name, slot, slot, slot, slot);
    } else if (strcmp(component, "lock") == 0) {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"state_topic\":\"zigbee2mqtt/slot%d\",\"command_topic\":\"zigbee2mqtt/slot%d/set\",\"payload_lock\":\"LOCK\",\"payload_unlock\":\"UNLOCK\"}",
            type_name, slot, slot, slot, slot);
    } else if (strcmp(component, "binary_sensor") == 0) {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"state_topic\":\"zigbee2mqtt/slot%d\",\"device_class\":\"%s\"}",
            type_name, slot, slot, slot, cls ? cls : "occupancy");
    } else {
        snprintf(config, sizeof(config),
            "{\"name\":\"Zigbee %s %d\",\"uniq_id\":\"zigbeed_%d\",\"state_topic\":\"zigbee2mqtt/slot%d\",\"command_topic\":\"zigbee2mqtt/slot%d/set\",\"pl_on\":\"ON\",\"pl_off\":\"OFF\"}",
            type_name, slot, slot, slot, slot);
    }
    char topic[160];
    snprintf(topic, sizeof(topic), "homeassistant/%s/zigbeed_%d/config", component, slot);
    mqtt_publish(cli->fd, topic, config, -1);
}

/* 从设备文件解析槽位/类型, 发布 discovery (设备存在时) */
static void mqtt_publish_all_discovery(mqtt_client *cli)
{
    FILE *f = fopen("/tmp/zigbeed_devices.json", "r");
    if (!f) return;
    char buf[2048];
    size_t r = fread(buf, 1, sizeof(buf) - 1, f);
    fclose(f);
    buf[r] = 0;
    /* 简单扫描: "slot": N 和 "type": "名称" */
    const char *p = buf;
    while ((p = strstr(p, "\"slot\"")) != NULL) {
        p = strchr(p, ':');
        if (!p) break;
        p++;
        int slot = atoi(p);
        if (slot < 1 || slot > 8) { p++; continue; }
        /* 找这个槽位对应的 type (最近的一个) */
        const char *q = p;
        const char *tq = NULL;
        const char *tt = strstr(q, "\"type\"");
        const char *ns = strstr(q, "\"slot\"");
        if (tt && (!ns || tt < ns)) tq = tt;
        char tname[64] = "switch";
        if (tq) {
            const char *v = strchr(tq, ':');
            if (v) {
                v++;
                while (*v == ' ' || *v == '"') v++;
                int i = 0;
                while (*v && *v != '"' && i < 63) tname[i++] = *v++;
                tname[i] = 0;
            }
        }
        mqtt_publish_discovery(cli, slot, tname);
        p++;
    }
}

static int mqtt_loop(const char *host, int port)
{
    char resp[RESP_MAX];
    mqtt_client cli;
    memset(&cli, 0, sizeof(cli));

    /* MQTT 日志写文件 (守护进程 stdout 缓冲不可靠) */
    FILE *mqtf = fopen("/tmp/zigbeed_mqtt.log", "a");
    if (mqtf) {
        fprintf(mqtf, "[%ld] === MQTT bridge 启动, 连接 %s:%d ===\n", (long)time(NULL), host, port);
        fflush(mqtf);
    }

    printf("[MQTT] 连接 %s:%d ...\n", host, port);
    char cid[32];
    snprintf(cid, sizeof(cid), "zigbeed-%ld", (long)time(NULL) % 100000);
    if (mqtt_connect(&cli, host, port, cid) < 0) {
        printf("[MQTT] 连接失败\n");
        return 1;
    }
    printf("[MQTT] 已连接, 订阅 zigbee2mqtt/+/set\n");
    if (mqtt_subscribe(cli.fd, "zigbee2mqtt/+/set") < 0) {
        printf("[MQTT] 订阅失败!\n");
        if (mqtf) { fprintf(mqtf, "[%ld] 订阅失败!\n", (long)time(NULL)); fflush(mqtf); }
    } else {
        printf("[MQTT] 订阅成功\n");
        if (mqtf) { fprintf(mqtf, "[%ld] 订阅成功\n", (long)time(NULL)); fflush(mqtf); }
    }

    /* 发布网关信息 */
    mqtt_publish(cli.fd, "zigbee2mqtt/bridge/info",
        "{\"type\":\"zigbeed\",\"vendor\":\"gemdale\",\"coordinator\":\"EFR32MG1B\",\"state\":\"online\"}", -1);

    unsigned char pkt[1024];
    time_t last_ping = time(NULL);
    time_t last_status = time(NULL);

    while (running) {
        int plen = 0;
        int ptype = mqtt_read_packet(cli.fd, pkt, sizeof(pkt), &plen, 5);

        if (mqtf && ptype > 0 && ptype != MQTT_PINGRESP) {
            fprintf(mqtf, "[%ld] 报文类型 0x%02X plen=%d\n", (long)time(NULL), ptype, plen);
            fflush(mqtf);
        }

        if (ptype == MQTT_PUBLISH) {
            char topic[128];
            const unsigned char *payload;
            int payload_len;
            mqtt_parse_publish(pkt, plen, topic, sizeof(topic), &payload, &payload_len);

            /* DEBUG: 无条件 dump 原始报文 */
            if (mqtf) {
                fprintf(mqtf, "[%ld] DEBUG ptype=0x%02X plen=%d raw: ", (long)time(NULL), ptype, plen);
                for (int di = 0; di < plen && di < 64; di++) fprintf(mqtf, "%02X ", pkt[di]);
                fprintf(mqtf, "\n");
                fflush(mqtf);
            }

            printf("[MQTT] 收到: topic=[%s] payload=[%.*s] plen=%d\n", topic, payload_len, payload, payload_len);
            if (mqtf) {
                fprintf(mqtf, "[%ld] 收到 topic=[%s] payload=[%.*s] plen=%d raw: ", (long)time(NULL), topic, payload_len, payload, payload_len);
                for (int di = 0; di < plen + 2 && di < 60; di++) fprintf(mqtf, "%02X ", pkt[di]);
                fprintf(mqtf, "\n");
                fflush(mqtf);
            }

            /* 解析控制命令: zigbee2mqtt/<addr>/set {"state":"ON"} 等 */
            char msg[256];
            int mlen = payload_len < 255 ? payload_len : 255;
            memcpy(msg, payload, mlen);
            msg[mlen] = 0;

            /* zigbee2mqtt 标准命令 → 协调器 JSON 映射 (支持组合: state+brightness 等) */
            char cmds[8][256];
            int ccount = 0;
            char sv[16];
            json_get_str(msg, "state", sv, sizeof(sv));
            if (sv[0]) {
                if (strcmp(sv, "ON") == 0 || strcmp(sv, "on") == 0 || strcmp(sv, "true") == 0 ||
                    strcmp(sv, "open") == 0 || strcmp(sv, "OPEN") == 0 ||
                    strcmp(sv, "LOCK") == 0 || strcmp(sv, "lock") == 0)
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"State\":\"1\"}");
                else
                    snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"State\":\"0\"}");
            }
            int b = json_get_int(msg, "brightness");
            if (b != -999) {
                if (b < 0) b = 0; if (b > 255) b = 255;
                snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Level\":\"%d\"}", b);
            }
            int h = json_get_int(msg, "hue");
            if (h != -999) {
                if (h < 0) h = 0; if (h > 360) h = 360;
                snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"HUE\":\"%d\"}", h);
            }
            int sat = json_get_int(msg, "saturation");
            if (sat != -999) {
                if (sat < 0) sat = 0; if (sat > 100) sat = 100;
                snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Saturation\":\"%d\"}", sat);
            }
            int temp = json_get_int(msg, "temperature");
            if (temp != -999) {
                if (temp < 0) temp = 0; if (temp > 50) temp = 50;
                snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Temperature\":\"%d\"}", temp);
            }
            int wm = json_get_int(msg, "work_mode");
            if (wm != -999) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"WorkMode\":\"%d\"}", wm);
            int fm = json_get_int(msg, "fan_mode");
            if (fm != -999) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"FanMode\":\"%d\"}", fm);
            char act[16];
            json_get_str(msg, "action", act, sizeof(act));
            if (act[0]) snprintf(cmds[ccount++], sizeof(cmds[0]), "{\"Action\":\"%s\"}", act);

            if (ccount && !has_devices()) {
                printf("[MQTT] 拒绝控制: 无已入网设备 (协调器固件对无设备控制命令有 bug)\n");
                if (mqtf) { fprintf(mqtf, "[%ld] 拒绝控制: 无设备\n", (long)time(NULL)); fflush(mqtf); }
                ccount = 0;
            }

            for (int ci = 0; ci < ccount; ci++) {
                printf("[MQTT] 控制命令: %s\n", cmds[ci]);
                if (mqtf) {
                    fprintf(mqtf, "[%ld] 控制命令: %s\n", (long)time(NULL), cmds[ci]);
                    fflush(mqtf);
                }
                /* 同步 + 发协调器 */
                send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
                msleep(150);
                tcflush(tty_fd, TCIOFLUSH);
                char cmd[512];
                snprintf(cmd, sizeof(cmd), "%s\n", cmds[ci]);
                int n = send_cmd(cmd, resp, sizeof(resp), 5);
                printf("[MQTT] 协调器响应 %d 字节\n", n);
                if (mqtf) {
                    fprintf(mqtf, "[%ld] 协调器响应 %d 字节\n", (long)time(NULL), n);
                    fflush(mqtf);
                }
            }
        } else if (ptype == MQTT_PINGRESP) {
            /* 心跳响应 */
        } else if (ptype == 0) {
            /* 超时: 心跳 + 周期状态 */
            if (time(NULL) - last_ping > 30) {
                mqtt_ping(cli.fd);
                last_ping = time(NULL);
            }
            if (time(NULL) - last_status > 30) {
                int n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
                if (n > 0) {
                    write_status_json(resp, n);
                    devices_cmd();  /* 更新设备文件 (供 discovery 使用) */
                    /* 发布状态摘要到 MQTT */
                    FILE *f = fopen("/tmp/zigbeed_status.json", "r");
                    if (f) {
                        char stbuf[512];
                        size_t r = fread(stbuf, 1, sizeof(stbuf) - 1, f);
                        fclose(f);
                        stbuf[r] = 0;
                        mqtt_publish(cli.fd, "zigbee2mqtt/bridge/state", stbuf, -1);
                    }
                    /* HA MQTT Discovery: 设备存在时发布 homeassistant/<component>/.../config */
                    mqtt_publish_all_discovery(&cli);
                }
                last_status = time(NULL);
            }
        } else if (ptype < 0) {
            printf("[MQTT] 连接断开, 重连...\n");
            if (mqtf) { fprintf(mqtf, "[%ld] 连接断开, 重连\n", (long)time(NULL)); fflush(mqtf); }
            close(cli.fd);
            msleep(3000);
            if (mqtt_connect(&cli, host, port, cid) < 0) {
                printf("[MQTT] 重连失败\n");
                msleep(5000);
                continue;
            }
            mqtt_subscribe(cli.fd, "zigbee2mqtt/+/set");
            last_ping = time(NULL);
            last_status = time(NULL);
        }
    }
    mqtt_send_packet(cli.fd, MQTT_DISCONNECT, NULL, 0);
    close(cli.fd);
    return 0;
}

/* ---------- 守护模式: 周期轮询 + 监听设备事件 ---------- */
static void daemon_loop(void)
{
    char resp[RESP_MAX];
    unsigned char buf[1024];
    printf("[守护] 轮询状态 + 监听设备事件 (30s 周期), 写 /tmp/zigbeed_status.json\n");

    /* 先做一次初始状态 */
    int n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
    if (n > 0) write_status_json(resp, n);

    while (running) {
        /* 事件监听窗口: 非阻塞读串口 3 秒, 捕获协调器推送 (设备入网/状态上报) */
        int ev_bytes = 0;
        unsigned char evbuf[4096];
        time_t ev_start = time(NULL);
        while (time(NULL) - ev_start < 3 && running) {
            int r = read(tty_fd, buf, sizeof(buf));
            if (r > 0 && ev_bytes + r < 4096) {
                memcpy(evbuf + ev_bytes, buf, r);
                ev_bytes += r;
            } else if (r > 0) {
                ev_bytes = 4095; /* 防爆 */
                break;
            } else {
                msleep(50);
            }
        }

        if (ev_bytes > 0) {
            /* 检查是否有设备事件帧: *xA 88 且含非协调器 MAC 或非 FF 槽位 */
            printf("[%ld] 捕获 %d 字节事件数据\n", (long)time(NULL), ev_bytes);
            int has_new = 0;
            /* 简单启发: 事件帧含 "REX_DEVICE_JOIN" 或新 MAC */
            for (int i = 0; i < ev_bytes - 8; i++) {
                if (memcmp(evbuf+i, "REX_DEVICE_JOIN", 15) == 0) has_new = 1;
            }
            if (has_new) {
                printf("[%ld] !! 检测到设备入网事件\n", (long)time(NULL));
            }
        }

        /* 周期状态轮询 */
        n = send_cmd("AT+RTOKEN\r\n", resp, sizeof(resp), 12);
        if (n > 0) {
            write_status_json(resp, n);
            printf("[%ld] 状态已更新\n", (long)time(NULL));
        } else {
            /* 铁律: 轮询无响应不自动复位 (避免干扰协调器网络), 只提示 */
            printf("[%ld] 轮询无响应 (不自动复位, 稍后重试)\n", (long)time(NULL));
        }
        for (int i = 0; i < 30 && running; i++) msleep(1000);
    }
}

static void sig_handler(int sig) { running = 0; }

/* 崩溃信号记录 (诊断用, 不自动重启) */
static void crash_handler(int sig)
{
    FILE *f = fopen("/tmp/zigbeed_crash.log", "a");
    if (f) {
        fprintf(f, "[%ld] 信号 %d (SIG%s)\n", (long)time(NULL), sig,
                sig == SIGSEGV ? "SEGV" : sig == SIGBUS ? "BUS" : sig == SIGABRT ? "ABRT" : "?");
        fflush(f);
        fclose(f);
    }
    _exit(1);
}


/* ---------- main ---------- */
int main(int argc, char **argv)
{
    int daemon_mode = 1;
    const char *one_cmd = NULL, *one_json = NULL;
    int do_status = 0;
    int do_devices = 0;
    const char *control_json = NULL;
    int pair_seconds = 0;
    const char *mqtt_host = NULL;
    int mqtt_port = 1883;
    int serve_port = 0;
    const char *devname_key = NULL, *devname_val = NULL;
    int do_form = 0;

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-c")) daemon_mode = 0;
        else if (!strcmp(argv[i], "-cmd") && i + 1 < argc) one_cmd = argv[++i];
        else if (!strcmp(argv[i], "-json") && i + 1 < argc) one_json = argv[++i];
        else if (!strcmp(argv[i], "-d")) daemon_mode = 1;
        else if (!strcmp(argv[i], "-status")) do_status = 1;
        else if (!strcmp(argv[i], "-devices")) do_devices = 1;
        else if (!strcmp(argv[i], "-control") && i + 1 < argc) control_json = argv[++i];
        else if (!strcmp(argv[i], "-pair") && i + 1 < argc) pair_seconds = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-devname") && i + 2 < argc) {
            devname_key = argv[++i]; devname_val = argv[++i];
        }
        else if (!strcmp(argv[i], "-form")) do_form = 1;
        else if (!strcmp(argv[i], "-serve") && i + 1 < argc) serve_port = atoi(argv[++i]);
        else if (!strcmp(argv[i], "-mqtt")) {
            mqtt_host = "127.0.0.1";
            if (i + 1 < argc && argv[i+1][0] != '-') mqtt_host = argv[++i];
            if (i + 1 < argc && argv[i+1][0] != '-') mqtt_port = atoi(argv[++i]);
        }
        else if (!strcmp(argv[i], "-dev") && i + 1 < argc) g_dev = argv[++i];
        else if (!strcmp(argv[i], "-baud") && i + 1 < argc) g_baud = atoi(argv[++i]);
    }

    if (init_gateway() < 0) return 1;

    char resp[RESP_MAX];
    if (devname_key && devname_val) {
        return devname_cmd(devname_key, devname_val);
    }
    if (do_form) {
        return form_network("11", "4710", "", "");
    }
    if (serve_port > 0 || mqtt_host) {
        /* 单进程 select 架构: serve + mqtt + 轮询 共存 (不 fork, 串口安全) */
        return gateway_main(serve_port, mqtt_host, mqtt_port);
    }
    if (pair_seconds > 0) {
        return pair_cmd(pair_seconds);
    }
    if (do_devices) {
        return devices_cmd();
    }
    if (control_json) {
        return control_cmd(control_json);
    }
    if (do_status) {
        return status_cmd();
    }
    if (one_cmd) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "%s\r\n", one_cmd);
        int n = send_cmd(cmd, resp, sizeof(resp), 4);
        print_resp(resp, n);
        /* 显示设备表帧 */
        if (strstr(one_cmd, "SHOWADDR") || strstr(one_cmd, "SCAN") || strstr(one_cmd, "SETCH"))
            dump_device_table(resp, n);
        return 0;
    }
    if (one_json) {
        char cmd[512];
        snprintf(cmd, sizeof(cmd), "%s\n", one_json);
        /* 先发一个 AT+VER 同步缓冲, 再发 JSON */
        send_cmd("AT+VER\r\n", resp, sizeof(resp), 2);
        msleep(200);
        tcflush(tty_fd, TCIOFLUSH);
        int n = send_cmd(cmd, resp, sizeof(resp), 6);
        printf("[JSON响应 %d 字节]\n", n);
        print_resp(resp, n);
        return 0;
    }

    if (daemon_mode) {
        signal(SIGTERM, sig_handler);
        signal(SIGINT, sig_handler);
        /* 崩溃信号记录 (诊断用, 不自动重启) */
        signal(SIGSEGV, crash_handler);
        signal(SIGBUS, crash_handler);
        signal(SIGABRT, crash_handler);
        daemon_loop();
    } else {
    }

    close(tty_fd);
    return 0;
}
