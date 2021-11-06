INCLUDE "hardware.inc"

SECTION "entry point", ROM0[$0100]
    nop
    jp $0150

; Need to write four bytes that specify the tile and where it goes.
; Can’t actually write them to OAM yet, so I need some scratch space in regular RAM — working RAM.
; The space from $c000 to $dfff is available as working RAM
SECTION "OAM Buffer", WRAM0[$C100]
oam_buffer:
    ds 4 * 40
    
; This is a directive for the assembler to put the following
; code at $0150 in the final ROM.
SECTION "main", ROM0[$0150]

	; ======================
	; | BACKGROUND PALETTE |
	; ======================
	ld a, %10000000		; write to palette 0. high bit to 1 to automatically increase where I will write 
	ld [$ff68], a
	; actually load colors
	ld bc, %0111101000000000  ; cyan
    ld a, c
    ld [$ff69], a
    ld a, b
    ld [$ff69], a
    ld bc, %0000001111010000  ; green
    ld a, c
    ld [$ff69], a
    ld a, b
    ld [$ff69], a
    ld bc, %0100000000011110  ; pink
    ld a, c
    ld [$ff69], a
    ld a, b
    ld [$ff69], a
    ld bc, %0111111111111111  ; white
    ld a, c
    ld [$ff69], a
    ld a, b
    ld [$ff69], a

    ; ==================
    ; | SPRITE PALETTE |
    ; ==================

    ld a, %10000000
    ld [$ff6a], a

    ld bc, %0000000000000000  ; transparent
    ld a, c
    ld [$ff6b], a
    ld a, b
    ld [$ff6b], a
    ld bc, %0010110100100101  ; dark
    ld a, c
    ld [$ff6b], a
    ld a, b
    ld [$ff6b], a
    ld bc, %0100000111001101  ; med
    ld a, c
    ld [$ff6b], a
    ld a, b
    ld [$ff6b], a
    ld bc, %0100001000010001  ; white
    ld a, c
    ld [$ff6b], a
    ld a, b
    ld [$ff6b], a

    ; =====================================================
    ; | LOAD BACKGROUND from $8000 to $8000 + 8 * 2 bytes |
    ; =====================================================
    ld hl, $8000
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
    ld hl, $8800
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
    ld hl, $ff80    
    REPT 13                     ; DMA routine is 13 bytes long
    ld a, [bc]
    inc bc
    ld [hl+], a
    ENDR
    call $ff80                  ; start transfer
    ; ======================================================
    ; | SET LCD CONTROLLER REGISTER to display some sprite |
    ; ======================================================
    ld a, %10010011             ; $91 plus bit 2
    ld [$ff40], a

; label, used to refer to some position in the code. Only exists in the source file.
_halt:
    ; Stop all CPU activity until there's an interrupt.  Haven't turned any interrupts on, so this stops forever.
    halt
    ; The Game Boy hardware has a bug where, under rare and unspecified conditions, the instruction after a halt will be skipped.  
    ; So every halt should be followed by a nop
    nop
    ; Short for "jump relative", and will end up as an instruction saying something like "jump backwards 5 bytes".
    jr _halt

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
