RM	= rm -f

CFLAGS  += -Wall

TEST_BIN = pppoedetect

TEST_OBJS = main.o pppoe.o

all: $(TEST_BIN)

$(TEST_BIN): $(TEST_OBJS)
	$(CC) -o $(TEST_BIN) $(TEST_OBJS) $(CFLAGS) $(LIBS)

clean:
	$(RM) wandetect *.o
