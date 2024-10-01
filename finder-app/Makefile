# Variables
CC := $(CROSS_COMPILE)gcc
SRC := writer.c
OBJ := writer.o
TARGET := writer

# Compiler flags (optional)
CFLAGS := -Wall -Werror

# Default target to build the writer application
all: $(TARGET)

$(TARGET):$(OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJ)
	
$(OBJ): $(SRC)
	$(CC) $(CFLAGS) -c $(SRC)
	
# Clean target to remove generated files
clean:
	rm -f $(TARGET) $(OBJ)
