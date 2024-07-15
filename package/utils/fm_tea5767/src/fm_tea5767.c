#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include <stdlib.h>
#include <string.h>

#define TEA5767_I2C_ADDR 0x60
#define MAX_FREQ 108.0
#define MIN_FREQ 87.5

// Function to set frequency on TEA5767
void set_frequency(int i2c_fd, float frequency_MHz) {
    uint16_t frequency = (uint16_t)((4 * (frequency_MHz * 1000000 + 225000)) / 32768);
    uint8_t buffer[5];

    buffer[0] = (frequency >> 8) & 0xFF;
    buffer[1] = frequency & 0xFF;
    buffer[2] = 0xB0;  // Mono, No Mute, No PLL
    buffer[3] = 0x10;  // Search Mode Off, No Port 1 High-Z
    buffer[4] = 0x00;  // No specific options set

    if (write(i2c_fd, buffer, 5) != 5) {
        perror("Failed to write to the I2C bus.");
    }
}

// Function to get the current frequency from TEA5767
float get_frequency(int i2c_fd) {
    uint8_t buffer[5];
    if (read(i2c_fd, buffer, 5) != 5) {
        perror("Failed to read from the I2C bus.");
        return -1;
    }

    uint16_t frequency = ((buffer[0] & 0x3F) << 8) | buffer[1];
    return ((frequency * 32768) / 4 - 225000) / 1000000.0;
}

void print_usage(const char *prog_name) {
    fprintf(stderr, "Usage: %s <i2c_device> [frequency]\n", prog_name);
    fprintf(stderr, "Examples:\n");
    fprintf(stderr, "  Get current frequency: %s /dev/i2c-0\n", prog_name);
    fprintf(stderr, "  Set frequency to 93.4 MHz: %s /dev/i2c-0 93.4\n", prog_name);
}

int main(int argc, char *argv[]) {
    int i2c_fd;
    char *i2c_device;
    float frequency_MHz;

    if (argc < 2 || argc > 3) {
        print_usage(argv[0]);
        return 1;
    }

    i2c_device = argv[1];

    // Open I2C bus
    if ((i2c_fd = open(i2c_device, O_RDWR)) < 0) {
        perror("Failed to open the I2C bus.");
        return 1;
    }

    // Set I2C device address
    if (ioctl(i2c_fd, I2C_SLAVE, TEA5767_I2C_ADDR) < 0) {
        perror("Failed to acquire bus access and/or talk to slave.");
        close(i2c_fd);
        return 1;
    }

    if (argc == 3) {
        // Set frequency provided by user
        frequency_MHz = atof(argv[2]);
        if (frequency_MHz < MIN_FREQ || frequency_MHz > MAX_FREQ) {
            fprintf(stderr, "Frequency out of range. Please enter a frequency between %.1f and %.1f MHz.\n", MIN_FREQ, MAX_FREQ);
        } else {
            set_frequency(i2c_fd, frequency_MHz);
            printf("Frequency set to: %.2f MHz\n", frequency_MHz);
        }
    } else {
        // Get current frequency
        frequency_MHz = get_frequency(i2c_fd);
        if (frequency_MHz != -1) {
            printf("Current frequency: %.2f MHz\n", frequency_MHz);
        }
    }

    // Close I2C bus
    close(i2c_fd);

    return 0;
}

