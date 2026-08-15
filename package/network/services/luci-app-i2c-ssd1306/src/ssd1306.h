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

/* LOGICAL_WIDTH is the fixed buffer ceiling (largest supported panel).
   Actual panel geometry is dev->width/dev->height: 128x32, 128x64, or
   96x16 (SSD1315 0.69"). All fixed arrays use this ceiling; all I2C
   transfers use dev->width so a 96-wide panel sends 96 bytes/page. */
#define LOGICAL_WIDTH 128

typedef enum {
    SSD1306_128x32,
    SSD1306_128x64,
    SSD1306_96x16
} SSD1306_Type;

typedef struct {
    bool enabled;
    char i2c_bus[32];
    uint8_t i2c_addr;
    char log_file[64];
    SSD1306_Type type;
    uint16_t screen_on_time;
    uint16_t screen_off_time;
    bool anti_burnin;
} SSD1306_Config;

typedef struct {
    int i2c_fd;
    SSD1306_Config config;
    uint8_t *buffer;
    uint8_t *last_buffer;  /* copy of what was sent; for incremental refresh */
    uint8_t width;
    uint8_t height;
    time_t last_state_change;
    time_t last_mtime;   /* log file mtime at last render (0 = unknown) */
    off_t  last_size;    /* log file size at last render */
    time_t last_refresh; /* last actual screen refresh timestamp */
    uint8_t i2c_fail;    /* consecutive I2C write failures (0 = healthy) */
    const uint8_t *font;      /* active font table (5x7 or 3x5) */
    uint8_t font_width;       /* glyph columns: 5 (5x7) or 3 (3x5) */
    uint8_t font_step;        /* advance per char: font_width+1 normally,
                                 5 for 5x7-on-96x16 (zero spacing) */
    uint8_t burnin_shift;     /* anti burn-in horizontal pixel shift (0..3) */
    bool burnin_shifted;      /* current shift applied (toggle state) */
    time_t burnin_next;       /* next shift time for always-on mode (0=off) */
} SSD1306_Device;

int ssd1306_init(SSD1306_Device *dev, const SSD1306_Config *config);
void ssd1306_cleanup(SSD1306_Device *dev);

void ssd1306_display(SSD1306_Device *dev);
void ssd1306_clear(SSD1306_Device *dev);

void ssd1306_draw_char(SSD1306_Device *dev, uint8_t x, uint8_t y, char c);
void ssd1306_draw_string(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str);

void ssd1306_display_log(SSD1306_Device *dev);
void parse_and_draw_shell(SSD1306_Device *dev, uint8_t x, uint8_t y, const char *str);

int write_command(SSD1306_Device *dev, uint8_t cmd);

#endif
