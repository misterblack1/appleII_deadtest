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

See C64 Dead Test ROM here: http://blog.worldofjani.com/?p=164
