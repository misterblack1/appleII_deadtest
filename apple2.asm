.list off
.include "inc/a2constants.inc"
.include "inc/a2macros.inc"
.macpack apple2
.list on 
.debuginfo
.feature org_per_seg
; .export __ZPSTART__ : absolute = $20

.zeropage
.org $20
.code

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
		inline_print banner_msg, TXTLINE20+((40-(banner_end-banner_msg-1))/2)
		inline_print zp_msg, TXTLINE21+((40-(zp_end-zp_msg-1))/2)


		; do the zero page test, including its own error reporting
.include "inc/marchu_zpsp.asm"
		; now we trust the zero page and stack page
		ldx #$FF
		txs				; initialize the stack pointer

		XYbeep $80, $FF
		XYbeep $80, $C0

		inline_print next_msg, TXTLINE21+((40-(next_end-next_msg-1))/2)

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
		LDA #4
loop:	PHA
		delay_cycles 500000
		PLA
		SEC
		SBC #1
		BNE loop
		RTS
.endproc

; ; print a string that's embedded immediately after the JSR
; ; screen location is in A register
; .proc	print_embedded
; 		xsave = $25
; 		ysave = $26
; 		asave = $27
; 		str = $28
; 		strhi = $29
; 		loc = $30
; 		lochi = $31

; 		stx xsave
; 		sty ysave
; 		sta asave

; 		pla				; fetch address of string (minus one)
; 		sta str
; 		pla
; 		sta strhi

; 		ldy	#$00		; index will remain 0
; 	next_char:
; 		inc	str			; increment pointer
; 		bne nocarry
; 		inc strhi
; 	nocarry:
; 		lda (str),y		; get character
; 		beq end

; 	end:
; .endproc

.include "inc/marchu.asm"

; tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
tst_tbl:.BYTE $5A ; while debugging, shorten the test value list
	tst_tbl_end = *
	; 	.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
	; 	.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
	; zp_tbl_end = *

banner_msg: 
		.asciiz "APPLE DEAD TEST BY KI3V AND ADRIAN BLACK"
banner_end = *

zp_msg:
		.asciiz "TESTING ZERO/STACK PAGES"
zp_end = *

next_msg:
		.asciiz "ZERO/STACK PAGES OK - RUNNING RAM TEST"
next_end = *
;-----------------------------------------------------------------------------
; end of the code	
	endofrom = *
.out .sprintf("    size of code: %d bytes",endofrom-romstart)

	.res ($FFFA-endofrom), $FF ; fills the unused space with $FF 

; vectors
	.org $FFFA
	.word	romstart,romstart,romstart
