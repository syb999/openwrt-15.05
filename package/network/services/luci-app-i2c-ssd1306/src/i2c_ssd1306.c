#include "ssd1306.h"
#include <signal.h>
#include <time.h>
#include <uci.h>

#define MAX_DEVICES 1

static volatile bool running = true;
static SSD1306_Device device;

void signal_handler(int sig) {
    running = false;
}

int load_uci_config(SSD1306_Config *config) {
    struct uci_context *ctx = uci_alloc_context();
    if (!ctx) {
        fprintf(stderr, "UCI context allocation failed\n");
        return -1;
    }

    struct uci_package *pkg = NULL;
    int ret = -1;

    if (uci_load(ctx, "i2c-ssd1306", &pkg) != UCI_OK) {
        fprintf(stderr, "Failed to load config file (is /etc/config/i2c-ssd1306 present?)\n");
        goto cleanup;
    }

    struct uci_element *e;
    uci_foreach_element(&pkg->sections, e) {
        struct uci_section *s = uci_to_section(e);
        
        if (strcmp(s->type, "i2c_ssd1306") == 0 || 
            strcmp(s->type, "i2c-ssd1306") == 0) {

            const char *enabled = uci_lookup_option_string(ctx, s, "enabled");
            const char *bus = uci_lookup_option_string(ctx, s, "i2c_bus");
            const char *addr = uci_lookup_option_string(ctx, s, "i2c_address");
            const char *log = uci_lookup_option_string(ctx, s, "log_file");

            const char *on_time = uci_lookup_option_string(ctx, s, "screen_on_time");
            const char *off_time = uci_lookup_option_string(ctx, s, "screen_off_time");

            config->enabled = enabled ? atoi(enabled) : 1;
            snprintf(config->i2c_bus, sizeof(config->i2c_bus), 
                    bus ? bus : "/dev/i2c-0");
            config->i2c_addr = addr ? (uint8_t)strtol(addr, NULL, 16) : 0x3C;
            snprintf(config->log_file, sizeof(config->log_file),
                    log ? log : "/var/log/ssd1306.log");
            config->type = SSD1306_128x64;
            config->screen_on_time = on_time ? atoi(on_time) : 10;
            config->screen_off_time = off_time ? atoi(off_time) : 10;

            ret = 0;
            break;
        }
    }

    if (ret != 0) {
        fprintf(stderr, "No valid section found in config\n");
    }

cleanup:
    if (pkg) uci_unload(ctx, pkg);
    uci_free_context(ctx);
    return ret;
}

int main(int argc, char *argv[]) {
    SSD1306_Config config;

    if (load_uci_config(&config) != 0) {
        fprintf(stderr, "Failed to load UCI config\n");
        return 1;
    }

    if (!config.enabled) {
        printf("Device is disabled in config\n");
        return 0;
    }

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    printf("Initializing on %s (0x%02X)\n", config.i2c_bus, config.i2c_addr);
    if (ssd1306_init(&device, &config) != 0) {
        fprintf(stderr, "Init failed\n");
        return 1;
    }

    ssd1306_clear(&device);
    ssd1306_draw_string(&device, 0, 0, "OLED Ready");
    ssd1306_draw_string(&device, 0, 8, config.i2c_bus);
    char addr_str[16];
    snprintf(addr_str, sizeof(addr_str), "Addr: 0x%02X", config.i2c_addr);
    ssd1306_draw_string(&device, 0, 16, addr_str);
    ssd1306_display(&device);
    sleep(2);

    time_t last_activity = time(NULL);
    bool screen_on = true;

    while (running) {
        time_t now = time(NULL);
        
        if (screen_on) {
            if (now - last_activity >= device.config.screen_on_time) {
                write_command(&device, 0xAE);
                screen_on = false;
                last_activity = now;
                continue;
            }
        } else {
            if (now - last_activity >= device.config.screen_off_time) {
                write_command(&device, 0xAF);
                screen_on = true;
                last_activity = now;
                ssd1306_display_log(&device);
                continue;
            }
        }
        
        if (screen_on) {
            ssd1306_display_log(&device);
        }

        sleep(1);
    }

    ssd1306_cleanup(&device);
    return 0;
}
