#include "ssd1306.h"
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/wait.h>

#define DEFAULT_MAX_CMD_LENGTH 64

/* Log file unchanged: keep a low-frequency fallback refresh so dynamic
   $(cmd) content (e.g. $(date ...)) still updates without redrawing the
   whole panel every second. Static-only logs fall back even less often.
   Refresh is incremental (only changed pages are pushed), so 1 s here
   costs a fraction of a full-frame redraw. */
#define REFRESH_INTERVAL         1   /* dynamic content ($(...)) fallback */
#define STATIC_REFRESH_INTERVAL 30   /* static content fallback */

/* --- $(cmd) execution hardening (see readme_c_review.md, fixes A+B) --- */
#define CMD_TIMEOUT_SECS     5   /* max seconds a single $(cmd) may run      */
#define CMD_BUDGET_SECS     10   /* max total $(cmd) time per display_log()  */
#define CMD_FAST_INTERVAL    1   /* date/uptime/hostname/uname re-run cadence */
#define CMD_SLOW_INTERVAL   15   /* everything else (ifstatus, ubus, ...)     */
#define CMD_CACHE_MAX        8

const uint8_t font5x7[] = {
    //   (32)
    0x00, 0x00, 0x00, 0x00, 0x00,
    // ! (33)
    0x00, 0x00, 0x5F, 0x00, 0x00,
    // " (34)
    0x00, 0x07, 0x00, 0x07, 0x00,
    // # (35)
    0x14, 0x7F, 0x14, 0x7F, 0x14,
    // $ (36)
    0x24, 0x2A, 0x7F, 0x2A, 0x12,
    // % (37)
    0x23, 0x13, 0x08, 0x64, 0x62,
    // & (38)
    0x36, 0x49, 0x56, 0x20, 0x50,
    // ' (39)
    0x00, 0x08, 0x07, 0x03, 0x00,
    // ( (40)
    0x00, 0x1C, 0x22, 0x41, 0x00,
    // ) (41)
    0x00, 0x41, 0x22, 0x1C, 0x00,
    // * (42)
    0x2A, 0x1C, 0x7F, 0x1C, 0x2A,
    // + (43)
    0x08, 0x08, 0x3E, 0x08, 0x08,
    // , (44)
    0x00, 0x80, 0x70, 0x30, 0x00,
    // - (45)
    0x08, 0x08, 0x08, 0x08, 0x08,
    // . (46)
    0x00, 0x00, 0x60, 0x60, 0x00,
    // / (47)
    0x20, 0x10, 0x08, 0x04, 0x02,
    // 0 (48)
    0x3E, 0x51, 0x49, 0x45, 0x3E,
    // 1 (49)
    0x00, 0x42, 0x7F, 0x40, 0x00,
    // 2 (50)
    0x72, 0x49, 0x49, 0x49, 0x46,
    // 3 (51)
    0x21, 0x41, 0x49, 0x4D, 0x33,
    // 4 (52)
    0x18, 0x14, 0x12, 0x7F, 0x10,
    // 5 (53)
    0x27, 0x45, 0x45, 0x45, 0x39,
    // 6 (54)
    0x3C, 0x4A, 0x49, 0x49, 0x31,
    // 7 (55)
    0x41, 0x21, 0x11, 0x09, 0x07,
    // 8 (56)
    0x36, 0x49, 0x49, 0x49, 0x36,
    // 9 (57)
    0x46, 0x49, 0x49, 0x29, 0x1E,
    // : (58)
    0x00, 0x00, 0x14, 0x00, 0x00,
    // ; (59)
    0x00, 0x40, 0x34, 0x00, 0x00,
    // < (60)
    0x00, 0x08, 0x14, 0x22, 0x41,
    // = (61)
    0x14, 0x14, 0x14, 0x14, 0x14,
    // > (62)
    0x00, 0x41, 0x22, 0x14, 0x08,
    // ? (63)
    0x02, 0x01, 0x59, 0x09, 0x06,
    // @ (64)
    0x3E, 0x41, 0x5D, 0x59, 0x4E,
    // A (65)
    0x7C, 0x12, 0x11, 0x12, 0x7C,
    // B (66)
    0x7F, 0x49, 0x49, 0x49, 0x36,
    // C (67)
    0x3E, 0x41, 0x41, 0x41, 0x22,
    // D (68)
    0x7F, 0x41, 0x41, 0x41, 0x3E,
    // E (69)
    0x7F, 0x49, 0x49, 0x49, 0x41,
    // F (70)
    0x7F, 0x09, 0x09, 0x09, 0x01,
    // G (71)
    0x3E, 0x41, 0x41, 0x51, 0x73,
    // H (72)
    0x7F, 0x08, 0x08, 0x08, 0x7F,
    // I (73)
    0x00, 0x41, 0x7F, 0x41, 0x00,
    // J (74)
    0x20, 0x40, 0x41, 0x3F, 0x01,
    // K (75)
    0x7F, 0x08, 0x14, 0x22, 0x41,
    // L (76)
    0x7F, 0x40, 0x40, 0x40, 0x40,
    // M (77)
    0x7F, 0x02, 0x1C, 0x02, 0x7F,
    // N (78)
    0x7F, 0x04, 0x08, 0x10, 0x7F,
    // O (79)
    0x3E, 0x41, 0x41, 0x41, 0x3E,
    // P (80)
    0x7F, 0x09, 0x09, 0x09, 0x06,
    // Q (81)
    0x3E, 0x41, 0x51, 0x21, 0x5E,
    // R (82)
    0x7F, 0x09, 0x19, 0x29, 0x46,
    // S (83)
    0x26, 0x49, 0x49, 0x49, 0x32,
    // T (84)
    0x03, 0x01, 0x7F, 0x01, 0x03,
    // U (85)
    0x3F, 0x40, 0x40, 0x40, 0x3F,
    // V (86)
    0x1F, 0x20, 0x40, 0x20, 0x1F,
    // W (87)
    0x3F, 0x40, 0x38, 0x40, 0x3F,
    // X (88)
    0x63, 0x14, 0x08, 0x14, 0x63,
    // Y (89)
    0x03, 0x04, 0x78, 0x04, 0x03,
    // Z (90)
    0x61, 0x59, 0x49, 0x4D, 0x43,
    // [ (91)
    0x00, 0x7F, 0x41, 0x41, 0x41,
    // \ (92)
    0x02, 0x04, 0x08, 0x10, 0x20,
    // ] (93)
    0x00, 0x41, 0x41, 0x41, 0x7F,
    // ^ (94)
    0x04, 0x02, 0x01, 0x02, 0x04,
    // _ (95)
    0x40, 0x40, 0x40, 0x40, 0x40,
    // ` (96)
    0x00, 0x03, 0x07, 0x08, 0x00,
    // a (97)
    0x20, 0x54, 0x54, 0x78, 0x40,
    // b (98)
    0x7F, 0x28, 0x44, 0x44, 0x38,
    // c (99)
    0x38, 0x44, 0x44, 0x44, 0x28,
    // d (100)
    0x38, 0x44, 0x44, 0x28, 0x7F,
    // e (101)
    0x38, 0x54, 0x54, 0x54, 0x18,
    // f (102)
    0x00, 0x08, 0x7E, 0x09, 0x02,
    // g (103)
    0x18, 0xA4, 0xA4, 0x9C, 0x78,
    // h (104)
    0x7F, 0x08, 0x04, 0x04, 0x78,
    // i (105)
    0x00, 0x44, 0x7D, 0x40, 0x00,
    // j (106)
    0x20, 0x40, 0x40, 0x3D, 0x00,
    // k (107)
    0x7F, 0x10, 0x28, 0x44, 0x00,
    // l (108)
    0x00, 0x41, 0x7F, 0x40, 0x00,
    // m (109)
    0x7C, 0x04, 0x78, 0x04, 0x78,
    // n (110)
    0x7C, 0x08, 0x04, 0x04, 0x78,
    // o (111)
    0x38, 0x44, 0x44, 0x44, 0x38,
    // p (112)
    0xFC, 0x18, 0x24, 0x24, 0x18,
    // q (113)
    0x18, 0x24, 0x24, 0x18, 0xFC,
    // r (114)
    0x7C, 0x08, 0x04, 0x04, 0x08,
    // s (115)
    0x48, 0x54, 0x54, 0x54, 0x24,
    // t (116)
    0x04, 0x04, 0x3F, 0x44, 0x24,
    // u (117)
    0x3C, 0x40, 0x40, 0x20, 0x7C,
    // v (118)
    0x1C, 0x20, 0x40, 0x20, 0x1C,
    // w (119)
    0x3C, 0x40, 0x30, 0x40, 0x3C,
    // x (120)
    0x44, 0x28, 0x10, 0x28, 0x44,
    // y (121)
    0x4C, 0x90, 0x90, 0x90, 0x7C,
    // z (122)
    0x44, 0x64, 0x54, 0x4C, 0x44,
    // { (123)
    0x00, 0x08, 0x36, 0x41, 0x00,
    // | (124)
    0x00, 0x00, 0x77, 0x00, 0x00,
    // } (125)
    0x00, 0x41, 0x36, 0x08, 0x00,
    // ~ (126)
    0x08, 0x08, 0x2A, 0x1C, 0x08
};

