# Entry

It's in [header.asm](src/header.asm)

It calls [palettes.asm](src/palettes.asm)

### Notable sections

Will probably need to get back to this one later. At least keep it in mind

```asm
ld a, IEF_VBLANK										; Select wanted interrupts here
ldh [rIE], a												; You can also enable them later if you want
xor a
ei 																	; Only takes effect after the following instruction
ldh [rIF], a 												; Clears "accumulated" interrupts
```	

OAM is cleared

```asm
ld hl, wShadowOAM										; Clear OAM, so it doesn't display garbage
ld c, NB_SPRITES * 4								; This will get committed to hardware OAM after the end of the first
xor a																; frame, but the hardware doesn't display it, so that's fine.
rst MemsetSmall
ld a, h ; ld a, HIGH(wShadowOAM)
ldh [hOAMHigh], a
```


# Display

### Tile Data

Tiles are 8x8, 4 colors per pixel. That's 2 bytes per line, 16 bytes per tile

256 tiles in the system. That's 32x32 tiles. So 256x256 pixels.

They are stored from $8000 to $97FF. So 384 tiles per bank (2 banks on the CGB)

Block 1: $8000–$87FF. Sprite 000 to 127. BG 000 to 127 if LCDC.4 = 1
Block 2: $8800–$8FFF. Sprite 128 to 255. BG 128 to 255
Block 3: $9000–$97FF.	--- Can't use ---. BG 000 to 127 if LCDC.4 = 0


Tiles are always indexed using an 8-bit integer, but the addressing method may differ. 
The “$8000 method” uses $8000 as its base pointer and uses an unsigned addressing, meaning that tiles 0-127 are in block 0, and tiles 128-255 are in block 1. 
The “$8800 method” uses $9000 as its base pointer and uses a signed addressing, meaning that tiles 0-127 are in block 2, and tiles -128 to -1 are in block 1, or to put it differently, “$8800 addressing” takes tiles 0-127 from block 2 and tiles 128-255 from block 1. 
You can notice that block 1 is shared by both addressing methods

Sprites always use “$8000 addressing”, but the BG and Window can use either mode, controlled by LCDC.4

### Tile Map

The Game Boy contains two 32x32 tile maps in VRAM at the memory areas $9800-$9BFF and $9C00-$9FFF.
Any of these maps can be used to display the Background or the Window.

Each tile map contains the 1-byte indexes of the tiles to be displayed.

Tiles are obtained from the Tile Data Table using either of the two addressing modes (described in VRAM Tile Data), which can be selected via the LCDC register.

In CGB Mode, an additional map of 32x32 bytes is stored in VRAM Bank 1
Each byte defines attributes for the corresponding tile-number map entry in VRAM Bank 0, that is, 1:9800 defines the attributes for the tile at 0:9800

```
Bit 7    BG-to-OAM Priority         (0=Use OAM Priority bit, 1=BG Priority)
Bit 6    Vertical Flip              (0=Normal, 1=Mirror vertically)
Bit 5    Horizontal Flip            (0=Normal, 1=Mirror horizontally)
Bit 4    Not used
Bit 3    Tile VRAM Bank number      (0=Bank 0, 1=Bank 1)
Bit 2-0  Background Palette number  (BGP0-7)
```



### What to do 

- Set LCDC.4 to 0
- Load 16 bytes to $8800 which is BG 128
- fill $9800 to $9C00 with 128



### Sprites

Color 0 is transparent

OAM memory stores


`| Pos X | Pos Y | Tile Number | Priority | Flip X | Flip Y | Palette |`


### Memory

Tile Data is stored at addresses $8000-97FF. 1 tile = 16 bytes, so that's 384 Tiles. In CGB Mode this is doubled because of the two VRAM banks.

There are three "blocks" of 128 tiles each:

- Block 0 is $8000-87FF
- Block 1 is $8800-8FFF
- Block 2 is $9000-97FF

# To keep in mind ?

##### NoNop

No nop on CGB ? [source](http://marc.rawer.de/Gameboy/Docs/GBCPUman.pdf)
```
WARNING: The instruction immediately following the HALT instruction is "skipped" when interrupts are  disabled (DI) on the GB,GBP, and SGB. 
As a result, always put a NOP after the HALT instruction. 
This instruction skipping doesn't occur when interrupts are enabled (EI).
This "skipping" does not seem to occur on the GameBoy Color even in regular GB mode. ($143=$00)
```

###### Half logo

CGB boot rom only compares half of the logo ? 

Source: someone in the comment section of a demo, somewhere on internet