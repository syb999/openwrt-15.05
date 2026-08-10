#include "ssd1306.h"
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
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

static const uint8_t *init_sequence_for(SSD1306_Type type) {
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

void write_command(SSD1306_Device *dev, uint8_t cmd) {
    uint8_t buf[2] = {0x00, cmd};
    i2c_write(dev, buf, 2);
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
    dev->width = LOGICAL_WIDTH;
    dev->height = (config->type == SSD1306_128x32) ? 32 : 64;

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
    
    const uint8_t *glyph = &font5x7[(c - 32) * 5];
    uint8_t page = y / 8;
    uint8_t bit_offset = y % 8;
    
    for (uint8_t col = 0; col < 5; col++) {
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
    char limited_str[22] = {0};
    strncpy(limited_str, str, 20);
    limited_str[20] = '\0';
    
    const char *p = limited_str;
    while (*p && x < dev->width) {
        ssd1306_draw_char(dev, x, y, *p++);
        x += 6;
        if (x >= dev->width - 5) {
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

static char* exec_shell_command(const char* cmd) {
    static char result[128] = {0};
    FILE* fp = popen(cmd, "r");
    if (fp == NULL) {
        strcpy(result, "[CMD ERR]");
        return result;
    }

    if (fgets(result, sizeof(result), fp) == NULL) {
        strcpy(result, "[NO OUTPUT]");
    }
    pclose(fp);

    char* p = result;
    while (*p) {
        if (*p == '\n' || *p == '\r' || (*p < 32 && *p != '\t')) {
            *p = ' ';
        }
        p++;
    }
    
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

void ssd1306_display(SSD1306_Device *dev) {
    uint8_t buf[LOGICAL_WIDTH + 1];
    buf[0] = 0x40;

    /* Incremental refresh: compare each page against what the panel shows
       and push only the changed ones. A 1-line clock update costs ~1 page
       of I2C traffic instead of a full 8-page frame. */
    for (uint8_t page = 0; page < dev->height/8; page++) {
        const uint8_t *cur = &dev->buffer[page * dev->width];
        uint8_t *last = &dev->last_buffer[page * dev->width];
        if (memcmp(cur, last, dev->width) == 0)
            continue;

        memcpy(last, cur, dev->width);
        write_command(dev, 0xB0 | page);   /* set page address */
        write_command(dev, 0x00);          /* lower column start */
        write_command(dev, 0x10);          /* higher column start */
        memcpy(&buf[1], cur, dev->width);
        i2c_write(dev, buf, sizeof(buf));
    }
}

void ssd1306_display_log(SSD1306_Device *dev) {
    const time_t now = time(NULL);
    const time_t error_min_duration = 5;
    
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
            parse_and_draw_shell(dev, 0, i * 8, lines[i]);
        } else {
            ssd1306_draw_string(dev, 0, i * 8, lines[i]);
        }
    }
    ssd1306_display(dev);
}
