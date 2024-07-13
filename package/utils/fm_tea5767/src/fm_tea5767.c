#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>

#define TEA5767_ADDR 0x60
#define MAX_FREQ 108000
#define MIN_FREQ 87500

static unsigned char radio_write_data[5] = {0x29, 0xc2, 0x20, 0x11, 0x00};
static unsigned char radio_read_data[5];
static unsigned long frequency = MIN_FREQ;
static unsigned int pll;

// 打开 I2C 设备
int open_i2c_device(const char *device) {
    int fd = open(device, O_RDWR);
    if (fd < 0) {
        perror("Failed to open I2C device");
        exit(1);
    }
    return fd;
}

// 选择 I2C 设备地址
void set_i2c_address(int fd, int addr) {
    if (ioctl(fd, I2C_SLAVE, addr) < 0) {
        perror("Failed to set I2C address");
        exit(1);
    }
}

// I2C 写入函数
void radio_write(int fd) {
    if (write(fd, radio_write_data, sizeof(radio_write_data)) != sizeof(radio_write_data)) {
        perror("Failed to write to I2C device");
        exit(1);
    }
}

// I2C 读取函数
void radio_read(int fd) {
    if (write(fd, &radio_write_data[0], 1) != 1) {
        perror("Failed to write to I2C device");
        exit(1);
    }
    if (read(fd, radio_read_data, sizeof(radio_read_data)) != sizeof(radio_read_data)) {
        perror("Failed to read from I2C device");
        exit(1);
    }
}

// 由频率计算 PLL
void get_pll(void) {
    unsigned char hlsi = radio_write_data[2] & 0x10;
    if (hlsi) {
        pll = (unsigned int)(((float)(frequency + 225) * 4) / 32.768);
    } else {
        pll = (unsigned int)(((float)(frequency - 225) * 4) / 32.768);
    }
}

// 由 PLL 计算频率
void get_frequency(void) {
    unsigned char hlsi = radio_write_data[2] & 0x10;
    if (hlsi) {
        frequency = (unsigned long)((float)pll * 8.192 - 225);
    } else {
        frequency = (unsigned long)((float)pll * 8.192 + 225);
    }
}

// 手动设置频率, mode=1, +0.1MHz; mode=0, -0.1MHz
void search(int fd, int mode) {
    radio_read(fd);
    if (mode) {
        frequency += 100;
        if (frequency > MAX_FREQ) {
            frequency = MIN_FREQ;
        }
    } else {
        frequency -= 100;
        if (frequency < MIN_FREQ) {
            frequency = MAX_FREQ;
        }
    }
    get_pll();
    radio_write_data[0] = pll >> 8;
    radio_write_data[1] = pll & 0xff;
    radio_write_data[2] = 0x20;
    radio_write_data[3] = 0x11;
    radio_write_data[4] = 0x00;
    radio_write(fd);
}

// 自动搜索, mode=1, 频率增加搜索; mode=0, 频率减小搜索
void auto_search(int fd, int mode) {
    radio_read(fd);
    get_pll();
    if (mode) {
        radio_write_data[2] = 0xa0;
    } else {
        radio_write_data[2] = 0x20;
    }
    radio_write_data[0] = (pll >> 8) | 0x40;
    radio_write_data[1] = pll & 0xff;
    radio_write_data[3] = 0x11;
    radio_write_data[4] = 0x00;
    radio_write(fd);
    do {
        radio_read(fd);
        usleep(100000); // 延迟以允许收音机处理
    } while (!(radio_read_data[0] & 0x80)); // 搜索成功标志
}

// 检查是否接收到可用的 FM 信号
int is_signal_available(int fd) {
    radio_read(fd);
    return (radio_read_data[0] & 0x80); // 信号检测标志
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <i2c_device>\n", argv[0]);
        return 1;
    }

    const char *i2c_device = argv[1];
    int fd = open_i2c_device(i2c_device);
    set_i2c_address(fd, TEA5767_ADDR);

    // 自动调频搜索
    int found = 0;
    while (!found) {
        auto_search(fd, 1); // 自动搜索上升频率
        if (is_signal_available(fd)) {
            printf("FM signal found at frequency: %lu kHz\n", frequency);
            found = 1;
        } else {
            auto_search(fd, 0); // 自动搜索下降频率
            if (is_signal_available(fd)) {
                printf("FM signal found at frequency: %lu kHz\n", frequency);
                found = 1;
            }
        }
        // 如果没有找到信号，继续搜索
        if (!found) {
            search(fd, 1); // 手动搜索增加频率
        }
    }

    close(fd);
    return 0;
}

