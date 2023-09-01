.macro	XYbeep length, period
		.local outer, inner
		LDX #length
outer:	LDY #period
inner:	DEY
		BNE inner
		STY SPKR
		DEX
		BNE outer
.endmacro

.macro 	XYdelay count
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

.macro	clear_text_screen
		LDA #$A0	 	; A0 is the black character on the Apple II and II plus
		LDY $FF			; clear the screen
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
		ORA #$80	; to fix flashing text on Apple II and II+
		STA dst,Y	; video memory pointer
		INY
		JMP pnext
pexit:	
.endmacro