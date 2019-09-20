SRC=main.c led.c button.c plat_led.c plat_btn.c plat.c
EXEC=led-button

all: $(EXEC)

led-button: $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRC) $(INCLUDES) $(LIBS)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o
