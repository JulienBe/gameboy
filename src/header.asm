INCLUDE "defines.asm"

SECTION "Header", ROM0[$100]

	; This is your ROM's entry point. You have 4 bytes of code to do... something
	sub $11 										; This helps check if we're on CGB more efficiently
	jr EntryPoint

	; Make sure to allocate some space for the header, so no important code gets put there and later overwritten by RGBFIX.
	; RGBFIX is designed to operate over a zero-filled header, so make sure to put zeros regardless of the padding value. 
	; (This feature was introduced in RGBDS 0.4.0, but the -MG etc flags were also introduced in that version.)
	ds $150 - @, 0

EntryPoint:
	ldh [hConsoleType], a

Reset::
	di 																; Disable interrupts while we set up

	xor a
	ldh [rNR52], a										; Kill sound

	; Wait for VBlank and turn LCD off
.waitVBlank
	ldh a, [rLY]
	cp SCRN_Y
	jr c, .waitVBlank
	xor a															; |_$8000–$87FF Sprite 0-127_|  |_$8800–$8FFF Sprite 128-255 & BG 128-255_|  |_$9000–$97FF BG 0-127_|
	ldh [rLCDC], a 

	; Goal now: set up the minimum required to turn the LCD on again
	; A big chunk of it is to make sure the VBlank handler doesn't crash

	ld sp, wStackBottom

	ld a, BANK(OAMDMA)
	; No need to write bank number to HRAM, interrupts aren't active
	ld [rROMB0], a
	ld hl, OAMDMA
	lb bc, OAMDMA.end - OAMDMA, LOW(hOAMDMA)
.copyOAMDMA
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyOAMDMA

	call load_palettes
	call LoadBackground
	; You will also need to reset your handlers' variables below
	; I recommend reading through, understanding, and customizing this file in its entirety anyways. 
	; This whole file is the "global" game init, so it's strongly tied to your own game.
	; I don't recommend clearing large amounts of RAM, nor to init things here that can be initialized later.
		
	xor a
	ldh [hVBlankFlag], a								; Reset variables necessary for the VBlank handler to function correctly
	ldh [hOAMHigh], a										; But only those for now
	ldh [hCanSoftReset], a
	dec a
	ldh [hHeldKeys], a
		
	ld a, BANK(Intro)										; Load the correct ROM bank for later		
	ldh [hCurROMBank], a								; Important to do it before enabling interrupts
	ld [rROMB0], a
		
	ld a, IEF_VBLANK										; Select wanted interrupts here
	ldh [rIE], a												; You can also enable them later if you want
	xor a
	ei 																	; Only takes effect after the following instruction
	ldh [rIF], a 												; Clears "accumulated" interrupts
	
	xor a
	ldh [hSCY], a												; Init shadow regs
	ldh [hSCX], a
	ld a, LCDCF_ON | LCDCF_BGON
	ldh [hLCDC], a	
	ldh [rLCDC], a											; And turn the LCD on!
		
	ld hl, wShadowOAM										; Clear OAM, so it doesn't display garbage
	ld c, NB_SPRITES * 4								; This will get committed to hardware OAM after the end of the first
	xor a																; frame, but the hardware doesn't display it, so that's fine.
	rst MemsetSmall
	ld a, h ; ld a, HIGH(wShadowOAM)
	ldh [hOAMHigh], a
	
	jp Intro														; `Intro`'s bank has already been loaded earlier

SECTION "OAM DMA routine", ROMX

; OAM DMA prevents access to most memory, but never HRAM.
; This routine starts an OAM DMA transfer, then waits for it to complete.
; It gets copied to HRAM and is called there from the VBlank handler
OAMDMA:
	ldh [rDMA], a
	ld a, NB_SPRITES
.wait
	dec a
	jr nz, .wait
	ret
.end

SECTION "Global vars", HRAM

; 0 if CGB (including DMG mode and GBA), non-zero for other models
hConsoleType:: db

; Copy of the currently-loaded ROM bank, so the handlers can restore it
; Make sure to always write to it before writing to ROMB0
; (Mind that if using ROMB1, you will run into problems)
hCurROMBank:: db

SECTION "OAM DMA", HRAM

hOAMDMA::
	ds OAMDMA.end - OAMDMA

SECTION UNION "Shadow OAM", WRAM0,ALIGN[8]

wShadowOAM::
	ds NB_SPRITES * 4

SECTION "Stack", WRAM0

wStack:
	ds STACK_SIZE
wStackBottom:
