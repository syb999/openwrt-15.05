CC := $(TARGET_CC)
CFLAGS := $(TARGET_CFLAGS) -Wall
LDFLAGS := $(TARGET_LDFLAGS)

# Define source and object files
SRCS := fm_tea5767.c
OBJS := $(SRCS:.c=.o)

# Define the target executable
TARGET := fm_tea5767

# Default target
all: $(TARGET)

# Link the final executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Compile source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean target
clean:
	rm -f $(OBJS) $(TARGET)

# Phony targets
.PHONY: all clean
