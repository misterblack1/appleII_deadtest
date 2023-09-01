.include "inc/a2macros.inc"

	ROM2K = 1
.ifdef ROM2K
	.org $F800	; this is designed to run in a 2K rom on the Apple II/II+
.else
    .org $E000	; for the IIe and IIc
.endif
	ROMSTART = *

	MEMTEST_START = $0200
	; MEMTEST_END = $C000
; test will end one byte before MEMTEST_END

	ptr_cur	= $20
	pg_cur	= $21
	pg_start= $22
	pg_end	= $23
	testidx = $24

start:
		SEI
		CLD
		LDX #$FF
		TXS		; initialize the stack pointer
		
		; soft switches
		; LDX $C051	; text mode
		; LDX $C054	; page 2 off

		LDA $C050 		; turn on graphics
        LDA $C057 		; set high res
		LDA $C053		; mixed mode on

		LDX $C00E	; turn off alt charset on later apple machines
		LDX $C00C	; turn off 80 col

		LDX $C061 ; read button 1 to clear the reading
		LDX $C062 ; read button 2
		LDX $C063 ; read button 3

		LDX #$20
sbeepo: LDY #$C0		
sbeep:	DEY 		; startup beep
		BNE sbeep
		LDA $C030	; tick the speaker
		DEX
		BNE sbeepo


		LDA #<MEMTEST_START			; set up the pointers
		STA ptr_cur
		LDA #>MEMTEST_START		; set up memory parameters
		STA pg_start		
		; LDA #>MEMTEST_END
		; STA pg_end

		; LDY #$80			; simulate finding 32K RAM
		; JMP count_done

		; Count RAM.  Check start of every 4K block.
		; Reads from empty locations return $FF
		LDA #$FF
		LDX #0

		LDY #$10			; test 4K
		STX $1000		
		CMP $1000
		BEQ count_done
		LDY #$20			; test 8K
		STX $2000		
		CMP $2000
		BEQ count_done
		LDY #$30			; test 12K
		STX $3000		
		CMP $3000
		BEQ count_done
		LDY #$40			; test 16K
		STX $4000		
		CMP $4000
		BEQ count_done
		LDY #$50			; test 20K
		STX $5000		
		CMP $5000
		BEQ count_done
		LDY #$60			; test 24K
		STX $6000		
		CMP $6000
		BEQ count_done
		LDY #$80			; test 32K
		STX $8000		
		CMP $8000
		BEQ count_done
		LDY #$90			; test 36K
		STX $9000		
		CMP $9000
		BEQ count_done
		LDY #$C0			; assume 48K
count_done:
		STY pg_end
		JMP marchU

zp_badj:JMP zp_bad

.proc 	marchU
		LDA $C050 		; turn on graphics
        LDA $C057 		; set high res
		LDA $C053		; mixed mode on

		LDA #(tst_tbl_end-tst_tbl-1)	; number of test values
		STA testidx

	init:	
		LDY #$00		; Y will be the pointer into the page
		LDX testidx		; get the index to the test value pages
		LDA tst_tbl,X	; get the test value into A
		TAX				; X will contain the test val throughout marchU
		LDA pg_start
		STA pg_cur

; In the descriptions below:
;	up: 	perform the test from low addresses to high ones
; 	down:	perform the test from high addresses to low ones
;	r0:		read the current location, compare to the test value, fail if different
;	r1:		read the current location, compare to the inverted test value, fail if different
;	w0:		write the test value to current location
;	w1:		write the inverted test value to current location

; step 0; up - w0 - write the test value
	step0:	
		TXA				; get the test value
		STA (ptr_cur),Y; w0 - write the test value to current location
		INY				; count up
		BNE step0		; repeat until Y overflows back to zero (do the whole page)

		INC pg_cur		; increment the page
		LDA pg_cur
		CMP pg_end		; compare with (one page past) the last page
		BNE step0		; if not there yet, loop again

		; LDA #$08		; simulate error
		; JMP zp_bad

