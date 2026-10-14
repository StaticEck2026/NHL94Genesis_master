;	Short absolute calls. The retail code calls these routines with jsr / jmp (x).w, which
;	only reaches $0000-$7FFF. If added data pushes one past $7FFF the build reports it here with
;	the routine, its callers and the fix. Emits no bytes. See docs/EXPANDING_THE_ROM.md.

shortcall	macro
	IF \1>$7FFF
		inform	2,"SHORTCALL \1 is past $7FFF (called with .w from \2). Fix: put the new data after menu94, or change those calls to .l. See docs/EXPANDING_THE_ROM.md"
	ENDIF
	endm

	shortcall	StartGame,setup94.asm
	shortcall	restoreteams,penalty94.asm
	shortcall	ResetClock,setup94.asm
	shortcall	GetPeriodTime,collide94.asm data94.asm
	shortcall	StartPer,setup94.asm
	shortcall	DoGameFrame,penalty94.asm
	shortcall	updatecrowdf,video94.asm
	shortcall	SetupPauseScreen,penalty94.asm
	shortcall	InitMenuState,penalty94.asm
	shortcall	DrawMenuScreen,penalty94.asm
	shortcall	HandleMenuInput,video94.asm
