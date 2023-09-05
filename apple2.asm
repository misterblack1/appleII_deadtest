.list off
.feature org_per_seg
.feature leading_dot_in_identifiers
.include "inc/a2constants.inc"
.include "inc/a2macros.inc"
.list on 
.debuginfo

.zeropage
.org $0
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

		inline_beep_xy $20, $C0
		inline_cls
		; inline_print banner_msg, TXTLINE20+((40-(banner_end-banner_msg-1))/2)


		; do the zero page test, including its own error reporting
.include "inc/marchu_zpsp.asm"
		; now we trust the zero page and stack page
		ldx #$FF
		txs				; initialize the stack pointer
		JSR count_ram	; count how much RAM is installed

		jsr show_banner
		puts_centered_at TXTLINE24, "ZERO/STACK PAGES OK"

		ldx #$40		; cycles
		lda #$80		; period
		jsr beep
		ldx #$80		; cycles
		lda #$40		; period
		jsr beep

		LDA #4
		JSR delay_seconds

		jsr init_results
test_ram:
		JSR marchU		; run the test on RAM
		; JSR report_ram	; report the results
		JMP test_ram

.proc	show_banner
		jsr con_cls
		puts_centered_at TXTLINE21, "APPLE DEAD TEST BY KI3V AND ADRIAN BLACK"
		puts_centered_at TXTLINE22, "TESTING RAM FROM $0200 TO $XXFF"
		m_con_goto TXTLINE22, 31
		LDA mu_page_end
		SEC
		SBC #1
		jsr con_put_hex
		rts
.endproc

.proc	delay_seconds
		asl				; double the number, since we actually count in half-seconds
loop:	PHA
		inline_delay_cycles_ay 500000
		PLA
		SEC
		SBC #1
		BNE loop
		RTS
.endproc


.include "inc/marchu.asm"
.include "inc/a2console.asm"

tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
; tst_tbl:.BYTE $80 ; while debugging, shorten the test value list
tst_tbl_end = *

; banner_msg: 
; 		.asciiz "APPLE DEAD TEST BY KI3V AND ADRIAN BLACK"
; banner_end = *

hex_tbl:.apple2sz "0123456789ABCDEF"

zp_msg:
		.apple2sz "TEST ZERO PAGE"
zp_end = *
pt_msg:
		.apple2sz "TEST PAGE ERRORS"
pt_end:
pe_msg:
		.apple2sz "PAGE ERRORS FOUND"
pe_end:
; re_msg: .apple2sz "RAM ERROR: XX AT XXXX"
; re_end:


; next_msg:
; 		.asciiz "ZERO/STACK PAGES OK - RUNNING RAM TEST"
; next_end = *
;-----------------------------------------------------------------------------
; end of the code	
	endofrom = *
.out .sprintf("    size of code: %d bytes",endofrom-romstart)

	.res ($FFFA-endofrom), $FF ; fills the unused space with $FF 

; vectors
	; .org $FFFA
.segment "VECTORS"
	.word	romstart,romstart,romstart
