;
; Uzebox Kernel - Video Mode 52
; Copyright (C) 2018 Sandor Zsuga (Jubatian)
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; Uzebox is a reserved trade mark
;
;
;
; ****************************************************************************
; Video Mode 52 Rasterizer and Functions
; ****************************************************************************
;
; Spec
; ----
; Type:         Tile-based
; Cycles/Pixel: 5
; Tile Width:   8
; Tile Height:  8
; Resolution:   Up to 288 x 224 pixels (narrower widths selectable)
; Sprites:      Possible by RAM tiles (16 bytes / tile)
; Scrolling:    X and Y scrolling possible
;
; Description
; -----------
;
; See exports
;
; ****************************************************************************
;

;
; Exports
;

;
; volatile u8 m52_config;
;
; Global configuration flags
;
; bit 0: Display enabled if set. Otherwise screen is colored by m52_discol.
; bit 2: If set, Color 0/1 reload is by physical scanline, otherwise logical.
;
.global m52_config

;
; u8* volatile m52_rowsel_p;
;
; Row selector pointer. Records are of 2 bytes in the following layout except
; for the first record which misses the first byte:
;
; - byte 0: Scanline to act on (0 - 223)
; - byte 1: New logical scanline position
;
; The list ends when the scanline can not match any more (either already
; passed or can never be reached).
;
.global m52_rowsel_p

;
; m52_rowdesc_t m52_rowdesc[32];
;
; Row descriptor list. This is an array of 32 row descriptors defining the
; mode of each of the possible logical scanlines (one row is for 8 scanlines).
;
; See "Tile row modes overwiev" in M52_Manual.rst for descriptions on how this
; list can be filled up.
;
.global m52_rowdesc

;
; volatile u8 m52_palette[16];
;
; 4 x 4 color palette available for the rows.
;
.global m52_palette

;
; volatile u8 m52_ramt_base;
;
; RAM tile base address, the first tile index which is a RAM tile, at the
; beginning of the RAM tileset. Below that are the ROM tiles.
;
.global m52_ramt_base

;
; u8* volatile m52_col0_p;
;
; Color 0 remap table if the feature is enabled. It takes up to 256 bytes.
;
.global m52_col0_p

;
; u8* volatile m52_col1_p;
;
; Color 1 remap table if the feature is enabled. It takes up to 256 bytes.
;
.global m52_col1_p

#if (M52_RESET_ENABLE != 0)
;
; volatile u16 m52_reset;
;
; Reset vector where the video frame render will reset upon return with an
; empty stack. It should be a function with void parameters and void return.
; This only happens when the video display is enabled. On init, before
; enabling display, a proper reset vector should be set up, then after enable,
; an empty loop should follow (waiting for the frame to terminate it).
;
.global m52_reset
#endif

;
; void SetTile(char x, char y, u16 tileId);
;
; Uzebox kernel function: sets a tile at a given X:Y location. This draws on
; Mode 6 / 7 SPI RAM canvas, setting fake tiles on the 1bpp bitmap.
;
.global SetTile

;
; void SetFont(char x, char y, u8 tileId);
;
; Uzebox kernel function: sets a character at a given X:Y location. This draws
; on Mode 6 / 7 SPI RAM canvas, setting fake tiles on the 1bpp bitmap.
;
.global SetFont

;
; void M52_SetTileset(u8 tsno, M52_FLASHPTR u8* data, M52_FLASHPTR u8* mski);
;
; Sets one of the 4 ROM tilesets & masks (tsno: 0 - 3).
;
; The ROM tileset must be aligned at a 256 byte boundary, define them as
; follows:
; M52_ROMTILESET_PRE u8 tiles[256 * 16] M52_ROMTILESET_POST = { ... };
; You can address into a ROM tileset at 16 tile boundaries if desired (16
; tiles = 256 bytes).
;
; The mask indices are used by the sprite engine, they take 1 byte / mask,
; indexing into a mask table. They don't have to be aligned at any boundary.
; NULL may be passed to indicate that the tileset has no masks.
;
.global M52_SetTileset

;
; void M52_LoadRowDesc(M52_FLASHPTR m52_rowdesc_t* data);
;
; Loads a full 128 byte row descriptor set into the row descriptors. You may
; use this function if you prefer to predefine complete screen layouts.
;
.global M52_LoadRowDesc

;
; void M52_RamTileFillRom(M52_FLASHPTR u8* src, u8 dst);
;
; Fills a RAM tile from a ROM tile. Source is a pointer, destination is a tile
; offset.
;
.global M52_RamTileFillRom

;
; void M52_RamTileFillRam(u8 src, u8 dst);
;
; Fills a RAM tile from a RAM tile. Both source and destination are tile
; offsets.
;
.global M52_RamTileFillRam