static const uint8_t init_sequence_64[] = {
    0xAE, 0xD5, 0x80, 0xA8, 0x3F, 0xD3, 0x00, 0x40,
    0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x12,
    0x81, 0xCF, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF
};

static const uint8_t init_sequence_32[] = {
    0xAE, 0xD5, 0x80, 0xA8, 0x1F, 0xD3, 0x00, 0x40,
    0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x02,
    0x81, 0x8F, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF
};

/* SSD1315 (0.69" 96x16): same instruction set as SSD1306, differs in
   multiplex ratio (0x0F = 16 rows), COM pin config and contrast. */
static const uint8_t init_sequence_16[] = {
    0xAE, 0xD5, 0x80, 0xA8, 0x0F, 0xD3, 0x00, 0x40,
    0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x02,
    0x81, 0xAF, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF
};

/* All three init sequences are the same length (25 bytes); the loops in
   ssd1306_init()/ssd1306_power() use sizeof(init_sequence_64) as bound. */
static const uint8_t *init_sequence_for(SSD1306_Type type) {
    if (type == SSD1306_96x16) return init_sequence_16;
    return (type == SSD1306_128x32) ? init_sequence_32 : init_sequence_64;
}

static int i2c_write(SSD1306_Device *dev, const uint8_t *data, size_t len) {
    int retry = 3;
    while (retry--) {
        if (write(dev->i2c_fd, data, len) == (ssize_t)len) {
            dev->i2c_fail = 0;
            return 0;
        }
        usleep(10000);
    }
    perror("I2C write failed after retries");
    if (dev->i2c_fail < 255)
        dev->i2c_fail++;
    return -1;
}

