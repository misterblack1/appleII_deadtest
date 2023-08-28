; This code is mostly ported from the C64 dead test ROM
; Some additional code written by Frank IZ8DWF and Adrian Black
; This tests the first 4K of RAM and does NOT rely on any working memory
; If anything is wrong, it will flash the bit that is bad. 
; 1 flash = bit 0 bad
; ...
; 8 flash = bit 7 bad
; The speaker will also tick the number of times the bit is bad. 
; And the screen will go from high res to low res

		* = $F800 ; this is designed to run in a 2K rom on the Apple II/II+

		SEI
		CLD
		LDX #$FF
		TXS		; initialize the stack pointer
		
		; soft switches
		LDX $C051	; text mode
		LDX $C054	; page 2 off
		
sbeep:		DEY 		; startup beep
		BNE sbeep
		LDA $C030	; tick the speaker
		DEX
		BNE sbeep

start   	LDA #$00
        	LDX #$15
        	LDY #$00

zp_wr   LDA tst_tbl,X      ;fills up the first 4K with the byte from the memtest pattern
        STA $0000,Y
        STA $0100,Y
        STA $0200,Y
        STA $0300,Y
        STA $0400,Y
        STA $0500,Y
        STA $0600,Y
        STA $0700,Y
        STA $0800,Y
        STA $0900,Y
        STA $0A00,Y
        STA $0B00,Y
        STA $0C00,Y
        STA $0D00,Y
        STA $0E00,Y
        STA $0F00,Y
        INY 
        BNE zp_wr
        TXA 
        LDX #$00
        LDY #$00

zpw_p   DEY 			; wait a bit
        BNE zpw_p
        DEX 
        BNE zpw_p
        TAX 
		
zp_rd   LDA $0000,Y		 ; now checkign to see if the contents of RAM is still good
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
	LDA $0100,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0200,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0300,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0400,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0500,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0600,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0700,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0800,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0900,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0A00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0B00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0C00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0D00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0E00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        LDA $0F00,Y
        CMP tst_tbl,X      ;memtest pattern
        BNE biterr
        INY 
        BEQ IE24F
        JMP zp_rd

biterr	JMP findbit		; there's a problem

IE24F   DEX 
        BMI IE010
        LDY #$00
        JMP zp_wr

IE010   	;memtest ok put the RAM test good code here
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
npcl:		LDA #$A0 	; A0 is the black character on the Apple II and II plus
cls:		STA ($00),Y
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

findbit	EOR tst_tbl,X      ;Figure out which bit is bad and store that in X
        TAX 
        AND #$FE
        BNE chkbit1
        LDX #$01		 ; bit 0 is bad
        JMP flasherr        ;mem error flash

chkbit1	TXA 
        AND #$FD
        BNE chkbit2
        LDX #$02		 ; bit 1 is bad
        JMP flasherr        ;mem error flash

chkbit2	TXA 
        AND #$FB
        BNE chkbit3
        LDX #$03		 ; bit 2 is bad
        JMP flasherr        ;mem error flash

chkbit3	TXA 
        AND #$F7
        BNE chkbit4
        LDX #$04		 ; bit 3 is bad
        JMP flasherr        ;mem error flash

chkbit4	TXA 
        AND #$EF
        BNE chkbit5
        LDX #$05		 ; bit 4 is bad
        JMP flasherr        ;mem error flash

chkbit5	TXA 
        AND #$DF
        BNE chkbit6
        LDX #$06		 ; bit 5 is bad
        JMP flasherr        ;mem error flash

chkbit6	TXA 
        AND #$BF
        BNE chkbit7
        LDX #$07		 ; bit 6 is bad
        JMP flasherr        ;mem error flash

chkbit7		LDX #$08		 ; bit 7 is bad
		JMP flasherr        ;mem error flash



flasherr				; time to flash the screen
					; put the error handling code here
		TXS  			; X is holding the bad bit, save it in the SP
		LDA $C050 		; turn on graphics
f_loop		LDA $C057 		; set high res
		LDA $C030 		; tick the speaker
		TXA

        LDX #$7F
        LDY #$00
f_sp1	DEY 
        BNE f_sp1
        DEX 
        BNE f_sp1

        TAX			; save A in X
	LDA $C056 		; set low res
	LDA $C030 		; tick the speaker
	TXA			; restore A

	LDX #$7F
        LDY #$00
f_sp2	DEY 			; wait a bit
        BNE f_sp2
        DEX 
        BNE f_sp2
f_sp3	DEY 			; wait a bit again
        BNE f_sp3
        DEX 
        BNE f_sp3

        TAX 
        DEX 
        BEQ f_lp
        JMP f_loop

f_lp	LDX #$00		; a long pause between flashes
        LDY #$00
f_lp1   DEY 
        BNE f_lp1
        DEX 
        BNE f_lp1
f_lp2	DEY 
        BNE f_lp2
        DEX 
        BNE f_lp2
f_lp3   DEY 
        BNE f_lp3
        DEX 
        BNE f_lp3
f_lp4   DEY 
        BNE f_lp4
        DEX 
        BNE f_lp4
        TSX 		; stack pointer is holding bad bit
        JMP f_loop	; flash all over again

print:		LDY #$00	; code to print text to screen
pnext:		LDA ($10),Y	; pointer to the string
		BEQ pexit	; end of string
		ORA #$80	; to fix flashing text on Apple II and II+
		STA ($00),Y	; video memory pointer
		INC $00
		CPY $00
		BNE skipv
		INC $01
skipv:		INC $10
		CPY $10
		BNE pnext
		INC $11
		JMP pnext
pexit:		RTS

beep:		LDY #$A0
beeplp:		DEY 		; will beep the computer to say things are good
		BNE beeplp
		LDA $C030	; tick the speaker
		DEX
		BNE beep
beep2:		LDY #$A0
beep2lp:	DEY 		; extend beep twice as long without adding another loop index
		BNE beep2lp
		LDA $C030	; tick the speaker
		DEX
		BNE beep2

done:		JMP done	; infinite loop

ramok:
.aasc "FIRST 4K OF RAM GOOD!", 0

tst_tbl .BYTE $00,$55,$AA,$FF,$01,$02,$04,$08     ; memtest pattern
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
