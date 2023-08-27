; This code is mostly ported from the C64 dead test ROM
; Some additional code written by Frank IZ8DWF and Adrian Black
; This tests the first 4K of RAM and does NOT rely on any working memory
; If anything is wrong, it will flash the bit that is bad. 
; 1 flash = bit 0 bad
; ...
; 8 flash = bit 7 bad
; The speaker will also tick the number of times the bit is bad. 
; And the screen will go from high res to low res

F0000 = $0000 ; this stuff is leftover from the dead test disassembly
F0100 = $0100 ; this values are the pages used to for the initial phase
F0200 = $0200
F0300 = $0300
F0400 = $0400
F0500 = $0500
F0600 = $0600
F0700 = $0700
F0800 = $0800
F0900 = $0900
F0A00 = $0A00
F0B00 = $0B00
F0C00 = $0C00
F0D00 = $0D00
F0E00 = $0E00
F0F00 = $0F00

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

start   LDA #$00
        LDX #$15
        LDY #$00

IE18F   LDA FE7F7,X      ;fills up the first 4K with the byte from the memtest pattern
        STA F0000,Y
        STA F0100,Y
        STA F0200,Y
        STA F0300,Y
        STA F0400,Y
        STA F0500,Y
        STA F0600,Y
        STA F0700,Y
        STA F0800,Y
        STA F0900,Y
        STA F0A00,Y
        STA F0B00,Y
        STA F0C00,Y
        STA F0D00,Y
        STA F0E00,Y
        STA F0F00,Y
        INY 
        BNE IE18F
        TXA 
        LDX #$00
        LDY #$00

IE1C7   DEY 			; wait a bit
        BNE IE1C7
        DEX 
        BNE IE1C7
        TAX 
		
IE1CE   LDA F0000,Y		 ; now checkign to see if the contents of RAM is still good
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
		LDA F0100,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0200,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0300,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0400,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0500,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0600,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0700,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0800,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0900,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0A00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0B00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0C00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0D00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0E00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        LDA F0F00,Y
        CMP FE7F7,X      ;memtest pattern
        BNE IE24C
        INY 
        BEQ IE24F
        JMP IE1CE

IE24C   JMP IE25A		; there's a problem

IE24F   DEX 
        BMI IE010
        LDY #$00
        JMP IE18F

IE010   ;memtest ok put the RAM test good code here
		; Since first 4K is good, we can use Zerp page now
		; we then use $00,$01 as pointer for video memory 
		LDA #$00
		STA $00
		LDA #$04	
		STA $01
		LDA #$08	; end of video memory (page)
		STA $02
					; clears the entire screen
		LDY #$00
npcl:	LDA #$A0 	; A0 is the black character on the Apple II and II plus
cls:	STA ($00),Y
		INY
		BNE cls
		INC $01
		LDA $02
		CMP $01
		BNE npcl

;prints the ramgood string
		LDA #$00
		STA $00
		LDA #$04	
		STA $01
		LDA #<ramok
		STA $10		; pointer to source string 
		LDA #>ramok
		STA $11
		JSR print
		JMP beep		; we may want to reset?

		; and we're done

IE25A   EOR FE7F7,X      ;Figure out which bit is bad and store that in X
        TAX 
        AND #$FE
        BNE IE267
        LDX #$01		 ; bit 0 is bad
        JMP IE2A5        ;mem error flash

IE267   TXA 
        AND #$FD
        BNE IE271
        LDX #$02		 ; bit 1 is bad
        JMP IE2A5        ;mem error flash

IE271   TXA 
        AND #$FB
        BNE IE27B
        LDX #$03		 ; bit 2 is bad
        JMP IE2A5        ;mem error flash

IE27B   TXA 
        AND #$F7
        BNE IE285
        LDX #$04		 ; bit 3 is bad
        JMP IE2A5        ;mem error flash

IE285   TXA 
        AND #$EF
        BNE IE28F
        LDX #$05		 ; bit 4 is bad
        JMP IE2A5        ;mem error flash

IE28F   TXA 
        AND #$DF
        BNE IE299
        LDX #$06		 ; bit 5 is bad
        JMP IE2A5        ;mem error flash

IE299   TXA 
        AND #$BF
        BNE IE2A3
        LDX #$07		 ; bit 6 is bad
        JMP IE2A5        ;mem error flash

IE2A3   LDX #$08		 ; bit 7 is bad
		JMP IE2A5        ;mem error flash
		
IE2A5        			; time to flash the screen
						; put the error handling code here
		TXS  			; X is holding the bad bit
		LDA $C050 		; turn on graphics
IE2A6   LDA $C057 		; set high res
		LDA $C030 		; tick the speaker
		TXA
        LDX #$7F
        LDY #$00
IE2B3   DEY 
        BNE IE2B3
        DEX 
        BNE IE2B3
        TAX
		LDA $C056 		; set low res
		TXA
		LDX #$7F
        LDY #$00
IE2C7   DEY 			; wait a bit
        BNE IE2C7
        DEX 
        BNE IE2C7

IE2CD   DEY 			
        BNE IE2CD
        DEX 
        BNE IE2CD
        TAX 
        DEX 
        BEQ IE2DA
        JMP IE2A6

IE2DA   LDX #$00		; a long pause between flashes
        LDY #$00
IE2DE   DEY 
        BNE IE2DE
        DEX 
        BNE IE2DE
IE2E4   DEY 
        BNE IE2E4
        DEX 
        BNE IE2E4
IE2EA   DEY 
        BNE IE2EA
        DEX 
        BNE IE2EA
IE2F0   DEY 
        BNE IE2F0
        DEX 
        BNE IE2F0
        TSX 		; stack pointer is holding bad bit
        JMP IE2A6	; flash all over again

print:	LDY #$00	; code to print text to screen
pnext:	LDA ($10),Y	; pointer to the string
		BEQ pexit	; end of string
		ORA #$80	; to fix flashing text on Apple II and II+
		STA ($00),Y	; video memory pointer
		INC $00
		CPY $00
		BNE skipv
		INC $01
skipv:	INC $10
		CPY $10
		BNE pnext
		INC $11
		JMP pnext
pexit:	RTS

beep:	DEY 		; will beep the computer forever to say things are good
		BNE beep
		LDA $C030	; tick the speaker
		DEX
		BNE beep

done:	JMP done	; infinite loop

ramok:
.aasc "FIRST 4K OF RAM GOOD!", 0

FE7F7   .BYTE $00,$55,$AA,$FF,$01,$02,$04,$08     ; memtest pattern
        .BYTE $10,$20,$40,$80,$FE,$FD,$FB,$F7     ; it cycles through all these bytes
        .BYTE $EF,$DF,$BF,$7F                     ; during the test

; end of the code	
endofrom
; fills the unused space with $FF 
        * = $FFFA
.dsb (*-endofrom), $FF

; vectors
	* = $FFFA

.db $00,$F8,$00,$F8,$00,$F8