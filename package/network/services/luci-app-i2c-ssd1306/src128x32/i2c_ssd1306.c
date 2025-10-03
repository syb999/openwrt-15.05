#include "ssd1306.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <sys/wait.h>

#define SSD1306_WIDTH 128
#define DEFAULT_MAX_CMD_LENGTH 64

static volatile bool running = true;

void signal_handler(int sig) {
    running = false;
}

static void parse_config(SSD1306_Config *config) {
    FILE *fp = fopen(CONFIG_FILE, "r");
    if (!fp) {
        fprintf(stderr, "Failed to open config file: %s\n", CONFIG_FILE);
        return;
    }

    char line[128];
    while (fgets(line, sizeof(line), fp)) {
        line[strcspn(line, "\n")] = 0;
        char *ptr = line;

        while (*ptr == ' ' || *ptr == '\t') ptr++;

        if (*ptr == '\0' || *ptr == '#') continue;
        
        if (strncmp(ptr, "option", 6) == 0) {
            ptr += 6;
            while (*ptr == ' ' || *ptr == '\t') ptr++;
            
            char *name_start = ptr;
            while (*ptr && *ptr != ' ' && *ptr != '\t') ptr++;
            if (*ptr == '\0') continue;
            
            char name[64];
            size_t name_len = ptr - name_start;
            if (name_len >= sizeof(name)) continue;
            strncpy(name, name_start, name_len);
            name[name_len] = '\0';

            while (*ptr == ' ' || *ptr == '\t') ptr++;

            char *value_start = strchr(ptr, '\'');
            if (!value_start) continue;
            value_start++;

            char *value_end = strchr(value_start, '\'');
            if (!value_end) continue;

            char value[128];
            size_t value_len = value_end - value_start;
            if (value_len >= sizeof(value)) continue;
            strncpy(value, value_start, value_len);
            value[value_len] = '\0';

            if (strcmp(name, "enabled") == 0) {
                config->enabled = (atoi(value) != 0) ? true : false;
                printf("Config: enabled = %d\n", config->enabled);
            } else if (strcmp(name, "i2c_bus") == 0) {
                strncpy(config->i2c_bus, value, sizeof(config->i2c_bus) - 1);
                config->i2c_bus[sizeof(config->i2c_bus) - 1] = '\0';
                printf("Config: i2c_bus = %s\n", config->i2c_bus);
            } else if (strcmp(name, "i2c_address") == 0) {
                config->i2c_addr = (uint8_t)strtol(value, NULL, 0);
                printf("Config: i2c_address = 0x%02x\n", config->i2c_addr);
            } else if (strcmp(name, "log_file") == 0) {
                strncpy(config->log_file, value, sizeof(config->log_file) - 1);
                config->log_file[sizeof(config->log_file) - 1] = '\0';
                printf("Config: log_file = %s\n", config->log_file);
            } else if (strcmp(name, "screen_on_time") == 0) {
                config->screen_on_time = atoi(value);
                printf("Config: screen_on_time = %d\n", config->screen_on_time);
            } else if (strcmp(name, "screen_off_time") == 0) {
                config->screen_off_time = atoi(value);
                printf("Config: screen_off_time = %d\n", config->screen_off_time);
            }
        }
    }
    fclose(fp);
}

static void init_log_file(const char *path) {
    if (access(path, F_OK) == 0) {
        FILE *fp = fopen(path, "r");
        if (fp) {
            char line[128];
            if (fgets(line, sizeof(line), fp)) {
                int is_text = 1;
                for (char *p = line; *p && *p != '\n'; p++) {
                    if (*p < 32 && *p != '\t' && *p != '\r') {
                        is_text = 0;
                        break;
                    }
                }
                if (!is_text) {
                    fclose(fp);
                    fp = fopen(path, "w");
                    if (fp) {
                        time_t now = time(NULL);
                        fprintf(fp, "%.24s\n", ctime(&now));
                        fprintf(fp, "SSD1306 Initialized\n");
                        fclose(fp);
                    }
                    return;
                }
            }
            fclose(fp);
        }
        return;
    }
    
    FILE *fp = fopen(path, "w");
    if (fp) {
        time_t now = time(NULL);
        fprintf(fp, "%.24s\n", ctime(&now));
        fprintf(fp, "SSD1306 Initialized\n");
        fclose(fp);
    }
}

static char* execute_shell_command(const char *cmd) {
    static char output[256];
    FILE *fp = popen(cmd, "r");
    if (fp == NULL) {
        strncpy(output, "CMD FAILED", sizeof(output) - 1);
        output[sizeof(output) - 1] = '\0';
        return output;
    }

    output[0] = '\0';
    char buffer[128];
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        if (strlen(output) + strlen(buffer) < sizeof(output) - 1) {
            strcat(output, buffer);
        } else {
            break;
        }
    }

    size_t len = strlen(output);
    while (len > 0 && (output[len-1] == '\n' || output[len-1] == '\r')) {
        output[len-1] = '\0';
        len--;
    }
    
    pclose(fp);
    return output;
}

