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

		; do the zero page test, including its own error reporting
.include "inc/marchu_zpsp.asm"
		; now we trust the zero page and stack page
		ldx #$FF
		txs				; initialize the stack pointer
		JSR count_ram	; count how much RAM is installed

		jsr show_banner
		puts_centered_at 24, "ZERO/STACK PAGES OK"
		jsr show_charset

		ldx #$40		; cycles
		lda #$80		; period
		jsr beep
		ldx #$80		; cycles
		lda #$40		; period
		jsr beep

		LDA #8
		JSR delay_seconds

		jsr init_results
test_ram:
		JSR marchU		; run the test on RAM and report
		JMP test_ram


.define charset_line_size 32
.macro	m_show_charset_lines
.repeat 256/charset_line_size, line
	m_con_goto line+5,(40-charset_line_size)/2-charset_line_size*line
	jsr show_charset_line
.endrepeat
.endmacro

.proc	show_charset
		puts_centered_at 1, "CHARACTER SET"
		ldy #0
		m_show_charset_lines
		rts
.endproc

; on entry:
; Y = first character segment to display
; con_loc = where to print, minus Y
.proc	show_charset_line
		ldx #charset_line_size
	:	tya				; get the character to print
		sta (con_loc),Y	; write it to the screen
		iny
		dex
		bne :-
		rts
.endproc

.proc	show_banner
		jsr con_cls
		puts_centered_at 22, "APPLE DEAD TEST BY KI3V AND ADRIAN BLACK"
		puts_centered_at 23, "TESTING RAM FROM $0200 TO $XXFF"
		m_con_goto 23, 31
		LDA mu_page_end
		SEC
		SBC #1
		jsr con_put_hex
		rts
.endproc

.proc	delay_seconds
		sta KBDSTRB
		asl				; double the number, since we actually count in half-seconds
loop:	PHA
		; inline_delay_cycles_ay 500000
		inline_delay_with_cancel 500000
		PLA
		SEC
		SBC #1
		BNE loop
		RTS
.endproc


.include "inc/marchu.asm"
.include "inc/a2console.asm"

; tst_tbl:.BYTE $80,$40,$20,$10, $08,$04,$02,$01, $00,$FF,$A5,$5A 
tst_tbl:.BYTE $80 ; while debugging, shorten the test value list
tst_tbl_end = *

; banner_msg: 
; 		.asciiz "APPLE DEAD TEST BY KI3V AND ADRIAN BLACK"
; banner_end = *

hex_tbl:.apple2sz "0123456789ABCDEF"

zp_msg: .apple2sz "TEST ZERO PAGE"
zp_end = *
pe_msg: .apple2sz "PAGE ERRORS FOUND"
pe_end:


;-----------------------------------------------------------------------------
; end of the code	
	endofrom = *
.out .sprintf("    size of code: %d bytes",endofrom-romstart)
	.res ($FFFA-endofrom), $FF ; fills the unused space with $FF 

; vectors
	; .org $FFFA
.segment "VECTORS"
	.word	romstart,romstart,romstart
