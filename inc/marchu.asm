
; .zeropage
; 	ptr_cur:	.res 1 ;	= $20
; 	pg_cur:		.res 1 ;	= $21
; 	pg_start:	.res 1 ;	= $22
; 	pg_end:		.res 1 ;	= $23
; 	testidx:	.res 1 ;	= $24
; .code
ptr_cur		= $20
pg_cur		= $21
pg_start	= $22
pg_end		= $23
testidx		= $24


.export count_ram
.proc	count_ram
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
		RTS
.endproc

PG_START = $02

; marchU
; returns bitmask of bad bits in A
.export marchU
.proc 	marchU
		LDA #0				; low bits 0 so we test a hardware page at a time
		STA ptr_cur
		LDA #PG_START		; set starting address (maybe change later to a parameter?)
		STA pg_start

		LDA #(tst_tbl_end-tst_tbl-1) ; number of test values
		STA testidx

	init:	
		LDY #$00			; Y will be the pointer into the page
		LDX testidx			; get the index to the test value pages
		LDA tst_tbl,X		; get the test value into A
		TAX					; X will contain the test val throughout marchU
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
		STA (ptr_cur),Y	; w0 - write the test value to current location
		INY				; count up
		BNE step0		; repeat until Y overflows back to zero (do the whole page)

		INC pg_cur		; increment the page
		LDA pg_cur
		CMP pg_end		; compare with (one page past) the last page
		BNE step0		; if not there yet, loop again

		; LDA #$08		; simulate error
		; JMP bad

; step 1; up - r0,w1,r1,w0
		LDA pg_start	; set up the starting page again for next stage
		STA pg_cur
	step1:	
		TXA				; get the test value
		EOR (ptr_cur),Y	; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (ptr_cur),Y	; w1 - write the inverted test value
		EOR (ptr_cur),Y	; r1 - read the same value back and compare using XOR
		BNE bad			; if bits differ, location is bad
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
		BNE bad			; if bits differ, location is bad
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
		JMP step3

	bad:RTS

	step3:	
		DEY				; pre-decrement (because counting down works differently than counting up)
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (ptr_cur),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		STA (ptr_cur),Y	; w0 - write the test value
		EOR (ptr_cur),Y	; r0 - read the same value back and compare using XOR
		BNE bad			; if bits differ, location is bad
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
		BNE bad			; if bits differ, location is bad
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
		BMI good		; out of test values, declare it good
		JMP init		; else go to next test value
	good:RTS
.endproc

.proc	report_ram
		; XYbeep $20, $FF
		; XYbeep $20, $C0
		; XYbeep $20, $FF
		; XYbeep $20, $C0
		; XYbeep $20, $FF
		; XYbeep $20, $C0
		ldx #$20
		ldy #$FF
		jsr beep
		ldy #$C0
		jsr beep
		ldy #$FF
		jsr beep
		ldy #$C0
		jsr beep
		ldy #$FF
		jsr beep
		ldy #$C0
		jsr beep
		RTS
.endproc

; beep
; X is number of cycles, Y is period of a cycle
.proc	beep
		phx
		phy
outer:	ply
		phy
inner:	sty SPKR
		dey
		bne inner
		dex
		bne outer
		ply
		plx
		rts
.endproc


; .data
; 	; memtest patterns to cycle through
; tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
; ; tst_tbl:.BYTE $FF ; while debugging, shorten the test value list
; 	tst_tbl_end = *
