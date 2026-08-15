#include "ssd1306.h"
#include <signal.h>
#include <time.h>
#include <uci.h>

#define MAX_DEVICES 1

/* Consecutive seconds of I2C write failure before declaring the panel gone. */
#define I2C_FAIL_LIMIT 20

/* If a full main-loop iteration takes longer than this, something is stuck
   (wedged I2C, etc.): die so procd restarts a fresh instance instead of
   freezing the panel forever. Longer than the worst-case display_log budget
   (CMD_BUDGET_SECS) + sleep, so it never fires during normal refresh. */
#define WATCHDOG_SECS 20

static volatile bool running = true;
static SSD1306_Device device;

void signal_handler(int sig) {
    running = false;
}

void watchdog_handler(int sig) {
    (void)sig;
    /* No cleanup: if we're here the main loop is stuck, don't trust the
       code path. procd will respawn a fresh instance. */
    _exit(1);
}

/* Cheap liveness probe: a 0-byte write sends only the I2C address (same
   trick as i2cdetect's quick probe) and checks for the device ACK without
   altering the display state. Runs every loop so an unplugged panel is
   noticed even when display_log is skipping redraws (static log). */
static int probe_panel(SSD1306_Device *dev) {
    if (write(dev->i2c_fd, NULL, 0) >= 0) {
        dev->i2c_fail = 0;
        return 0;
    }
    if (dev->i2c_fail < 255)
        dev->i2c_fail++;
    return -1;
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
            const char *screen_type = uci_lookup_option_string(ctx, s, "screen_type");

            config->enabled = enabled ? atoi(enabled) : 1;
            snprintf(config->i2c_bus, sizeof(config->i2c_bus), 
                    bus ? bus : "/dev/i2c-0");
            config->i2c_addr = addr ? (uint8_t)strtol(addr, NULL, 16) : 0x3C;
            snprintf(config->log_file, sizeof(config->log_file),
                    log ? log : "/var/log/ssd1306.log");
            if (screen_type && strcmp(screen_type, "96x16") == 0)
                config->type = SSD1306_96x16;
            else if (screen_type && strcmp(screen_type, "128x32") == 0)
                config->type = SSD1306_128x32;
            else
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
    signal(SIGALRM, watchdog_handler);
    signal(SIGPIPE, SIG_IGN);

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
    int fail_seconds = 0;

    while (running) {
        alarm(WATCHDOG_SECS);   /* re-arm each iteration: fires only on a hang */
        time_t now = time(NULL);
        
        /* screen_off_time == 0 means "always on": never blank the panel,
           so the screen does not blink at the end of each on-cycle. */
        if (device.config.screen_off_time > 0) {
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
        }
        
        if (screen_on) {
            ssd1306_display_log(&device);
        }

        /* Liveness probe independent of redraw frequency: catches an
           unplugged panel even when the log is static and display_log
           is skipping frames. */
        probe_panel(&device);

        /* Consecutive write failures mean the panel was unplugged/failed:
           stop instead of spinning on retries and log spam forever. */
        if (device.i2c_fail > 0) {
            if (++fail_seconds >= I2C_FAIL_LIMIT) {
                fprintf(stderr, "SSD1306 unreachable for %d s - assuming panel removed, exiting\n",
                        I2C_FAIL_LIMIT);
                break;
            }
        } else {
            fail_seconds = 0;
        }

        sleep(1);
    }

    alarm(0);
    ssd1306_cleanup(&device);
    return 0;
}