int write_command(SSD1306_Device *dev, uint8_t cmd) {
    uint8_t buf[2] = {0x00, cmd};
    return i2c_write(dev, buf, 2);
}

int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config) {
    if (!dev || !config) return -1;

    if ((dev->i2c_fd = open(config->i2c_bus, O_RDWR)) < 0) {
        perror("Failed to open I2C device");
        return -1;
    }

    if (ioctl(dev->i2c_fd, I2C_SLAVE, config->i2c_addr) < 0) {
        perror("Failed to set I2C address");
        close(dev->i2c_fd);
        return -1;
    }

    /* Absent-panel probe: without a device ACK this write fails immediately.
       Bail out instead of running a busy error loop (which otherwise spins
       on retries and perror logging forever). */
    {
        uint8_t probe[2] = {0x00, 0xAE};
        if (write(dev->i2c_fd, probe, sizeof(probe)) != (ssize_t)sizeof(probe)) {
            fprintf(stderr, "No SSD1306 detected at %s address 0x%02X - aborting\n",
                    config->i2c_bus, config->i2c_addr);
            close(dev->i2c_fd);
            return -1;
        }
    }

    const uint8_t *seq = init_sequence_for(config->type);
    for (size_t i = 0; i < sizeof(init_sequence_64); i++) {
        write_command(dev, seq[i]);
    }

    dev->config = *config;
    /* Geometry is fully dynamic: 96x16 is 96 wide (SSD1315), the 128-wide
       panels use LOGICAL_WIDTH. height/8 pages drive buffers, page-range
       commands and the line loop everywhere else. */
    dev->width = (config->type == SSD1306_96x16) ? 96 : LOGICAL_WIDTH;
    dev->height = (config->type == SSD1306_128x32) ? 32 :
                  (config->type == SSD1306_96x16)  ? 16 : 64;

    /* 96x16 is only 96px wide: the normal 5x7 spacing (6px/char) fits 16
       chars per line, which truncates IPs. Squeeze the SAME 5x7 font to
       zero spacing (5px/char, 19 chars/line) so "WAN:255.255.255.255"
       fits on one line while keeping full 5x7 readability (4x6 was too
       thin/blocky). */
    dev->font = font5x7;
    dev->font_width = 5;
    dev->font_step = (config->type == SSD1306_96x16) ? 5 : 6;

    dev->buffer = malloc(dev->width * (dev->height / 8));
    if (!dev->buffer) {
        close(dev->i2c_fd);
        return -1;
    }
    memset(dev->buffer, 0, dev->width * (dev->height / 8));

    /* last_buffer tracks what the panel shows; init to 0xFF so the first
       ssd1306_display() pushes every page (dirty vs blank buffer). */
    dev->last_buffer = malloc(dev->width * (dev->height / 8));
    if (!dev->last_buffer) {
        free(dev->buffer);
        close(dev->i2c_fd);
        return -1;
    }
    memset(dev->last_buffer, 0xFF, dev->width * (dev->height / 8));

    dev->last_state_change = 0;
    dev->last_mtime = 0;
    dev->last_size = 0;
    dev->last_refresh = 0;
    dev->i2c_fail = 0;
    dev->burnin_shift = 0;
    dev->burnin_shifted = false;
    dev->burnin_next = 0;

    return 0;
}

