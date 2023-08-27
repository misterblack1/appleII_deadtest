# Apple II Dead Test ROM
While fixing an Apple II+ clone, I was annoyed there seemed to be no diagnostic ROM for the system that could test the RAM without using RAM.

So this ROM is a result of that. I mostly ported the C64 dead test ROM over to the Apple II and replicated the functionality of the initial phase of that ROM. The main thing that makes this test great is it does NOT rely on DRAM at all. It runs entirely inside the ROM and does not use the ZERP PAGE ($00-$FF) or the stack ($100-$1FF.) All the other tests I found use that part of RAM, which isn't helpful if you have bad RAM in that part of the system.

Note: It does use the ZERO PAGE at the end to print the message about the RAM being good. See below.

Here is how it works:

* Upon power up of the machine, it'll beep the speaker to indicate things are working.
* It will then procede to fill the first 4K of RAM with these bytes $00,$55,$AA,$FF,$01,$02,$04,$08,$10,$20,$40,$80,$FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F (in reverse order)
* Since it is filling the first 4K, that includes the text mode screen buffer, so you will see it running! (Unlike the C64 dead test)
* Between each byte, it will wait a little bit in order to catch refresh problems, bit rot, etc.
* It then goes back and reads the 4K of RAM and compares to the written byte, and if any bits are wrong, it'll just to the error handler.
* If all the bits look good, it will clear the screen, beep again and print a message saying the first 4K of RAM is ok.
* If there are problems with the bits, it will detect the issue and let you knwo the bit is bad.
* It does this by alternating the screen between HGR (high res) and GR (low res graphings) n times where n is the bit that is bit. It will also tick the speaker the n times, in case your screen isn't working.
* So if bit 7 is bad, you will get 8 flashes and ticks, followed by a pause, then it will flash/tick 8 times again.

To decode the flashes:
* Bit 0 error -> 1 flash
* Bit 1 error -> 2 flashes
* Bit 2 error -> 3 flashes
* Bit 3 error -> 4 flashes
* ...
* Bit 7 error -> 8 flashes

Something to keep in mind is that it will only flash the first bit it saw as wrong, starting at bit 0. So if you have a chip that has all bits bad, I presume it will only flash 1 time to indicate bit 0. Change that chip and run again.

To use this ROM:
* It is designed to run in the F8 ROM socket on the Apple II, Apple II+ or Apple ROM card.
* Since Apple uses 2316 (2K) mask ROMs on their motherboard, you will need an adapter to use an EPROM in any of these sockets. (Make one or use a PCB)
* IIe can use a 2764 (8K) that holds EF ROM, so you can load this F8 ROM into the top of the chip ($1800)
* Platinum //e has CF ROM which is a 27128 (16K) so you would load this F8 ROM into the top of the chip ($3800)
* IIc ROM is 27256 (32k) and we have not tested this on the IIc

To assemble the ROM:
* Install XA on your computer using some package manager (apt-get xa)
* Compile it with xa -C apple2-deadtest.asm -o 341-0020-00.f8

Thanks: 
* World of Jani for sharing disassembled C64 dead test code.
* IZ8DWF for guidance on this along with some of his ROR-test code for printing a messagae to screen.

Code assembled on xa (xa65) v2.3.8 Written by Andre Fachat, Jolse Maginnis, David Weinehall and Cameron Kaiser

See C64 Dead Test ROM here: http://blog.worldofjani.com/?p=164
