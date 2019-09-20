
BIN             = eth0_listen
OBJ             = main.o

SOCK_FLAGS = $(LDFLAGS) -I$(STAGING_DIR)/usr/include/libnl-tiny

$(BIN): $(OBJ)
	$(CC) $(LDFLAGS) -o $(BIN) $(OBJ)

%.o: %.c
	$(CC) $(SOCK_FLAGS) -c -o $@ $<

.PHONY: clean

clean:
	-rm -f *.elf *.gdb *.o $(BIN)
