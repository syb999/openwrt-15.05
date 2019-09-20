
SOCK_SERVER             = ndscan
SOCK_SERVER_LIB_OBJ     = netdiscover.o

SOCK_SERVER_CFLAGS      = $(CFLAGS) -I$(STAGING_DIR)/usr/lib/libnet-1.1.x/include 

SOCK_SERVER_LDFLAGS     = $(LDFLAGS) -L$(STAGING_DIR)/usr/lib/libnet-1.1.x/lib


%.o: %.c
	$(CC) $(SOCK_SERVER_CFLAGS) -c -o $@ $<

compile: clean $(SOCK_SERVER_LIB_OBJ)
	$(CC) $(SOCK_SERVER_LDFLAGS) -o $(SOCK_SERVER) $(SOCK_SERVER_LIB_OBJ)

clean:
	-rm -f *.elf *.gdb *.o $(SOCK_SERVER)
