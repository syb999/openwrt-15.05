P2P_LIB_OBJ     = main.o
P2P_TARGET      = p2p
P2P_CCFLAGS     = $(CCFLAGS) -g
P2P_LDFLAGS     = $(LDFLAGS)

%.o: %.c
	$(CXX) $(P2P_CCFLAGS) -c -o $@ $<

compile: clean $(P2P_LIB_OBJ)
	$(CXX) $(P2P_LDFLAGS) -o $(P2P_TARGET) $(P2P_LIB_OBJ)

clean:
	-rm -f *.elf *.gdb *.o $(P2P_TARGET)
