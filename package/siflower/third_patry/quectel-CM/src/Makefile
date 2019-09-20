SRC=QmiWwanCM.c GobiNetCM.c main.c MPQMUX.c QMIThread.c util.c udhcpc.c
EXEC=quectel-CM
LIBS=-lpthread -ldl

all: $(EXEC)

quectel-CM:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) $(INCLUDES) $(LIBS)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o

