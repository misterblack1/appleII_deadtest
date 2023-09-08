; Runs on Apple II at $F800 
; Rev 0.2a
; uses no Page Zero pointers
; IZ8DWF 2023
; edited to assemble with ca65 by KI3V

; VIDEO RAM is mapped from $0400 to $07FF

.org $F800

reset:	SEI
		CLD
		LDX #$FF
		TXS		; initialize the stack pointer
	
		; soft switches
		LDX $C051	; text mode
		LDX $C054	; page 2 off

		LDA #$A0
		; fills the entire screen
		LDX #$00
scf:	STA $0400,X
		STA $0500,X
		STA $0600,X
		STA $0700,X
		TAY
		STY $0,X
		LDA $0,X
		INX
		STA $0400,X
		STA $0500,X
		STA $0600,X
		STA $0700,X
		TYA
		INX
		BNE scf
		CLC
		ADC #$1		; change character
		LDY $C030	; tick the speaker
		LDY #$0
wait:	INX
		BNE wait
		DEY
		BNE wait
		JMP scf
endofrom:
; fills the unused space with $FF 
.res ($FFFA-endofrom), $FF ; fills the unused space with $FF 
.segment "VECTORS"
.byte $00,$F8,$00,$F8,$00,$F8

