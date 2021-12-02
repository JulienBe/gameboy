INCLUDE "include/hardware.inc/hardware.inc"

SECTION "Intro", ROMX

Intro::  
main_loop:  
  rst WaitVBlank
; ====================
; || ACT ON BUTTONS ||
; ====================  
  ld a, [hHeldKeys]
  bit PADB_LEFT, a        ;? button detect
  jr z, .skip_left        ;? button detect                  
  ldh a, [hSCX]           ;= if left pressed
  dec a                   ;= if left pressed
  ldh [hSCX], a           ;= if left pressed
  ld a, [hHeldKeys]
  .skip_left:
    bit PADB_RIGHT, a     ;? button detect
    jr z, .skip_right     ;? button detect
    ldh a, [hSCX]         ;= if right pressed
    inc a                 ;= if right pressed
    ldh [hSCX], a         ;= if right pressed
    ld a, [hHeldKeys]
  .skip_right:    
    bit PADB_UP, a        ;? button detect
    jr z, .skip_up        ;? button detect
    ldh a, [hSCY]         ;= scroll up
    dec a                 ;= scroll up
    ldh [hSCY], a         ;= scroll up
    ld a, [hHeldKeys]
  .skip_up:
    bit PADB_DOWN, a      ;? button detect
    jr z, .skip_down      ;? button detect
    ldh a, [hSCY]         ;= scroll down
    inc a                 ;= scroll down
    ldh [hSCY], a         ;= scroll down  
  .skip_down
  ldh a, [hSCY]
  ldh [rSCY], a
  ldh a, [hSCX]
  ldh [rSCX], a
  jr main_loop

load_background::
  ld de, background_tiles  
  ld hl, $9000  
  ld bc, SIZEOF("Background Tiles")
;  call memcpy_small
  call Memcpy
  
  ld de, background_tilemap
  ld hl, $9800
  ld bc, SIZEOF("Background Tilemap")
  call Memcpy  
  ret
load_car::
  ld de, carcar_north  
  ld hl, $9000 + SIZEOF("CarCar North")
  ld bc, SIZEOF("CarCar North")
  call Memcpy

SECTION "vars", HRAM
player_x:
  db
player_y:
  db

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