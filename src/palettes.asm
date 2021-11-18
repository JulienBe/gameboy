INCLUDE "include/hardware.inc/hardware.inc"
; =========
; | MACRO |
; =========
dcolor: MACRO  ; $rrggbb -> gbc representation
_r = ((\1) & $ff0000) >> 16 >> 3
_g = ((\1) & $00ff00) >> 8  >> 3
_b = ((\1) & $0000ff) >> 0  >> 3
  dw (_r << 0) | (_g << 5) | (_b << 10)
  ENDM

SECTION "Palettes", ROM0
load_palettes::
  ; ======================
	; | BACKGROUND PALETTE |
	; ======================
	ld a, %10000000                 ; write to palette 0. high bit to 1 to automatically increase where I will write 
	; when auto-increment is set, writing to rBCPD auto-increments to the next byte, and then the next palette (every 8 bytes)
	ldh [rBCPS], a                  ; Background Color Palette Specification
	ld hl, PALETTE_BG0
	REPT 8
	ld a, [hl+]
	ld [rBCPD], a                   ; Background Color Palette Data
	ENDR

	; ==================
	; | SPRITE PALETTE |
	; ==================
	ld a, %10000000
	ld [rOCPS], a                  ; Object Color Palette Specification
	ld bc, %0000000000000000        ; transparent
	ld a, c
	ld [rOCPD], a                  ; Object Color Palette Data
	ld a, b
	ld [rOCPD], a
	ld bc, %0010110100100101        ; dark
	ld a, c
	ld [rOCPD], a
	ld a, b
	ld [rOCPD], a
	ld bc, %0100000111001101        ; med
	ld a, c
	ld [rOCPD], a
	ld a, b
	ld [rOCPD], a
	ld bc, %0100001000010001        ; white
	ld a, c
	ld [rOCPD], a
	ld a, b
	ld [rOCPD], a

PALETTE_BG0:
	dcolor $000000  ; BLACK
	dcolor $1D2B53  ; DARK BLUE
	dcolor $7E2553  ; DARK PURPLE
	dcolor $008751  ; DARK GREEN
  dcolor $AB5236
  dcolor $5F574F
  dcolor $C2C3C7
  dcolor $FFF1E8
  dcolor $FF004D
  dcolor $FFA300
  dcolor $FFEC27
  dcolor $00E436
  dcolor $29ADFF
  dcolor $83769C
  dcolor $FF77A8
  dcolor $FFCCAA 