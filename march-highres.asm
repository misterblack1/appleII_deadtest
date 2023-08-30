; modified version that does a few things
; draws the test pattern to graphics for better visualization of what's happening
; and also loops forever
; hold down shift to stop the loop (checks the joystick buttons)

#define ROM2K

#ifdef ROM2K
		* = $F800 ; this is designed to run in a 2K rom on the Apple II/II+
#else
    	* = $E000 ; for the IIe and IIc
#endif

		SEI
		CLD
		LDX #$FF
		TXS		; initialize the stack pointer
		
		; soft switches
		;LDX $C051	; text mode
		;LDX $C054	; page 2 off
		
		LDA $C050 		; turn on graphics
        LDA $C057 		; set high res
		
		LDX $C00E	; turn off alt charset on later apple machines
		LDX $C00C	; turn off 80 col

		LDX $C061 ; read button 1 to clear the reading
		LDX $C062 ; read button 2
		LDX $C063 ; read button 3

sbeep:	DEY 		; startup beep
		BNE sbeep
		LDA $C030	; tick the speaker
		DEX
		BNE sbeep

start:	LDX #15	


; step 0; up - w0 - write the test value
marchU:	LDY #$00
		LDA tst_tbl,X	; get the test value into A
		TXS				; save the index to the test value into SP
		TAX				; copy the test value into X
marchU0:STA $00,Y		; w0 - write the test value
		STA $2000,Y		; also write to the screen
		STA $2100,Y		; also write to the screen
		STA $2200,Y		; also write to the screen
		STA $2300,Y		; also write to the screen
		STA $2400,Y		; also write to the screen
		STA $2500,Y		; also write to the screen
		STA $2600,Y		; also write to the screen
		STA $2700,Y		; also write to the screen
		STA $2800,Y		; also write to the screen
		STA $2900,Y		; also write to the screen
		STA $2A00,Y		; also write to the screen
		STA $2B00,Y		; also write to the screen
		STA $2C00,Y		; also write to the screen
		STA $2D00,Y		; also write to the screen
		STA $2E00,Y		; also write to the screen
		STA $2F00,Y		; also write to the screen

		STA $3000,Y		; also write to the screen
		STA $3100,Y		; also write to the screen
		STA $3200,Y		; also write to the screen
		STA $3300,Y		; also write to the screen
		STA $3400,Y		; also write to the screen
		STA $3500,Y		; also write to the screen
		STA $3600,Y		; also write to the screen
		STA $3700,Y		; also write to the screen
		STA $3800,Y		; also write to the screen
		STA $3900,Y		; also write to the screen
		STA $3A00,Y		; also write to the screen
		STA $3B00,Y		; also write to the screen
		STA $3C00,Y		; also write to the screen
		STA $3D00,Y		; also write to the screen
		STA $3E00,Y		; also write to the screen
		STA $3F00,Y		; also write to the screen

		INY				; count up
		BNE marchU0		; repeat until Y overflows back to zero

		; STY $00			; intentionally create an error for testing
; step 1; up - r0,w1,r1,w0
; A contains test value
marchU1:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		EOR $00,Y		; r1 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $00,Y		; w0 - write the test value to the memory location
		INY				; count up
		BNE marchU1		; repeat until Y overflows back to zero

; step 2; up - r0,w1
; A contains test value from prev step
marchU2:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		EOR #$FF		; invert
		INY				; count up
		BNE marchU2		; repeat until Y overflows back to zero

; step 3; down - r1,w0,r0,w1
; A contains the inverted test value from prev step
		EOR #$FF		; invert
		DEY				; decrement Y from 0 to FF
marchU3:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		EOR $00,Y		; r0 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		DEY				; count down
		BPL marchU3		; repeat until Y overflows back to FF

; step 4; down - r1,w0
; A contains the inverted test value from prev step
marchU4:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		DEY				; count down
		BPL marchU4		; repeat until Y overflows back to FF

		TSX				; recover the test value index from SP
		DEX				; choose the next one
		BPL marchup		; start again with next value
		JMP zp_good

