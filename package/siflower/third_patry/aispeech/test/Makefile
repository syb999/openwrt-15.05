MODULE_NAME:=text_dm

LOCAL_SRC_FILES += $(MODULE_NAME)/example.c

LOCAL_CFLAGS 	+= -I.
LOCAL_LDFLAGS	+= -L. -ldds -Wl,-rpath,./ -lpthread

OBJECTS = $(subst .c,.o,$(subst .cpp,.o,$(subst .cc,.o,$(LOCAL_SRC_FILES))))

EXECUTABLE  = aispeech_test

all: $(EXECUTABLE)

%.o : %.c
	$(CC) $(LOCAL_CFLAGS) $(CFLAGS) -c $< -o $@

$(EXECUTABLE) : $(OBJECTS)
	$(CC) $^ $(LOCAL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	rm -f *.elf *.gdb *.o $(EXECUTABLE)
