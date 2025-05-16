CC = gcc
LD = gcc


SOURCES = i2c_lcd1602.c
OBJS := $(SOURCES:.c=.o)
CPPFLAGS := -I I2C_Library
CFLAGS := -g -std=gnu99

i2c_lcd1602: $(OBJS)
	$(CC) $^ -o $@

clean:
	rm -rf i2c_lcd1602 $(OBJS)

compile: i2c_lcd1602

install: compile
	mkdir -p $(DESTDIR)/usr/sbin
	cp i2c_lcd1602 $(DESTDIR)/usr/sbin/i2c_lcd1602
