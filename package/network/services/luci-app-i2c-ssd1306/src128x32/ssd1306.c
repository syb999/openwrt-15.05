#include "ssd1306.h"
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>

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

static int i2c_write(SSD1306_Device *dev, const uint8_t *data, size_t len) {
    int retry = 3;
    while (retry--) {
        if (write(dev->i2c_fd, data, len) == (ssize_t)len) {
            return 0;
        }
        usleep(10000);
    }
    perror("I2C write failed after retries");
    return -1;
}

static void write_command(SSD1306_Device *dev, uint8_t cmd) {
    uint8_t buf[2] = {0x00, cmd};
    i2c_write(dev, buf, 2);
}

static const uint8_t init_sequence[] = {
    0xAE,
    0xD5, 0x80,
    0xA8, 0x1F,
    0xD3, 0x00,
    0x40,
    0xA1,
    0xC8,
    0xDA, 0x02,
    0x81, 0x8F,
    0xD9, 0xF1,
    0xDB, 0x40,
    0xA4,
    0xA6,
    0x8D, 0x14,
    0xAF
};


int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config) {
    if (!dev || !config) return -1;

    if ((dev->i2c_fd = open(config->i2c_bus, O_RDWR)) < 0)
        return -1;

    if (ioctl(dev->i2c_fd, I2C_SLAVE, config->i2c_addr) < 0) {
        close(dev->i2c_fd);
        return -1;
    }

    // Reset display
    write_command(dev, 0xAE);  // Display off
    write_command(dev, 0xD5);  // Set display clock divide ratio/oscillator frequency
    write_command(dev, 0x80);  // Suggested ratio
    write_command(dev, 0xA8);  // Set multiplex ratio
    write_command(dev, 0x1F);  // 1/32 duty
    write_command(dev, 0xD3);  // Set display offset
    write_command(dev, 0x00);  // No offset
    write_command(dev, 0x40);  // Set display start line
    write_command(dev, 0xA1);  // Segment remap
    write_command(dev, 0xC8);  // COM output scan direction
    write_command(dev, 0xDA);  // Set COM pins hardware configuration
    write_command(dev, 0x02);
    write_command(dev, 0x81);  // Set contrast control
    write_command(dev, 0x8F);
    write_command(dev, 0xD9);  // Set pre-charge period
    write_command(dev, 0xF1);
    write_command(dev, 0xDB);  // Set VCOMH deselect level
    write_command(dev, 0x40);
    write_command(dev, 0xA4);  // Entire display on
    write_command(dev, 0xA6);  // Set normal display
    write_command(dev, 0x8D);  // Charge pump setting
    write_command(dev, 0x14);
    write_command(dev, 0xAF);  // Display on

    dev->width = SSD1306_WIDTH;
    dev->height = SSD1306_HEIGHT;
    dev->buffer = malloc(dev->width * dev->height / 8);
    if (!dev->buffer) {
        close(dev->i2c_fd);
        return -1;
    }
    ssd1306_clear(dev);
    memcpy(&dev->config, config, sizeof(SSD1306_Config));

    dev->power_on = true;

    return 0;
}

void ssd1306_cleanup(SSD1306_Device *dev) {
    if (dev->i2c_fd >= 0) {
        uint8_t buf[2] = {0x00, 0xAE};
        write(dev->i2c_fd, buf, 2);
        close(dev->i2c_fd);
    }
    free(dev->buffer);
}

void ssd1306_clear(SSD1306_Device *dev) {
    if (dev && dev->buffer) {
        memset(dev->buffer, 0, dev->width * dev->height / 8);
    }
}

void ssd1306_display(SSD1306_Device *dev) {
    if (!dev) return;

    uint8_t setup_cmds[] = {
        0x21, 0x00, 0x7F,  // Set column address range (0-127)
        0x22, 0x00, 0x07    // Set page address range (0-7 for 64-line display)
    };
    
    // Send setup commands
    for (size_t i = 0; i < sizeof(setup_cmds); i++) {
        write_command(dev, setup_cmds[i]);
    }

    // Send display data in chunks
    for (uint16_t page = 0; page < 8; page++) {
        write_command(dev, 0xB0 | page);  // Set page start address
        write_command(dev, 0x00);         // Set lower column start address
        write_command(dev, 0x10);         // Set higher column start address
        
        uint8_t buf[17];
        buf[0] = 0x40;  // Co=0, D/C=1 (data)
        
        uint16_t start = page * SSD1306_WIDTH;
        for (uint16_t i = 0; i < SSD1306_WIDTH; i += 16) {
            uint16_t remaining = SSD1306_WIDTH - i;
            uint16_t chunk_size = (remaining > 16) ? 16 : remaining;
            
            memcpy(&buf[1], &dev->buffer[start + i], chunk_size);
            if (i2c_write(dev, buf, chunk_size + 1) != 0) {
                fprintf(stderr, "Display update failed at page %d, col %d\n", page, i);
            }
            usleep(1000);  // Reduced delay
        }
    }
}

