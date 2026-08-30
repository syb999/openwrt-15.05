/*
 * gw-link.c - 对等网关互联服务 (多网关)
 *
 * 架构: 每台盒子跑 zigbeed -serve <port>, gw-link 聚合本机 + 多个对端
 *   peer 列表从 /etc/gw-link/peers.conf 加载 (每行 "ip:port", 支持注释)
 *   API:
 *     GET /ping                         健康检查
 *     GET /status                       本机 + 所有 peer 状态
 *     GET /devices                      本机 + 所有 peer 设备
 *     GET /control/<gw>/<urljson>       路由控制 (gw=self|peer|<ip>|<idx>)
 *     GET /pair/<gw>/<sec>              打开配对窗口
 *     GET /peers                        列出 peer 列表
 *     GET /rules                        联动规则列表
 *     GET /trigger/<id>                 手动触发联动
 *
 * 编译: mipsel-openwrt-linux-uclibc-gcc -std=gnu99 -static -o gw-link gw-link.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>

#define DEFAULT_PORT 8890
#define BUF_MAX 8192
#define PEERS_MAX 16

/* 配置: 本机 + peer 列表 */
static char local_host[64] = "127.0.0.1";
static int  local_port = 8888;

typedef struct {
    char host[64];
    int  port;
    char label[64];   /* 可选标签 */
} peer_t;

static peer_t g_peers[PEERS_MAX];
static int g_peer_cnt = 0;

static void msleep(int ms) { usleep(ms * 1000); }

/* ---------- 从配置文件加载 peer 列表 ---------- */
static void peers_load(const char *conf)
{
    g_peer_cnt = 0;
    FILE *f = fopen(conf, "r");
    if (!f) return;
    char line[256];
    while (fgets(line, sizeof(line), f) && g_peer_cnt < PEERS_MAX) {
        char *p = strchr(line, '\n');
        if (p) *p = 0;
        p = strchr(line, '#');
        if (p) *p = 0;
        if (line[0] == 0) continue;
        /* 格式: ip:port [label] */
        char *sep = strchr(line, ':');
        if (!sep) continue;
        *sep = 0;
        snprintf(g_peers[g_peer_cnt].host, sizeof(g_peers[0].host), "%s", line);
        g_peers[g_peer_cnt].port = atoi(sep + 1);
        /* label 在行尾 (空格后) */
        p = strchr(sep + 1, ' ');
        if (p) {
            snprintf(g_peers[g_peer_cnt].label, sizeof(g_peers[0].label), "%s", p + 1);
            *p = 0;
            g_peers[g_peer_cnt].port = atoi(sep + 1);
        } else {
            g_peers[g_peer_cnt].label[0] = 0;
        }
        g_peer_cnt++;
    }
    fclose(f);
}

/* 按名字找 peer: self|local|peer|<ip>|<idx> 返回 host/port, 找到返回 1 */
static int peer_resolve(const char *name, char *host, int *port)
{
    if (strcmp(name, "self") == 0 || strcmp(name, "local") == 0) {
        snprintf(host, 64, "%s", local_host);
        *port = local_port;
        return 1;
    }
    /* 数字索引 */
    if (name[0] >= '0' && name[0] <= '9' && atoi(name) < g_peer_cnt) {
        int idx = atoi(name);
        snprintf(host, 64, "%s", g_peers[idx].host);
        *port = g_peers[idx].port;
        return 1;
    }
    /* IP 匹配 */
    for (int i = 0; i < g_peer_cnt; i++) {
        if (strcmp(name, g_peers[i].host) == 0) {
            snprintf(host, 64, "%s", g_peers[i].host);
            *port = g_peers[i].port;
            return 1;
        }
    }
    /* 兼容旧 "peer" 关键字: 第一个 peer */
    if (strcmp(name, "peer") == 0 && g_peer_cnt > 0) {
        snprintf(host, 64, "%s", g_peers[0].host);
        *port = g_peers[0].port;
        return 1;
    }
    return 0;
}

/* ---------- HTTP 客户端 ---------- */
static int http_get(const char *host, int port, const char *path, char *out, int outlen)
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(host);
    if (addr.sin_addr.s_addr == INADDR_NONE) { close(fd); return -1; }
    struct timeval tv = {2, 0};
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) { close(fd); return -1; }

    char req[2048];
    snprintf(req, sizeof(req),
        "GET %s HTTP/1.1\r\nHost: %s:%d\r\nConnection: close\r\n\r\n",
        path, host, port);
    write(fd, req, strlen(req));

    int total = 0;
    time_t start = time(NULL);
    while (total < outlen - 1 && time(NULL) - start < 2) {
        int r = read(fd, out + total, outlen - 1 - total);
        if (r > 0) total += r;
        else break;
    }
    out[total] = 0;
    close(fd);

    char *body = strstr(out, "\r\n\r\n");
    if (body) {
        body += 4;
        memmove(out, body, strlen(body) + 1);
    }
    return 0;
}