void ssd1306_cleanup(SSD1306_Device *dev) {
    if (dev->i2c_fd >= 0) {
        write_command(dev, 0xAE);
        close(dev->i2c_fd);
    }
    free(dev->buffer);
    free(dev->last_buffer);
}

void ssd1306_clear(SSD1306_Device *dev) {
    memset(dev->buffer, 0, dev->width * dev->height / 8);
}

void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c) {
    if (x >= dev->width || y >= dev->height) return;
    if (c < 32 || c > 126) c = '?';
    
    const uint8_t *glyph = &dev->font[(c - 32) * dev->font_width];
    uint8_t page = y / 8;
    uint8_t bit_offset = y % 8;
    
    for (uint8_t col = 0; col < dev->font_width; col++) {
        if (x + col >= dev->width) break;   /* clip at right edge (burn-in shift) */
        if (bit_offset) {
            dev->buffer[page * dev->width + x + col] |= (glyph[col] << bit_offset);
            if (page + 1 < dev->height/8) {
                dev->buffer[(page + 1) * dev->width + x + col] |= (glyph[col] >> (8 - bit_offset));
            }
        } else {
            dev->buffer[page * dev->width + x + col] |= glyph[col];
        }
    }
}

void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str) {
    char limited_str[28] = {0};
    strncpy(limited_str, str, 26);
    limited_str[26] = '\0';
    
    const char *p = limited_str;
    uint8_t step = dev->font_step;
    while (*p && x < dev->width) {
        ssd1306_draw_char(dev, x, y, *p++);
        x += step;
        if (x >= dev->width - dev->font_width) {
            x = 0;
            y += 8;
            if (y >= dev->height) break;
        }
    }
}

static int is_safe_command(const char* cmd) {
    const char* dangerous_chars = "&;";
    
    for (int i = 0; dangerous_chars[i]; i++) {
        if (strchr(cmd, dangerous_chars[i])) {
            return 0;
        }
    }

    const char* allowed_commands[] = {
        "date", "uptime", "ip", "cat", "free", 
        "df", "uname", "hostname", "uci", "ls", 
        "ifconfig", "head", "tail", "grep", "awk",
        "cut", "ubus", "jsonfilter", "ifstatus", NULL
    };
    
    int allowed = 0;
    for (int i = 0; allowed_commands[i]; i++) {
        if (strncmp(cmd, allowed_commands[i], strlen(allowed_commands[i])) == 0) {
            allowed = 1;
            break;
        }
    }
    
    return allowed;
}

