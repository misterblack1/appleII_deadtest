.zeropage
	con_loc:	.res 2
	con_str:	.res 2
	con_xsave:	.res 1
	con_ysave:	.res 1
	con_asave:	.res 1
.code


.proc con_goto
		rts
.endproc

.proc con_put
		rts
.endproc



; ; setup: con_loc is destination location, con_str is the string to write
; .proc	_con_put_sz
; 	put:
; 		lda (con_str),Y	; fetch char
; 		beq end			; finish on zero byte
; 		sta (con_loc),Y	; emit the string
; 		inc con_loc		; increment location
; 		bne nextchar
; 		inc con_loc+1
; 	nextchar:
; 		inc	con_str		; increment pointer
; 		bne put			; skip if no carry
; 		inc con_str+1	; now con_str points to start of the string
; 		jmp put
; 	end:
; 		rts
; .endproc

; print a string with args immediately embedded after the calling function
; first screen location, then the string itself, zero-terminated
.proc	con_puts_embedded
		stx con_xsave
		sty con_ysave
		sta con_asave

		pla				; fetch address of argument (minus one)
		sta con_str
		pla
		sta con_str+1

		ldy	#$00

		inc	con_str		; increment pointer
		bne :+			; skip if no carry
		inc con_str+1	; now con_str points to the screen location lo byte
	:	lda (con_str),Y	; fetch lo byte
		sta con_loc		; store new screen location
		inc	con_str		; increment pointer
		bne :+			; skip if no carry
		inc con_str+1	; now con_str points to the screen location hi byte
	:	lda (con_str),Y	; fetch hi byte
		sta con_loc+1

		; jsr _con_put_sz::nextchar
	nextchar:
		inc	con_str		; increment pointer
		bne :+			; skip if no carry
		inc con_str+1	; now con_str points to start of the string
	:	lda (con_str),Y	; fetch char
		beq end			; finish on zero byte
		sta (con_loc),Y	; emit the string
		inc con_loc		; increment location
		bne :+
		inc con_loc+1
	:	clc
		bcc nextchar	; branch (always) to next char

	end:
		lda con_str+1	; fix up the stack for return
		pha
		lda con_str
		pha
		lda con_asave	; restore regs
		lda con_ysave
		lda con_xsave
		rts
.endproc

; print value in A to current screen location
.proc	con_put_hex
		sta con_asave		; save the value for reuse

		LSR					; shift the high nybble into the low
		LSR
		LSR
		LSR
		TAY					; use it as an index
		LDA hex_tbl,Y		; into the hex table
		LDY #0
		STA (con_loc),Y		; store the low nybble

		lda con_asave		; get another copy
		AND #$0F			; get low nybble
		TAY					; use it as an index
		LDA hex_tbl,Y		; into the hex table
		LDY #1
		STA (con_loc),Y		; store the low nybble
		RTS
.endproc

.proc con_cls
		inline_cls
		rts
.endproc