GAME_NAME equs " SNAKE "
SGB_SUPPORT equ 1
; GBC_SUPPORT equ 1 ; Note that this line is commented out ,
; setting it to 0 does not disable GBC support
ROM_SIZE equ 2
RAM_SIZE equ 1
INCLUDE " gingerbread.asm"
INCLUDE "hardware.inc"

; =========
; | MACRO |
; =========
dcolor: MACRO  ; $rrggbb -> gbc representation
_r = ((\1) & $ff0000) >> 16 >> 3
_g = ((\1) & $00ff00) >> 8  >> 3
_b = ((\1) & $0000ff) >> 0  >> 3
    dw (_r << 0) | (_g << 5) | (_b << 10)
    ENDM

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

SECTION "Utility code", ROM0
; idle until next vblank
wait_for_vblank:
    xor a                       ; clear the vblank flag
    di                          ; avoid irq race after this ld
    ld [vblank_flag], a
.vblank_loop:
    ei
    halt                        ; wait for interrupt
    di
    ld a, [vblank_flag]         ; was it a vblank interrupt?
    and a
    jr z, .vblank_loop          ; if not, keep waiting
    ei
    ret
; copy c bytes from de to hl. c = 0 means to copy 256 bytes!
copy:
    ld a, [de]
    inc de
    ld [hl+], a
    dec c
    jr nz, copy
    ret
    
; This is a directive for the assembler to put the following
; code at $0150 in the final ROM.
SECTION "main", ROM0[$0150]

    ; =====================    
    ; | ENABLE INTERRUPTS |
    ; =====================
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei
    
    ; ================
    ; | TURN OFF LCD |
    ; ================
    call wait_for_vblank
    ld a, [rLCDC]
    and a, $ff & ~LCDCF_ON
    ldh [rLCDC], a    

    ; ======================
    ; | BACKGROUND PALETTE |
    ; ======================
    ld a, %10000000                 ; write to palette 0. high bit to 1 to automatically increase where I will write 
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

    ; =====================================================
    ; | LOAD BACKGROUND from $8000 to $8000 + 8 * 2 bytes |
    ; =====================================================
    ld de, BACKGROUND
    ld hl, _VRAM
    ld c, 255
    call copy
    ld de, BACKGROUND+255
    ld hl, _VRAM+255
    ld c, 255
    call copy
    ld de, BACKGROUND+255*2
    ld hl, _VRAM+255*2
    ld c, 255
    call copy
    ld de, BACKGROUND+255*3
    ld hl, _VRAM+255*3
    ld c, 255
    call copy
    ld de, BACKGROUND+255*4
    ld hl, _VRAM+255*4
    ld c, 255
    call copy
;    ld hl, _VRAM
;    ld de, EMPTY_SPRITE
;    ld c, 16
;    call copy
;    
;    ; Read the grass sprite into tile 1, which immediately follows tile 0, so hl is already in the right place
;    ld bc, GRASS_SPRITE
;    REPT 16
;    ld a, [bc]
;    inc bc
;    ld [hl+], a
;    ENDR

    ; ============================    
    ; | SET BACKGROUND TILE USED |
    ; ============================    
    ; Fill the screen buffer with a pattern of grass tiles
    ; Note that the buffer is 32x32 tiles, and it ends at $9c00
    ld hl, $9800
    ld b, $00
screen_fill_loop:    
    ld a, b    
    ld [hl+], a
    inc b
    ld a, h                     ; If we haven't reached $9c00 yet, continue looping
    cp a, $9C
    jr c, screen_fill_loop


    ; ==============================================
    ; | LOAD SPRITE from $8800 to $8000 + 16 bytes |
    ; ==============================================
    ld de, ANISE_SPRITE
    ld hl, _VRAM + $800
    ld c, 16
    call copy    

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
    ld de, DMA_BYTECODE
    ld hl, _HRAM
    ld c, 13
    call copy
    call _HRAM                  ; start transfer

    ; ======================================================
    ; | SET LCD CONTROLLER REGISTER to display some sprite |
    ; ======================================================
    ld a, LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON | LCDCF_ON | LCDCF_BG8000
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
    swap b                      ; put dpab in the high nybble 
    or a, b                      
    ld [buttons], a              

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
    bit PADB_LEFT, a            ; This sets the z flag to match a particular bit in a    
    jr z, skip_left             ; If z, the bit is zero, so left isn't held down    
    dec c                       ; Otherwise, left is held down, so decrement x
skip_left:    
    bit PADB_RIGHT, a
    jr z, skip_right
    inc c
skip_right:
    bit PADB_UP, a
    jr z, skip_up
    dec b
skip_up:
    bit PADB_DOWN, a
    jr z, skip_down
    inc b
skip_down:    
    ld [hl], c                   ; Finally, write the new coordinates back to the OAM buffer, which hl is still pointing into    
    dec hl
    ld [hl], b

    jp vblank_loop


; ========
; | DATA |
; ========
SECTION "Sprites", ROM0
PALETTE_BG0:
    dcolor $80c870  ; light green
    dcolor $48b038  ; darker green
    dcolor $000000  ; unused
    dcolor $000000  ; unused
PALETTE_ANISE:
    dcolor $000000  
    dcolor $204048
    dcolor $20b0b0
    dcolor $f8f8f8
GRASS_SPRITE:
    dw `00000000
    dw `00000000
    dw `01000100
    dw `01010100
    dw `00010000
    dw `00000000
    dw `00000000
    dw `00000000
EMPTY_SPRITE:
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
    dw `00000000
ANISE_SPRITE:
    dw `00000000
    dw `00001333
    dw `00001323
    dw `10001233
    dw `01001333
    dw `00113332
    dw `00003002
    dw `00003002

BACKGROUND:
    incbin "background.2bpp"

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

