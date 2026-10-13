; HOCKEY.BIN crowd frame table, file $2654C, 128 bytes.
; The cartridge cd0 table (data94.asm). Loaded at $1B000 this is $4154C,
; which is the pointer updatecrowdf uses. Four bands of frame/time words.
; No extra frames past the cartridge table.

	org	$2654C

	dc.w	$010C,$020C,$030C,$040C,$050C,$0A0C,$090C,$080C
	dc.w	$060C,$070C,$080C,$090C,$0A0C,$050C,$040C,$030C
	dc.w	$0107,$0207,$0307,$0407,$0507,$0B07,$0C07,$0D07
	dc.w	$0607,$0707,$0807,$0907,$0A07,$0B07,$0C07,$0D07
	dc.w	$0E07,$0F07,$1007,$1107,$1207,$0B07,$0C07,$0D07
	dc.w	$1207,$1107,$1007,$0F07,$0E07,$0D07,$0C07,$0B07
	dc.w	$0E03,$0F03,$1003,$1103,$1203,$0B03,$0C03,$0D03
	dc.w	$1203,$1103,$1003,$0F03,$0E03,$0D03,$0C03,$0B03
