#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <stdlib.h>
#include <time.h>
#include <sys/wait.h>
#include <sys/param.h>
#include "lcd_api.h"

#define DEFAULT_I2C_ADDR 0x27
#define DEFAULT_LCD_LINE_WIDTH 16
#define DEFAULT_LCD_LINE_COUNT 2
#define DEFAULT_MAX_CMD_LENGTH 1024
#define DEFAULT_LOG_FILE "/var/log/lcd1602.log"
#define DEFAULT_CMD_PIPE "/var/state/lcd1602_backlight"
#define DEFAULT_I2C_BUS "/dev/i2c-0"

#ifndef LCD_LINE_WIDTH
#define LCD_LINE_WIDTH DEFAULT_LCD_LINE_WIDTH
#endif

typedef struct {
    int i2c_fd;
    uint8_t addr;
    LcdApi api;
} I2cLcd;

typedef struct {
    const char *prefix;
    int (*handler)(const char *args, char *output, size_t out_len);
} CommandHandler;

static int i2c_write(I2cLcd *lcd, const uint8_t *data, uint16_t len) {
    if (write(lcd->i2c_fd, data, len) != len) {
        return -1;
    }
    return 0;
}

static void hal_write_command(uint8_t cmd, void *user_data) {
    I2cLcd *lcd = (I2cLcd *)user_data;
    uint8_t buf[4];
    uint8_t bl_bit = lcd->api.backlight ? 0x08 : 0x00;

    buf[0] = (cmd & 0xF0) | 0x04 | bl_bit;
    buf[1] = (cmd & 0xF0) | 0x00 | bl_bit;
    buf[2] = (cmd << 4) | 0x04 | bl_bit;
    buf[3] = (cmd << 4) | 0x00 | bl_bit;

    i2c_write(lcd, buf, 4);
    usleep(100);
}

static void hal_write_data(uint8_t data, void *user_data) {
    I2cLcd *lcd = (I2cLcd *)user_data;
    uint8_t buf[4];
    uint8_t bl_bit = lcd->api.backlight ? 0x08 : 0x00;

    buf[0] = (data & 0xF0) | 0x05 | bl_bit;
    buf[1] = (data & 0xF0) | 0x01 | bl_bit;
    buf[2] = (data << 4) | 0x05 | bl_bit;
    buf[3] = (data << 4) | 0x01 | bl_bit;

    i2c_write(lcd, buf, 4);
    usleep(100);
}

static void hal_backlight_on(void *user_data) {
    I2cLcd *lcd = (I2cLcd *)user_data;
    if (!lcd->api.backlight_enabled) return;
    lcd->api.backlight = true;
}

static void hal_backlight_off(void *user_data) {
    I2cLcd *lcd = (I2cLcd *)user_data;
    lcd->api.backlight = false;
}

static void hal_backlight_enable(void *user_data, bool enable) {
    I2cLcd *lcd = (I2cLcd *)user_data;
    lcd->api.backlight_enabled = enable;
    if (!enable) hal_backlight_off(user_data);
}

static void i2c_lcd_init(I2cLcd *lcd, const char *i2c_bus, uint8_t addr, uint8_t rows, uint8_t cols) {
    if ((lcd->i2c_fd = open(i2c_bus, O_RDWR)) < 0) {
        perror("Failed to open I2C bus");
        exit(1);
    }

    if (ioctl(lcd->i2c_fd, I2C_SLAVE, addr) < 0) {
        perror("Failed to acquire bus access");
        close(lcd->i2c_fd);
        exit(1);
    }

    lcd->addr = addr;
    lcd->api.num_lines = rows;
    lcd->api.num_columns = cols;
    lcd->api.cursor_x = 0;
    lcd->api.cursor_y = 0;
    lcd->api.backlight = true;
    lcd->api.hal_write_command = hal_write_command;
    lcd->api.hal_write_data = hal_write_data;
    lcd->api.hal_backlight_on = hal_backlight_on;
    lcd->api.hal_backlight_off = hal_backlight_off;
    lcd->api.hal_backlight_enable = hal_backlight_enable;
    lcd->api.user_data = lcd;
    lcd->api.backlight_enabled = true;

    usleep(50000);
    hal_write_command(0x33, lcd);
    usleep(5000);
    hal_write_command(0x32, lcd);
    usleep(5000);
    hal_write_command(0x28, lcd);
    usleep(5000);
    hal_write_command(0x0C, lcd);
    hal_write_command(0x01, lcd);
    usleep(2000);
}

