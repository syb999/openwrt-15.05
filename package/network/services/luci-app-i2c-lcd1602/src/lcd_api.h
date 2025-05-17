#ifndef LCD_API_H
#define LCD_API_H

#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>

#define LCD_CLR             0x01
#define LCD_HOME            0x02

#define LCD_ENTRY_MODE      0x04
#define LCD_ENTRY_INC       0x02
#define LCD_ENTRY_SHIFT     0x01

#define LCD_ON_CTRL         0x08
#define LCD_ON_DISPLAY      0x04
#define LCD_ON_CURSOR       0x02
#define LCD_ON_BLINK        0x01

#define LCD_MOVE            0x10
#define LCD_MOVE_DISP       0x08
#define LCD_MOVE_RIGHT      0x04

#define LCD_FUNCTION        0x20
#define LCD_FUNCTION_8BIT   0x10
#define LCD_FUNCTION_2LINES 0x08
#define LCD_FUNCTION_10DOTS 0x04
#define LCD_FUNCTION_RESET  0x30

#define LCD_CGRAM           0x40
#define LCD_DDRAM           0x80

typedef struct {
    uint8_t num_lines;
    uint8_t num_columns;
    uint8_t cursor_x;
    uint8_t cursor_y;
    bool backlight;
    
    void (*hal_write_command)(uint8_t cmd, void *user_data);
    void (*hal_write_data)(uint8_t data, void *user_data);
    void (*hal_backlight_on)(void *user_data);
    void (*hal_backlight_off)(void *user_data);
    void (*hal_backlight_enable)(void *user_data, bool enable);
    bool backlight_enabled;

    void *user_data;
} LcdApi;

static inline void lcd_command(LcdApi *lcd, uint8_t cmd) {
    lcd->hal_write_command(cmd, lcd->user_data);
}

static inline void lcd_clear(LcdApi *lcd) {
    lcd_command(lcd, LCD_CLR);
    usleep(20000);
}

static inline void lcd_home(LcdApi *lcd) {
    lcd_command(lcd, LCD_HOME);
    usleep(2000);
}

void lcd_move_to(LcdApi *api, uint8_t col, uint8_t row) {
    uint8_t cmd = 0x80;
    if (row == 1) {
        cmd += 0x40;
    }
    cmd += col;
    api->hal_write_command(cmd, api->user_data);
}

static inline void lcd_putchar(LcdApi *lcd, char c) {
    lcd->hal_write_data(c, lcd->user_data);
    if (++lcd->cursor_x >= lcd->num_columns) {
        lcd->cursor_x = 0;
        if (++lcd->cursor_y >= lcd->num_lines) {
            lcd->cursor_y = 0;
        }
        lcd_move_to(lcd, lcd->cursor_x, lcd->cursor_y);
    }
}

void lcd_putstr(LcdApi *api, const char *str) {
    if (!str) return;

    while (*str) {
        api->hal_write_data(*str++, api->user_data);
    }
}

static inline void lcd_show_cursor(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL | LCD_ON_DISPLAY | LCD_ON_CURSOR);
}

static inline void lcd_hide_cursor(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL | LCD_ON_DISPLAY);
}

static inline void lcd_blink_cursor_on(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL | LCD_ON_DISPLAY | LCD_ON_BLINK);
}

static inline void lcd_blink_cursor_off(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL | LCD_ON_DISPLAY);
}

static inline void lcd_display_on(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL | LCD_ON_DISPLAY);
}

static inline void lcd_display_off(LcdApi *lcd) {
    lcd_command(lcd, LCD_ON_CTRL);
}

static inline void lcd_backlight_on(LcdApi *lcd) {
    lcd->backlight = true;
    if (lcd->hal_backlight_on) lcd->hal_backlight_on(lcd->user_data);
}

static inline void lcd_backlight_off(LcdApi *lcd) {
    lcd->backlight = false;
    if (lcd->hal_backlight_off) lcd->hal_backlight_off(lcd->user_data);
}

static inline void lcd_custom_char(LcdApi *lcd, uint8_t location, const uint8_t charmap[8]) {
    location &= 0x7;
    lcd_command(lcd, LCD_CGRAM | (location << 3));
    for (int i = 0; i < 8; i++) {
        lcd->hal_write_data(charmap[i], lcd->user_data);
    }
}

#endif
