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

.macpack apple2

.macro .apple2sz string
		scrcode string
		.byte 0
.endmacro

; doesn't modify A
.macro	inline_beep_xy length, period
		.local outer, inner
		LDX #length
outer:	LDY #period
inner:	DEY
		nop
		nop
		BNE inner
		STA SPKR
		DEX
		BNE outer
.endmacro

.macro 	inline_delay_xy count
	.if .blank(count)
	.else
		.repeat count
	.endif
:		DEY 
        BNE :-
        DEX 
        BNE :-
	.if .blank(count)
	.else
		.endrepeat
	.endif
.endmacro

; this macro can delay for an approximate specified number of clock cycles up to 589815
; downside is it destroys A and Y
.macro inline_delay_cycles_ay cycles
		.local n
		n = cycles/9
		lda #>n
		ldy #<n
	:	cpy #1			; 2 cycles
		dey				; 2 cycles
		sbc #0			; 2 cycles
		bcs :-			; 3 cycles
.endmacro

.macro	inline_cls
		LDA #$A0	 	; A0 is the black character on the Apple II and II plus
		LDY #$00			; clear the screen
	:	DEY
		STA $0400,Y		
		STA $0500,Y		
		STA $0600,Y		
		STA $0700,Y		
		BNE :-
.endmacro

.macro	inline_print msg, dst
		.local pnext, pexit

		LDY #$00	; code to print text to screen
pnext:	LDA msg,Y	; pointer to the string
		BEQ pexit	; end of string
		; ORA #$80	; to fix flashing text on Apple II and II+
		STA dst,Y	; video memory pointer
		INY
		BNE pnext	; next char (unless we overflowed)
pexit:	
.endmacro

.macro	zp_alloc id, size
	.pushseg
	.zeropage
	id :
	.ifblank size
		.res 1
	.else
		.res size
	.endif
	.popseg
.endmacro

.macro puts_at loc, message
		jsr con_puts_embedded
		.word loc
		scrcode message
		.byte 0
.endmacro

.macro puts_centered_at lineloc, message
		.local msg, loc, end
		jsr con_puts_embedded
		.word lineloc+((40-(end-msg))/2)
msg:	scrcode message
end:	.byte 0
.endmacro

.macro m_con_goto line, col
		lda #<(line+col)
		sta con_loc
		lda #>line
		sta con_loc+1
.endmacro