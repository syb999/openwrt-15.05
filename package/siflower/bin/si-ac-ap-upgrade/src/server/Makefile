EXE:=siupserver

LDFLAGS+=-lc
all: $(EXE)
ssct:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ siupserver.c $(LDLIBS)

clean:
	-rm -f siupserver *.elf *.gdb *.o