static void display_two_lines(I2cLcd *lcd, const char *line1, const char *line2) {
    lcd_clear(&lcd->api);
    lcd_move_to(&lcd->api, 0, 0);
    lcd_putstr(&lcd->api, line1);
    lcd_move_to(&lcd->api, 0, 1);
    lcd_putstr(&lcd->api, line2);
}

static void sanitize_line(char *str, size_t max_len) {
    size_t j = 0;
    for (size_t i = 0; str[i] != '\0' && j < max_len - 1; i++) {
        if (str[i] == '\r' || str[i] == '\n') continue;
        str[j++] = str[i];
    }
    str[j] = '\0';
}

static int handle_date_command(const char *args, char *output, size_t out_len) {
    const char *format = "%Y-%m-%d %H:%M:%S";
    
    if (args && *args == '+') {
        format = args + 1;
    }
    
    time_t now = time(NULL);
    struct tm *tm = localtime(&now);
    return strftime(output, out_len, format, tm) > 0;
}

static CommandHandler cmd_handlers[] = {
    {"date", handle_date_command},
    {NULL, NULL}
};

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

static void replace_shell_commands(char *line, size_t line_len) {
    char temp_buffer[LCD_LINE_WIDTH * 2 + 2];
    char output_buffer[LCD_LINE_WIDTH * 2 + 2];
    char *src = line;
    char *dst = temp_buffer;
    size_t remaining = sizeof(temp_buffer) - 1;

    *dst = '\0';

    while (*src && remaining > 0) {
        if (strncmp(src, "$(", 2) == 0) {
            char *end = strchr(src + 2, ')');
            if (end) {
                size_t cmd_len = end - (src + 2);
                char cmd[DEFAULT_MAX_CMD_LENGTH];
                strncpy(cmd, src + 2, cmd_len);
                cmd[cmd_len] = '\0';

                char output[DEFAULT_MAX_CMD_LENGTH];
                if (process_shell_command(cmd, output, sizeof(output))) {
                    size_t out_len = strlen(output);
                    while (out_len > 0 && 
                          (output[out_len-1] == '\n' || output[out_len-1] == '\r')) {
                        output[--out_len] = '\0';
                    }
                    
                    size_t copy_len = MIN(out_len, remaining);
                    strncpy(dst, output, copy_len);
                    dst += copy_len;
                    remaining -= copy_len;
                }
                src = end + 1;
                continue;
            }
        }

        *dst++ = *src++;
        remaining--;
    }
    *dst = '\0';

    strncpy(line, temp_buffer, line_len);
    line[line_len - 1] = '\0';
}

static void strncpy_clean(char *dest, const char *src, size_t n) {
    size_t i;
    for (i = 0; i < n && src[i] != '\0'; i++) {
        if (src[i] >= ' ' && src[i] <= '~') {
            dest[i] = src[i];
        } else {
            dest[i] = ' ';
        }
    }
    dest[i] = '\0';
    
    if (strchr(dest, '.') && i == n && src[i] != '\0') {
        char *last_dot = strrchr(dest, '.');
        if (last_dot) {
            char *p = last_dot + 1;
            while (*p && *p >= '0' && *p <= '9') p++;
            if (p - dest > n) {
                dest[n] = '\0';
            }
        }
    }
}

static void safe_str_copy(char *dest, const char *src, size_t max_len) {
    size_t i;
    for (i = 0; i < max_len - 1 && src[i] != '\0'; i++) {
        dest[i] = src[i];
    }
    dest[i] = '\0';
    
    if (strchr(dest, '.') && i == max_len - 1 && src[i] != '\0') {
        char *last_dot = strrchr(dest, '.');
        if (last_dot) {
            size_t len_after_dot = strlen(last_dot + 1);
            if (len_after_dot > 0 && len_after_dot < 4) {
                dest[i - (3 - len_after_dot)] = '\0';
            }
        }
    }
}

static void read_and_display_log(I2cLcd *lcd, const char *log_file) {
    char buffer[LCD_LINE_WIDTH * 2 + 10] = {0};
    char line1[LCD_LINE_WIDTH + 1] = {0};
    char line2[LCD_LINE_WIDTH + 1] = {0};

    int fd = open(log_file, O_RDONLY);
    if (fd < 0) {
        display_two_lines(lcd, "File Error", "");
        return;
    }
    
    ssize_t bytes_read = read(fd, buffer, sizeof(buffer) - 1);
    close(fd);
    
    if (bytes_read <= 0) {
        display_two_lines(lcd, "No Data", "");
        return;
    }
    buffer[bytes_read] = '\0';

    replace_shell_commands(buffer, sizeof(buffer));
    
    char *line1_end = strchr(buffer, '\n');
    if (line1_end) {
        *line1_end = '\0';
        safe_str_copy(line1, buffer, LCD_LINE_WIDTH);
        
        char *line2_start = line1_end + 1;
        safe_str_copy(line2, line2_start, LCD_LINE_WIDTH);
    } else {
        safe_str_copy(line1, buffer, LCD_LINE_WIDTH);
        line2[0] = '\0';
    }

    display_two_lines(lcd, line1, line2);
}

