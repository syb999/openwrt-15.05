EXEC=dec-tool
SRB=dec-tool.c

all: $(EXEC)
dec-tool: $(SRB)
	$(CC) $(LDFLAGS) -o $@ $(SRB)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o
