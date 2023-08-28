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

start:	LDX #15	


; step 0; up - w0 - write the test value
marchU:	LDY #$00
		LDA tst_tbl,X	; get the test value into A
		TXS				; save the index to the test value into SP
		TAX				; copy the test value into X
marchU0:STA $00,Y		; w0 - write the test value
		STA $0400,Y		; also write to the screen
		STA $0500,Y		; also write to the screen
		STA $0600,Y		; also write to the screen
		STA $0700,Y		; also write to the screen
		INY				; count up
		BNE marchU0		; repeat until Y overflows back to zero

		STY $00
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
		BPL marchU		; start again with next value
		JMP zp_good

; zp_bad; Y will equal the current pointer, A will have the bits that differ
zp_bad:
		JMP findbit

zp_good:; memtest ok put the RAM test good code here
		; Since first 4K is good, we can use Zero page now
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
		; JMP beep		; we may want to reset?

beep:	LDY #$A0
beeplp:	DEY 		; will beep the computer to say things are good
		BNE beeplp
		LDA $C030	; tick the speaker
		DEX
		BNE beep
beep2:	LDY #$A0
beep2lp:DEY 		; extend beep twice as long without adding another loop index
		BNE beep2lp
		LDA $C030	; tick the speaker
		DEX
		BNE beep2

done:	JMP done	; infinite loop


; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found
findbit:; EOR tst_tbl,X      ;Figure out which bit is bad and store that in X
        TAX 
        AND #$FE
        BNE chkbit1
        LDX #$01		 ; bit 0 is bad
        JMP flasherr        ;mem error flash

chkbit1:TXA 
        AND #$FD
        BNE chkbit2
        LDX #$02		 ; bit 1 is bad
        JMP flasherr        ;mem error flash

chkbit2:TXA 
        AND #$FB
        BNE chkbit3
        LDX #$03		 ; bit 2 is bad
        JMP flasherr        ;mem error flash

chkbit3:TXA 
        AND #$F7
        BNE chkbit4
        LDX #$04		 ; bit 3 is bad
        JMP flasherr        ;mem error flash

chkbit4:TXA 
        AND #$EF
        BNE chkbit5
        LDX #$05		 ; bit 4 is bad
        JMP flasherr        ;mem error flash

chkbit5:TXA 
        AND #$DF
        BNE chkbit6
        LDX #$06		 ; bit 5 is bad
        JMP flasherr        ;mem error flash

chkbit6:TXA 
        AND #$BF
        BNE chkbit7
        LDX #$07		 ; bit 6 is bad
        JMP flasherr        ;mem error flash

chkbit7:LDX #$08		 ; bit 7 is bad
		JMP flasherr        ;mem error flash



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
.aasc "FIRST 4K OF RAM GOOD!", 0


tst_tbl	.BYTE $00,$55,$AA,$FF,$01,$02,$04,$08     ; memtest pattern
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