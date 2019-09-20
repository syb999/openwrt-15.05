EXEC=anomaly_server
EXEB=anomaly_client
SRC=anomaly_server.c
SRB=anomaly_client.c

all: $(EXEC)  $(EXEB)
anomaly_server: $(SRC)
	$(CC) $(LDFLAGS) -o $@ $(SRC) 

anomaly_client: $(SRB)
	$(CC) $(LDFLAGS) -o $@ $(SRB)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o
	-rm -f $(EXEB) *.elf *.gdb *.o
