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
:		DEY 			; 512X cycles
        BNE :-			; 513X cycles
        DEX 			; 2X cycles
        BNE :-			; 2X+1 cycles - total = 1029X + 1 cycles (when Y = $FF)
	.if .blank(count)
	.else
		.endrepeat
	.endif
.endmacro


; this macro can delay for an approximate specified number of clock cycles up to 589815
; downside is it destroys A and X
.macro inline_delay_cycles_ax cycles
		.local n
		n = cycles/9
		lda #>n			; 2 cycles (outside loop)
		ldx #<n			; 2 cycles (outside loop)
	:	cpx #1			; 2 cycles
		dex				; 2 cycles
		sbc #0			; 2 cycles
		bcs :-			; 3 cycles (+1 outside loop at end)
.endmacro

; this macro can delay for an approximate specified number of clock cycles up to 589815
; downside is it destroys A and Y
.macro inline_delay_cycles_ay cycles
		.local n
		n = cycles/9
		lda #>n			; 2 cycles (outside loop)
		ldy #<n			; 2 cycles (outside loop)
	:	cpy #1			; 2 cycles
		dey				; 2 cycles
		sbc #0			; 2 cycles
		bcs :-			; 3 cycles (+1 outside loop at end)
.endmacro

; this macro can delay for an approximate specified number of clock cycles up to 983,040
; downside is it destroys A and Y
.macro inline_delay_with_pause cycles, onkey
		.local n, done
		n = cycles/15
		lda #>n
		ldy #<n
	:	bit KBD			; 4 cycles
		.if .not .blank({onkey})
		bmi onkey		; 2 cycles
		.else
		bmi done
		.endif
		cpy #1			; 2 cycles
		dey				; 2 cycles
		sbc #0			; 2 cycles
		bcs :-			; 3 cycles
		; jmp done
	; kbhit:
	; :	lda KBD			; wait until key has been let up
	; 	and #$7F  
	; 	bne :-
	; 	.if .not .blank({onkey})
	; 	jmp onkey
	; 	.endif
	done:
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

; line is one-based, col is zero-based... sorry
.macro puts_at line, col, message
		.local loc
		loc = .ident(.concat("TXTLINE",.string(line)))+col
		jsr con_puts_embedded
		.word loc
		scrcode message
		.byte 0
.endmacro

.macro puts_centered_at line, message
		puts_at line, (40-.strlen(message))/2, message

; 		.local msg, loc, end
; 		jsr con_puts_embedded
; 		.word lineloc+((40-(end-msg))/2)
; msg:	scrcode message
; end:	.byte 0
.endmacro

.macro m_con_goto line, col
		.local loc
		loc = .ident(.concat("TXTLINE",.string(line))) + col
		lda #<(loc)
		sta con_loc
		lda #>(loc)
		sta con_loc+1
		; lda #<(line+col)
		; sta con_loc
		; lda #>(line+col)
		; sta con_loc+1
.endmacro

.macro m_erase_line line
		m_con_goto line, 0
		lda #' '|$80
		ldy #39
	:	sta (con_loc),Y
		dey
		bpl :-
.endmacro