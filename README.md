# Apple II Dead Test RAM Diagnostic ROM

## Background
Recently while fixing an Apple II+ clone, I was annoyed there seemed to be no diagnostic ROMs available for the Apple II that could test the RAM without using RAM. This ROM is a result of that frustration. 

The ROM you have here began as a quick test ROM whipped up by Frank (IZ8DWF) that simply displayed full screens of characters in text mode, all without using zero page. This was seen in my Apple II+ Clone repair series.

I then wanted to do more, so I found disassembled code for the C64 "Dead Test" ROM on World Of Janni, and ported that to the Apple II. I had to adjusted the functionality of the initial phase of that ROM to work with the Apple II, but it actually worked even with my very limited assembly skills. The main thing that makes this test great is it does NOT rely on DRAM at all. It runs entirely inside the ROM and does not use the ZERO PAGE ($00-$FF) or the stack ($100-$1FF.) All the other tests I found for the Apple II use Zero Page and stack, which is useless if you have DRAM problems in the first bank of memory. 

The biggest problem with the C64 dead test is the diagnostic is a very simply RAM test that simply filled up the first several pages of RAM with simple patters. It will mis a lot of problems and also can be fooled by many issues. So that's where David took over the work -- and at this point, very little of the original code from Frank or the C64 Dead test code exists. 

## Scope
This test was designed and tested on the Apple II and Apple II+. (Clones of the Apple II+ should be supported.) 

The test should work fine on the Apple IIe and IIc as well, but keep in mind that those systems use 64kbit DRAM chips, with some using 64kbit x 1 chips (where you have 8 chips for the lower 64K of RAM) and some later machines use 64kbit x 4 bit chips, where you only have two RAM chips for the lower 64k of RAM. You will need to use the schematics to understand how the bit / address errors we're reporting map to the specific motherboard you have. 

