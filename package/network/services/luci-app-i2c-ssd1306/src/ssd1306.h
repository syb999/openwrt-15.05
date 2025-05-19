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
#include <time.h>

#define LOGICAL_WIDTH 128
#define LOGICAL_HEIGHT 64

typedef enum {
    SSD1306_128x32,
    SSD1306_128x64
} SSD1306_Type;

typedef struct {
    bool enabled;
    char i2c_bus[32];
    uint8_t i2c_addr;
    char log_file[64];
    SSD1306_Type type;
    uint16_t screen_on_time;
    uint16_t screen_off_time;
} SSD1306_Config;

typedef struct {
    int i2c_fd;
    SSD1306_Config config;
    uint8_t *buffer;
    uint8_t scale;
    time_t last_state_change;
} SSD1306_Device;

int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config);
void ssd1306_cleanup(SSD1306_Device *dev);

void ssd1306_display(SSD1306_Device *dev);
void ssd1306_clear(SSD1306_Device *dev);

void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c);
void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str);

void ssd1306_display_log(SSD1306_Device *dev);
void parse_and_draw_shell(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str);

void write_command(SSD1306_Device *dev, uint8_t cmd);

#endif
