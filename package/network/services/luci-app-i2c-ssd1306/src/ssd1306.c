#include "ssd1306.h"
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/wait.h>

#define DEFAULT_MAX_CMD_LENGTH 64

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

static const uint8_t init_sequence[] = {
    0xAE, 0xD5, 0x80, 0xA8, 0x3F, 0xD3, 0x00, 0x40,
    0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x12,
    0x81, 0xCF, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF
};

static int i2c_write(SSD1306_Device *dev, const uint8_t *data, size_t len) {
    if (write(dev->i2c_fd, data, len) != (ssize_t)len) {
        return -1;
    }
    return 0;
}

void write_command(SSD1306_Device *dev, uint8_t cmd) {
    uint8_t buf[2] = {0x00, cmd};
    i2c_write(dev, buf, 2);
}

int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config) {
    if ((dev->i2c_fd = open(config->i2c_bus, O_RDWR)) < 0) {
        perror("Failed to open I2C device");
        return -1;
    }

    if (ioctl(dev->i2c_fd, I2C_SLAVE, config->i2c_addr) < 0) {
        perror("Failed to set I2C address");
        close(dev->i2c_fd);
        return -1;
    }

    for (size_t i = 0; i < sizeof(init_sequence); i++) {
        write_command(dev, init_sequence[i]);
    }

    dev->config = *config;
    dev->buffer = malloc(LOGICAL_WIDTH * LOGICAL_HEIGHT / 8);
    if (!dev->buffer) {
        close(dev->i2c_fd);
        return -1;
    }

    dev->buffer = malloc(LOGICAL_WIDTH * (LOGICAL_HEIGHT / 8));
    memset(dev->buffer, 0, LOGICAL_WIDTH * (LOGICAL_HEIGHT / 8));

    dev->scale = (config->type == SSD1306_128x64) ? 2 : 1;
    dev->last_state_change = 0;
    
    return 0;
}

void ssd1306_cleanup(SSD1306_Device *dev) {
    if (dev->i2c_fd >= 0) {
        write_command(dev, 0xAE);
        close(dev->i2c_fd);
    }
    free(dev->buffer);
}

void ssd1306_clear(SSD1306_Device *dev) {
    memset(dev->buffer, 0, LOGICAL_WIDTH * LOGICAL_HEIGHT / 8);
}

void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c) {
    if (x >= LOGICAL_WIDTH || y >= LOGICAL_HEIGHT) return;
    if (c < 32 || c > 126) c = '?';
    
    const uint8_t *glyph = &font5x7[(c - 32) * 5];
    uint8_t page = y / 8;
    uint8_t bit_offset = y % 8;
    
    for (uint8_t col = 0; col < 5; col++) {
        if (bit_offset) {
            dev->buffer[page * LOGICAL_WIDTH + x + col] |= (glyph[col] << bit_offset);
            if (page + 1 < LOGICAL_HEIGHT/8) {
                dev->buffer[(page + 1) * LOGICAL_WIDTH + x + col] |= (glyph[col] >> (8 - bit_offset));
            }
        } else {
            dev->buffer[page * LOGICAL_WIDTH + x + col] |= glyph[col];
        }
    }
}

void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str) {
    char limited_str[22] = {0};
    strncpy(limited_str, str, 20);
    limited_str[20] = '\0';
    
    const char *p = limited_str;
    while (*p && x < LOGICAL_WIDTH) {
        ssd1306_draw_char(dev, x, y, *p++);
        x += 6;
        if (x >= LOGICAL_WIDTH - 5) {
            x = 0;
            y += 8;
            if (y >= LOGICAL_HEIGHT) break;
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
        for (size_t i = 0; i < sizeof(init_sequence); i++) {
            write_command(dev, init_sequence[i]);
        }
        ssd1306_display(dev);
    } else {
        write_command(dev, 0xAE);
    }
}

void ssd1306_display(SSD1306_Device *dev) {
    write_command(dev, 0x21);
    write_command(dev, 0x00);
    write_command(dev, LOGICAL_WIDTH - 1);
    
    write_command(dev, 0x22);
    write_command(dev, 0x00);
    write_command(dev, (LOGICAL_HEIGHT / 8) - 1);
    
    uint8_t buf[LOGICAL_WIDTH + 1];
    buf[0] = 0x40;
    
    for (uint8_t page = 0; page < LOGICAL_HEIGHT/8; page++) {
        memcpy(&buf[1], &dev->buffer[page * LOGICAL_WIDTH], LOGICAL_WIDTH);
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
    
    dev->last_state_change = 0;
    char line[LOGICAL_WIDTH + 1];
    uint8_t line_num = 0;
    ssd1306_clear(dev);
    
    while (line_num < 6 && fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\r\n")] = 0;

        if (strstr(line, "$(")) {
            parse_and_draw_shell(dev, 0, line_num * 8, line);
        } else {
            ssd1306_draw_string(dev, 0, line_num * 8, line);
        }
        line_num++;
    }
    
    fclose(fp);
    ssd1306_display(dev);
}