/* ---- $(cmd) execution with timeout, frequency grading and budget ---- */

typedef struct {
    char cmd[64];        /* full command string = cache key (parse_and_draw_shell
                            caps commands at 63 chars, so 64 is always enough) */
    time_t last_run;
    char result[128];
} CmdCacheEntry;

static CmdCacheEntry cmd_cache[CMD_CACHE_MAX];
static int cmd_cache_n = 0;
static time_t cmd_budget_deadline = 0;   /* set per display_log() call */

static int cmd_is_fast(const char *token) {
    static const char *fast[] = { "date", "uptime", "hostname", "uname", NULL };
    for (int i = 0; fast[i]; i++)
        if (strcmp(token, fast[i]) == 0)
            return 1;
    return 0;
}

static void sanitize_output(char *s) {
    for (; *s; s++) {
        if (*s == '\n' || *s == '\r' || (*s < 32 && *s != '\t'))
            *s = ' ';
    }
}

/* Return cached output if this command ran recently enough, else NULL.
   Key is the FULL command string: two commands sharing a first token
   (e.g. "ifstatus lan ..." vs "ifstatus wan ...") must NOT collide. */
static char *cmd_cache_get(const char *cmd, const char *token, char *out, size_t out_sz) {
    for (int i = 0; i < cmd_cache_n; i++) {
        if (strcmp(cmd_cache[i].cmd, cmd) == 0) {
            time_t interval = cmd_is_fast(token) ? CMD_FAST_INTERVAL : CMD_SLOW_INTERVAL;
            if (time(NULL) - cmd_cache[i].last_run < interval) {
                snprintf(out, out_sz, "%s", cmd_cache[i].result);
                return out;
            }
            return NULL;
        }
    }
    return NULL;
}

static void cmd_cache_put(const char *cmd, const char *token, const char *result) {
    time_t now = time(NULL);
    for (int i = 0; i < cmd_cache_n; i++) {
        if (strcmp(cmd_cache[i].cmd, cmd) == 0) {
            cmd_cache[i].last_run = now;
            snprintf(cmd_cache[i].result, sizeof(cmd_cache[i].result), "%s", result);
            return;
        }
    }
    if (cmd_cache_n < CMD_CACHE_MAX) {
        snprintf(cmd_cache[cmd_cache_n].cmd, sizeof(cmd_cache[cmd_cache_n].cmd), "%s", cmd);
        cmd_cache[cmd_cache_n].last_run = now;
        snprintf(cmd_cache[cmd_cache_n].result, sizeof(cmd_cache[cmd_cache_n].result), "%s", result);
        cmd_cache_n++;
    }
}

