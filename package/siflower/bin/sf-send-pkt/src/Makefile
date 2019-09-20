
SEND_PACKAGE_LOST             = sendpkt
SEND_PACKAGE_LOST_LIB_OBJ     = sendpkt.o
SEND_PACKAGE_LOST_CFLAGS      = $(CFLAGS) -Wunused-but-set-variable
LIBS = -lwebsockets
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

compile: clean $(SEND_PACKAGE_LOST_LIB_OBJ)
	$(CC) $(LDFLAGS) $(LIBS) -o $(SEND_PACKAGE_LOST) $(SEND_PACKAGE_LOST_LIB_OBJ)

clean:
	-rm -f *.elf *.gdb *.o $(SEND_PACKAGE_LOST)
