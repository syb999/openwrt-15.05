EXEC=ccm3310test
SRC=main.c

all: $(EXEC)
ccm3310test: $(SRC)
	$(CC) $(LDFLAGS) -o $@ $(SRC) -ldl -pthread

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o
