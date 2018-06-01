;
; Uzebox Kernel - Video Mode 52 sprite output
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
; This part manages the output of sprites including the necessary RAM tile
; allocations and tile copies.
;
; It uses whatever VRAM layout is defined. Y coordinates are by logical
; scanline, X coordinates assume a 40 tiles wide display over which the actual
; area is centered (for example at 32 tiles width, X = 32 is the leftmost
; pixel column).
;
; The maximal count of RAM tiles used for sprites may be specified. Sprites
; will take RAM tiles incrementally from m52_rtbase until hitting the limit
; when already allocated sprite parts might be dropped to favor more important
; oncoming elements. RAM tiles outside of the bounds of the sprite allocatior
; may be used normally for tile data, the sprite output routine will properly
; handle their contents like any ROM tile.
;
; The description of mask support:
;
; For every tile there is a corresponding mask index whose pointers can be set
; up using M52_SetTileset(). The mask index selects the mask to use from the
; mask pool. Its values are to be interpreted as follows:
;
; 0x00 - 0xDF: Indexes masks in the ROM mask pool.
; 0xE0 - 0xFD: Indexes masks in the RAM mask pool.
; 0xFE: Zero mask (all sprite pixels are shown).
; 0xFF: Full mask (no sprite pixels visible; no RAM tile allocation happens).
;
; Of course these only apply if the sprite was requested to be blit with mask,
; and the mask index lists are present.
;
; Sprite generation:
;
; The region of RAM tiles used for sprites (m52_sprite_ramt_max count of RAM
; tiles beginning at m52_sprite_ramt_base) also have a corresponding region of
; mask indices in the mask index list for the RAM tiles. When allocating a RAM
; tile, not only the original tile data is copied, but also the corresponding
; mask index. This way overlapping sprites would work proper (further sprites
; also mask against the original tile mask).
;
; If the RAM tiles have no masks, a limited sprite masking may still be used,
; particularly if all sprites are asked to be masked and only mask types 0xFE
; and 0xFF are used, and masked sprites are drawn first, things will work
; normally.
;

;
; The layout of the sprite allocation workspace:
;
; Uses byte triplets with the following contents:
; byte0: bit 0-3: RAM pointer high of VRAM where tile index was replaced
;        bit 4-7: Importance of sprite content
; byte1: RAM pointer low of VRAM where tile index was replaced
; byte2: Original tile index at the VRAM location
;




;
; void M52_VramRestore(void);
;
; Restores VRAM and clears sprite engine state.
;
; Should be called after frame generation, before starting working on the
; VRAM. General suggested workflow:
; Restore VRAM => Operate on VRAM (ex.: scrolling) => Sprite output.
;
.global M52_VramRestore

;
; void M52_ResReset(void);
;
; Resets the VRAM restore list.
;
; This should be called if you want to drop the VRAM restore list for
; completely refilling the VRAM.
;
.global M52_ResReset

;
; void M52_BlitSprite(m52_sprite_dataptr_t data, u16 xl, u8 yl, u8 flg);
;
; Blits a 8x8 sprite.
;
; Assumes a 40 tiles wide target on which tile rows are centered. xl and yl
; specifies locations on this target by the sprite's lower right corner (a
; sprite at 40:8 would be visible in the upper left corner of a 32 tiles wide
; display).
;
; The sprite has fixed 8x8 pixel layout, 2 or 3 bytes per line, 16 or 24 bytes
; total. See M52_Manual.rst for descriptions on the sprite formats.
;
; The flags:
; bit0: If set, flip horizontally (M52_SPR_FLIPX)
; bit1: If set, sprite source is RAM (M52_SPR_RAM)
; bit2: If set, flip vertically (M52_SPR_FLIPY)
; bit4: If set, mask is used (M52_SPR_MASK)
; bit5: If set, sprite is 4 colors + transparency mask (M52_SPR_4COL)
; bit6-7: Sprite importance (M52_SPR_I0 - M52_SPR_I3)
;
.global M52_BlitSprite

;
; void M52_BlitSpriteRom(M52_FLASHPTR u8* data, u16 xl, u8 yl, u8 flg);
;
; Same as above, provided for an easier to use C interface.
;
.global M52_BlitSpriteRom

;
; void M52_BlitSpriteRam(u8* data, u16 xl, u8 yl, u8 flg);
;
; Sets M52_SPR_RAM in flags, then the same as M52_BlitSprite().
;
.global M52_BlitSpriteRam