void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c) {
    if (x >= SSD1306_WIDTH || y >= SSD1306_HEIGHT) {
        return;
    }

    if (c < 32 || c > 126) {
        c = '?';
    }

    uint8_t char_index = c - 32;
    if (char_index >= (sizeof(font5x7)/5)) {
        char_index = '?' - 32;
    }
    const uint8_t *glyph = &font5x7[char_index * 5];

    for (uint8_t col = 0; col < 5; col++) {
        if (x + col >= SSD1306_WIDTH) break;
        
        uint8_t col_data = glyph[col];
        for (uint8_t bit = 0; bit < 7; bit++) {
            if (y + bit >= SSD1306_HEIGHT) break;
            
            uint16_t buf_index = x + col + ((y + bit) / 8) * SSD1306_WIDTH;
            uint8_t bit_pos = (y + bit) % 8;
            
            if (col_data & (1 << bit)) {
                dev->buffer[buf_index] |= (1 << bit_pos);
            } else {
                dev->buffer[buf_index] &= ~(1 << bit_pos);
            }
        }
    }
}

void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str) {
    while (*str && x < SSD1306_WIDTH) {
        ssd1306_draw_char(dev, x, y, *str++);
        x += FONT_WIDTH + CHAR_SPACING;
        
        if (x >= SSD1306_WIDTH - FONT_WIDTH) {
            x = 0;
            y += FONT_HEIGHT + 1;
            if (y >= SSD1306_HEIGHT - FONT_HEIGHT) break;
        }
    }
}

int process_shell_command(const char *cmd, char *output, size_t out_len) {
    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe");
        return 0;
    }

    pid_t pid = fork();
    if (pid == -1) {
        perror("fork");
        close(pipefd[0]);
        close(pipefd[1]);
        return 0;
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);
        execl("/bin/sh", "sh", "-c", cmd, NULL);
        perror("execl");
        _exit(1);
    } else {
        close(pipefd[1]);
        ssize_t bytes_read = read(pipefd[0], output, out_len - 1);
        close(pipefd[0]);
        
        if (bytes_read > 0) {
            output[bytes_read] = '\0';
            waitpid(pid, NULL, 0);
            return 1;
        } else {
            waitpid(pid, NULL, 0);
            return 0;
        }
    }
}

void replace_shell_commands(char *line, size_t line_len) {
    char temp[line_len * 2];
    char *src = line;
    char *dst = temp;
    size_t remaining = sizeof(temp) - 1;
    
    *dst = 0;
    
    while (*src && remaining > 1) {
        if (strncmp(src, "$(", 2) == 0) {
            char *end = strchr(src + 2, ')');
            if (end) {
                char cmd[DEFAULT_MAX_CMD_LENGTH];
                size_t cmd_len = end - (src + 2);
                
                if (cmd_len >= sizeof(cmd)) cmd_len = sizeof(cmd) - 1;
                
                strncpy(cmd, src + 2, cmd_len);
                cmd[cmd_len] = 0;
                
                char output[DEFAULT_MAX_CMD_LENGTH];
                if (process_shell_command(cmd, output, sizeof(output))) {
                    char *out_ptr = output;
                    while (*out_ptr && remaining > 1) {
                        if ((*out_ptr >= 32 && *out_ptr <= 126) || *out_ptr == ' ') {
                            *dst++ = *out_ptr;
                            remaining--;
                        }
                        out_ptr++;
                    }
                }
                src = end + 1;
                continue;
            }
        }
        
        if ((*src >= 32 && *src <= 126) || *src == ' ') {
            *dst++ = *src;
            remaining--;
        }
        src++;
    }
    
    *dst = 0;
    strncpy(line, temp, line_len);
    line[line_len - 1] = 0;
}

void ssd1306_display_log(SSD1306_Device *dev) {
   
    FILE *fp = fopen(dev->config.log_file, "r");
    if (!fp) {
        ssd1306_clear(dev);
        ssd1306_draw_string(dev, 0, 0, "Log Open Error");
        ssd1306_display(dev);
        return;
    }

    ssd1306_clear(dev);
    char line[SSD1306_WIDTH + 1];
    uint8_t line_num = 0;
    
    while (line_num < 4 && fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\r\n")] = 0;
        
        ssd1306_draw_string(dev, 0, line_num * 8, line);
        line_num++;
    }
    
    fclose(fp);
    ssd1306_display(dev);
}

void ssd1306_power_on(SSD1306_Device *dev) {
    if (dev->i2c_fd < 0) return;

    uint8_t cmd[] = {0x00, 0xAF};
    if (write(dev->i2c_fd, cmd, sizeof(cmd)) != sizeof(cmd)) {
        fprintf(stderr, "Failed to power on SSD1306\n");
        return;
    }
    
    dev->power_on = true;
}

void ssd1306_power_off(SSD1306_Device *dev) {
    if (dev->i2c_fd < 0) return;

    uint8_t cmd[] = {0x00, 0xAE};
    if (write(dev->i2c_fd, cmd, sizeof(cmd)) != sizeof(cmd)) {
        fprintf(stderr, "Failed to power off SSD1306\n");
        return;
    }
    
    dev->power_on = false;
}