## How it works
* Upon power up of the machine, it'll beep the speaker to indicate things are working.
* The ROM will test the zero page and stack using a March-U test, one of the best RAM tests available. This will catch page errors within the first page, and if any issues are detected, it will beep out an error code to indicate which bit is bad. (More on this further down.)
* Next the ROM will do a quick test for page errors inside the RAM. This is a subtle issue that can fool many RAM tests. For the rest of the test to run, we need fully functional Zero page and stack, and if these will get corrupted by a page error, this will cause the ROM to crash.
* The page error test work by by writing $00 to address $0000 (inside zerp page) and then writing $FF to $0100, $0200, $0400, $0800, $1000, $2000, $4000, and $8000. If when writing $FF to those locations the $00 at location $0000 is disturbed, then we have a page error and must halt. (There is a bit more going on, but it's not relevant)
* The ROM should beep out which RAM bit is bad with another possible outcome being a logic problem on the motherboard. (To-do, does this work?)
* The next phase is to detect how much RAM is installed in the Apple II. Possible configurations are 4k, 8k, 12k, 16k, 32k, 48k and a couple other configs. Currently this test does NOT test above 48k.
* The ROM will print a banner showing how much RAM is detected and that the Zero Page is good.
* It will then procede to do March-U RAM test on all of the RAM (minus the zero Page and stack, which are used to run the diagnostic ROM.)
* A full test of 48k takes about 1 minute 30 seconds.
* When all RAM passes, you will get an all good message, and the test will run again.

### If an error is detected in the zero page, stack, or you have a page error, it will beep out the bit that is bad

```
1 beep = D0 problem, this is the RAM chip at C3
2 beeps = D1 problem, this is the RAM chip at C4
3 beeps = D2 problem, this is the RAM chip at C5
4 beeps = D3 problem, this is the RAM chip at C6
5 beeps = D4 problem, this is the RAM chip at C7
6 beeps = D5 problem, this is the RAM chip at C8
7 beeps = D6 problem, this is the RAM chip at C9
8 beeps = D7 problem, this is the RAM chip at C10
9 beeps = Motherboard logic problem causing a page error (only possible on page error test)
```

## If an error is detected in the main memory
The ROM will display a grid showing you where the bit errors are:
![RAM errors detected](https://github.com/misterblack1/appleII_deadtest/blob/main/pictures/grid%20errors.jpg?raw=true)

If yo udo not see this grid, you likely have a problem with the video display circuitry on your Apple II. You must fix that first. 

To understand how to decode the grid, it will show all of the pages that contain a bit error. In the above picture it is telling you:
* Page $19 has a bit error $08 (converted to binary -> 0000 1000 or bit 4, aka D3.) This means the RAM chip in C6 is bad.
* Page $A1 has a bit error $01 (converted to binary -> 0000 0001 or bit 1, aka D0.) This means the RAM chip in E3 is bad.

The II and II+ motherboards have their DRAM laid out like this:

```
  3  4  5  6  7  8  9  10
E D0 D1 D2 D3 D4 D5 D6 D7 E   RAM from $8000 to $BFFF (pages $80 to $BF)
D D0 D1 D2 D3 D4 D5 D6 D7 D   RAM from $4000 to $7FFF (pages $40 to $7F)
C D0 D1 D2 D3 D4 D5 D6 D7 C   RAM from $0000 to $3FFF (pages $00 to $3F)
  3  4  5  6  7  8  9  10
```
For beep codes, remember that 1 beep = Bit 1 or D0. 8 beeps = Bit 8 or D7. (There is no way for us to make a beep code for 0, which is why D0-D7 is represented by Bit 1 - 8.

## Limitations
* This ROM is designed as a troubleshooting aid only.
* An indicated bit error from this test does not mean the DRAM is faulty, it means the CPU is unable to correctly see the bit it expects from the DRAM. This could be caused by a bad RAM chip or other faults on the system.
* The RAM subsystem on the Apple II is more complex than that of other contemporary 8-bit systems of the time, so many components in that subsystem can cause indicated bit errors.
* The Apple II has a dedicated DRAM output bus that is used to display text/graphics, and this bus is connected to the CPU data bus as needed via some logic chips.
* Please keep in mind is that it will only flash the first bit it saw as wrong, starting at bit 7 (8 flashes.) So if you have multiple bad chips, the highest bad bit will usually win and flash. Change that chip and run again.
* Remember that each bit of DRAM in each bank is parallel with the other banks, so even if the test is running on the first 4K of RAM, you could have a bad chip in an adjacent bank causing a bit error in the first 4K. 

## To use this ROM
* It is designed to run in the F8 ROM socket on the Apple II, Apple II+, language card or Apple ROM card.
* Since Apple uses 2316 (2K) mask ROMs on their motherboard and on the Apple ROM card, you will need an adapter to use an EPROM in any of these sockets. (Make one or use a PCB)
* Some languge cards can use 2716 EPROMs in the ROM socket, that may be helpful
* IIe can use a 2764 (8K) that holds EF ROMs, so you can load this F8 ROM into the top of the chip. (Load into address $1800 in the EPROM to map into $F800)
* Platinum //e has CF ROM which is a 27128 (16K) so you would load this F8 ROM into the top of the chip ($3800 to map into $F800)
* IIc ROM is 27256 (32k) and we have not tested this on the IIc, but you would need to find the right location to load this ROM into the EPROM so it would start at $F800 in the 6502 memory map.

![ROM adapter in card](https://github.com/misterblack1/appleII_deadtest/blob/main/pictures/Screen%20Shot%202023-08-27%20at%207.45.43%20PM.png?raw=true)

## To assemble the ROM
* apt-get install cc65 make
* Then download the zip from the repo and run "make"

a2vmemnoram.asm and a2vmemnoram.bin is Frank IZ8DWF's original test ROM, as shown in my Apple II Clone repair

## Thanks
* World of Jani for sharing disassembled C64 dead test code.
* IZ8DWF for guidance on this along with some of his ROR-test code for printing a messagae to screen.
* David for all the amazing work on this rom!

See C64 Dead Test ROM here: http://blog.worldofjani.com/?p=164