;
; void M52_PutPixel(u8 col, u16 xl, u8 yl, u8 flg);
;
; Plots a single pixel.
;
; Assumes a 40 tiles wide target on which tile rows are centered. xl and yl
; specifies locations on this target.
;
; A pixel importance value of 3 (M52_SPR_I3) gives the highest possible
; importance score to the allocated RAM tile. A pixel importance of 1
; (M52_SPR_I1) is the lowest importance which adds up when plotting multiple
; pixels on the same tile. A pixel importance of 0 (M52_SPR_I0) gives the
; lowest possible importance score which doesn't add up with multiple pixels.
;
; The flags:
; bit4: If set, mask is used (M52_SPR_MASK)
; bit6-7: Sprite importance (M52_SPR_I0 - M52_SPR_I3)
;
.global M52_PutPixel

;
; u8* volatile m52_sprite_work_p;
;
; RAM tile allocation workspace pointer. Uses 3 bytes for an entry, so assign
; a location accordingly depending on the desired number of RAM tiles to use
; for sprites. Should only be written after a VRAM restore before any sprites
; were produced.
;
.global m52_sprite_work_p

;
; volatile u8 m52_sprite_ramt_max;
;
; Maximal number of RAM tiles to use for sprites. RAM tiles are taken
; beginning with m52_sprite_ramt_base, any RAM tile outside these bounds is
; free for any use (if they occur on the VRAM, they can be composed with
; sprites normally). Should only be written after a VRAM restore before any
; sprites were produced.
;
.global m52_sprite_ramt_max

;
; volatile u8 m52_sprite_ramt_base;
;
; The base RAM tile for sprite output. It must be larger or equal to
; m52_ramt_base for proper function.
;
.global m52_sprite_ramt_base

;
; u8* volatile m52_ramt_mski_p;
;
; Pointer to RAM tile mask indices. The first entry contains the mask for the
; first RAM tile (index: m52_ramt_base). When set NULL, the RAM tiles have no
; mask (sprites always visible on them). Masked sprite blitting has some
; limitations this case.
;
.global m52_ramt_mski_p

;
; M52_FLASHPTR u8* m52_mskpool_rom_p;
;
; Pointer to ROM mask pool for mask indices 0x00 - 0xDF. A mask is 8 bytes.
;
.global m52_mskpool_rom_p

;
; u8* m52_mskpool_ram_p;
;
; Pointer to RAM mask pool for mask indices 0xE0 - 0xFD. A mask is 8 bytes.
;
.global m52_mskpool_ram_p



.section .bss

	; Globals

	m52_sprite_work_p:     .space 2 ; RAM tile allocation workspace pointer
	m52_sprite_ramt_max:   .space 1 ; Maximal number of RAM tiles allowed
	m52_sprite_ramt_base:  .space 1 ; Base RAM tile for sprite output
	m52_ramt_mski_p:       .space 2 ; RAM tile mask indices pointer
	m52_mskpool_rom_p:     .space 2 ; ROM mask pool pointer
	m52_mskpool_ram_p:     .space 2 ; RAM mask pool pointer

	; Locals

	v_rtno:                .space 1 ; Number of RAM tiles currently allocated

.section .text



;
; void M52_VramRestore(void);
;
; Restores VRAM and clears sprite engine state.
;
; Should be called after frame generation, before starting working on the
; VRAM. General suggested workflow:
; Restore VRAM => Operate on VRAM (ex.: scrolling) => Sprite output.
;
; Clobbered registers:
; r0, r1 (set zero), XL, XH, ZL, ZH
;
M52_VramRestore:
	lds   ZL,      m52_sprite_work_p + 0
	lds   ZH,      m52_sprite_work_p + 1
	lds   XH,      v_rtno
	cpi   XH,      0
	breq  rlsrr1           ; List is empty
	mov   r1,      XH
