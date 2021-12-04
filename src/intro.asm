INCLUDE "include/hardware.inc/hardware.inc"


SECTION "Intro", ROMX

Intro::  
main_loop:  

  ld hl, player_car_soam    ; it's tile 80
  ld a, $42                 ; just make sure it's on screen
  ; y  
  ld [hl+], a
  ; x
  ld [hl+], a           
  ld a, carcar_tile_num      
  ld [hl+], a
  ld a, carcar_attributes
  ld [hl], a

  ld a, HIGH(wShadowOAM) ;queue OAM DMA
	ldh [hOAMHigh], a
  rst WaitVBlank

;  ld hl, wBallY ; this is 12.4, but we want to convert to integer
;  ld de, OBJ_BALL
;  lb bc, BALL_Y_OFFSET, BALL_X_OFFSET

;  ld de, OBJ_ARROW ;shadow OAM entry

; HL: pointer to 12.4 Y position, followed by 12.4 X position
; B: Y offset from the center of the sprite to the top edge
; C: X offset from the center of the sprite to the left edge
; DE: pointer to the shadow OAM entry where this sprite can go

; ====================
; || ACT ON BUTTONS ||
; ====================  
  ld a, [hHeldKeys]
  bit PADB_LEFT, a        ;? button detect
  jr z, .skip_left        ;? button detect                  
  ldh a, [player_x]           ;= if left pressed
  dec a                   ;= if left pressed
  ldh [player_x], a           ;= if left pressed
  ld a, [hHeldKeys]
  .skip_left:
    bit PADB_RIGHT, a     ;? button detect
    jr z, .skip_right     ;? button detect
    ldh a, [player_x]         ;= if right pressed
    inc a                 ;= if right pressed
    ldh [player_x], a         ;= if right pressed
    ld a, [hHeldKeys]
  .skip_right:    
    bit PADB_UP, a        ;? button detect
    jr z, .skip_up        ;? button detect
    ldh a, [player_y]         ;= scroll up
    dec a                 ;= scroll up
    ldh [player_y], a         ;= scroll up
    ld a, [hHeldKeys]
  .skip_up:
    bit PADB_DOWN, a      ;? button detect
    jr z, .skip_down      ;? button detect
    ldh a, [player_y]         ;= scroll down
    inc a                 ;= scroll down
    ldh [player_y], a         ;= scroll down  
  .skip_down

  ldh a, [player_y]
  ldh [hSCY], a
  ldh [rSCY], a
  ldh a, [player_x]
  ldh [hSCX], a
  ldh [rSCX], a
  
  jr main_loop

load_tiles::
  ld de, background_tiles  
  ld hl, $9000  
  ld bc, SIZEOF("Background Tiles")
;  call memcpy_small
  call Memcpy
  
  ld de, background_tilemap
  ld hl, $9800
  ld bc, SIZEOF("Background Tilemap")
  call Memcpy

  ld de, carcar_north
  ld hl, carcar_north_tile
  ld bc, SIZEOF("CarCar North")
  call Memcpy
  ld de, carcar_north
  ld hl, carcar_north_tile + $f
  ld bc, SIZEOF("CarCar North")
  call Memcpy
  ret

SECTION "vars", HRAM
player_x:
  db
player_y:
  db



carcar_north_tile   EQU $9000 - $8 - ($FF * 8)
carcar_tile_num     EQU $80
carcar_attributes   EQU %00000000
carcar_r_sprite_y   EQU _OAMRAM + 0
carcar_r_sprite_x   EQU _OAMRAM + 1
carcar_r_tile       EQU _OAMRAM + 2
carcar_r_attributes EQU _OAMRAM + 3
;Bit7   BG and Window over OBJ (0=No, 1=BG and Window colors 1-3 over the OBJ)
;Bit6   Y flip          (0=Normal, 1=Vertically mirrored)
;Bit5   X flip          (0=Normal, 1=Horizontally mirrored)
;Bit4   Palette number  **Non CGB Mode Only** (0=OBP0, 1=OBP1)
;Bit3   Tile VRAM-Bank  **CGB Mode Only**     (0=Bank 0, 1=Bank 1)
;Bit2-0 Palette number  **CGB Mode Only**     (OBP0-7)

SECTION "CarCar North", ROM0
carcar_north:
INCBIN "res/carcar_north.2bpp"

SECTION "Background Tiles", ROM0
background_tiles:
INCBIN "res/circuit256.2bpp"

SECTION "Background Tilemap", ROM0
background_tilemap:
;INCBIN "res/background.bit7.tilemap"
INCBIN "res/circuit256.tilemap"

SECTION "Sprites", ROM0
ANISE_SPRITE:
    dw `00000000
    dw `00001333
    dw `00001323
    dw `10001233
    dw `01001333
    dw `00113332
    dw `00003002
    dw `00003002

SECTION "OAM Buffer", WRAM0[$C100]
oam_buffer:
    ds 4 * 40
