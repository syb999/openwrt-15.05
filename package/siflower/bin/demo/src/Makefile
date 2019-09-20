CC = gcc
EXEC=demo
SRC=netlink_demo.c

all: $(EXEC)

demo: $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) $(LDLIBS)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o