rlsrr0:
	ld    XH,      Z+
	andi  XH,      0x0F    ; Zero in XH indicates mangled entry, so no restore
	ld    XL,      Z+      ; (This happens when a RAM tile was discarded,
	ld    r0,      Z+      ; by restoring the VRAM, but a new proper tile
	breq  .+2              ; allocation didn't finish yet)
	st    X,       r0      ; Memory restored
	dec   r1
	brne  rlsrr0           ; List emptied
	sts   v_rtno,  r1
rlsrr1:
	ret



;
; void M52_ResReset(void);
;
; Resets the VRAM restore list.
;
; This should be called if you want to drop the VRAM restore list for
; completely refilling the VRAM.
;
; Clobbered registers:
; r1 (set zero)
;
M52_ResReset:
	clr   r1
	sts   v_rtno,  r1
	ret



;
; void M52_PutPixel(u8 col, u16 xl, u8 yl, u8 flg);
;
; Plots a single pixel.
;
; Assumes a 40 tiles wide target on which tile rows are centered. xl and yl
; specifies locations on this target.
;
; A pixel importance value of 3 (M52_SPR_I3) gives the highest possible
; importance score to the allocated RAM tile. A pixel importance of 1
; (M52_SPR_I1) is the lowest importance which adds up when plotting multiple
; pixels on the same tile. A pixel importance of 0 (M52_SPR_I0) gives the
; lowest possible importance score which doesn't add up with multiple pixels.
;
;     r24: Pixel color (only low 2 bits used)
; r23:r22: X location
;     r20: Y location
;     r18: Flags
;          bit4: If set, mask is used
;          bit6-7: Pixel importance (ignored)
; Clobbered registers:
; r0, r1 (set zero), r18, r19, r20, r21, r22, r23, r24, r25, XL, XH, ZL, ZH, T
;
M52_PutPixel:

	push  r14
	push  r15
	push  r16
	push  r17
	push  YL
	push  YH
	clr   r1               ; Make sure it is zero
	mov   r16,     r18     ; Flags into r16 for the RAM tile allocator

	; Load tile row descriptor where the pixel is output

	mov   ZL,      r20
	lsr   ZL
	andi  ZL,      0x7C
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_rowdesc))
	sbci  ZH,      hi8(-(m52_rowdesc))
	ld    XL,      Z+
	ld    XH,      Z+
	ld    r18,     Z+
	ld    r19,     Z+

	; Adjust X to compensate for X shift on the row

	mov   ZL,      r18
	andi  ZL,      0x07
	add   r22,     ZL
	adc   r23,     r1

	; Break down X to column & in-tile coordinate

	lsr   r23
	brne  bpixe            ; X >= 512: Certainly off-screen
	mov   r17,     r22
	andi  r22,     0x07    ; In-tile X coordinate
	ror   r17              ; Bit 8 of X is still in carry
	lsr   r17
	lsr   r17              ; Tile column got

	; Get Y in-tile coordinate

	mov   r23,     r20
	andi  r23,     0x07    ; In-tile Y coordinate

	; Prepare pixel's importance into r20

	mov   r20,     r16
	andi  r20,     0xC0
	breq  .+8              ; 0x00: Don't change any more
	sbrc  r20,     6
	subi  r20,     0xD0    ; (0x00); 0x70; 0x80; 0xF0 importances
	sbrs  r20,     7
	subi  r20,     0x60    ; (0x00); 0x10; 0x80; 0xF0 importances

	; Allocate RAM tile

	rcall m52_ramtilealloc
	brtc  bpixe            ; No RAM tile

	; Plot pixel
	; From RAM tile allocation:
	; r14:r15: Mask offset (only set up if masking remined enabled)
	;     r16: Flags updated:
	;          bit4 cleared if backround's mask is zero (no masking)
	;          bit7 indicates whether mask is in ROM (0) or RAM (1)
	;       Y: Allocated RAM tile's data address

	sbrs  r16,     4
	rjmp  bpixnm           ; No mask: pixel will be produced
	add   r14,     r23
	adc   r15,     r1      ; Set up mask source adding Y
	movw  ZL,      r14
	sbrs  r16,     7
	rjmp  .+4
	ld    r17,     Z       ; RAM mask source
	rjmp  .+2
	lpm   r17,     Z       ; ROM mask source
	sbrc  r22,     2
	swap  r17
	bst   r22,     1
	brtc  .+4
	lsl   r17
	lsl   r17
	sbrc  r22,     0
	lsl   r17
	sbrc  r17,     7
	rjmp  bpixe            ; Pixel masked off
bpixnm:
	lsl   r23
	ldi   r19,     0x03    ; Mask on target
	andi  r24,     0x03    ; Pixel color
	lsr   r22              ; X offset, bit 0
	brcs  .+6
	ldi   r19,     0x0C
	lsl   r24
	lsl   r24              ; Align pixel in byte
	lsr   r22              ; X offset, bit 1
	brcs  .+4
	swap  r19
	swap  r24              ; Align pixel in byte
	add   r23,     r22
	add   YL,      r23     ; Target pixel quad offset in RAM tile
	ld    r0,      Y
	com   r19
	and   r0,      r19
	or    r0,      r24
	st    Y,       r0      ; Pixel completed

bpixe:

	; Done

	pop   YH
	pop   YL
	pop   r17
	pop   r16
	pop   r15
	pop   r14
	ret




