CC = gcc
LD = gcc

SOURCES = i2c_ssd1306.c ssd1306.c
OBJS := $(SOURCES:.c=.o)
CPPFLAGS := -I I2C_Library
CFLAGS :=-Os -Wall -std=gnu99 -I. -luci


i2c_ssd1306: $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

clean:
	rm -rf i2c_ssd1306 $(OBJS)

compile: i2c_ssd1306

install: compile
	mkdir -p $(DESTDIR)/usr/sbin
	cp i2c_ssd1306 $(DESTDIR)/usr/sbin/i2c_ssd1306