marchup:
		JMP marchU

; zp_bad; Y will equal the current pointer, A will have the bits that differ
zp_bad:
		JMP findbit

zp_good:; memtest ok put the RAM test good code here
		; Since first 4K is good, we can use Zero page now
		; we then use $00,$01 as pointer for video memory 
		LDX $C051	; text mode
		LDX $C054	; page 2 off

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
		; JMP beep		; we may want to reset?

beep:	LDY #$80
beeplp:	DEY 		; will beep the computer to say things are good
		BNE beeplp
		LDA $C030	; tick the speaker
		DEX
		BNE beep

		LDA $C050 		; turn on graphics
        LDA $C057 		; set high res

done:	
		LDA $C061 ; read button0
		AND #$80  ; high bit set if pushed
		BNE finished
		LDA $C062 ; read button1
		AND #$80
		BNE finished
		LDA $C063 ; read button2
		AND #$80
		BNE finished
		JMP start ; run it all again
		
finished:
		LDX $C051	; text mode
		LDX $C054	; page 2 off
		JMP finished	; infinite loop


; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found

findbit:LDX #8			; start at high bit
		CLC				; clear carry
chkbit:	ROL				; move tested bit into carry
		BCS flasherr		; bit set, display it
		DEX				; count down
		BNE chkbit		; test next bit
wha:	JMP wha			; should not get here?




flasherr:				; time to flash the screen
						; put the error handling code here
		TXS  			; X is holding the bad bit, save it in the SP
		LDA $C050 		; turn on graphics
f_loop:	LDA $C057 		; set high res
		LDA $C030 		; tick the speaker
		LDA $C030		; tick the speaker again as on real hardware you need this twice
		TXA

        LDX #$7F
        LDY #$00
f_sp1:	DEY 
        BNE f_sp1
        DEX 
        BNE f_sp1

        TAX				; save A in X
		LDA $C056 		; set low res
		LDA $C030 		; tick the speaker
		TXA				; restore A

		LDX #$7F
        LDY #$00
f_sp2:	DEY 			; wait a bit
        BNE f_sp2
        DEX 
        BNE f_sp2
f_sp3:	DEY 			; wait a bit again
        BNE f_sp3
        DEX 
        BNE f_sp3

        TAX 
        DEX 
        BEQ f_lp
        JMP f_loop

f_lp:	LDX #$00		; a long pause between flashes
        LDY #$00
f_lp1:	DEY 
        BNE f_lp1
        DEX 
        BNE f_lp1
f_lp2:	DEY 
        BNE f_lp2
        DEX 
        BNE f_lp2
f_lp3:	DEY 
        BNE f_lp3
        DEX 
        BNE f_lp3
f_lp4:	DEY 
        BNE f_lp4
        DEX 
        BNE f_lp4
        TSX 		; stack pointer is holding bad bit
        JMP f_loop	; flash all over again

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



ramok:
.aasc "ZERO PAGE SEEMS GOOD", 0

tst_tbl	.BYTE $EE,$77,$80,$40, $20,$10,$08,$04, $02,$01,$A5,$5A, $AA,$55,$FF,$00 ; memtest patterns to cycle through

; tst_tbl	.BYTE $00,$55,$AA,$FF,$01,$02,$04,$08     ; memtest pattern
;         .BYTE $10,$20,$40,$80,$FE,$FD,$FB,$F7     ; it cycles through all these bytes
;         .BYTE $EF,$DF,$BF,$7F                     ; during the test

; end of the code	
endofrom
; fills the unused space with $FF 
        * = $FFFA
.dsb (*-endofrom), $FF

; vectors
	* = $FFFA

#ifdef ROM2K
.db $00,$F8,$00,$F8,$00,$F8 ; for the II and II+
#else
.db $00,$E0,$00,$E0,$00,$E0 ; for the //e and //c
#endif