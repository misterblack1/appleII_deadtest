.scope	ZPSP

start:	
		LDX #(zp_tbl_end-tst_tbl-1)	; initialize the pointer to the table of values

; step 0; up - w0 - write the test value
marchU:	
		LDY #$00
		LDA tst_tbl,X	; get the test value into A

		TXS				; save the index to the test value into SP
		TAX				; copy the test value into X
marchU0:STA $00,Y		; w0 - write the test value
		STA $0100,Y		;    - also to stack page
		; STA $0400,Y		; also write to the screen
		; STA $0500,Y		; also write to the screen
		; STA $0600,Y		; also write to the screen
		STA $0700,Y		; also write to the screen
		INY				; count up
		BNE marchU0		; repeat until Y overflows back to zero

		; STY $00			; intentionally create an error for testing
; step 1; up - r0,w1,r1,w0
; A contains test value
marchU1:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		EOR $00,Y		; r1 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $0100,Y		; w1s - also stack page
		EOR $0100,Y		; r1s
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $00,Y		; w0 - write the test value to the memory location
		STA $0100,Y		; w0s - also stack page
		INY				; count up
		BNE marchU1		; repeat until Y overflows back to zero

; step 2; up - r0,w1
; A contains test value from prev step
marchU2:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s  - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		EOR #$FF		; invert
		INY				; count up
		BNE marchU2		; repeat until Y overflows back to zero
		JMP continue

zp_bad:	JMP findbit

continue:
; step 3; down - r1,w0,r0,w1
; A contains the inverted test value from prev step
		EOR #$FF		; invert
marchU3:DEY				; decrement Y from 0 to FF
		EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF
		EOR $0100,Y		; r1s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		EOR $00,Y		; r0 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $0100,Y		; w0s - write the test value
		EOR $0100,Y		; r0s - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		DEY				; count down
		INY
		BCS marchU3		; repeat until Y overflows back to FF

; step 4; down - r1,w0
; A contains the inverted test value from prev step
marchU4:DEY
		EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		EOR $0100,Y		; r1s - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		STA $0100,Y		; w0s - also stack page
		DEY				; count down
		INY
		BCS marchU4		; repeat until Y overflows back to FF

		TSX				; recover the test value index from SP
		DEX				; choose the next one
		BPL marchup		; start again with next value
		JMP zp_good

marchup:
		JMP marchU



; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found
findbit:LDX #8			; start at high bit
		CLC				; clear carry
chkbit:	ROL				; move tested bit into carry
		BCS flasherr	; bit set, display it
		DEX				; count down
		BNE chkbit		; test next bit
wha:	JMP wha			; should not get here?


.proc flasherr			; time to flash the screen
		TXS  			; X is holding the bad bit, save it in the SP

		; XXX HACK: print the bank number on the bottom line
		; clear the bottom lines
		LDA TXTSET		; text mode
		LDX LOWSCR		; page 2 off

		clear_text_screen
	; 	LDA #$A0	 	; A0 is the black character on the Apple II and II plus
	; 	LDY $FF			; clear the screen
	; :	DEY
	; 	STA $0400,Y		
	; 	STA $0500,Y		
	; 	STA $0600,Y		
	; 	STA $0700,Y		
	; 	BNE :-

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
		ROR					; get the top 3 bits as the bank number
		ROR
		ROR
		ROR
		ROR
		ROR
		AND #$03			; get only the low 3 bits

		CLC					; XXX is this needed?
		TAX					; copy bank number to X
		LDA hex_tbl,X		; look up the hex value of the bank number
		ORA #$80			; set the top bit so it's non-inverse
		STA $07D0+bad_msg_len ; write it to the screen

		TSX					; get the bad bits mask from the sp
		TXA					; into A
		AND #$0F			; get low nybble
		TAY					; use it as an index
		LDA hex_tbl,Y		; into the hex table
		STA $07D5			; TODO write low nybble to screen should set top bit to make it normal text
		TXA					; get bad bits again
		ROR					; rotate high nybble to low
		ROR
		ROR
		ROR
		AND #$0F			; get low nybble
		TAY					; use it as an index
		LDA hex_tbl,Y		; into the hex table
		STA $07D4			; TODO write high nybble to screen should set top bit to make it normal text

		

	byte_loop:
		LDA TXTSET			; text mode
		LDX #$00			; a long pause at beginning and between flashes
        LDY #$00
		XYdelay 4
		TSX	
	bit_loop:
		LDA TXTCLR 			; turn on graphics
		LDA HIRES 			; set high res
		TXA					; save bit counter in A

		XYbeep $FF, $FF
; 		LDX #$80
; 		LDY #$FF			; low beep for bad bit
; beep:	STA $C030			; tick the speaker
; :		DEY 			
; 		BNE :-
; :		DEY 			
; 		BNE :-
; 		DEX
; 		BNE beep

		LDA TXTSET			; text mode
		TXA					; save bit counter in A

		LDX #$7F			; pause with low res on
        LDY #$00
		XYdelay 2

        TAX					; move bit counter back to X
        DEX 
		BNE bit_loop
		JMP byte_loop
.endproc

bad_msg:.asciiz "ERR    BANK"
	bad_msg_len = * - bad_msg

hex_tbl:.asciiz "0123456789ABCDEF"

zp_good:
.endscope