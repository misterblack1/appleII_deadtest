RAMSIZE = 16K
MAME = mame


all: apple2.bin a2vmemnoram.bin
apple2.bin: config.inc inc/marchu_zpsp.asm inc/marchu.asm inc/a2console.asm inc/a2macros.inc inc/a2constants.inc

OUTPUT = apple2.bin
ASSEMBLE = cl65 -t apple2 -C a2_f8rom.cfg -I ./inc -l $(@:%.bin=%.lst) -Ln $(@:%.bin=%.sym) $(QUICKTEST)
CHECKSUM = sha1sum --tag


%.bin: %.asm Makefile a2_f8rom.cfg 
	$(ASSEMBLE) -o $@ $< 
	-@$(CHECKSUM) $@


config.inc: config_inc.sh *.asm inc/*
	sh $< > $@

.SECONDARY: config.inc


export QUICKTEST

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
	rm -f *.lst *.o *.map *.sym

cleanall: clean
	rm -f apple2.bin config.inc appleII_deadtest*.zip

showver:
	@git describe --tags --long --always --dirty=-L --broken=-X

.PHONY: all test clean cleanall showver run debug