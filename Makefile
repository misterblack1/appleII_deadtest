MAME = $(HOME)/Downloads/mame0257-arm64/mame
# OUTPUT = 341-0020-00.f8

OUTPUT = apple2.bin

RAMSIZE = 16K

ASSEMBLE = cl65 -t apple2 -C a2_f8rom.cfg -I ./inc -l $(@:%.bin=%.lst) -Ln $(@:%.bin=%.sym)


CHECKSUM = sha1sum --tag

all: apple2.bin a2vmemnoram.bin

%.bin: %.asm Makefile a2_f8rom.cfg
	$(ASSEMBLE) -o $@ $<
	-@$(CHECKSUM) $@

# $(ASSEMBLE) -o $@ $<


apple2.bin: inc/marchu_zpsp.asm inc/marchu.asm inc/a2console.asm inc/a2macros.inc inc/a2constants.inc

debug: $(OUTPUT)
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger osx

run: $(OUTPUT)
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger none

clean: 
	rm -f *.lst *.o *.map *.sym

showver:
	@git describe --tags --long --always --dirty=-L --broken=-X

.PHONY: all test clean showver