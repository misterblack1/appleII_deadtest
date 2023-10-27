# Apple ][ Dead Test RAM Diagnostic ROM

![animation](pictures/apple2dead.gif?raw=true)

#### A Note on Downloading and Programming
The file you want for programming an EPROM is [`apple2dead.bin`](https://github.com/misterblack1/appleII_deadtest/releases/latest/download/apple2dead.bin).  You don't need to compile/assemble this ROM if you just want to use it to diagnose your machine.  You can always find the most recent ROM image on the **[Releases](https://github.com/misterblack1/appleII_deadtest/releases)** page, also linked on the right side of this repository page.

## Background
Recently while fixing an Apple II+ clone, I was annoyed there seemed to be no diagnostic ROMs available for the Apple II that could test the RAM without using RAM. This ROM was born from that frustration.

The ROM you have here began as a quick test ROM whipped up by Frank (IZ8DWF) that simply displayed full screens of characters in text mode, all without using zero page. This was seen in my Apple II+ Clone repair series.  (Frank's original is included here as `a2vmemnoram.asm` and `a2vmemnoram.bin`.)

I then wanted to do more, so I found disassembled code for the C64 "Dead Test" ROM on [World Of Janni](https://blog.worldofjani.com/?p=164), and ported that to the Apple II. I had to adjusted the functionality of the initial phase of that ROM to work with the Apple II, but it actually worked even with my  limited assembly skills. The main thing that makes this test great is it does NOT rely on DRAM at all. It runs entirely inside the ROM and does not use the **zero page** (`$00`-`$FF`) or the stack (`$100`-`$1FF`). All the other tests I found for the Apple II use Zero Page and stack, which is useless if you have DRAM problems in the first bank of memory.

The biggest problem with the C64 dead test is the diagnostic is a very simple RAM test that simply filled up the first several pages of RAM with simple patters. It will miss many common RAM problems and also can be fooled by many issues. So that's where David took over the work -- and at this point, essentially none of the original code from Frank or the C64 Dead test code is left.

## Scope
This test was designed and tested on the Apple II and Apple II+. (Clones of the Apple II+ should be supported.) 

The test should work fine on the Apple IIe and IIc as well, but please keep in mind that those systems use 64kbit DRAM chips, with some using 64kbit x 1 chips (where you have 8 chips for the lower 64K of RAM) and some later machines use 64kbit x 4 bit chips, where you only have two RAM chips for the lower 64k of RAM. You will need to use the schematics to understand how the bit / address errors we're reporting map to the specific motherboard you have.

## How it works

* Upon power up of the machine, it'll beep the speaker to indicate things are working.
* The ROM will test the zero page and stack using a [March-U](https://www.researchgate.net/profile/Georgi-Gaydadjiev/publication/3349024_March_U_A_test_for_unlinked_memory_faults/links/00b495294fc58a4b87000000/March-U-A-test-for-unlinked-memory-faults.pdf) test, one of the best RAM tests available. This will catch page errors within the zero and stack pages (`$000-$1FF`), and if any issues are detected, it will beep out an error code to indicate which bit is bad. (More on this further down.)
* Next the ROM will do a quick test for page errors inside the RAM. This is a subtle issue that can fool many RAM tests. For the main RAM tests to run, we need fully functional Zero page and stack, and if these will get corrupted by a page error causing the ROM to crash.  This page error test tries to prevent that from happening.
* The page error test work by by writing `$00` to address `$0000` (inside zero page) and then writing `$FF` to `$0100`, `$0200`, `$0400`, `$0800`, `$1000`, `$2000`, `$4000`, and `$8000`. If when writing `$FF` to those locations the `$00` at location `$0000` is disturbed, then we have a page error and must halt. (There is a bit more going on, but it's not relevant).
* If the page error test fails, the ROM will beep out which RAM bit is bad (helping indicate which chip has a page fault).  In the event location `$00` is corrupted with the value `$FF`, this indicates a logic problem on the motherboard.
* The next phase is to detect how much RAM is installed in the Apple II. Valid configurations of the original Apple II are 4K, 8K, 12K, 16K, 20K, 24K, 32K, 36K, and 48K. Currently this test does NOT test above 48k, because using/testing that RAM requires banking out the ROM.
* The ROM will print a banner showing how much RAM is detected and that the zero page and stack page are good.
* It will then procede to do March-U RAM test on all of the RAM (minus the zero page and stack, which are used to run the diagnostic ROM.)
* A full test of 48k takes about 1 minute 30 seconds.
* When the March-U RAM test finishes, you will get a page displaying the test results for all of the RAM detected in the machine.

### If an error is detected in the zero page, stack, or you have a page error, it will beep out the bit that is bad

* One long low beep followed by a number of medium beeps:
  * This is a zero page or stack page error.  
  * The count of medium beeps tells you which bit, and thus which chip (see below).
* A brief trill of high beeps, followed by a number of medium beeps:
  * This is a page error.  Address lines inside a chip are being crossed, so writes to one location corrupt bits in another location.
  * Again, the count of medium beeps tells you which bit and chip (see below).
* A constant trill of high beeps:
  * This is a problem with the address decoding logic on the motherboard.  This will only happen during the page error test.

How to find the offending RAM chip on an Apple II or II+:

* 1 beep: D0 (data bit 0), RAM chip at location C3
* 2 beeps: D1, RAM chip at location C4
* 3 beeps: D2, RAM chip at location C5
* 4 beeps: D3, RAM chip at location C6
* 5 beeps: D4, RAM chip at location C7
* 6 beeps: D5, RAM chip at location C8
* 7 beeps: D6, RAM chip at location C9
* 8 beeps: D7, RAM chip at location C10

At the end of the main memory test, the ROM will display a grid of results and play a tone.  A low tone indicates there was a memory fault found.  A rising two-beep tone indicates no problems found.  The test will automatically repeat after 10 seconds.  We suggest taking a cell phone picture of the screen for a recording... mixing the new technology with the old, you might say.

You don't have to worry about losing the results though.  All of the errors are cumulative.  You can leave the test running for hours, and any page that shows an error will always show that error, even if the error is intermittent.

## Interpreting the result display grid
The ROM will display a grid showing you where the bit errors are:
![RAM errors detected](pictures/grid%20errors.jpg?raw=true)

If you do not see this grid after the March-U test finishes and beeps, you likely have a problem with the video display circuitry on your Apple II. You must fix that first.

To understand how to decode the grid, it will show all of the pages that contain a bit error. In the above picture it is telling you:

* Page `$19` has a bit error `$08`
  * Converted to binary -> `0000 1000` or bit 4, aka D3
  * This means the RAM chip in location C6 is bad (for the Apple II or II+).
* Page `$A1` has a bit error `$01`
  * Converted to binary -> `0000 0001` or bit 1, aka D0.\
  * This means the RAM chip in E3 is bad.

The II and II+ motherboards have their DRAM laid out like this, at least when using 16K&nbsp;x&nbsp;1 DRAMs:

```
D0 through D7 is the processor data line

                  ROW 3  4  5  6  7  8  9  10 ROW
Pages $80 to $BF   E  D0 D1 D2 D3 D4 D5 D6 D7  E   RAM from $8000 to $BFFF
Pages $40 to $7F   D  D0 D1 D2 D3 D4 D5 D6 D7  D   RAM from $4000 to $7FFF
Pages $00 to $3F   C  D0 D1 D2 D3 D4 D5 D6 D7  C   RAM from $0000 to $3FFF 
                  ROW 3  4  5  6  7  8  9  10 ROW
```
For beep codes, remember that 1 beep = Bit 1 or D0. 8 beeps = Bit 8 or D7. (There is no way for us to make a beep code for 0, which is why D0-D7 are represented by 1-8 beeps, respectively).

## Limitations

* This ROM is designed as a troubleshooting aid only.
* An indicated bit error from this test does not necessarily mean the DRAM is faulty. It means the CPU is unable to correctly see the bit it expects from the DRAM. This could be caused by a bad RAM chip, but could also be some other fault in the system.
* The RAM subsystem on the Apple II is more complex than that of other contemporary 8-bit systems of the time, so many components in that subsystem can cause indicated bit errors.
* The Apple II has a dedicated DRAM output bus that is used to display text/graphics, and this bus is connected to the CPU data bus as needed via some logic chips.
* Please keep in mind that the ROM will only report the first bit it found in error.
  * When beeping or flashing, it starts at bit D0 (1 flashs). So if you have multiple bad chips, the lowest bad bit will usually be indicated. Change that chip and run again.
  * The full RAM test's grid will show all of the errors it's seen, but within a given page, it stops searching after the first error.  So again, the displays will show ***a*** fault, but not necessarily the only fault.
* Remember that each bit of DRAM in each bank is parallel with the other banks, so even if the test is running on the first 4K of RAM, you could have a bad chip in an adjacent bank causing a bit error in the first 4K.

## To use this ROM
(See also on YouTube: [Apple II Dead Test Diagnostic: How it works on a good system](https://youtu.be/60skMMOYuAw?si=O4dUQrf9blEDD3wS))

* It is designed to run in the `F8` ROM socket on the Apple II, Apple II+, language card or Apple ROM card.
* Since Apple uses 2316 (2K) mask ROMs on their motherboard and on the Apple ROM card, you will need an adapter to use an EPROM in any of these sockets. (Make one or use a PCB).
* Some languge cards can use 2716 EPROMs in the ROM socket, that may be helpful.
* The Apple //e can use a 2764 (8K) that holds EF ROMs, so you can load this F8 ROM into the top of the chip. (Load into address `$1800` in the EPROM to map into `$F800`)
* The Platinum //e has `CF` ROM which is a 27128 (16K) so you would load this `F8` ROM into the top of the chip (`$3800` to map into `$F800`)
* The Apple //c ROM is 27256 (32k) and we have not tested this on the //c, but you would need to find the right location to load this ROM into the EPROM so it would start at `$F800` in the 6502 memory map.

There is also a 170K DOS 3.3 disk image [`apple2dead.dsk`](https://github.com/misterblack1/appleII_deadtest/releases/latest/download/apple2dead.dsk) in the [Releases](https://github.com/misterblack1/appleII_deadtest/releases) page.  You can try that out if your system is working well enough to boot into DOS *AND* you have a working language card installed in your system (or a machine with built-in language card function... all 64K+ Apples II family machines and most/all 64K+ clones). It will auto start once the disk boots up. (Remember this will only test the first 48K in your system even if you have more.  The disk version loads the ROM image into the top 16K language card area.)

![ROM adapter in card](pictures/language_card.jpg?raw=true)

## To assemble the ROM (Linux or WSL on Windows)
You only need to assemble if you are planning to make changes.  Otherwise see the **[Releases](https://github.com/misterblack1/appleII_deadtest/releases)** page.

* `apt-get install cc65 make`
* Then download the zip from the repo and run `make`

`a2vmemnoram.asm` and `a2vmemnoram.bin` are Frank IZ8DWF's original test ROM, as shown in my Apple II Clone repair video.

## Thanks

* [World of Jani](https://blog.worldofjani.com) for sharing disassembled C64 dead test code.
* [IZ8DWF](https://www.youtube.com/@iz8dwf) for guidance on this along with some of his ROR-test code for printing a messagae to screen.
* [David KI3V](https://github.com/ki3v) for all the amazing work on this ROM!

See C64 Dead Test ROM here: http://blog.worldofjani.com/?p=164
