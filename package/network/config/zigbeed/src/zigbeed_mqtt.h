/*
 * zigbeed_mqtt.c - 轻量 MQTT 3.1.1 客户端 (纯 C, 无外部依赖)
 * 用于 zigbeed -mqtt 模式: 连接本地 mosquitto, 发布设备状态, 订阅控制命令
 * topic 结构仿 zigbee2mqtt:
 *   订阅  zigbee2mqtt/+/set            控制命令 (state/brightness/color...)
 *   发布  zigbee2mqtt/<short_addr>     设备状态
 *   发布  zigbee2mqtt/bridge/info      网关信息
 * 编译: 与 zigbeed.c 一起
 */

#ifndef ZIGBEED_MQTT_H
#define ZIGBEED_MQTT_H

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
#include <netdb.h>

/* MQTT 控制报文类型 */
#define MQTT_CONNECT     0x10
#define MQTT_CONNACK     0x20
#define MQTT_PUBLISH     0x30
#define MQTT_PUBACK      0x40
#define MQTT_SUBSCRIBE   0x82
#define MQTT_SUBACK      0x90
#define MQTT_PINGREQ     0xC0
#define MQTT_PINGRESP    0xD0
#define MQTT_DISCONNECT  0xE0

typedef struct {
    int fd;
    char client_id[64];
    char host[64];
    int port;
} mqtt_client;

/* 剩余长度编码 (MQTT 可变长度, 最多 4 字节) */
static int mqtt_encode_len(unsigned char *buf, int len)
{
    int i = 0;
    do {
        unsigned char d = len % 128;
        len /= 128;
        if (len > 0) d |= 0x80;
        buf[i++] = d;
    } while (len > 0 && i < 4);
    return i;
}

/* 发送完整报文 */
static int mqtt_send_packet(int fd, unsigned char type, const unsigned char *payload, int plen)
{
    unsigned char header[5];
    int hlen = 1;
    header[0] = type;
    hlen += mqtt_encode_len(header + 1, plen);
    if (write(fd, header, hlen) != hlen) return -1;
    if (plen > 0 && write(fd, payload, plen) != plen) return -1;
    return 0;
}

/* 编码 UTF-8 字符串到缓冲 */
static int mqtt_put_str(unsigned char *buf, const char *s)
{
    int len = strlen(s);
    buf[0] = (len >> 8) & 0xFF;
    buf[1] = len & 0xFF;
    memcpy(buf + 2, s, len);
    return len + 2;
}

/* 前向声明 (mqtt_subscribe 需要) */
static int mqtt_read_packet(int fd, unsigned char *buf, int buflen, int *payload_len, int timeout_s);

/* 连接 MQTT broker */
static int mqtt_connect(mqtt_client *c, const char *host, int port, const char *client_id)
{
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(host);
    if (addr.sin_addr.s_addr == INADDR_NONE) {
        struct hostent *he = gethostbyname(host);
        if (!he) { close(fd); return -1; }
        memcpy(&addr.sin_addr, he->h_addr, he->h_length);
    }

    struct timeval tv = {5, 0};
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }

    /* CONNECT 报文 */
    unsigned char payload[256];
    int plen = 0;
    plen += mqtt_put_str(payload + plen, "MQTT");       /* protocol name */
    payload[plen++] = 4;                                 /* protocol level 4 (3.1.1) */
    payload[plen++] = 0x02;                              /* clean session */
    payload[plen++] = 0; payload[plen++] = 0x3C;         /* keepalive 60s */
    plen += mqtt_put_str(payload + plen, client_id);     /* client id */

    if (mqtt_send_packet(fd, MQTT_CONNECT, payload, plen) < 0) {
        close(fd);
        return -1;
    }

    /* 等 CONNACK */
    unsigned char resp[4];
    int got = 0;
    time_t start = time(NULL);
    while (got < 4 && time(NULL) - start < 5) {
        int r = read(fd, resp + got, 4 - got);
        if (r > 0) got += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) break;
    }
    if (got < 4 || resp[0] != MQTT_CONNACK || resp[3] != 0) {
        close(fd);
        return -1;
    }

    c->fd = fd;
    strncpy(c->host, host, sizeof(c->host) - 1);
    c->port = port;
    strncpy(c->client_id, client_id, sizeof(c->client_id) - 1);
    return 0;
}

