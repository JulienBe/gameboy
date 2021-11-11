INCLUDE "hardware.inc"

; Constants
BUTTON_RIGHT  EQU 0
BUTTON_LEFT   EQU 1
BUTTON_UP     EQU 2
BUTTON_DOWN   EQU 3
BUTTON_A      EQU 4
BUTTON_B      EQU 5
BUTTON_START  EQU 6
BUTTON_SELECT EQU 7

SECTION "entry point", ROM0[$0100]
    nop
    jp $0150

; Interrupt handlers
SECTION "Vblank interrupt", ROM0[$0040]
    push hl
    ld hl, vblank_flag
    ld [hl], 1
    pop hl
    reti

SECTION "LCD controller status interrupt", ROM0[$0048]
    ; Fires on a handful of selectable LCD conditions, e.g. after repainting a specific row on the screen
    reti

SECTION "Timer overflow interrupt", ROM0[$0050]
    ; Fires at a configurable fixed interval
    reti

SECTION "Serial transfer completion interrupt", ROM0[$0058]
    ; Fires when the serial cable is done?
    reti

SECTION "P10-P13 signal low edge interrupt", ROM0[$0060]
    ; Fires when a button is released?
    reti

SECTION "Important twiddles", WRAM0[$C000]    
    vblank_flag:
        db
    buttons:
        db
; Need to write four bytes that specify the tile and where it goes.
; Can’t actually write them to OAM yet, so I need some scratch space in regular RAM — working RAM.
; The space from $c000 to $dfff is available as working RAM
SECTION "OAM Buffer", WRAM0[$C100]
oam_buffer:
    ds 4 * 40
    
