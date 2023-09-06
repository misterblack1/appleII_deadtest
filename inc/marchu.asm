; Apple ][ Dead Test RAM Diagnostic ROM
; Copyright (C) 2023  David Giller

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

.zeropage
		mu_ptr_lo:		.res 1
		mu_ptr_hi:
		count_ptr:		.res 1	; when counting, use same location to store low part of address
		mu_page_end:	.res 1
		mu_page_start:	.res 1
		mu_test_idx:	.res 1
		mu_ysave:		.res 1
		all_errs:		.res 1
		scratch:		.res 2
		results:		.res 48*4
.code

FIRST_PAGE = $02


.proc	count_ram
		; Count RAM.  Check start of every 4K block.
		; Reads from empty locations return $FF regardless of what was written there.
		LDA #0
		STA count_ptr		; low bits.  High are at mu_page_end

		LDY #0				; no offsets
		LDX #(sizes_end-sizes-1)
	lp:	LDA sizes,X			; fetch the size from the table
		STA mu_page_end		; use it as the page number in the scratch pointer
		LDA #0
		STA (count_ptr),Y	; store 0 at the start of the page
		LDA (count_ptr),Y	; if no RAM there, will return $FF
		CMP #$FF			; if $FF we found the end of RAM
		BEQ found
		DEX					; try next location
		BPL lp
		LDA #$C0			; if not yet found, it's 48K.  Don't want to probe at $C000.
		STA mu_page_end
	found:
		RTS

		sizes: .byte $90,$80,$60,$50,$40,$30,$20,$10
		sizes_end = *
.endproc

.proc	init_results
		lda #0
		sta all_errs
		tay
	lp: sta results,Y
		iny
		bne lp
		rts
.endproc

.macro checkbad
		beq :+
		STY mu_ysave
		LDY mu_ptr_hi	; get the page number as index into results array
		ORA results,Y	; collect any bad bits
		STA results,Y	; store the accumulated errors back to the results array
		ORA all_errs	; also store one value that collects all of the bad bits found
		STA all_errs
		LDY mu_ysave
	:
.endmac

; marchU
; returns bitmask of bad bits in A
.proc 	marchU
		sta TXTCLR			; use graphics
        sta HIRES 			; set high res
		sta MIXSET			; mixed mode on

		LDA #FIRST_PAGE		; set starting address (maybe change later to a parameter?)
		STA mu_page_start

		LDA #(tst_tbl_end-tst_tbl-1) ; number of test values
		STA mu_test_idx

	init:	
		LDA #0				; low bits 0 so we test a hardware page at a time
		STA mu_ptr_lo
		LDY #$00			; Y will be the pointer into the page
		LDX mu_test_idx		; get the index to the test value pages
		LDA tst_tbl,X		; get the test value into A
		TAX					; X will contain the test val throughout marchU
		LDA mu_page_start
		STA mu_ptr_hi

		; lda #08
		; sta results+$19
		; lda #01
		; sta results+$A1
		; sta all_errs
		; jmp show_report		; simulate a run with canned errors

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
		; BNE bad			; if bits differ, location is bad
		checkbad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (mu_ptr_lo),Y	; w1 - write the inverted test value
		EOR (mu_ptr_lo),Y	; r1 - read the same value back and compare using XOR
		; BNE bad			; if bits differ, location is bad
		checkbad
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
		; BNE bad			; if bits differ, location is bad
		checkbad
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
		JMP continue3

	; bad: 
	; 	LDY mu_ptr_hi	; get the page number as index into results array
	; 	ORA results,Y	; collect any bad bits
	; 	STA results,Y	; store the accumulated errors back to the results array
	; 	ORA all_errs	; also store one value that collects all of the bad bits found
	; 	STA all_errs
	; 	JMP next

	continue3:
		LDY #$FF		; start at FF and count down
	step3:	
		TXA				; get the test value
		EOR #$FF		; invert
		EOR (mu_ptr_lo),Y	; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		; BNE bad			; if bits differ, location is bad
		checkbad
		TXA				; get the test value
		STA (mu_ptr_lo),Y	; w0 - write the test value
		EOR (mu_ptr_lo),Y	; r0 - read the same value back and compare using XOR
		; BNE bad			; if bits differ, location is bad
		checkbad
		TXA				; get the test value
		EOR #$FF		; invert
		STA (mu_ptr_lo),Y	; w1 - write the inverted test value
		DEY				; determine if we are at offset zero
		CPY #$FF			; did we wrap around?
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
		; BNE bad			; if bits differ, location is bad
		checkbad
		TXA				; get the test value
		STA (mu_ptr_lo),Y	; w0 - write the test value
		DEY				; determine if we are at offset zero
		CPY #$FF			; did we wrap around?
		BNE step4		; repeat until Y overflows back to FF

	next:
		DEC mu_ptr_hi	; decrement the page
		LDA mu_ptr_hi
		CMP mu_page_start	; compare with the first page, which can't be zero
		BCS step4		; if not there yet (mu_ptr_hi>=mu_page_start so carry set), loop again

; now, determine whether to repeat with a new test value
		LDX mu_test_idx
		DEX
		STX mu_test_idx

		BMI show_report	; we're done with all values, so show results

		JMP init		; else go to next test value
.endproc

.proc	show_report
		sta TXTSET 		; turn on text
		jsr show_banner
		puts_at 1,0, "GITHUB.COM/MISTERBLACK1/APPLEII_DEADTEST"
		puts_at 3,0, "PAGE"

		ldx #15
	next_head_line:
		txa				; go to the correct line
		clc
		adc #4			; start on this line
		tay
		lda #0
		jsr con_goto
		txa
		jsr con_put_hex
		lda #'_'|$80
		ldy #0
		sta (con_loc),Y
		lda #':'|$80
		ldy #2
		sta (con_loc),Y
		dex
		bpl next_head_line


		LDX #0
	next_page:
		txa				; calculate the column
		lsr				; get the high nybble
		lsr
		lsr
		lsr
		tay				; get the column offset from table
		lda columns,Y
		pha				; save the column number on the stack

		ldy #2			; print the heading row
		jsr con_goto
		txa
		jsr con_put_hex
		inc con_loc
		lda #'_'|$80
		ldy #0
		sta (con_loc),Y


		txa				; calculate the line number on the screen
		and #$0F		; 16 lines of results
		clc
		adc #4			; offset by starting line
		tay				; put line into Y

		pla				; retrieve column into A
		jsr con_goto	; move to that location on screen

		lda results,X	; get the value to print
		bne	hex			; see if there's an error
		lda #'-'|$80	; if not, print dashes
		ldy #0
		sta (con_loc),Y ; put two dashes there
		iny
		sta (con_loc),Y
		jmp next

	hex:				; print a hex value
		jsr con_put_hex

	next:
		INX				; look for the next page
		TXA				; compare to the last page to test
		cmp mu_page_end
		bne next_page	; continue if there are more to print

		lda all_errs
		beq good
		jsr beep_bad
		jmp done
	good:
		jsr beep_good

	done:
		LDA #10
		jsr delay_seconds
		jmp marchU

		columns: .byte 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38
.endproc


.proc	beep_bad
		ldx #$20		; cycles
		lda #$80		; period
		jsr beep
		ldx #$FF		; cycles
		lda #$FF		; period
		jsr beep
		ldx #$FF		; cycles
		lda #$FF		; period
		jsr beep
		rts
.endproc

.proc	beep_good
		ldx #$20		; cycles
		lda #$80		; period
		jsr beep
		ldx #$40		; cycles
		lda #$40		; period
		jsr beep
		ldx #$00		; cycles
		lda #$20		; period
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

