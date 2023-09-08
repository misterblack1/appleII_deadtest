RAMSIZE = 16K
MAME = mame

VERSION := $(shell git describe --tags --always --dirty=-LOCAL --broken=-XX 2>/dev/null || echo LOCAL_BUILD)
VERSION_UC := $(shell echo $(VERSION) | tr a-z A-Z)
TAG := $(shell git describe --tags --exact-match 2>/dev/null || echo LOCAL_BUILD)

$(info Version: $(VERSION))
$(info Tag: $(TAG))

RELEASE_ZIP := appleII_deadtest-BIN-$(VERSION).zip
RELEASE_FILES := apple2dead.bin apple2dead.dsk LICENSE.html README.html

all: $(RELEASE_FILES)

apple2dead.bin: config.inc inc/marchu_zpsp.asm inc/marchu.asm inc/a2console.asm inc/a2macros.inc inc/a2constants.inc

# OUTPUT = apple2.bin
ASSEMBLE = cl65 -t apple2 -C a2_f8rom.cfg -I ./inc -l $(@:%.bin=%.lst) -Ln $(@:%.bin=%.sym) $(QUICKTEST)
CHECKSUM = sha1sum --tag


%.bin: %.asm Makefile a2_f8rom.cfg 
	$(ASSEMBLE) -o $@ $< 
	-@$(CHECKSUM) $@


config.inc:
	@echo ".define VERSION_STR \"$(VERSION_UC)\"" > $@

.INTERMEDIATE: config.inc

export QUICKTEST

DEBUGGER := none

debug: DEBUGGER := osx
debug: QUICKTEST := -D QUICKTEST=1
debug: run 

apple2dead.dsk: apple2dead.bin apple2dead.srcdsk
	cp apple2dead.srcdsk $@
	cat $< | ac -p $@ DEADTEST BIN 0xF800

run: apple2dead.bin all
	ln -sf $< 341-0020-00.f8
	$(MAME) apple2p -ramsize $(RAMSIZE) -keepaspect -volume -10 -window -resolution 800x600 -skip_gameinfo -debug -debugger $(DEBUGGER)

showver:
	@git describe --tags --long --always --dirty=-L --broken=-X

%.html: %.md
	pandoc $< -f markdown -t html -s -o $@ -V mainfont=sans-serif -V maxwidth=50em --metadata title="$*"

$(RELEASE_ZIP): $(RELEASE_FILES)
	@rm -f $@
	zip $@ $^

zip: $(RELEASE_ZIP)


release: clean $(RELEASE_ZIP)
	$(info )
	$(info VERSION: $(VERSION))
	$(info RELEASE: $(TAG))
ifneq (,$(findstring LOCAL,$(TAG) $(VERSION)))
	@echo
	@echo "Abort: release only from a clean, tagged commit"
	@echo
	@git status --short --branch
	@echo
	@false
else
	git push origin $(TAG)
	gh release create $(TAG) --draft --generate-notes
	gh release upload $(TAG) $(RELEASE_FILES) $(RELEASE_ZIP)
	@echo
	@echo Release $(TAG) is a draft.  Approve or discard on GitHub.
endif

clean: 
	rm -f *.lst *.o *.map *.sym $(RELEASE_FILES) appleII_deadtest*.zip

.PHONY: all test clean cleanall showver run debug release zip
