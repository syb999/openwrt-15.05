EXE:=siupclient

LDFLAGS+=-lc
all: $(EXE)
ssct:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ siupclient.c $(LDLIBS)

clean:
	-rm -f siupclient *.elf *.gdb *.o