; This is a directive for the assembler to put the following
; code at $0150 in the final ROM.
SECTION "main", ROM0[$0150]

    ; =====================    
    ; | ENABLE INTERRUPTS |
    ; =====================
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei
    ; ======================
    ; | BACKGROUND PALETTE |
    ; ======================
    ld a, %10000000                 ; write to palette 0. high bit to 1 to automatically increase where I will write 
    ld [rBCPS], a                  ; Background Color Palette Specification
    ; actually load colors
    ld bc, %0111101000000000        ; cyan
    ld a, c
    ld [rBCPD], a                  ; Background Color Palette Data
    ld a, b
    ld [rBCPD], a
    ld bc, %0000001111010000        ; green
    ld a, c
    ld [rBCPD], a
    ld a, b
    ld [rBCPD], a
    ld bc, %0100000000011110        ; pink
    ld a, c
    ld [rBCPD], a
    ld a, b
    ld [rBCPD], a
    ld bc, %0111111111111111        ; white
    ld a, c
    ld [rBCPD], a
    ld a, b
    ld [rBCPD], a

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

    ; =====================================================
    ; | LOAD BACKGROUND from $8000 to $8000 + 8 * 2 bytes |
    ; =====================================================
    ld hl, _VRAM
    ld bc, `00112233
    REPT 8
    ld a, b
    ld [hl+], a
    ld a, c
    ld [hl+], a
    ENDR

    ; ==============================================
    ; | LOAD SPRITE from $8800 to $8000 + 16 bytes |
    ; ==============================================
    ld hl, _VRAM + $800
    ld bc, ANISE_SPRITE
    REPT 16
    ld a, [bc]
    ld [hl+], a
    inc bc
    ENDR
    ; =======================
    ; | SET SPRITE POSITION |
    ; =======================    
    ld hl, oam_buffer           ; Put an object on the screen
    ld a, 64                    ; y-coord
    ld [hl+], a
    ld [hl+], a                 ; x-coord    
    ld a, 128                   ; tile index ($8800)
    ld [hl+], a    
    ld a, %00000000             ; attributes, including palette, which are all zero
    ld [hl+], a
    ; =====================================================
    ; | DMA TRANSFER to copy data from working RAM to OAM |
    ; =====================================================    
    ld bc, DMA_BYTECODE         ; Copy the little DMA routine into high RAM
    ld hl, _HRAM    
    REPT 13                     ; DMA routine is 13 bytes long
    ld a, [bc]
    inc bc
    ld [hl+], a
    ENDR
    call _HRAM                  ; start transfer
    ; ======================================================
    ; | SET LCD CONTROLLER REGISTER to display some sprite |
    ; ======================================================
    ld a, %10010011             ; $91 plus bit 2
    ld [rLCDC], a

; label, used to refer to some position in the code. Only exists in the source file.
vblank_loop:    
    halt                        ; Stop all CPU activity until there's an interrupt.  
    ; The Game Boy hardware has a bug where, under rare and unspecified conditions, the instruction after a halt will be skipped.      
    nop                         ; So every halt should be followed by a nop    
    ; ===============================
    ; | ENSURE ITS VBLANK INTERRUPT |
    ; ===============================
    ld a, [vblank_flag]         ; I might later use one of the other interrupts, all of which would also cancel the halt
    and a                       ; This sets the zero flag if a is zero
    jr z, vblank_loop


    xor a, a                    ; This always sets a to zero, and is shorter (and thus faster) than ld a, 0
    ld [vblank_flag], a

    ; Do this FIRST to ensure that it happens before the screen starts to update again.
    call _HRAM                  ; Use DMA to update object attribute memory.

    ; ===============
    ; | READ INPUTS |
    ; ===============

    ; It takes a moment to get a reliable read after requesting a particular set of buttons, so we need to wait a moment
    ; this is based on the code from the manual, which stalls simply by reading multiple times

    
    ld a, %00100000             ; bit 4 being OFF means to read the d-pad)
    ldh [rP1], a    
    ld a, [rP1]                 ; But it's unreliable, so do it twice
    ld a, [rP1]    
    cpl                         ; This is 'complement', and flips all the bits in a, so now set bits will mean a button is held down    
    and a, $0f                  ; Store the lower four bits in b
    ld b, a
    
    ld a, $10                   ; Bit 5 off means to read the buttons
    ldh [rP1], a    
    ld a, [rP1]                 ; Not sure why this needs more stalling?  Someone speculated that this circuitry might just be further away
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]
    ld a, [rP1]    
    cpl                         ; Again, complement and mask off the lower four bits
    and a, $0f
    swap a                      ; swaps the high and low nybbles in any register    
    or a, b                     ; Combine b's lower nybble with a's high nybble    
    ld [buttons], a             ; And finally store it in RAM

    ; ===============
    ; | LOGIC START |
    ; ===============

    ; =====================
    ; | UPDATE SPRITE POS |
    ; =====================
    ld hl, oam_buffer
    ld b, [hl]
    inc hl
    ld c, [hl]    
    bit BUTTON_LEFT, a          ; This sets the z flag to match a particular bit in a    
    jr z, skip_left            ; If z, the bit is zero, so left isn't held down    
    dec c                       ; Otherwise, left is held down, so decrement x
skip_left:    
    bit BUTTON_RIGHT, a
    jr z, skip_right
    inc c
skip_right:
    bit BUTTON_UP, a
    jr z, skip_up
    dec b
skip_up:
    bit BUTTON_DOWN, a
    jr z, skip_down
    inc b
skip_down:    
    ld [hl], c                   ; Finally, write the new coordinates back to the OAM buffer, which hl is still pointing into    
    dec hl
    ld [hl], b

    jp vblank_loop


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

SECTION "DMA Bytecode", ROM0
DMA_BYTECODE:
    db $F5, $3E, $C1, $EA, $46, $FF, $3E, $28, $3D, $20, $FD, $F1, $D9
    
; =======
; | DOC |
; =======
;                           bit 4 ON (default)  bit 4 OFF
;                           ------------------  ---------
;$8000   obj tiles 0-127    bg tiles 0-127
;$8800   obj tiles 128-255  bg tiles 128-255    bg tiles 128-255
;$9000                                          bg tiles 0-127

