; soft switches
KBD     	:=	$C000   ; R - Read keyboard
KBDSTRB		:=	$C010   ; R - Clear keyboard strobe

CLR80COL	:=	$C000	; W - Disable 80 column store
SET80COL	:=	$C001	; W - Enable 80 column store
RDMAINRAM	:=	$C002	; W - Read RAM on mainboard
RDCARDRAM	:=	$C003	; W - Read RAM on card
WRMAINRAM	:=	$C004	; W - Write RAM on mainboard
WRCARDRAM	:=	$C005	; W - Write RAM on card
SETINTCXROM	:=	$C007	; W - Set internal CX00 ROM
SETSTDZP	:=	$C008	; W - Set standard zero page/stack
SETALTZP	:=	$C009	; W - Set alternate zero page/stack
SETSLOTC3ROM:=	$C00B	; W - Enable C300 slot ROM
CLR80VID	:=	$C00C	; W - Disable 80 column video
SET80VID	:=	$C00D	; W - Set 80 column video
CLRALTCHAR	:=	$C00E	; W - Normal lower case, flash upper case
SETALTCHAR	:=	$C00F	; W - Normal/inverse lower case, no flash

RDLCBNK2	:=	$C011	; R - Reads language card bank 2 - >127 if LC bank 2 in use
RDLCRAM		:=	$C012	; R - Reads language card RAM enable - >127 if LC is read enabled
RDRAMRD		:=	$C013	; R - Reads RAMREAD state
RDRAMWRT	:=	$C014	; R - Reads BANKWRT state
RD80COL		:=	$C018	; R - Reads SET80COL - >127 if 80 column store enabled
RDVBLBAR	:=	$C019	; R - Reads VBL signal 
RDTEXT		:=	$C01A	; R - Reads text mode
RDPAGE2		:=	$C01C	; R - Reads page 1/2 status
ALTCHARSET	:=	$C01E	; R - Reads SETALTCHAR - >127 if alt charset switched in
RD80VID		:=	$C01F	; R - Reads SET80VID - >127 if 80 column video enabled

; Hardware
SPKR		:=	$C030	; RW - toggle the speaker

; Video mode switches
TXTCLR		:=	$C050	; RW - Display graphics
TXTSET		:=	$C051	; RW - Display text
MIXCLR		:=	$C052	; RW - Disable 4 lines of text
MIXSET		:=	$C053	; RW - Enable 4 lines of text
LOWSCR		:=	$C054	; RW - Page 1
HISCR		:=	$C055	; RW - Page 2
LORES		:=	$C056	; RW - Lores graphics
HIRES		:=	$C057	; RW - Hires graphics
DHIRESON	:=	$C05E	; RW - Enable double-width graphics
DHIRESOFF	:=	$C05F	; RW - Disable double-width graphics

; Game controller
BUTN0		:=	$C061	; RW - Open-Apple Key
BUTN1		:=	$C062	; RW - Closed-Apple Key

; IOU
IOUDISON	:=	$C07E	; RW - Disable IOU
IOUDISOFF	:=	$C07F	; RW - Enable IOU

; Language card switches
ROMIN		:=	$C081	; RW - Swap in D000-FFFF ROM
LCBANK2		:=	$C083	; RW - Swap in LC bank 2
LCBANK1		:=	$C08B	; RW - Swap in LC bank 1

