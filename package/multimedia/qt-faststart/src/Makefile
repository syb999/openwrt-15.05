CC = gcc
CFLAGS = -Wall
OBJS = qt-faststart.o

all: qt-faststart

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

qt-faststart: $(OBJS)
	$(CC) -o $@ $(OBJS)