static char *exec_shell_command(const char *cmd) {
    static char result[128] = {0};
    char token[16] = {0};
    size_t i = 0;

    /* First whitespace/pipe-delimited token identifies the command. */
    while (cmd[i] && cmd[i] != ' ' && cmd[i] != '\t' && cmd[i] != '|' &&
           i < sizeof(token) - 1) {
        token[i] = cmd[i];
        i++;
    }
    token[i] = '\0';

    /* Frequency gate: fast commands 1 s, slow commands 15 s. */
    if (token[0] && cmd_cache_get(cmd, token, result, sizeof(result)))
        return result;

    /* Whole-refresh budget: a batch of hung commands must never freeze the
       panel for tens of seconds; skip the rest and retry next refresh. */
    if (time(NULL) > cmd_budget_deadline) {
        strcpy(result, "[BUSY]");
        goto out;
    }

    {
        int fds[2];
        if (pipe(fds) != 0) {
            strcpy(result, "[PIPE ERR]");
            goto out;
        }

        pid_t pid = fork();
        if (pid < 0) {
            close(fds[0]);
            close(fds[1]);
            strcpy(result, "[FORK ERR]");
            goto out;
        }

        if (pid == 0) {
            /* Child: own process group so a timeout can kill the whole
               pipeline (sh + ubus + jsonfilter), not just the shell. */
            setpgid(0, 0);
            alarm(0);                    /* don't inherit the watchdog timer */
            close(fds[0]);
            dup2(fds[1], STDOUT_FILENO);
            close(fds[1]);
            execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
            _exit(127);
        }

        close(fds[1]);

        struct timeval tv = { CMD_TIMEOUT_SECS, 0 };
        fd_set rfds;
        FD_ZERO(&rfds);
        FD_SET(fds[0], &rfds);
        int sel = select(fds[0] + 1, &rfds, NULL, NULL, &tv);

        ssize_t n = 0;
        if (sel > 0) {
            n = read(fds[0], result, sizeof(result) - 1);
            if (n < 0)
                n = 0;
            if (n == 0)
                strcpy(result, "[NO OUTPUT]");
        } else {
            /* Timeout: kill the whole process group, show a marker. */
            kill(-pid, SIGKILL);
            strcpy(result, "[TIMEOUT]");
        }
        if (n > 0)
            result[n] = '\0';
        close(fds[0]);

        /* Reap; retry EINTR so no orphan can survive a signal. */
        while (waitpid(pid, NULL, 0) == -1 && errno == EINTR)
            ;
    }

out:
    sanitize_output(result);
    /* Cache successes and [TIMEOUT] (anti-hammer); don't cache transient
       [BUSY]/[PIPE ERR]/[FORK ERR] so they retry on the next refresh. */
    if (token[0] && strncmp(result, "[BUSY]", 6) != 0 &&
        strncmp(result, "[PIPE ERR]", 10) != 0 &&
        strncmp(result, "[FORK ERR]", 10) != 0)
        cmd_cache_put(cmd, token, result);
    return result;
}

void parse_and_draw_shell(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str) {
    char output[LOGICAL_WIDTH + 1] = {0};
    char temp[64];
    const char *start, *end;
    
    while (*str) {
        if (strncmp(str, "$(", 2) == 0) {
            start = str + 2;
            end = strchr(start, ')');
            if (end) {
                size_t cmd_len = end - start;
                if (cmd_len >= sizeof(temp)) cmd_len = sizeof(temp) - 1;
                
                strncpy(temp, start, cmd_len);
                temp[cmd_len] = '\0';
                
                if (is_safe_command(temp)) {
                    char* cmd_result = exec_shell_command(temp);
                    strncat(output, cmd_result, sizeof(output) - strlen(output) - 1);
                } else {
                    strncat(output, "[BLOCKED]", sizeof(output) - strlen(output) - 1);
                }
                str = end + 1;
                continue;
            }
        }
        
        size_t len = strcspn(str, "$(");
        if (len > 0) {
            strncat(output, str, len);
            str += len;
        } else {
            strncat(output, str, 1);
            str++;
        }
    }
    
    output[LOGICAL_WIDTH] = '\0';
    ssd1306_draw_string(dev, x, y, output);
}

void ssd1306_power(SSD1306_Device *dev, bool on) {
    if (on) {
        write_command(dev, 0xAF);
        const uint8_t *seq = init_sequence_for(dev->config.type);
        for (size_t i = 0; i < sizeof(init_sequence_64); i++) {
            write_command(dev, seq[i]);
        }
        ssd1306_display(dev);
    } else {
        write_command(dev, 0xAE);
    }
}

/* Push one page to the panel (dev->width bytes of data, NOT the fixed
   buffer ceiling: a 96-wide panel must send exactly 96 bytes, otherwise
   uninitialized tail bytes would leak onto the bus). Every attempt
   re-addresses the page first, so a partial/failed transfer (column
   pointer mid-page) can never corrupt subsequent data. Returns 0. */