/* 订阅 topic */
static int mqtt_subscribe(int fd, const char *topic)
{
    unsigned char payload[256];
    int plen = 0;
    payload[plen++] = 0x00; payload[plen++] = 0x01;  /* packet id 1 */
    plen += mqtt_put_str(payload + plen, topic);
    payload[plen++] = 0;  /* QoS 0 */

    if (mqtt_send_packet(fd, MQTT_SUBSCRIBE, payload, plen) < 0) return -1;

    /* 等 SUBACK: 固定读 5 字节 [0]=0x90 [1]=0x03 [2-3]=pid [4]=rc */
    unsigned char sresp[8];
    int got = 0;
    time_t start = time(NULL);
    while (got < 5 && time(NULL) - start < 5) {
        int r = read(fd, sresp + got, 5 - got);
        if (r > 0) got += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) return -1;
        else usleep(10000);
    }
    return (got == 5 && sresp[0] == MQTT_SUBACK) ? 0 : -1;
}

/* 发布消息 (QoS 0) */
static int mqtt_publish(int fd, const char *topic, const char *msg, int msglen)
{
    unsigned char payload[512];
    int plen = 0;
    plen += mqtt_put_str(payload + plen, topic);
    if (msglen < 0) msglen = strlen(msg);
    memcpy(payload + plen, msg, msglen);
    plen += msglen;
    return mqtt_send_packet(fd, MQTT_PUBLISH, payload, plen);
}

/* 读一个 MQTT 报文 (阻塞至多 timeout 秒) */
/* 返回: >0 报文类型, 0 超时, -1 错误 */
static int mqtt_read_packet(int fd, unsigned char *buf, int buflen, int *payload_len, int timeout_s)
{
    unsigned char hdr[2];
    int got = 0;
    time_t start = time(NULL);

    /* 读 type + 剩余长度第1字节 */
    while (got < 2 && time(NULL) - start < timeout_s) {
        int r = read(fd, hdr + got, 2 - got);
        if (r > 0) got += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) return -1;
    }
    if (got < 2) return 0;

    /* 剩余长度: 从 hdr[1] 开始解析, 多字节续读 */
    int len = hdr[1] & 0x7F;
    int mult = 1;
    int len_bytes = 1;
    unsigned char lb = hdr[1];
    while (lb & 0x80) {
        if (len_bytes >= 4) return -1;
        int r = read(fd, &lb, 1);
        if (r <= 0) return 0;
        len += (lb & 0x7F) * (mult * 128);
        mult *= 128;
        len_bytes++;
    }

    if (len > buflen - 2) len = buflen - 2;
    buf[0] = hdr[0];
    buf[1] = hdr[1];
    got = 0;
    time_t pl_start = time(NULL);
    while (got < len && time(NULL) - pl_start < 3) {
        int r = read(fd, buf + 2 + got, len - got);
        if (r > 0) got += r;
        else if (r < 0 && errno != EAGAIN && errno != EWOULDBLOCK) return -1;
        else usleep(5000);
    }
    *payload_len = got;
    return hdr[0] & 0xF0;
}

/* 解析 PUBLISH 报文的 topic 和 payload */
/* buf[0]=type, buf[1]=剩余长度编码, buf[2..]=payload区(topic长度字段+topic+payload) */
/* total = payload 区长度 (剩余长度, 不含 type+len 头) */
static void mqtt_parse_publish(const unsigned char *buf, int total,
                               char *topic, int topic_max,
                               const unsigned char **payload, int *payload_len)
{
    if (total < 4) { topic[0] = 0; *payload = NULL; *payload_len = 0; return; }
    int tlen = (buf[2] << 8) | buf[3];
    if (tlen >= topic_max) tlen = topic_max - 1;
    memcpy(topic, buf + 4, tlen);
    topic[tlen] = 0;
    *payload = buf + 4 + tlen;
    *payload_len = total - 2 - tlen;
    if (*payload_len < 0) *payload_len = 0;
}

/* 心跳 */
static int mqtt_ping(int fd)
{
    return mqtt_send_packet(fd, MQTT_PINGREQ, NULL, 0);
}

#endif /* ZIGBEED_MQTT_H */
