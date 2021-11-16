
SECTION "Intro", ROMX

Intro::

	ld hl, $8000
	ld de, BackgroundTiles
	ld bc, SIZEOF("Background Tiles")	
	call Memcpy
	jr @

SECTION "Background Tiles", ROM0
BackgroundTiles:
	INCBIN "res/background.pb16"
.end	