;
; void M52_BlitSprite(m52_sprite_dataptr_t data, u16 xl, u8 yl, u8 flg);
;
; Blits a 8x8 sprite.
;
; Assumes a 40 tiles wide target on which tile rows are centered. xl and yl
; specifies locations on this target by the sprite's lower right corner (a
; sprite at 40:8 would be visible in the upper left corner of a 32 tiles wide
; display).
;
; The sprite has fixed 8x8 pixel layout, 2 or 3 bytes per line, 16 or 24 bytes
; total. See M52_Manual.rst for descriptions on the sprite formats.
;
; The flags:
; bit0: If set, flip horizontally (M52_SPR_FLIPX)
; bit1: If set, sprite source is RAM (M52_SPR_RAM)
; bit2: If set, flip vertically (M52_SPR_FLIPY)
; bit4: If set, mask is used (M52_SPR_MASK)
; bit5: If set, sprite is 4 colors + transparency mask (M52_SPR_4COL)
; bit6-7: Sprite importance (M52_SPR_I0 - M52_SPR_I3)
;
; r25:r24: Source 8x8 sprite start address
; r23:r22: X location (right side)
;     r20: Y location (bottom)
;     r18: Flags
; Clobbered registers:
; r0, r1 (set zero), r18, r19, r20, r21, r22, r23, r24, r25, XL, XH, ZL, ZH, T
;
M52_BlitSpriteRam:

	ori   r18,     1       ; RAM sprite

M52_BlitSprite:
M52_BlitSpriteRom:

	push  r4
	push  r5
	push  r6
	push  r7
	push  r8
	push  r9
	push  r10
	push  r11
	push  r12
	push  r13
	push  r14
	push  r15
	push  r16
	push  r17
	push  YL
	push  YH

	mov   r16,     r18     ; Flags will stay in r16
	clr   r1               ; Make sure this is zero

	; Prepare for lower row

	mov   r21,     r20
	andi  r21,     0x07    ; Location within tile on Y
	subi  r21,     8
	cpi   r21,     0xF8
	breq  bsplle           ; No sprite (off tile)

	; Save X & Y for upper row

	movw  r12,     r22
	mov   r10,     r20

	; Load tile row descriptor where the sprite part is output

	mov   ZL,      r20
	lsr   ZL
	andi  ZL,      0x7C
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_rowdesc))
	sbci  ZH,      hi8(-(m52_rowdesc))
	ld    XL,      Z+
	ld    XH,      Z+
	ld    r18,     Z+
	ld    r19,     Z+

	; Adjust X to compensate for X shift on the row

	mov   ZL,      r18
	andi  ZL,      0x07
	add   r22,     ZL
	adc   r23,     r1

	; Break down X to column & in-tile coordinate

	lsr   r23
	brne  bspller          ; X >= 512: Certainly off-screen
	mov   r17,     r22
	andi  r22,     0x07    ; In-tile X coordinate
	ror   r17              ; Bit 8 of X is still in carry
	lsr   r17
	lsr   r17              ; Tile column got

	; In-tile Y

	mov   r23,     r21

	; Generate lower right sprite part

	movw  r4,      r22
	subi  r22,     8
	cpi   r22,     0xF8
	breq  bsplre           ; No sprite (off tile)
	movw  r6,      XL
	movw  r8,      r18
	mov   r11,     r17
	rcall m52_blitspriteptprep
	mov   r17,     r11
	movw  r18,     r8
	movw  XL,      r6
bsplre:
	movw  r22,     r4

	; Generate lower left sprite part

	dec   r17
	rcall m52_blitspriteptprep
bspller:

	mov   r20,     r10
	movw  r22,     r12
bsplle:

	; Prepare for upper row

	mov   r21,     r20
	andi  r21,     0x07    ; Location within tile on Y

	; Load tile row descriptor where the sprite part is output

	mov   ZL,      r20
	subi  ZL,      8
	lsr   ZL
	andi  ZL,      0x7C
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_rowdesc))
	sbci  ZH,      hi8(-(m52_rowdesc))
	ld    XL,      Z+
	ld    XH,      Z+
	ld    r18,     Z+
	ld    r19,     Z+

	; Adjust X to compensate for X shift on the row

	mov   ZL,      r18
	andi  ZL,      0x07
	add   r22,     ZL
	adc   r23,     r1

	; Break down X to column & in-tile coordinate

	lsr   r23
	brne  bspuler          ; X >= 512: Certainly off-screen
	mov   r17,     r22
	andi  r22,     0x07    ; In-tile X coordinate
	ror   r17              ; Bit 8 of X is still in carry
	lsr   r17
	lsr   r17              ; Tile column got

	; In-tile Y

	mov   r23,     r21

	; Generate upper right sprite part

	movw  r4,      r22
	subi  r22,     8
	cpi   r22,     0xF8
	breq  bspure           ; No sprite (off tile)
	movw  r6,      XL
	movw  r8,      r18
	mov   r11,     r17
	rcall m52_blitspriteptprep
	mov   r17,     r11
	movw  r18,     r8
	movw  XL,      r6
bspure:
	movw  r22,     r4

	; Generate upper left sprite part

	dec   r17
	rcall m52_blitspriteptprep
