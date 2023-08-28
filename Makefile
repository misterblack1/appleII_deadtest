SOURCE = apple2-deadtest.asm
# SOURCE = apple2-deadtest-h.asm
MAME = $(HOME)/Downloads/mame0257-arm64/mame
OUTPUT = 341-0020-00.f8

all: $(OUTPUT)

$(OUTPUT): $(SOURCE) Makefile
	xa -C -o $(OUTPUT) $(SOURCE)

debug: $(OUTPUT)
	$(MAME) apple2p -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger osx

run: $(OUTPUT)
	$(MAME) apple2p -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger none

.PHONY: all test