; step 1; up - r0,w1,r1,w0
		LDA pg_start	; set up the starting page again for next stage
		STA pg_cur
	step1:	
		TXA				; get the test value
		EOR (ptr_cur),Y	; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_badj		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (ptr_cur),Y	; w1 - write the inverted test value
		EOR (ptr_cur),Y	; r1 - read the same value back and compare using XOR
		BNE zp_badj		; if bits differ, location is bad
		TXA				; get the test value
		STA (ptr_cur),Y	; w0 - write the test value to the memory location
		INY				; count up
		BNE step1		; repeat until Y overflows back to zero

		INC pg_cur		; increment the page
		LDA pg_cur
		CMP pg_end		; compare with (one page past) the last page
		BNE step1		; if not there yet, loop again

; step 2; up - r0,w1
		LDA pg_start	; set up the starting page again for next stage
		STA pg_cur
	step2:	
		TXA				; get the test value
		EOR (ptr_cur),Y	; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (ptr_cur),Y	; w1 - write the inverted test value
		INY				; count up
		BNE step2		; repeat until Y overflows back to zero

		INC pg_cur		; increment the page
		LDA pg_cur
		CMP pg_end		; compare with (one page past) the last page
		BNE step2		; if not there yet, loop again

; step 3; down - r1,w0,r0,w1
		LDA pg_end
		STA pg_cur
		DEC pg_cur		; start at the end page minus one
	step3:	
		DEY				; pre-decrement (because counting down works differently than counting up)
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (ptr_cur),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA (ptr_cur),Y	; w0 - write the test value
		EOR (ptr_cur),Y	; r0 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (ptr_cur),Y	; w1 - write the inverted test value
		DEY				; determine if we are at offset zero
		INY
		BNE step3		; repeat until Y overflows back to FF

		DEC pg_cur		; decrement the page
		LDA pg_cur
		CMP pg_start	; compare with the first page, which can't be zero
		BCS step3		; if not there yet (pg_cur>=pg_start so carry set), loop again

; step 4; down - r1,w0
		LDA pg_end
		STA pg_cur
		DEC pg_cur		; start at the end page minus one
	step4:	
		DEY				; pre-decrement (because counting down works differently than counting up)
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (ptr_cur),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA (ptr_cur),Y	; w0 - write the test value
		DEY				; determine if we are at offset zero
		INY
		BNE step4		; repeat until Y overflows back to FF

		DEC pg_cur		; decrement the page
		LDA pg_cur
		CMP pg_start	; compare with the first page, which can't be zero
		BCS step4		; if not there yet (pg_cur>=pg_start so carry set), loop again

; now, determine whether to repeat with a new test value
		LDX testidx
		DEX
		STX testidx
		BMI zp_good		; start again with next value if we didn't go past zero
		JMP init
.endproc

; zp_bad; Y will equal the current pointer, A will have the bits that differ
zp_bad:
		JMP findbit

zp_good:
		LDX #$FF	; XXX Hack: fix the stack, we've stomped on it.
		TXS
		; LDA #$08		; simulate error
		; JMP zp_bad
		; memtest ok put the RAM test good code here
		; Since first 4K is good, we can use Zero page now
		; we then use $00,$01 as pointer for video memory 
		LDX $C051	; text mode
		LDX $C054	; page 2 off

		LDA #$00
		STA $00
		LDA #$04	
		STA $01
		LDA #$08	; end of video memory (page)
		STA $02
					; clears the entire screen
		LDY #$00
npcl:	LDA #$A0 	; A0 is the black character on the Apple II and II plus
cls:	STA ($00),Y
		INY
		BNE cls
		INC $01
		LDA $02
		CMP $01
		BNE npcl

;prints the ramgood string
		LDA #$00
		STA $00
		LDA #$04	
		STA $01
		LDA #<ramok
		STA $10		; pointer to source string 
		LDA #>ramok
		STA $11
		JSR print
		; JMP beep		; we may want to reset?

beep:	LDY #$A0
beeplp:	DEY 		; will beep the computer to say things are good
		BNE beeplp
		LDA $C030	; tick the speaker
		DEX
		BNE beep
beep2:	LDY #$A0
beep2lp:DEY 		; extend beep twice as long without adding another loop index
		BNE beep2lp
		LDA $C030	; tick the speaker
		DEX
		BNE beep2

