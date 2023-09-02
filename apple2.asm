.list off
.include "inc/a2constants.inc"
.include "inc/a2macros.inc"
.macpack apple2
.list on 

.org $F800				; this is designed to run in a 2K rom on the Apple II/II+

romstart:

		sei				; stop interrupts
		cld				; make sure we're not in decimal mode
		ldx #$FF
		txs				; initialize the stack pointer
		TXA				; init A to a known value


		sta TXTSET 		; turn on text
		sta CLRALTCHAR	; turn off alt charset on later apple machines
		sta CLR80VID	; turn off 80 col on //e or //c

		lda BUTN0		; read button 1 to clear the reading
		lda BUTN1		; read button 2 to clear the reading

		XYbeep $20, $C0
		clear_text_screen
		inline_print banner_msg, $0650+((40-(banner_end-banner_msg-1))/2)
		inline_print zp_msg, $06D0+((40-(zp_end-zp_msg-1))/2)


		; do the zero page test, including its own error reporting
.include "inc/marchu_zpsp.asm"
		; now we trust the zero page and stack page
		ldx #$FF
		txs				; initialize the stack pointer

		XYbeep $80, $FF
		XYbeep $80, $C0

		inline_print next_msg, $750+((40-(next_end-next_msg-1))/2)

		JSR display_delay
		; delay_cycles 500000
		; delay_cycles 500000

		sta TXTCLR		; use graphics
        sta HIRES 		; set high res
		sta MIXSET		; mixed mode on


		JSR count_ram	; count how much RAM is installed
test_ram:
		JSR marchU		; run the test on RAM
		JSR report_ram	; report the results
		JMP test_ram

.proc	display_delay
		LDA #6
loop:	PHA
		delay_cycles 500000
		PLA
		SEC
		SBC #1
		BNE loop
		RTS
.endproc

.include "inc/marchu.asm"

tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
; tst_tbl:.BYTE $FF ; while debugging, shorten the test value list
	tst_tbl_end = *
	; 	.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
	; 	.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
	; zp_tbl_end = *

banner_msg: .asciiz "DEAD TEST BY KI3V AND ADRIAN BLACK"
	banner_end = *
zp_msg: .asciiz "TESTING ZERO PAGE AND STACK AREA"
	zp_end = *
next_msg: .asciiz "ZP/STACK OK - NOW TESTING RAM"
	next_end = *
;-----------------------------------------------------------------------------
; end of the code	
	endofrom = *
.out .sprintf("    size of code: %d bytes",endofrom-romstart)

	.res ($FFFA-endofrom), $FF ; fills the unused space with $FF 

; vectors
	.org $FFFA
	.word	romstart,romstart,romstart
