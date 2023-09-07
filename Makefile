MAME = $(HOME)/Downloads/mame0257-arm64/mame
# OUTPUT = 341-0020-00.f8

OUTPUT = apple2.bin

RAMSIZE = 16K


VERSION_STR = $(shell git describe --tags --always --dirty=-L --broken=-X | tr a-z A-Z)
ifeq ("x$(VERSION_STR)", "x")
	VERSION_STR := LOCAL_BUILD
endif

ASSEMBLE = cl65 -t apple2 -C a2_f8rom.cfg -I ./inc -l $(@:%.bin=%.lst) -Ln $(@:%.bin=%.sym) $(QUICKTEST)

CHECKSUM = sha1sum --tag

all: apple2.bin a2vmemnoram.bin

%.bin: %.asm Makefile a2_f8rom.cfg | version.inc
	$(ASSEMBLE) -o $@ $< 
	-@$(CHECKSUM) $@

version.inc:
	echo ".define VERSION_STR \"$(VERSION_STR)\"" > $@


apple2.bin: inc/marchu_zpsp.asm inc/marchu.asm inc/a2console.asm inc/a2macros.inc inc/a2constants.inc

QUICKTEST :=

DEBUGGER := none

debug: DEBUGGER := osx
debug: QUICKTEST := -D QUICKTEST=1
debug: run 

# debug: $(OUTPUT)
# 	ln -sf $< 341-0020-00.f8
# 	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger osx

run: $(OUTPUT)
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger $(DEBUGGER)

clean: 
	rm -f *.lst *.o *.map *.sym version.inc

cleanall: clean
	rm -f *.bin

showver:
	@git describe --tags --long --always --dirty=-L --broken=-X

.PHONY: all test clean cleanall showver version.inc run debug