static int write_page(SSD1306_Device *dev, uint8_t page, const uint8_t *data) {
    uint8_t buf[LOGICAL_WIDTH + 1];
    buf[0] = 0x40;
    memcpy(&buf[1], data, dev->width);

    int attempts = 3;
    while (attempts--) {
        if (write_command(dev, 0xB0 | page) == 0 &&
            write_command(dev, 0x00) == 0 &&
            write_command(dev, 0x10) == 0 &&
            i2c_write(dev, buf, dev->width + 1) == 0)
            return 0;
        usleep(10000);
    }
    return -1;
}

void ssd1306_display(SSD1306_Device *dev) {
    /* Incremental refresh: compare each page against what the panel shows
       and push only the changed ones. last_buffer is updated ONLY after a
       successful transfer: a failed write leaves the page dirty so the next
       refresh retries it (self-healing, no permanent desync = no garbling
       after hours of occasional I2C glitches). */
    for (uint8_t page = 0; page < dev->height/8; page++) {
        const uint8_t *cur = &dev->buffer[page * dev->width];
        uint8_t *last = &dev->last_buffer[page * dev->width];
        if (memcmp(cur, last, dev->width) == 0)
            continue;
        if (write_page(dev, page, cur) == 0)
            memcpy(last, cur, dev->width);
    }
}

void ssd1306_display_log(SSD1306_Device *dev) {
    const time_t now = time(NULL);
    const time_t error_min_duration = 5;

    /* Refresh-wide command budget (see CMD_BUDGET_SECS): bounds the total
       time spent running $(cmd) so one bad refresh can't freeze the panel. */
    cmd_budget_deadline = now + CMD_BUDGET_SECS;
    
    char full_path[128];
    snprintf(full_path, sizeof(full_path), "%s%s", 
            (dev->config.log_file[0] == '/') ? "" : "/",
            dev->config.log_file);

    /* Track log file changes (mtime/size). */
    struct stat st;
    bool changed = false;
    if (stat(full_path, &st) == 0) {
        if (st.st_mtime != dev->last_mtime || st.st_size != dev->last_size) {
            changed = true;
            dev->last_mtime = st.st_mtime;
            dev->last_size = st.st_size;
        }
    } else {
        /* File missing: error banner shows a live countdown, always redraw. */
        changed = true;
    }

    FILE *fp = fopen(full_path, "r");
    if (!fp) {
        if (dev->last_state_change == 0) {
            dev->last_state_change = now;
        }
        
        if (now - dev->last_state_change < error_min_duration) {
            ssd1306_clear(dev);
            char buf[32];
            snprintf(buf, sizeof(buf), "Retry in %lds", 
                    error_min_duration - (now - dev->last_state_change));
            ssd1306_draw_string(dev, 0, 0, buf);
        } else {
            ssd1306_clear(dev);
            ssd1306_draw_string(dev, 0, 0, "LOGFILE ERROR");
            ssd1306_draw_string(dev, 0, 8, full_path);
        }
        ssd1306_display(dev);
        return;
    }

    /* Read lines into a small buffer and detect dynamic $(cmd) content. */
    char lines[8][LOGICAL_WIDTH + 1];
    uint8_t line_count = 0;
    bool has_dynamic = false;
    while (line_count < dev->height/8 && fgets(lines[line_count], sizeof(lines[line_count]), fp)) {
        lines[line_count][strcspn(lines[line_count], "\r\n")] = 0;
        if (strstr(lines[line_count], "$("))
            has_dynamic = true;
        line_count++;
    }
    fclose(fp);

    /* Skip redraw when nothing changed: dynamic logs refresh every
       REFRESH_INTERVAL s, static logs only every STATIC_REFRESH_INTERVAL s. */
    if (!changed) {
        time_t interval = has_dynamic ? REFRESH_INTERVAL : STATIC_REFRESH_INTERVAL;
        if (now - dev->last_refresh < interval)
            return;
    }
    dev->last_refresh = now;

    dev->last_state_change = 0;
    ssd1306_clear(dev);
    for (uint8_t i = 0; i < line_count; i++) {
        if (strstr(lines[i], "$(")) {
            parse_and_draw_shell(dev, dev->burnin_shift, i * 8, lines[i]);
        } else {
            ssd1306_draw_string(dev, dev->burnin_shift, i * 8, lines[i]);
        }
    }
    ssd1306_display(dev);
}
