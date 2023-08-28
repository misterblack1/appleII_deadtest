		* = $F800 ; this is designed to run in a 2K rom on the Apple II/II+

		SEI
		CLD
		LDX #$FF
		TXS		; initialize the stack pointer
		
		; soft switches
		LDX $C051	; text mode
		LDX $C054	; page 2 off
		
sbeep:	DEY 		; startup beep
		BNE sbeep
		LDA $C030	; tick the speaker
		DEX
		BNE sbeep

start:	LDA #$00
        LDX #$15	
        LDY #$00