done:	
		LDA $C061 ; read button 0
		AND #$80
		BNE again
		LDA $C062 ; read button 0
		AND #$80
		BNE again
		LDA $C063 ; read button 0
		AND #$80
		BNE again
		JMP done	; infinite loop

again:	; user pushed a button or shift, so re-run the test
		JMP marchU 


; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found
.proc findbit
		LDX #8			; start at high bit
		CLC				; clear carry
	chkbit:	
		ROL				; move tested bit into carry
		BCS flasherr	; bit set, display it
		DEX				; count down
		BNE chkbit		; test next bit
	oops:	
		JMP oops			; should not get here?
.endproc

.proc flasherr			; time to flash the screen
		TXS  			; X is holding the bad bit, save it in the SP

		; XXX HACK: print the bank number on the bottom line
		; clear the bottom lines
		LDA $C051		; text mode
		LDX $C054	; page 2 off

		LDA #$A0	 	; A0 is the black character on the Apple II and II plus

		LDY $FF
	:	DEY
		STA $0400,Y		
		STA $0500,Y		
		STA $0600,Y		
		STA $0700,Y		
		BNE :-


		LDY #0			; print the bad bank message
	saybad:
		LDA bad_msg,Y
		BEQ :+
		ORA #$80
		STA $07D0,Y
		INY
		JMP saybad
	:

		LDA pg_cur

		ROR				; get the top 3 bits as the bank number
		ROR
		ROR
		ROR
		ROR
		ROR
		
		AND #$03			; get only the low 3 bits

		CLC
		TAX
		LDA hex_tbl,X
		ORA #$80

		STA $07D0+bad_msg_len

		TSX					; get the bat bits mask from the sp
		TXA
		AND #$0F			; get low nybble
		TAY
		LDA hex_tbl,Y
		STA $07D5
		TXA
		ROR
		ROR
		ROR
		ROR
		AND #$0F			; get low nybble
		TAY
		LDA hex_tbl,Y
		STA $07D4

		

	byte_loop:
		LDA $C051		; text mode
		LDX #$00		; a long pause at beginning and between flashes
        LDY #$00
		XYdelay 4
		TSX	
	bit_loop:
		LDA $C050 		; turn on graphics
		LDA $C057 		; set high res
		LDA $C030 		; tick the speaker
		LDA $C030		; tick the speaker again as on real hardware you need this twice
		TXA				; save bit counter in A

        ; LDX #$7F		; pause with hi res on
        ; LDY #$00
		; XYdelay

		LDX #$80
		LDY #$FF		; low beep for bad bit
beep:	STA $C030		; tick the speaker
:		DEY 			
		BNE :-
:		DEY 			
		BNE :-
		DEX
		BNE beep


        TAX				; move bit counter back to X
		LDA $C051		; text mode
		; LDA $C056 		; set low res
		LDA $C030 		; tick the speaker
		TXA				; save bit counter in A

		LDX #$7F		; pause with low res on
        LDY #$00
		XYdelay 2

        TAX				; move bit counter back to X
        DEX 
		BNE bit_loop
		TSX	
		; JMP byte_loop
		JMP marchU
.endproc

print:	LDY #$00	; code to print text to screen
pnext:	LDA ($10),Y	; pointer to the string
		BEQ pexit	; end of string
		ORA #$80	; to fix flashing text on Apple II and II+
		STA ($00),Y	; video memory pointer
		INC $00
		CPY $00
		BNE skipv
		INC $01
skipv:	INC $10
		CPY $10
		BNE pnext
		INC $11
		JMP pnext
pexit:	RTS


ramok:	.asciiz "RAM OK. PUSH SHIFT TO RUN AGAIN."

	; memtest patterns to cycle through
tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
; tst_tbl:.BYTE $FF ; while debugging, shorten the test value list
	tst_tbl_end = *

bad_msg:.asciiz "ERR    BANK"
	bad_msg_len = * - bad_msg

hex_tbl:.asciiz "0123456789ABCDEF"

; end of the code	
	endofrom = *
; fills the unused space with $FF 
	.res ($FFFA-endofrom), $FF

; vectors
	.org $FFFA
	.word	ROMSTART,ROMSTART,ROMSTART

; code: language=ca65
