
; zp_alloc mu_ptr_lo

.zeropage
		mu_ptr_lo:		.res 1
		mu_ptr_hi:		.res 1
		mu_page_start:	.res 1
		mu_page_end:	.res 1
		mu_test_idx:	.res 1
.code

FIRST_PAGE = $02


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
		STY mu_page_end
		RTS
.endproc

; marchU
; returns bitmask of bad bits in A
.proc 	marchU
		LDA #0				; low bits 0 so we test a hardware page at a time
		STA mu_ptr_lo
		LDA #FIRST_PAGE		; set starting address (maybe change later to a parameter?)
		STA mu_page_start

		LDA #(tst_tbl_end-tst_tbl-1) ; number of test values
		STA mu_test_idx

	init:	
		LDY #$00			; Y will be the pointer into the page
		LDX mu_test_idx		; get the index to the test value pages
		LDA tst_tbl,X		; get the test value into A
		TAX					; X will contain the test val throughout marchU
		LDA mu_page_start
		STA mu_ptr_hi

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
		STA (mu_ptr_lo),Y	; w0 - write the test value to current location
		INY				; count up
		BNE step0		; repeat until Y overflows back to zero (do the whole page)

		INC mu_ptr_hi	; increment the page
		LDA mu_ptr_hi
		CMP mu_page_end	; compare with (one page past) the last page
		BNE step0		; if not there yet, loop again

		; LDA #$08		; simulate error
		; JMP bad

; step 1; up - r0,w1,r1,w0
		LDA mu_page_start	; set up the starting page again for next stage
		STA mu_ptr_hi
	step1:	
		TXA				; get the test value
		EOR (mu_ptr_lo),Y	; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (mu_ptr_lo),Y	; w1 - write the inverted test value
		EOR (mu_ptr_lo),Y	; r1 - read the same value back and compare using XOR
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		STA (mu_ptr_lo),Y	; w0 - write the test value to the memory location
		INY				; count up
		BNE step1		; repeat until Y overflows back to zero

		INC mu_ptr_hi	; increment the page
		LDA mu_ptr_hi
		CMP mu_page_end	; compare with (one page past) the last page
		BNE step1		; if not there yet, loop again

; step 2; up - r0,w1
		LDA mu_page_start	; set up the starting page again for next stage
		STA mu_ptr_hi
	step2:	
		TXA				; get the test value
		EOR (mu_ptr_lo),Y	; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (mu_ptr_lo),Y	; w1 - write the inverted test value
		INY				; count up
		BNE step2		; repeat until Y overflows back to zero

		INC mu_ptr_hi	; increment the page
		LDA mu_ptr_hi
		CMP mu_page_end	; compare with (one page past) the last page
		BNE step2		; if not there yet, loop again

; step 3; down - r1,w0,r0,w1
		LDA mu_page_end
		STA mu_ptr_hi
		DEC mu_ptr_hi	; start at the end page minus one
		JMP step3

	bad:RTS

		LDY #$FF		; start at FF and count down
	step3:	
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (mu_ptr_lo),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		STA (mu_ptr_lo),Y	; w0 - write the test value
		EOR (mu_ptr_lo),Y	; r0 - read the same value back and compare using XOR
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (mu_ptr_lo),Y	; w1 - write the inverted test value
		DEY				; determine if we are at offset zero
		CPY $FF			; did we wrap around?
		BNE step3		; repeat until Y overflows back to FF

		DEC mu_ptr_hi	; decrement the page
		LDA mu_ptr_hi
		CMP mu_page_start	; compare with the first page, which can't be zero
		BCS step3		; if not there yet (mu_ptr_hi>=mu_page_start so carry set), loop again

; step 4; down - r1,w0
		LDA mu_page_end
		STA mu_ptr_hi
		DEC mu_ptr_hi	; start at the end page minus one
	step4:	
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (mu_ptr_lo),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE bad			; if bits differ, location is bad
		TXA				; get the test value
		STA (mu_ptr_lo),Y	; w0 - write the test value
		DEY				; determine if we are at offset zero
		CPY $FF			; did we wrap around?
		BNE step4		; repeat until Y overflows back to FF

		DEC mu_ptr_hi	; decrement the page
		LDA mu_ptr_hi
		CMP mu_page_start	; compare with the first page, which can't be zero
		BCS step4		; if not there yet (mu_ptr_hi>=mu_page_start so carry set), loop again

; now, determine whether to repeat with a new test value
		LDX mu_test_idx
		DEX
		STX mu_test_idx
		BMI good		; out of test values, declare it good
		JMP init		; else go to next test value
	good:RTS
.endproc

.proc	report_ram
		ldx #$20		; cycles
		lda #$80		; period
		jsr beep
		ldx #$40		; cycles
		lda #$40		; period
		jsr beep
		ldx #$00		; cycles
		lda #$20		; period
		jsr beep
		jsr beep
		RTS
.endproc

; A is period, X is cycles, destroys Y
.proc	beep
outer:	pha
		tay
inner:	nop
		nop
		nop
		dey
		bne inner
		STA SPKR
		pla
		dex
		bne outer
		rts
.endproc

; .data
; 	; memtest patterns to cycle through
; tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
; ; tst_tbl:.BYTE $FF ; while debugging, shorten the test value list
; 	tst_tbl_end = *
