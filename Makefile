# QuickTime Fixer Makefile

# Compiler and flags
CC = clang
CFLAGS = -dynamiclib -framework Foundation -framework AppKit -framework AVFoundation -fobjc-arc
OUTPUT = QuickTimeFixer.dylib
SOURCES = main.m ZKSwizzle/ZKSwizzle.m
INSTALL_PATH = /Applications/QuickTime Player.app/Contents/Frameworks

# Default target
all: $(OUTPUT)

# Build the dylib
$(OUTPUT): $(SOURCES)
	$(CC) $(CFLAGS) -o $@ $^

# Clean build artifacts
clean:
	rm -f $(OUTPUT)

# Install dylib and source files to QuickTime Player.app
install: $(OUTPUT)
	@echo "Installing QuickTimeFixer.dylib to $(INSTALL_PATH)..."
	@sudo cp -f $(OUTPUT) "$(INSTALL_PATH)/"
	@echo "Installing source files to $(INSTALL_PATH)..."
	@sudo cp -f main.m "$(INSTALL_PATH)/QuickTimeFixer.m"
	@sudo codesign --deep -f -s - /Applications/QuickTime\ Player.app/
	@echo "Installation complete."

.PHONY: all clean install