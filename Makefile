# SOURCE = apple2-deadtest.asm
# SOURCE = apple2-deadtest-h.asm
# SOURCE = zp-march.asm
# SOURCE = zpsp-march.asm
# SOURCE = march-highres.asm
SOURCE = marchu-ram.asm

MAME = $(HOME)/Downloads/mame0257-arm64/mame
OUTPUT = 341-0020-00.f8

ASSEMBLE_xa = xa -C -M -o
ASSEMBLE_sa = cl65 -t apple2 -C none.cfg -l $(<:%.asm=%.lst) -o

ASSEMBLE = $(ASSEMBLE_sa)

all: $(OUTPUT)

$(OUTPUT): $(SOURCE) Makefile
	$(ASSEMBLE) $(OUTPUT) $(SOURCE)
	-@md5 $(OUTPUT)

debug: $(OUTPUT)
	$(MAME) apple2p -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger osx

run: $(OUTPUT)
	$(MAME) apple2p -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger none

.PHONY: all test