static int create_command_pipe(const char *pipe_path) {
    if (access(pipe_path, F_OK) == -1) {
        if (mkfifo(pipe_path, 0666) == -1) {
            perror("mkfifo");
            return -1;
        }
    }
    return open(pipe_path, O_RDWR | O_NONBLOCK);
}

static void process_commands(I2cLcd *lcd, int cmd_fd) {
    char cmd_buf[32];
    ssize_t bytes_read;
    
    while ((bytes_read = read(cmd_fd, cmd_buf, sizeof(cmd_buf)-1)) > 0) {
        cmd_buf[bytes_read] = '\0';
        char *cmd = strtok(cmd_buf, "\n");
        while (cmd) {
            if (strcmp(cmd, "BL_ON") == 0) {
                lcd->api.hal_backlight_enable(lcd, true);
                lcd->api.hal_backlight_on(lcd);
            } 
            else if (strcmp(cmd, "BL_OFF") == 0) {
                lcd->api.hal_backlight_enable(lcd, false);
            }
            else if (strcmp(cmd, "BL_TOGGLE") == 0) {
                lcd->api.backlight_enabled = !lcd->api.backlight_enabled;
                if (lcd->api.backlight_enabled) {
                    lcd->api.hal_backlight_on(lcd);
                } else {
                    lcd->api.hal_backlight_off(lcd);
                }
            }
            cmd = strtok(NULL, "\n");
        }
        
        while (read(cmd_fd, cmd_buf, sizeof(cmd_buf)) > 0) {}
    }
}

int main(int argc, char *argv[]) {
    const char *i2c_bus = DEFAULT_I2C_BUS;
    const char *log_file = DEFAULT_LOG_FILE;
    uint8_t i2c_addr = DEFAULT_I2C_ADDR;
    uint8_t lcd_lines = DEFAULT_LCD_LINE_COUNT;
    uint8_t lcd_width = DEFAULT_LCD_LINE_WIDTH;

    int opt;
    while ((opt = getopt(argc, argv, "i:l:a:w:")) != -1) {
        switch (opt) {
            case 'i':
                i2c_bus = optarg;
                break;
            case 'l':
                log_file = optarg;
                break;
            case 'a':
                i2c_addr = (uint8_t)strtol(optarg, NULL, 0);
                break;
            case 'w':
                lcd_width = (uint8_t)strtol(optarg, NULL, 0);
                if (lcd_width > 40) {
                    fprintf(stderr, "LCD width too large. Maximum is 40.\n");
                    return 1;
                }
                break;
            default:
                fprintf(stderr, "Usage: %s [-i i2c_bus] [-l log_file] [-a i2c_address] [-w lcd_width]\n", argv[0]);
                return 1;
        }
    }

    if (lcd_lines < 1 || lcd_lines > DEFAULT_LCD_LINE_COUNT) {
        fprintf(stderr, "LCD lines must be between 1 and %d.\n", DEFAULT_LCD_LINE_COUNT);
        return 1;
    }

    I2cLcd lcd;
    i2c_lcd_init(&lcd, i2c_bus, i2c_addr, lcd_lines, lcd_width);

    int cmd_fd = create_command_pipe(DEFAULT_CMD_PIPE);
    if (cmd_fd < 0) {
        fprintf(stderr, "Failed to create command pipe\n");
        return 1;
    }

    char welcome_line1[LCD_LINE_WIDTH + 1];
    char welcome_line2[LCD_LINE_WIDTH + 1];
    snprintf(welcome_line1, sizeof(welcome_line1), "Log Monitor");
    snprintf(welcome_line2, sizeof(welcome_line2), "Ready...");
    if (strlen(welcome_line1) > lcd_width) {
        welcome_line1[lcd_width] = '\0';
    }
    if (strlen(welcome_line2) > lcd_width) {
        welcome_line2[lcd_width] = '\0';
    }
    display_two_lines(&lcd, welcome_line1, welcome_line2);
    sleep(2);

    while (1) {
        read_and_display_log(&lcd, log_file);
        process_commands(&lcd, cmd_fd);
        sleep(1); //
    }

    close(lcd.i2c_fd);
    return 0;
}
