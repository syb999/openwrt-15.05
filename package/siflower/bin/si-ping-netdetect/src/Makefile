
PING_PACKAGE_LOST             = netdetect
PING_PACKAGE_LOST_LIB_OBJ     = netdetect.o
PING_PACKAGE_LOST_CFLAGS      = $(CFLAGS) -Wunused-but-set-variable 

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

compile: clean $(PING_PACKAGE_LOST_LIB_OBJ)
	$(CC) $(LDFLAGS) -o $(PING_PACKAGE_LOST) $(PING_PACKAGE_LOST_LIB_OBJ)

clean:
	-rm -f *.elf *.gdb *.o $(PING_PACKAGE_LOST)