bspuler:

	; Done

	pop   YH
	pop   YL
	pop   r17
	pop   r16
	pop   r15
	pop   r14
	pop   r13
	pop   r12
	pop   r11
	pop   r10
	pop   r9
	pop   r8
	pop   r7
	pop   r6
	pop   r5
	pop   r4
	ret



;
; Blits a sprite part including the allocation and management of RAM tiles
; for this.
;
; r25:r24: Source 8x8 sprite start address
;     r23: Y location on tile (2's complement; 0xF9 - 0x07 inclusive)
;     r22: X location on tile (2's complement; 0xF9 - 0x07 inclusive)
;     r19: Byte 3 of Row Descriptor
;     r18: Byte 2 of Row Descriptor
;     r17: Column (X) on VRAM
;     r16: Flags
;          bit0: If set, flip horizontally
;          bit1: If set, sprite source is RAM
;          bit2: If set, flip vertically
;          bit3: Unused
;          bit4: If set, mask is used
;          bit5: If set, 4+1 color sprites
;          bit6-7: Sprite importance (larger: higher)
;      r1: Zero
;       X: Row's VRAM base address (as loaded from the Row Descriptor)
; Return:
; Clobbered registers:
; r0, r14, r15, r17, r18, r19, r20, r21, r22, r23, XL, XH, YL, YH, ZL, ZH, T
;
m52_blitspriteptprep:

	; Calculate sprite part importance. This depends on how large portion
	; of the sprite is within the tile and its set importance. Produces a
	; number between 0 and 15, the higher the more important.

	ldi   r20,     15      ; Importance into r20
	sbrs  r22,     7       ; X alignment (0xF9 - 0x07)
	sub   r20,     r22
	sbrc  r22,     7
	add   r20,     r22
	sbrs  r23,     7       ; Y alignment (0xF9 - 0x07)
	sub   r20,     r23
	sbrc  r23,     7
	add   r20,     r23
	mov   r21,     r16     ; Importance bits at 6 - 7
	swap  r21              ; Importance bits at 2 - 3
	lsr   r21              ; Importance bits at 1 - 2 (0, 2, 4 or 6)
	andi  r21,     0x06
	add   r20,     r21     ; Importance added
	subi  r20,     0x06    ; Compensate it (so lower importance makes result less)
	sbrc  r20,     7
	clr   r20              ; Gone below 0: constrain to 0.
	swap  r20              ; Make it suitable for the RAM tile allocator

	; Allocate the RAM tile and calculate necessary address data

	push  r16              ; Save to preserve various flag bits
	rcall m52_ramtilealloc
	brtc  bsppexit         ; No RAM tile

	; Call the sprite part blitter

	rcall m52_blitspritept

bsppexit:

	pop   r16              ; Restore flags for further sprite parts
	ret



;
; RAM tile allocator. This is responsible for managing the allocation of RAM
; tiles and filling them up with the proper contents from the source ROM or
; RAM tile. It also returns the necessary parameters for blitting.
;
;     r20: Importance, low 4 bits must be zero. Higher is the more important.
;     r19: Byte 3 of Row Descriptor
;     r18: Byte 2 of Row Descriptor
;     r17: Tile Column (X)
;     r16: Flags
;          bit4: If set, mask is used
;      r1: Zero
;       X: Row's VRAM base address (as loaded from the Row Descriptor)
; Return:
;       T: Set if sprite can render, clear if it can't
; r14:r15: Mask offset (only set up if masking remined enabled)
;     r16: Flags updated:
;          bit4: Cleared if backround's mask is zero (no masking)
;          bit7: Indicates whether mask is in ROM (0) or RAM (1)
;       Y: Allocated RAM tile's data address
; Clobbered registers:
; r0, r17, r18, r19, r20, r21, XL, XH, ZL, ZH
;
m52_ramtilealloc:

	; Use Y for allocation workspace, so gaining access to LDD / STD

	lds   YL,      m52_sprite_work_p + 0
	lds   YH,      m52_sprite_work_p + 1

	; Check whether sprite can blit. Attribute modes 0 and 1 are available
	; for sprites.

	sbrc  r18,     3       ; Sprites are disabled for the row?
	rjmp  rtadroptile
	sbrc  r18,     5       ; Attribute mode: 0 or 1?
	rjmp  rtadroptile

	; Load tile index, also positioning the VRAM pointer on it. The tile
	; index is first used to determine whether it is an already allocated
	; RAM tile.

	mov   ZL,      r19
	swap  ZL
	andi  ZL,      0x0F    ; Display width selector
#if   (M52_TILES_MAX_H == 36)
	cpi   ZL,      0x0D
	brcs  .+2
	ldi   ZL,      0x0D
#elif (M52_TILES_MAX_H == 34)
	cpi   ZL,      0x0C
	brcs  .+2
	ldi   ZL,      0x0C
#else
	cpi   ZL,      0x0B
	brcs  .+2
	ldi   ZL,      0x0B
#endif
	add   r17,     ZL
	subi  r17,     0x0F
	brcs  rtadroptile0     ; Off screen to the left
	lsl   ZL
	subi  ZL,      0xF6    ; Add 10, so it is 10 - 40, count of total tiles when no scroll
	mov   ZH,      r18
	andi  ZH,      0x07
	breq  .+2
	inc   ZL               ; Add one tile extra when shifted by 1-7 pixels
	cp    r17,     ZL
	brcc  rtadroptile0     ; Off screen to the right

#if (M52_ENABLE_ATTR0 != 0)
	sec
	sbrc  r18,     4
	rol   r17              ; Attribute mode 1: (Index * 2) + 1 is VRAM address
#endif
	add   XL,      r17
	adc   XH,      r1
	ld    r17,     X       ; Tile index

	mov   r0,      r17
	lds   r21,     m52_sprite_ramt_base
	sub   r0,      r21
	lds   r21,     m52_sprite_ramt_max
	sub   r0,      r21
	brcc  rtanew


	; Fast path: Already allocated RAM tile. VRAM address in X is no
	; longer needed. Load its mask if necessary.

	lds   r21,     m52_ramt_base
	sub   r17,     r21     ; RAM tile number (r21 = m52_sprite_ramt_base)
	sbrs  r16,     4       ; Mask used?
	rjmp  rtafnm           ; No mask, do nothing
	lds   ZL,      m52_ramt_mski_p + 0
	lds   ZH,      m52_ramt_mski_p + 1
	cpi   ZH,      0       ; NULL?
	breq  rtafn1           ; If NULL (anywhere in IO area), no mask on sprite
	add   ZL,      r17
	adc   ZH,      r1
	ld    r18,     Z       ; Load mask index of RAM tile
	cpi   r18,     0xFE
	brcc  rtafn0           ; No mask (0xFE) or Full mask (0xFF)
	cpi   r18,     0xE0
	brcs  rtafro           ; 0x00 - 0xDF: ROM masks
	lds   ZL,      m52_mskpool_ram_p + 0
	lds   ZH,      m52_mskpool_ram_p + 1
	subi  r18,     0xE0
	ori   r16,     0x80    ; Mask is in RAM (bit 7 set)
	rjmp  rtafrc
rtadroptile0:
	clt                    ; Tile can not be rendered exit point
	ret
rtafn0:
	brne  rtadroptile0     ; 0xFF: Full mask: Tile dropped
rtafn1:
	andi  r16,     0xEF    ; Clear bit 4 of flags (no mask)
	rjmp  rtafnm           ; 0xFE: No mask: Sprite blits
rtafro:
	lds   ZL,      m52_mskpool_rom_p + 0
	lds   ZH,      m52_mskpool_rom_p + 1
	andi  r16,     0x7F    ; Mask is in ROM (bit 7 clear)
rtafrc:
	ldi   r19,     8       ; Multiplier for mask data
	mul   r18,     r19
	add   ZL,      r0
	adc   ZH,      r1      ; Start offset of mask
	clr   r1
	movw  r14,     ZL
rtafnm:

	; Add importance of new sprite part to the RAM tile, so it becomes
	; less likely to be removed when too many sprites are to be rendered.

	mov   r0,      r17
	lsl   r0
	add   r0,      r17
	add   YL,      r0
	adc   YH,      r1
	ld    r19,     Y
	add   r19,     r20     ; Add importance
	brcc  .+2
	ori   r19,     0xF0    ; Saturate at 15
	st    Y,       r19

	; Finish, loading the RAM tile data start offset in Y

	add   r17,     r21     ; Restore tile index (r21 = m52_sprite_ramt_base)
	ldi   r21,     16
	mul   r17,     r21
	movw  YL,      r0
	clr   r1
	set                    ; T flag set: Render the sprite
	ret



	; Slow path: A new RAM tile has to be allocated or reused since the
	; targeted tile is a ROM or non-sprite allocated RAM tile

rtanew:

	; First process masks as a mask index of 0xFF should inhibit the
	; output of a masked sprite (so no RAM tile allocation must happen
	; for them). The mask index will have to be copied along with the
	; source tile data. Also prepare RAM / ROM tile data address into
	; r15:r14.

	lds   r21,     m52_ramt_base
	cp    r17,     r21
	brcs  rtamro           ; ROM tiles if tile index (r17) < m52_ramt_base

	ldi   r18,     16
	mul   r18,     r17
	movw  r14,     r0      ; RAM tile address
	clr   r1
	inc   r14              ; Bit0 = 1 indicates that source is RAM
	lds   ZL,      m52_ramt_mski_p + 0
	lds   ZH,      m52_ramt_mski_p + 1
	ldi   r18,     0xFE
	cpi   ZH,      0       ; NULL?
	breq  rtamrd
	sub   r17,     r21
	add   ZL,      r17
	adc   ZH,      r1
	ld    r18,     Z
	add   r17,     r21
	rjmp  rtamrd

rtamro:
	andi  r19,     0x03    ; ROM tileset to use for VRAM row (byte 3 of row desc.)
	ldi   ZL,      lo8(m52_romt_pht)
	ldi   ZH,      hi8(m52_romt_pht)
	add   ZL,      r19
	adc   ZH,      r1
	ld    r15,     Z       ; ROM tile address base
	ldi   r18,     16
	mul   r18,     r17
	mov   r14,     r0
	add   r15,     r1      ; ROM tile address (Bit0 is 0, indicating ROM source)
	clr   r1
	lsl   r19
	ldi   ZL,      lo8(m52_mski_pt)
	ldi   ZH,      hi8(m52_mski_pt)
	add   ZL,      r19
	adc   ZH,      r1
	ld    r0,      Z+
	ld    ZH,      Z
	ldi   r18,     0xFE
	cpi   ZH,      0       ; NULL?
	breq  rtamrd
	mov   ZL,      r0
	add   ZL,      r17
	adc   ZH,      r1
	lpm   r18,     Z

rtamrd:
	sbrs  r16,     4       ; Mask used?
	rjmp  rtamno           ; No mask, do nothing for now with the mask index
	cpi   r18,     0xFE
	brcs  rtamno           ; Normal masking, do nothing for now with mask index
	breq  rtamoff          ; 0xFE: No mask
rtadroptile:
	clt                    ; Tile can not be rendered exit point
	ret
rtamoff:
	andi  r16,     0xEF    ; Clear bit 4 of flags (no mask)
rtamno:

	; Is it possible to allocate a new RAM tile?

	lds   r21,     v_rtno
	lds   r0,      m52_sprite_ramt_max
	cp    r21,     r0
	brcc  .+2
	rjmp  rtaallocnew      ; A new RAM tile can be allocated

	; Out of RAM tiles. One of the existing RAM tiles have to be taken
	; over if importance permits.

	mov   ZH,      r21     ; Will be used for loop counter
	ldi   r21,     0xFF    ; Will seek the lowest importance
	ldi   ZL,      0       ; ZL: Will store index of lowest importance
	subi  ZH,      1
	andi  ZH,      0xF8
	add   YL,      ZH
	adc   YH,      r1
	add   YL,      ZH
	adc   YH,      r1
	add   YL,      ZH
	adc   YH,      r1      ; Y starts so first iteration performs 1 - 8 comparisons
	andi  ZL,      0x07
	breq  rtaallocil8
	cpi   ZL,      0x02
	brcs  rtaallocil1
	breq  rtaallocil2
	cpi   ZL,      0x04
	brcs  rtaallocil3
	breq  rtaallocil4
	cpi   ZL,      0x06
	brcs  rtaallocil5
	breq  rtaallocil6
	rjmp  rtaallocil7
rtaallocil:
	sbiw  YL,      24
	subi  ZL,      0xF8    ; Add 8, correcting tile indices found in prev. iteration
rtaallocil8:
	ldd   r0,      Y + 21
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x07
rtaallocil7:
	ldd   r0,      Y + 18
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x06
rtaallocil6:
	ldd   r0,      Y + 15
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x05
rtaallocil5:
	ldd   r0,      Y + 12
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x04
rtaallocil4:
	ldd   r0,      Y +  9
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x03
rtaallocil3:
	ldd   r0,      Y +  6
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x02
rtaallocil2:
	ldd   r0,      Y +  3
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x01
rtaallocil1:
	ldd   r0,      Y +  0
	cp    r0,      r21
	brcc  .+4
	mov   r21,     r0
	ldi   ZL,      0x00
	subi  ZH,      8
	brcc  rtaallocil
	andi  r21,     0xF0
	cp    r20,     r21     ; Compare with new part's importance
	brcc  .+2
	rjmp  rtadroptile      ; Exit without render since it was less important

	; Restore old tile index

	mov   r21,     ZL      ; New (RAM) tile index will be in r21
	lsl   ZL
	add   ZL,      r21
	add   YL,      ZL
	adc   YH,      r1      ; Note: During the loop, Y wound back to start
	ldd   ZH,      Y + 0
	ldd   ZL,      Y + 1
	ldd   r0,      Y + 2
	andi  ZH,      0xF
	st    Z,       r0      ; Restored old tile, so all sprite work is gone here
	clr   ZH               ; 0x0 as high 4 bits of RAM address indicates no
	std   Y + 0,   ZH      ; tile here in restore list

	; Point the restore list entry to the new tile (note: writing 0x0 for the
	; high 4 bits of the RAM address is necessary to prevent a hazard when the
	; routine is terminated while writing the new tile's address).

	mov   ZH,      XH
	andi  ZH,      0x0F
	or    ZH,      r20     ; Combined with importance of new sprite part
	std   Y + 2,   r17     ; Original tile saved
	std   Y + 1,   XL
	std   Y + 0,   ZH      ; Write high 4 bits of address last

	; Jump to prepare new tile

	rjmp  rtaallocbl

rtaallocnew:

	; New RAM tile allocation (Sprite RAM tile index is in r21)

	mov   r0,      r21
	lsl   r0
	add   r0,      r21
	add   YL,      r0
	adc   YH,      r1      ; Position at new ramtile's location in workspace
	mov   ZH,      XH
	andi  ZH,      0x0F
	or    ZH,      r20     ; Combined with importance of new sprite part
	std   Y + 2,   r17     ; Original tile saved
	std   Y + 1,   XL
	std   Y + 0,   ZH      ; Restore list entry OK
	mov   r0,      r21
	inc   r0
	sts   v_rtno,  r0      ; Increment to include the new entry

rtaallocbl:

	; RAM tile preparation: either newly allocated or over a discarded
	; previously allocated RAM tile, both are the same from here. The
	; target RAM tile index to use is in r21 (m52_sprite_ramt_base based).
	; In r17 the source tile's index is still present.

	; The original address in X is kept for writing the RAM tile's index
	; in it later when the RAM tile is already filled from the source (to
	; prevent artifacts when the routine is terminated by a frame reset).

	; r20 is free from this point as the importance is saved.

	; Prepare destination offset (on RAM tile)

	lds   r20,     m52_sprite_ramt_base
	add   r21,     r20     ; Target RAM tile index done
	ldi   r20,     16
	mul   r20,     r21
	movw  YL,      r0
	clr   r1

	; Load source offset and branch off to ROM / RAM tile fill

	movw  ZL,      r14
	sbrs  ZL,      0
	rjmp  rtaallocromt
	andi  ZL,      0xFE    ; RAM tiles, clear low bit


	; RAM tile filler.

	ldi   r20,     8
rtaallocramtl:
	ld    r0,      Z+
	st    Y+,      r0
	ld    r0,      Z+
	st    Y+,      r0
	dec   r20
	brne  rtaallocramtl
	rjmp  rtaalloccpe      ; Copy OK, now set VRAM offset to new tile


	; ROM tile filler. Unrolled to make it faster (this is the most common
	; path)

rtaallocromt:
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
	lpm   r0,      Z+
	st    Y+,      r0
rtaalloccpe:


	; Write out mask index for the RAM tile

	lds   ZL,      m52_ramt_mski_p + 0
	lds   ZH,      m52_ramt_mski_p + 1
	cpi   ZH,      0       ; NULL?
	breq  rtamnl
	lds   r20,     m52_ramt_base
	sub   r21,     r20
	add   ZL,      r21
	adc   ZH,      r1
	st    Z,       r18
	add   r21,     r20
rtamnl:

	; Fill completed. Rewind destination to the beginning of the tile,
	; and save the RAM tile's index on VRAM so it becomes visible.

	sbiw  YL,      16
	st    X,       r21     ; X still holds VRAM offset

	; Complete the mask by loading the offset into r15:r14.

	sbrs  r16,     4
	rjmp  rtaanm           ; No masking if clear
	cpi   r18,     0xE0
	brcs  rtaaro           ; 0x00 - 0xDF: ROM masks
	lds   ZL,      m52_mskpool_ram_p + 0
	lds   ZH,      m52_mskpool_ram_p + 1
	subi  r18,     0xE0
	ori   r16,     0x80    ; Mask is in RAM (bit 7 set)
	rjmp  rtaarc
rtaaro:
	lds   ZL,      m52_mskpool_rom_p + 0
	lds   ZH,      m52_mskpool_rom_p + 1
	andi  r16,     0x7F    ; Mask is in ROM (bit 7 clear)
rtaarc:
	ldi   r21,     8       ; Multiplier for mask data
	mul   r18,     r21
	add   ZL,      r0
	adc   ZH,      r1      ; Start offset of mask
	clr   r1
	movw  r14,     ZL
rtaanm:

	; All done, return

	set                    ; T flag set: Render the sprite
	ret



;
; Add the blitter, to the same section
;
;#if (M52_SPIRAM_SPRITES != 0)
;#include "videoMode52/videoMode52_sprb_sr.s"
;#else
#include "videoMode52/videoMode52_sprblit.s"
;#endif
