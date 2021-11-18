INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Intro", ROMX

Intro::	
	rst WaitVBlank	
	xor a
	jr @

SECTION "load splash screen", ROM0 ;this is called by the header when the screen is off
LoadBackground::
.loadTiles
	ld hl, $8800
  ld bc, BackgroundTiles
  REPT 16
  ld a, [bc]
  inc bc
  ld [hl+], a
  ENDR	

	ld hl, $9800
.load_tilemap	
	ld a, 128
	ld [hl+], a
	ld a, h
	cp a, $9C
	jr c, .load_tilemap
;.loadTilemap
;	ld hl, $9400
;	ld b, SCRN_Y_B
;.row
;	ld c, SCRN_X_B
;	call LCDMemcpySmall
;	;move to the next row
;	ld a, l
;	add SCRN_VX_B - SCRN_X_B
;	ld l, a
;	adc h
;	sub l
;	ld h, a
;	dec b
;	jr nz, .row
;	ret

SECTION "Background Tiles", ROM0
BackgroundTiles:
;	INCBIN "res/background.2bpp"
	dw `00000000
	dw `00000000
	dw `01000100
	dw `01010100
	dw `00010000
	dw `00000000
	dw `00000000
	dw `00000000	
SECTION "Background Tilemap", ROM0
BackgroundTilemap:
	INCBIN "res/background.imagemap"