/* ---------- HTTP 服务端 ---------- */
static void http_send(int fd, const char *body)
{
    char hdr[512];
    snprintf(hdr, sizeof(hdr),
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
        "Content-Length: %d\r\nConnection: close\r\n"
        "Access-Control-Allow-Origin: *\r\n\r\n", (int)strlen(body));
    write(fd, hdr, strlen(hdr));
    write(fd, body, strlen(body));
}

static void http_send_error(int fd, int code, const char *msg)
{
    char hdr[512];
    snprintf(hdr, sizeof(hdr),
        "HTTP/1.1 %d %s\r\nContent-Type: text/plain\r\n"
        "Content-Length: %d\r\nConnection: close\r\n\r\n",
        code, msg, (int)strlen(msg));
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
        } else dst[j++] = src[i++];
    }
    dst[j] = 0;
}

/* ---------- 联动规则引擎 ---------- */
#define RULES_MAX 32
#define RULE_LINE_MAX 512

typedef struct {
    char name[64];
    char trig_gw[64];      /* self|peer|ip|idx */
    char trig_cmd[128];
    char dst_gw[64];
    char dst_cmd[128];
} link_rule;

static link_rule g_rules[RULES_MAX];
static int g_rule_cnt = 0;

static void rules_load(void)
{
    g_rule_cnt = 0;
    FILE *f = fopen("/etc/gw-master/rules.conf", "r");
    if (!f) return;
    char line[RULE_LINE_MAX];
    while (fgets(line, sizeof(line), f) && g_rule_cnt < RULES_MAX) {
        char *p = strchr(line, '\n');
        if (p) *p = 0;
        if (line[0] == '#' || line[0] == 0) continue;
        char *name = strtok(line, "|");
        char *tg = strtok(NULL, "|");
        char *tc = strtok(NULL, "|");
        char *dg = strtok(NULL, "|");
        char *dc = strtok(NULL, "|");
        if (!name || !tg || !tc || !dg || !dc) continue;
        snprintf(g_rules[g_rule_cnt].name, sizeof(g_rules[0].name), "%s", name);
        snprintf(g_rules[g_rule_cnt].trig_gw, sizeof(g_rules[0].trig_gw), "%s", tg);
        snprintf(g_rules[g_rule_cnt].trig_cmd, sizeof(g_rules[0].trig_cmd), "%s", tc);
        snprintf(g_rules[g_rule_cnt].dst_gw, sizeof(g_rules[0].dst_gw), "%s", dg);
        snprintf(g_rules[g_rule_cnt].dst_cmd, sizeof(g_rules[0].dst_cmd), "%s", dc);
        g_rule_cnt++;
    }
    fclose(f);
}

static int rule_exec(const link_rule *r)
{
    char host[64];
    int port;
    if (!peer_resolve(r->dst_gw, host, &port)) return -1;
    char enc[512];
    int ei = 0;
    for (int i = 0; r->dst_cmd[i] && ei < 500; i++) {
        char c = r->dst_cmd[i];
        if (c == '{' || c == '}' || c == '"' || c == ' ' || c == ':') {
            snprintf(enc + ei, 8, "%%%02X", (unsigned char)c);
            ei += 3;
        } else {
            enc[ei++] = c;
        }
    }
    enc[ei] = 0;
    char cpath[512];
    snprintf(cpath, sizeof(cpath), "/control/%s", enc);
    char resp[BUF_MAX];
    http_get(host, port, cpath, resp, sizeof(resp));
    return 0;
}

static void rule_check_link(const char *gw, const char *cmd)
{
    for (int i = 0; i < g_rule_cnt; i++) {
        int trig = (strcmp(g_rules[i].trig_gw, gw) == 0);
        /* self 规则也匹配 local 关键字 */
        if (!trig && strcmp(g_rules[i].trig_gw, "self") == 0 && strcmp(gw, "local") == 0) trig = 1;
        if (trig && strcmp(g_rules[i].trig_cmd, cmd) == 0) {
            printf("[联动] %s: %s → %s/%s\n",
                   g_rules[i].name, g_rules[i].trig_cmd,
                   g_rules[i].dst_gw, g_rules[i].dst_cmd);
            rule_exec(&g_rules[i]);
        }
    }
}

/* ---------- 合并多 peer JSON (status/devices) ---------- */
static void merge_all(const char *path, char *out, int outlen)
{
    int pos = 0;
    char buf[BUF_MAX];

    /* self */
    memset(buf, 0, sizeof(buf));
    http_get(local_host, local_port, path, buf, sizeof(buf));
    pos += snprintf(out + pos, outlen - pos, "{\"self\":%s",
                    buf[0] ? buf : "{\"error\":\"self down\"}");

    /* peers: 用 /self 拉取对端 (避免 /status 递归互拉死锁) */
    for (int i = 0; i < g_peer_cnt; i++) {
        memset(buf, 0, sizeof(buf));
        http_get(g_peers[i].host, g_peers[i].port, "/self", buf, sizeof(buf));
        pos += snprintf(out + pos, outlen - pos, ",\"%s\":%s",
                        g_peers[i].host,
                        buf[0] ? buf : "{\"error\":\"peer down\"}");
    }
    pos += snprintf(out + pos, outlen - pos, "}");
}

/* ---------- 单连接处理 (fork 子进程调用) ---------- */
static void handle_conn(int cfd)
{
    char req[2048];
    int got = 0;
    time_t start = time(NULL);
    while (got < sizeof(req) - 1 && time(NULL) - start < 3) {
        int r = read(cfd, req + got, 1);
        if (r > 0) {
            got++;
            if (got >= 4 && req[got-4]=='\r' && req[got-3]=='\n' && req[got-2]=='\r' && req[got-1]=='\n') break;
        } else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
        else msleep(5);
    }
    req[got] = 0;

    char method[16], path[1024];
    if (sscanf(req, "%15s %1023s", method, path) == 2) {
        char body[BUF_MAX];
        if (strncmp(path, "/ping", 5) == 0) {
            http_send(cfd, "{\"gw_master\":true,\"pong\":true}");
        } else if (strncmp(path, "/peers", 6) == 0) {
            char pbody[2048];
            int pp = 0;
            pp += snprintf(pbody + pp, sizeof(pbody) - pp, "{\"peers\":[");
            for (int i = 0; i < g_peer_cnt; i++) {
                if (i) pp += snprintf(pbody + pp, sizeof(pbody) - pp, ",");
                pp += snprintf(pbody + pp, sizeof(pbody) - pp,
                    "{\"idx\":%d,\"host\":\"%s\",\"port\":%d,\"label\":\"%s\"}",
                    i, g_peers[i].host, g_peers[i].port, g_peers[i].label);
            }
            pp += snprintf(pbody + pp, sizeof(pbody) - pp, "],\"count\":%d}", g_peer_cnt);
            http_send(cfd, pbody);
        } else if (strncmp(path, "/rules", 6) == 0) {
            char rbody[4096];
            int rp = 0;
            rp += snprintf(rbody + rp, sizeof(rbody) - rp, "{\"rules\":[");
            for (int i = 0; i < g_rule_cnt; i++) {
                if (i) rp += snprintf(rbody + rp, sizeof(rbody) - rp, ",");
                rp += snprintf(rbody + rp, sizeof(rbody) - rp,
                    "{\"id\":%d,\"name\":\"%s\",\"trigger\":\"%s/%s\",\"action\":\"%s/%s\"}",
                    i, g_rules[i].name, g_rules[i].trig_gw, g_rules[i].trig_cmd,
                    g_rules[i].dst_gw, g_rules[i].dst_cmd);
            }
            rp += snprintf(rbody + rp, sizeof(rbody) - rp, "],\"count\":%d}", g_rule_cnt);
            http_send(cfd, rbody);
        } else if (strncmp(path, "/trigger/", 9) == 0) {
            int rid = atoi(path + 9);
            if (rid >= 0 && rid < g_rule_cnt) {
                char rbody[256];
                snprintf(rbody, sizeof(rbody),
                    "{\"trigger\":true,\"rule\":%d,\"name\":\"%s\"}",
                    rid, g_rules[rid].name);
                rule_exec(&g_rules[rid]);
                http_send(cfd, rbody);
            } else {
                http_send_error(cfd, 404, "{\"error\":\"rule not found\"}");
            }
        } else if (strncmp(path, "/status", 7) == 0) {
            merge_all("/status", body, sizeof(body));
            http_send(cfd, body);
        } else if (strncmp(path, "/self", 5) == 0) {
            /* 只返回本机状态 (peer 互拉用, 不递归拉 peer) */
            http_get(local_host, local_port, "/status", body, sizeof(body));
            http_send(cfd, body[0] ? body : "{\"error\":\"self down\"}");
        } else if (strncmp(path, "/devices", 8) == 0) {
            merge_all("/devices", body, sizeof(body));
            http_send(cfd, body);
        } else if (strncmp(path, "/control/", 9) == 0) {
            /* /control/<gw>/<urljson> */
            char rest[512];
            snprintf(rest, sizeof(rest), "%s", path + 9);
            char *slash = strchr(rest, '/');
            if (!slash) { http_send_error(cfd, 400, "bad path: /control/<gw>/<json>"); close(cfd); return; }
            *slash = 0;
            char gw[64], jcmd[512];
            snprintf(gw, sizeof(gw), "%s", rest);
            url_decode(jcmd, slash + 1);
            char host[64];
            int port2;
            if (!peer_resolve(gw, host, &port2)) {
                http_send_error(cfd, 400, "bad gw");
                close(cfd);
                return;
            }
            char cpath[1024];
            snprintf(cpath, sizeof(cpath), "/control/%s", slash + 1);
            printf("[控制] %s: %s\n", gw, cpath);
            http_get(host, port2, cpath, body, sizeof(body));
            rule_check_link(gw, jcmd);
            http_send(cfd, body[0] ? body : "{\"error\":\"no response\"}");
        } else if (strncmp(path, "/pair/", 6) == 0) {
            char rest[128];
            snprintf(rest, sizeof(rest), "%s", path + 6);
            char *slash = strchr(rest, '/');
            if (!slash) { http_send_error(cfd, 400, "bad path: /pair/<gw>/<sec>"); close(cfd); return; }
            *slash = 0;
            char gw[64];
            snprintf(gw, sizeof(gw), "%s", rest);
            char host[64];
            int port2;
            if (!peer_resolve(gw, host, &port2)) {
                http_send_error(cfd, 400, "bad gw");
                close(cfd);
                return;
            }
            char cpath[256];
            snprintf(cpath, sizeof(cpath), "/pair?sec=%s", slash + 1);
            http_get(host, port2, cpath, body, sizeof(body));
            http_send(cfd, body[0] ? body : "{\"error\":\"no response\"}");
        } else {
            http_send_error(cfd, 404, "not found");
        }
    }
    close(cfd);
}

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IOLBF, 0);
    int port = DEFAULT_PORT;

    /* 参数: gw-link [port] [local_port] [peers.conf] */
    if (argc > 1) port = atoi(argv[1]);
    if (argc > 2) local_port = atoi(argv[2]);
    const char *peers_conf = "/etc/gw-link/peers.conf";
    if (argc > 3) peers_conf = argv[3];

    peers_load(peers_conf);

    printf("[gw-link] 端口 %d, 本机 zigbeed %s:%d, peers: %d\n",
           port, local_host, local_port, g_peer_cnt);
    for (int i = 0; i < g_peer_cnt; i++) {
        printf("[gw-link]   peer[%d] %s:%d %s\n", i, g_peers[i].host,
               g_peers[i].port, g_peers[i].label);
    }

    char pong[BUF_MAX];
    int lok = http_get(local_host, local_port, "/ping", pong, sizeof(pong)) == 0 && strstr(pong, "pong");
    printf("[gw-link] 本机 zigbeed: %s\n", lok ? "OK" : "FAIL");
    for (int i = 0; i < g_peer_cnt; i++) {
        int ok = http_get(g_peers[i].host, g_peers[i].port, "/ping", pong, sizeof(pong)) == 0 && strstr(pong, "pong");
        printf("[gw-link]   peer[%d] %s: %s\n", i, g_peers[i].host, ok ? "OK" : "FAIL");
    }

    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    if (lfd < 0) { perror("socket"); return 1; }
    int opt = 1;
    setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(port);
    if (bind(lfd, (struct sockaddr *)&addr, sizeof(addr)) < 0) { perror("bind"); return 1; }
    listen(lfd, 4);
    rules_load();
    printf("[gw-link] 已加载 %d 条联动规则\n", g_rule_cnt);
    printf("[gw-link] 监听 0.0.0.0:%d\n", port);

    /* 并发处理: 每连接 fork 子进程, 慢请求(拉 peer 4s)不阻塞主循环 */
    signal(SIGCHLD, SIG_IGN);
    while (1) {
        struct sockaddr_in caddr;
        socklen_t clen = sizeof(caddr);
        int cfd = accept(lfd, (struct sockaddr *)&caddr, &clen);
        if (cfd < 0) { msleep(50); continue; }
        pid_t pid = fork();
        if (pid == 0) {
            handle_conn(cfd);
            _exit(0);
        }
        close(cfd);
    }
    return 0;
}
