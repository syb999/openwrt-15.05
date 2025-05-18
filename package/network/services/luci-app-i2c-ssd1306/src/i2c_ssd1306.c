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
    if (!fp) return;

    char line[128];
    while (fgets(line, sizeof(line), fp)) {
        char *key = strtok(line, " \t");
        if (!key || *key == '#') continue;

        char *name = strtok(NULL, " \t");
        char *value = strtok(NULL, "'\"");
        if (!name || !value) continue;

        if (strcmp(name, "enabled") == 0) {
            config->enabled = atoi(value) ? true : false;
        } else if (strcmp(name, "i2c_bus") == 0) {
            strncpy(config->i2c_bus, value, sizeof(config->i2c_bus) - 1);
        } else if (strcmp(name, "i2c_address") == 0) {
            config->i2c_addr = (uint8_t)strtol(value, NULL, 0);
        } else if (strcmp(name, "log_file") == 0) {
            strncpy(config->log_file, value, sizeof(config->log_file) - 1);
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

int main(int argc, char *argv[]) {
    SSD1306_Config config = {
        .enabled = true,
        .i2c_bus = DEFAULT_I2C_BUS,
        .i2c_addr = DEFAULT_I2C_ADDR,
        .log_file = DEFAULT_LOG_FILE
    };

    parse_config(&config);

    int opt;
    while ((opt = getopt(argc, argv, "i:a:l:e:")) != -1) {
        switch (opt) {
            case 'i': strncpy(config.i2c_bus, optarg, sizeof(config.i2c_bus) - 1); break;
            case 'a': config.i2c_addr = (uint8_t)strtol(optarg, NULL, 0); break;
            case 'l': strncpy(config.log_file, optarg, sizeof(config.log_file) - 1); break;
            case 'e': config.enabled = atoi(optarg) ? true : false; break;
            default: break;
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
    
    while (running) {
        ssd1306_display_log(&dev);
		FILE *fp = fopen(config.log_file, "r");
		if (fp) {
			char line[128];
			while (fgets(line, sizeof(line), fp)) {
				printf("%s", line);
			}
			fclose(fp);
		}

        ssd1306_display(&dev);
        sleep(1);
    }

    ssd1306_cleanup(&dev);
    return 0;
}
