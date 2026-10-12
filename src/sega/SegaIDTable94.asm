;	Sega ID header: console name, copyright and date, game titles, serial number,
;	checksum, I/O support, ROM and RAM ranges and region codes.

	org	$00000100
;					Data No. Address	Description
	dc.b	'SEGA GENESIS    '	; 01	$100	Sega Genesis ID (16 bytes)
	dc.b	'(C)T-50 1993.JUL'	; 02	$110	company ID / release date (YYYY.MMM) (16 bytes)
	dc.b	'NHL Hockey ''94  '	; 03	$120	game title for US market (48 bytes)
	dc.b	'                '	; 		$130
	dc.b	'                '	; 		$140
	dc.b	'NHL Hockey ''94  '	; 04	$150	game title for Japanese market (48 bytes, space padded like $120)
	dc.b	'                '	; 		$160
	dc.b	'                '	; 		$170
	dc.b	'GM T-50656 -00'	; 05	$180	cartridge cat., product no., version no. (14 bytes)
	IF CHECKSUM=1 ; Security check enabled
		IF REV=0 ; RETAIL
			dc.w	$5512		; 06	$18E	check sum data (installed by checsum program) (2 bytes)
		ELSE ; REV A
			dc.w	$0000 		; 06	$18E	check sum data (installed by checsum program) (2 bytes)
		ENDIF
	ELSE ; Security check disabled
		dc.w	$0000				; 06	$18E	check sum data (installed by checsum program) (2 bytes)
	ENDIF
	dc.b	'J               '	; 07	$190	I/O peripheral info. (J=Control Pad) (16 bytes)
	dc.l	$00000000,$000FFFFF	; 08	$1A0	cartridge size (start and end address) (8 bytes). 1 MB
	dc.l	$00FF0000,$00FFFFFF	; 09	$1A8	RAM size (start and end address) (8 bytes)
	dc.b	'RA',$F8,$20		; 10	$1B0	external RAM info. (12 bytes): backup RAM, odd bytes (93: 12 spaces)
	dc.l	$00200001,$00203FFF	; 		$1B4	backup RAM start and end address
	dc.b	'            '		; 11	$1BC	modem info. (12 bytes)
	dc.b	'        '			; 12	$1C8	inhibit to use (40 bytes)
	dc.b	'                '	; 		$1D0
	dc.b	'                '	; 		$1E0
	dc.b	'UE              '	; 13	$1F0	contry code for release (16 bytes). U = USA, E = Europe (93: U)