static char* expand_shell_variables(const char *line) {
    static char expanded[512];
    char temp[512];
    char command[256];
    char *output;
    char *start, *end;
    
    strncpy(temp, line, sizeof(temp) - 1);
    temp[sizeof(temp) - 1] = '\0';
    
    expanded[0] = '\0';
    char *current = temp;
    
    while (*current) {
        start = strstr(current, "$(");
        if (!start) {
            strcat(expanded, current);
            break;
        }

        *start = '\0';
        strcat(expanded, current);

        end = strstr(start + 2, ")");
        if (!end) {
            strcat(expanded, "$(");
            strcat(expanded, start + 2);
            break;
        }

        *end = '\0';
        strncpy(command, start + 2, sizeof(command) - 1);
        command[sizeof(command) - 1] = '\0';

        output = execute_shell_command(command);
        strcat(expanded, output);

        current = end + 1;
    }
    
    return expanded;
}

static void process_log_content(SSD1306_Device *dev, const char *log_file) {
    FILE *fp = fopen(log_file, "r");
    if (!fp) return;

    char line[128];
    int line_count = 0;

    static time_t last_exec_time = 0;
    static char cached_lines[8][128] = {0};
    time_t current_time = time(NULL);
    
    if (current_time - last_exec_time < 1) {
        for (int i = 0; i < 8 && cached_lines[i][0] != '\0'; i++) {
            ssd1306_draw_string(dev, 0, i * 8, cached_lines[i]);
        }
        fclose(fp);
        return;
    }
    
    last_exec_time = current_time;
    
    while (fgets(line, sizeof(line), fp) && line_count < 8) {
        line[strcspn(line, "\n")] = 0;
        line[strcspn(line, "\r")] = 0;

        char *display_line;
        if (strstr(line, "$(") != NULL) {
            display_line = expand_shell_variables(line);
        } else {
            display_line = line;
        }

        if (strlen(display_line) > 0) {
            ssd1306_draw_string(dev, 0, line_count * 8, display_line);
            strncpy(cached_lines[line_count], display_line, sizeof(cached_lines[line_count]) - 1);
            cached_lines[line_count][sizeof(cached_lines[line_count]) - 1] = '\0';
            line_count++;
        }
    }

    for (int i = line_count; i < 8; i++) {
        cached_lines[i][0] = '\0';
    }
    
    fclose(fp);
}

static void handle_screen_power(SSD1306_Device *dev, SSD1306_Config *config) {
    static time_t cycle_start_time = 0;
    static bool screen_on = true;
    static bool initialized = false;
    
    time_t current_time = time(NULL);
    
    if (!initialized) {
        cycle_start_time = current_time;
        initialized = true;
        if (screen_on) {
            ssd1306_power_on(dev);
        }
        return;
    }

    if (config->screen_off_time == 0) {
        if (!screen_on) {
            ssd1306_power_on(dev);
            screen_on = true;
        }
        return;
    }

    time_t elapsed = current_time - cycle_start_time;
    time_t cycle_length = config->screen_on_time + config->screen_off_time;

    if (elapsed >= cycle_length) {
        cycle_start_time = current_time;
        elapsed = 0;
    }

    if (elapsed < config->screen_on_time) {
        if (!screen_on) {
            ssd1306_power_on(dev);
            screen_on = true;
        }
    } else {
        if (screen_on) {
            ssd1306_power_off(dev);
            screen_on = false;
        }
    }
}

int main(int argc, char *argv[]) {
    SSD1306_Config config = {
        .enabled = true,
        .i2c_bus = DEFAULT_I2C_BUS,
        .i2c_addr = DEFAULT_I2C_ADDR,
        .log_file = DEFAULT_LOG_FILE,
        .screen_on_time = 0,
        .screen_off_time = 0
    };

    parse_config(&config);

    int opt;
    while ((opt = getopt(argc, argv, "i:a:l:e:")) != -1) {
        switch (opt) {
            case 'i': 
                strncpy(config.i2c_bus, optarg, sizeof(config.i2c_bus) - 1);
                config.i2c_bus[sizeof(config.i2c_bus) - 1] = '\0';
                break;
            case 'a': 
                config.i2c_addr = (uint8_t)strtol(optarg, NULL, 0); 
                break;
            case 'l': 
                strncpy(config.log_file, optarg, sizeof(config.log_file) - 1);
                config.log_file[sizeof(config.log_file) - 1] = '\0';
                break;
            case 'e': 
                config.enabled = (atoi(optarg) != 0) ? true : false; 
                break;
            default: 
                break;
        }
    }

    if (!config.enabled) return 0;

    init_log_file(config.log_file);

    SSD1306_Device dev;
    if (ssd1306_init(&dev, &config) != 0) {
        fprintf(stderr, "Init failed. Check I2C connection.\n");
        return 1;
    }

    signal(SIGTERM, signal_handler);
    signal(SIGINT, signal_handler);
    
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 500000000; // 500ms
    
    while (running) {
        handle_screen_power(&dev, &config);

        if (dev.power_on) {
            ssd1306_clear(&dev); 
            process_log_content(&dev, config.log_file);
            ssd1306_display(&dev);
        }

        nanosleep(&ts, NULL);
    }

    ssd1306_cleanup(&dev);
    return 0;
}
