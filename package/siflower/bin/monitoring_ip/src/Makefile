EXEC=monitoring_ip
SRC=monitoring_ip.c

all: $(EXEC)
monitoring_ip: $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) $(LDLIBS)

clean:
	-rm -f $(EXEC) *.o