;
; void M52_RamTileClear(u8 dst);
;
; Clears a RAM tile to color index zero. Destination is a tile offset.
;
.global M52_RamTileClear

;
; void M52_Halt(void);
;
; Halts program execution. Use with reset (M52_RESET_ENABLE set) to terminate
; components which are supposed to be terminated by a new frame. This is not
; required, but by the C language a function call is necessary to enforce a
; sequence point (so every side effect completes before the call including
; writes to any globals).
;
.global M52_Halt

;
; void M52_Seq(void);
;
; Sequence point. Use with reset (M52_RESET_ENABLE set) to enforce a sequence
; point, so everything is carried out which is before. This is not required,
; but by the C language a function call is necessary to enforce a sequence
; point (so every side effect completes before the call including writes to
; any globals).
;
.global M52_Seq


;
; Video output port, where the pixels go and Stack
;
#define PIXOUT  VIDEO_PORT
#define STACKH  0x3E
#define STACKL  0x3D



;
; Replacement WAIT macro for the mode. The routines it calls are in
; videoMode52_sub.s, within rcall range for all components. This macro makes
; overall code size smaller.
;
.macro M52WT_SMR24 clocks
	.if     (\clocks) >= 15
		rcall m52_wait_15
	.elseif (\clocks) == 14
		rcall m52_wait_14
	.elseif (\clocks) == 13
		rcall m52_wait_13
	.elseif (\clocks) == 12
		rcall m52_wait_12
	.elseif (\clocks) == 11
		rcall m52_wait_11
	.elseif (\clocks) == 10
		rcall m52_wait_10
	.elseif (\clocks) == 9
		rcall m52_wait_9
	.elseif (\clocks) == 8
		rcall m52_wait_8
	.elseif (\clocks) == 7
		rcall m52_wait_7
	.elseif (\clocks) == 6
		lpm   r24,     Z
		lpm   r24,     Z
	.elseif (\clocks) == 5
		lpm   r24,     Z
		rjmp  .
	.elseif (\clocks) == 4
		rjmp  .
		rjmp  .
	.elseif (\clocks) == 3
		lpm   r24,     Z
	.elseif (\clocks) == 2
		rjmp  .
	.elseif (\clocks) == 1
		nop
	.else
	.endif
.endm
.macro M52WT_R24   clocks
	.if     (\clocks) > 267
		ldi   r24,     ((\clocks) / 16)
		rcall m52_wait_13
		dec   r24
		brne  .-6
		M52WT_SMR24    ((\clocks) % 16)
	.elseif (\clocks) > 15
		ldi   r24,     ((\clocks) - 12)
		rcall m52_wait
	.else
		M52WT_SMR24    (\clocks)
	.endif
.endm



.section .bss

	; Globals

	m52_config:            .space 1   ; Global configuration
	m52_rowsel_p:          .space 2   ; Row selector pointer
#if (M52_ROWDESC_ADDR == 0)
	m52_rowdesc:           .space 128 ; Row descriptor array
#else
.equ	m52_rowdesc = M52_ROWDESC_ADDR    ; Row descriptor array
#endif
	m52_palette:           .space 16  ; 4 x 4 color palette
	m52_ramt_base:         .space 1   ; RAM tile base address
	m52_col0_p:            .space 2   ; Color 0 remap table pointer
	m52_col1_p:            .space 2   ; Color 1 remap table pointer
#if (M52_RESET_ENABLE != 0)
	m52_reset:             .space 2   ; Reset vector
#endif

	; Locals

	m52_romt_pht:          .space 4   ; 4 x ROM tile pointers (high bytes)
	m52_mski_pt:           .space 8   ; 4 x ROM tile mask index set pointers

.section .text



#if (M52_SPR_ENABLE != 0)
;
; Sprite library. Included here to avoid it interfering with relative jumps &
; calls within the Mode 52 core.
;
#include "videoMode52/videoMode52_sprite.s"
#endif



;
; void SetTile(char x, char y, u16 tileId);
; void SetFont(char x, char y, u8 tileId);
;
; Uzebox kernel function: sets a tile at a given X:Y location.
;
;     r24: x
;     r22: y
; r21:r20: tileId (r21 not set for SetFont)
;
.section .text.SetTileFont
SetFont:
	ldi   r21,     0       ; SetFont takes only 8 bits for the ID.
	subi  r20,     0xE0    ; Also it assumes index 0 corresponding to ASCII 0x20.
SetTile:
	ret



