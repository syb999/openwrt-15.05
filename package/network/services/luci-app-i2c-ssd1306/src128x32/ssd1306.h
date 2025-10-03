#ifndef SSD1306_H
#define SSD1306_H

#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <sys/types.h>
#include <sys/wait.h>

#define SSD1306_WIDTH  128
#define SSD1306_HEIGHT 32

#define FONT_WIDTH      5
#define FONT_HEIGHT     7
#define CHAR_SPACING    1

#define DEFAULT_I2C_BUS    "/dev/i2c-0"
#define DEFAULT_I2C_ADDR   0x3C
#define DEFAULT_LOG_FILE   "/var/log/ssd1306.log"
#define CONFIG_FILE        "/etc/config/i2c-ssd1306"

typedef struct {
    bool enabled;
    char i2c_bus[32];
    uint8_t i2c_addr;
    char log_file[64];
    int screen_on_time;
    int screen_off_time;
} SSD1306_Config;

typedef struct {
    int i2c_fd;
    SSD1306_Config config;
    bool power_on;  
    uint8_t width;
    uint8_t height;
    uint8_t *buffer;
} SSD1306_Device;

extern const uint8_t font5x7[];

int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config);
void ssd1306_cleanup(SSD1306_Device *dev);
void ssd1306_display(SSD1306_Device *dev);
void ssd1306_clear(SSD1306_Device *dev);
void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c);
void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str);
void ssd1306_display_log(SSD1306_Device *dev);
int process_shell_command(const char *cmd, char *output, size_t out_len);
void replace_shell_commands(char *line, size_t line_len);

void ssd1306_power_on(SSD1306_Device *dev);
void ssd1306_power_off(SSD1306_Device *dev);

#endif
