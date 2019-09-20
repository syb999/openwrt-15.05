EXE:=ssct

#EXE+=switch_7530
LDFLAGS+=-lc
all: $(EXE) 
ssct:
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ client.c $(LDLIBS)

clean:
	-rm -f ssct *.elf *.gdb *.o