;
; void M52_SetTileset(u8 tsno, M52_FLASHPTR u8* data, M52_FLASHPTR u8* mski);
;
; Sets one of the 4 ROM tilesets & masks (tsno: 0 - 3).
;
;     r24: Tileset to set up
; r23:r22: Pointer of ROM tileset (r22 should be zero and is ignored)
; r21:r20: Pointer of Mask index set
;
.section .text.M52_SetTileset
M52_SetTileset:
	mov   ZL,      24
	andi  ZL,      3
	ldi   ZH,      0
	movw  XL,      ZL
	subi  ZL,      lo8(-(m52_romt_pht))
	sbci  ZH,      hi8(-(m52_romt_pht))
	st    Z+,      r23
	lsl   XL
	subi  XL,      lo8(-(m52_mski_pt))
	sbci  XH,      hi8(-(m52_mski_pt))
	st    X+,      r20
	st    X+,      r21
	ret



;
; void M52_LoadRowDesc(M52_FLASHPTR m52_rowdesc_t* data);
;
; Loads a full 128 byte row descriptor set into the row descriptors. You may
; use this function if you prefer to predefine complete screen layouts.
;
.section .text.M52_LoadRowDesc
M52_LoadRowDesc:
	movw  ZL,      r24
	ldi   r24,     32
	ldi   XL,      lo8(m52_rowdesc)
	ldi   XH,      hi8(m52_rowdesc)
	lpm   r25,     Z+
	st    X+,      r25
	lpm   r25,     Z+
	st    X+,      r25
	lpm   r25,     Z+
	st    X+,      r25
	lpm   r25,     Z+
	st    X+,      r25
	dec   r24
	brne  .-20
	ret



;
; void M52_RamTileFillRom(M52_FLASHPTR u8* src, u8 dst);
;
; Fills a RAM tile from a ROM tile. Source is a pointer, destination is a tile
; offset.
;
; r25:r24: src
;     r22: dst
;
.section .text.M52_RamTileFillRom
M52_RamTileFillRom:
	movw  ZL,      r24     ; Source pointer in Z
	ldi   XL,      16
	mul   r22,     XL
	movw  XL,      r0      ; Destination offset generated in X
	clr   r1               ; r1 must be zero for C
	ldi   r22,     4
frtrol:
	lpm   r0,      Z+
	st    X+,      r0
	lpm   r0,      Z+
	st    X+,      r0
	lpm   r0,      Z+
	st    X+,      r0
	lpm   r0,      Z+
	st    X+,      r0
	dec   r22
	brne  frtrol
	ret



;
; void M52_RamTileFillRam(u8 src, u8 dst);
;
; Fills a RAM tile from a RAM tile. Both source and destination are RAM tile
; indices.
;
;     r24: src
;     r22: dst
;
.section .text.M52_RamTileFillRam
M52_RamTileFillRam:
	ldi   XL,      16
	mul   r24,     XL
	movw  ZL,      r0      ; Source offset generated in Z
	mul   r22,     XL
	movw  XL,      r0      ; Destination offset generated in X
	clr   r1               ; r1 must be zero for C
	ldi   r22,     4
frtral:
	ld    r0,      Z+
	st    X+,      r0
	ld    r0,      Z+
	st    X+,      r0
	ld    r0,      Z+
	st    X+,      r0
	ld    r0,      Z+
	st    X+,      r0
	dec   r22
	brne  frtral
	ret



;
; void M52_RamTileClear(u8 dst);
;
; Clears a RAM tile to color index zero. Destination is a RAM tile index.
;
;     r24: dst
;
.section .text.M52_RamTileClear
M52_RamTileClear:
	ldi   XL,      16
	mul   r24,     XL
	movw  XL,      r0      ; Destination offset generated in X
	clr   r1               ; r1 must be zero for C
	ldi   r22,     4
frtcll:
	st    X+,      r1
	st    X+,      r1
	st    X+,      r1
	st    X+,      r1
	dec   r22
	brne  frtcll
	ret



;
; void M52_Halt(void);
;
; Halts program execution. Use with reset (M52_RESET_ENABLE set) to terminate
; components which are supposed to be terminated by a new frame. This is not
; required, but by the C language a function call is necessary to enforce a
; sequence point (so every side effect completes before the call including
; writes to any globals).
;
.section .text.M52_Halt
M52_Halt:
	rjmp  M52_Halt



;
; void M52_Seq(void);
;
; Sequence point. Use with reset (M52_RESET_ENABLE set) to enforce a sequence
; point, so everything is carried out which is before. This is not required,
; but by the C language a function call is necessary to enforce a sequence
; point (so every side effect completes before the call including writes to
; any globals).
;
.section .text.M52_Seq
M52_Seq:
	ret



.section .text


;
; Other components of the mode.
; Note that the order of elements must be preserved and they must be last (so
; add further includes before them, this is required due to some hsync_pulse
; rcalls which the kernel adds after the video mode), to ensure that all
; relative jumps are within range.
;
#include "videoMode52/videoMode52_sccore.s"
#include "videoMode52/videoMode52_sub.s"
#include "videoMode52/videoMode52_scloop.s"
