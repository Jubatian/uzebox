/*
 *  Uzebox Kernel - Mode 80
 *  Copyright (C) 2019 Sandor Zsuga (Jubatian)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Uzebox is a reserved trade mark
*/

;=============================================================================
;
; Video mode 80
;
; Real-time code generated tile data
;
; 80 tiles width (17 cycles / tile)
; 16 colors, option for using up to 2 vertical palette reloads
; Tiles have fixed colors selected from the 16 of the palette
; Tile size: 112 bytes (at 8 pixels tile height)
; No scrolling
; No sprites
;
;=============================================================================
;
; The mode needs a code tileset and palette source provided by the user.
;
; The following global symbols are required:
;
; m90_defpalette:
;     16 bytes at arbitrary location in ROM, defining the default palette.
;     This palette is loaded upon initialization into palette.
;
; m90_deftilerows:
;     An array of entry jumps (2 words each) for each tile row in ROM. Its
;     size depends on the tile height (TILE_HEIGHT). This address is loaded
;     upon initialization for rendering tile rows. Note: Jumps are used
;     instead of entry points since it is impossible to make the assembler
;     emit addresses in ".byte" directives.
;
; The tile row generator should work within the following constraints:
;
; Inputs:
; X:   Points at first tile to render in VRAM
; r2:  Color 0 of palette
; ...
; r17: Color 15 of palette
;
; Entry happens at cycle 277 (the first instruction: the entry jump begins at
; this cycle). Exit must happen at cycle 1758 (after the "ret").
; In total (including the "jmp" and "ret") the code must use 1481 cycles.
;
; The palette registers have to be preserved.
;
; It should produce 60 tiles, then blank the output.
;
; Technically anything is doable there, however a normal Mode 90 output should
; work as follows:
;
; r18: Loaded with 60, counts the tiles to render.
; r19: Loaded with 7, used as a multiplier to get the tile data.
; r20: Loaded with the low byte of the base of the tile data blocks.
; r21: Loaded with the high byte of the base of the tile data blocks.
;
; 17 cycles wide tiles are chosen to break sync with Colorburst (which is 8
; cycles), while still allowing 80 tiles (a little wider than CGA 80 column
; mode this way).
;
; Code tiles are 17 cycles wide with up to 6 pixel outputs. There is a tile
; generator producing them, in principle, they have the following body for
; example (this is a nice generic layout for typical characters):
;
; row_x_tile_xx:
;	out   PIXOUT,  r6/r7   ; 3cy
;	rjmp  .                ; Used to reduce size by common tails
;	out   PIXOUT,  r6/r7   ; 3cy
;	movw  ZL,      r0
;	nop                    ; Could go anywhere (or 7th pixel)
;	out   PIXOUT,  r6/r7   ; 3cy
;	ld    r5,      X+
;	out   PIXOUT,  r6/r7   ; 2cy
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	out   PIXOUT,  r6/r7   ; 3cy
;	mul   r5,      r4      ; r4: Codeblock size
;	out   PIXOUT,  r6/r7   ; 3cy (always, inter-character gap)
;	ijmp
;
; Permissible orders of key instructions (there may be less than 6 pixel
; outputs, first "out" must always be present to terminate previous tile in
; case it ended with a Foreground pixel):
;
;	rjmp  .                ; (2) Used to reduce size by common tails
;	movw  ZL,      r0
;	ld    r5,      X+      ; (2)
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	mul   r5,      r4      ; (2) r4: Codeblock size
;
;	rjmp  .                ; (2) Used to reduce size by common tails
;	ld    r5,      X+      ; (2)
;	movw  ZL,      r0
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	mul   r5,      r4      ; (2) r4: Codeblock size
;
;	rjmp  .                ; (2) Used to reduce size by common tails
;	ld    r5,      X+      ; (2)
;	movw  ZL,      r0
;	mul   r5,      r4      ; (2) r4: Codeblock size
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;
;	rjmp  .                ; (2) Used to reduce size by common tails
;	movw  ZL,      r0
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	ld    r5,      X+      ; (2)
;	mul   r5,      r4      ; (2) r4: Codeblock size
;
;	movw  ZL,      r0
;	rjmp  .                ; (2) Used to reduce size by common tails
;	ld    r5,      X+      ; (2)
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	mul   r5,      r4      ; (2) r4: Codeblock size
;
;	movw  ZL,      r0
;	rjmp  .                ; (2) Used to reduce size by common tails
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;	ld    r5,      X+      ; (2)
;	mul   r5,      r4      ; (2) r4: Codeblock size
;
;	rjmp  .                ; (2) Used to reduce size by common tails
;	movw  ZL,      r0
;	ld    r5,      X+      ; (2)
;	mul   r5,      r4      ; (2) r4: Codeblock size
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;
;	movw  ZL,      r0
;	rjmp  .                ; (2) Used to reduce size by common tails
;	ld    r5,      X+      ; (2)
;	mul   r5,      r4      ; (2) r4: Codeblock size
;	subi  ZH,      hi8(-(pm(row_x_tile_00)))
;
; Instruction cycles sequences by this:
;
; 21212
; 22112
; 22121
; 21122
; 12212
; 12122
; 21221
; 12221
;
; Permissible begin sequences of tiles (to control codeblock size):
;
;	out   PIXOUT,  r5/r6   ; 3cy
;	rjmp  .
;
;	out   PIXOUT,  r5/r6   ; 1cy
;	out   PIXOUT,  r5/r6   ; 3cy
;	rjmp  .
;
;	out   PIXOUT,  r5/r6   ; 2cy
;	movw  ZL,      r0
;	out   PIXOUT,  r5/r6   ; 3cy
;	rjmp  .
;
; One row this way takes 2K minimum (excluding tails)
;
;=============================================================================


;
; unsigned char vram[];
;
; The Video RAM. Its size depends on the configuration in VideoMode80.def.h.
;
.global vram

;
; void ClearVram(void);
;
; Uzebox kernel function: clears the VRAM.
;
.global ClearVram

;
; void SetTile(char x, char y, unsigned int tileId);
;
; Uzebox kernel function: sets a tile at a given X:Y location on VRAM.
;
.global SetTile

;
; unsigned int GetTile(char x, char y);
;
; Retrieves a tile from a given X:Y location on VRAM. This is a supplementary
; function set up to match with the Uzebox kernel's SetTile function.
;
.global GetTile

;
; void SetFont(char x, char y, unsigned char tileId);
;
; Uzebox kernel function: sets a (character) tile at a given X:Y location on
; VRAM.
;
.global SetFont

;
; unsigned char GetFont(char x, char y);
;
; Retrieves a (character) tile from a given X:Y location on VRAM. This is a
; supplementary function set up to match with the Uzebox kernel's SetFont
; function.
;
.global GetFont

;
; void SetFontTilesIndex(unsigned char index);
;
; Uzebox kernel function: sets the address of the space (0x20) character in
; the tileset, which is by default at tile 0x00.
;
.global SetFontTilesIndex



.section .bss

	; Globals

	vram:          .space VRAM_SIZE

	; Locals

	v_fbase:       .space 1 ; Font base address (space char. in font)

.section .text




;
; Video frame renderer
;
; Register usage:
;
;  r1: r0: Temporaries, used within scanline code for multiplication
;  r2-r17: Palette colors, r8: Background
;     r18: Temporary, used to load tile in scanline loop
;     r19: Contains current row code block high word
;     r20: Set to 4, size of code blocks in scanline loop
;     r21: Zero pixel for terminating the line
;     r22: Line counter
;     r23:
;     r24: Tile row counter
;     r25: Line within tile row counter
;       X: Used to read VRAM
;       Y:
;       Z: Used for jumps within scanline code
;

sub_video_mode80:

;
; Entry happens in cycle 467.
;

	; Prepare some reasonable test stuff

	ldi   ZL,      0       ; Colors
	mov   r2,      ZL
	ldi   ZL,      0xFF
	mov   r3,      ZL

	ldi   r22,     0       ; Line Counter
	ldi   r24,     0       ; Tile Row counter
	ldi   r25,     0       ; Line within Tile Row counter

	; Prepare for Timer 1 use in the scanline loop for line termination

	ldi   ZL,      (1 << OCF1B) + (1 << OCF1A) + (1 << TOV1)
	sts   _SFR_MEM_ADDR(TIFR1), ZL  ; Clear any pending timer int

	ldi   ZL,      (0 << WGM12) + (1 << CS10)
	sts   _SFR_MEM_ADDR(TCCR1B), ZL ; Switch to timer1 normal mode (mode 0)

	ldi   ZL,      (1 << TOIE1)
	sts   _SFR_MEM_ADDR(TIMSK1), ZL ; Enable Overflow interrupt

	; Prepare constants

	ldi   r21,     0       ; Line terminating zero pixel
	ldi   r20,     4       ; Size of code blocks (heads)

	; Wait until next line

	WAIT  r18,     1322
	rjmp  scl_0

	; Scanline loop entry by Timer1 termination

.global TIMER1_OVF_vect
TIMER1_OVF_vect:

	out   _SFR_IO_ADDR(PORTC), r21 ; Zero pixel terminating the line

	pop   r0               ; pop & discard OVF interrupt return address
	pop   r0               ; pop & discard OVF interrupt return address

	; Tail wait

	WAIT  ZL,      ((((86 - SCREEN_TILES_H) * TILE_WIDTH) + 0) / 2) + 46

	; Entry point from lead-in

scl_0:

	; Check end of line

	lds   ZL,      render_lines_count
	cp    r22,     ZL
	breq  scl_0e
	rjmp  .
	rjmp  .
	lpm   ZL,      Z

	; Audio and Alignment (at cycle 1820 = 0 here)
	; The hsync_pulse routine clobbers r0, r1, Z and the T flag.

	rcall hsync_pulse      ; (21 + AUDIO)
	WAIT  ZL,      ((((86 - SCREEN_TILES_H) * TILE_WIDTH) + 1) / 2) + (HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES)

	; Enter code tile row

	; Prepare row variables

	ldi   XL,      lo8(vram)
	ldi   XH,      hi8(vram)
	ldi   ZL,      SCREEN_TILES_H
	mul   ZL,      r24
	add   XL,      r0
	adc   XH,      r1      ; VRAM begin address to read
	mov   ZL,      r25
	ldi   ZH,      0
	subi  ZL,      lo8(-(m80_tilerows))
	sbci  ZH,      hi8(-(m80_tilerows))
	lpm   r19,     Z       ; Current row renderer select
	subi  r19,     hi8(-(pm(m80_tilerow_0)))
	inc   r25              ; Increment line within tile row
	cpi   r25,     TILE_HEIGHT
	brne  .+2
	ldi   r25,     0
	brne  .+2
	inc   r24              ; Increment tile row when passed previous
	inc   r22              ; Increment line counter

	; Prepare timer

	ldi   ZL,      lo8(0x10000 - ((TILE_WIDTH * SCREEN_TILES_H) + 10))
	ldi   ZH,      hi8(0x10000 - ((TILE_WIDTH * SCREEN_TILES_H) + 10))
	sts   _SFR_MEM_ADDR(TCNT1H), ZH
	sts   _SFR_MEM_ADDR(TCNT1L), ZL
	sei

	; Prepare for the tile row

	ld    r18,     X+
	mul   r18,     r20
	movw  ZL,      r0
	add   ZH,      r19
	ld    r18,     X+
	mul   r18,     r20

	; Enter tile row, will be terminated by timer

	ijmp

scl_0e:

	; Restore Timer 1 to the value it should normally have at this point

	ldi   r24,     hi8(101 - TIMER1_DISPLACE)
	sts   _SFR_MEM_ADDR(TCNT1H), r24
	ldi   r24,     lo8(101 - TIMER1_DISPLACE)
	sts   _SFR_MEM_ADDR(TCNT1L), r24

	rcall hsync_pulse      ; Last hsync, from now cycle precise part over.

	; Set vsync flag & flip field

	lds   ZL,      sync_flags
	ldi   r20,     SYNC_FLAG_FIELD
	ori   ZL,      SYNC_FLAG_VSYNC
	eor   ZL,      r20
	sts   sync_flags, ZL

	; Restore Timer 1's operation mode

	ldi   r24,     (1 << OCF1B) + (1 << OCF1A) + (1 << TOV1)
	sts   _SFR_MEM_ADDR(TIFR1), r24  ; Clear any pending timer int

	ldi   r24,     (1 << WGM12) + (1 << CS10)
	sts   _SFR_MEM_ADDR(TCCR1B), r24 ; Switch back to timer1 CTC mode (mode 4)

	ldi   r24,     (1 << OCIE1A)
	sts   _SFR_MEM_ADDR(TIMSK1), r24 ; Restore ints on compare match

	ret



;
; void ClearVram(void);
;
; Uzebox kernel function: clears the VRAM.
;
.section .text.ClearVram
ClearVram:

	ldi   ZL,      lo8(VRAM_SIZE)
	ldi   ZH,      hi8(VRAM_SIZE)
	ldi   XL,      lo8(vram)
	ldi   XH,      hi8(vram)
	clr   r1
clvr0:
	st    X+,      r1
	sbiw  ZL,      1
	brne  clvr0
	ret



;
; void SetTile(char x, char y, unsigned int tileId);
;
; Uzebox kernel function: sets a tile at a given X:Y location on VRAM.
;
;     r24: x
;     r22: y
; r21:r20: tileId (r21 not used)
;
.section .text.SetTile
SetTile:

	ldi   r18,     VRAM_TILES_H
	mul   r22,     r18     ; Calculate Y line addr in vram
	movw  XL,      r0
	clr   r1
	add   XL,      r24     ; Add X offset
	adc   XH,      r1
	subi  XL,      lo8(-(vram))
	sbci  XH,      hi8(-(vram))
	st    X,       r20
	ret



;
; unsigned int GetTile(char x, char y);
;
; Retrieves a tile from a given X:Y location on VRAM. This is a supplementary
; function set up to match with the Uzebox kernel's SetTile function.
;
;     r24: x
;     r22: y
;
; Returns:
;
; r25:r24: Tile ID (r25 always zero)
;
.section .text.GetTile
GetTile:

	ldi   r18,     VRAM_TILES_H
	mul   r22,     r18     ; Calculate Y line addr in vram
	movw  XL,      r0
	clr   r1
	add   XL,      r24     ; Add X offset
	adc   XH,      r1
	subi  XL,      lo8(-(vram))
	sbci  XH,      hi8(-(vram))
	ld    r24,     X
	clr   r25
	ret



;
; void SetFont(char x, char y, unsigned char tileId);
;
; Uzebox kernel function: sets a (character) tile at a given X:Y location on
; VRAM.
;
;     r24: x
;     r22: y
;     r20: tileId
;
.section .text.SetFont
SetFont:

	ldi   r18,     VRAM_TILES_H
	mul   r22,     r18     ; Calculate Y line addr in vram
	movw  XL,      r0
	clr   r1
	add   XL,      r24     ; Add X offset
	adc   XH,      r1
	subi  XL,      lo8(-(vram))
	sbci  XH,      hi8(-(vram))
	lds   r0,      v_fbase
	add   r20,     r0
	st    X,       r20
	ret



;
; unsigned char GetFont(char x, char y);
;
; Retrieves a (character) tile from a given X:Y location on VRAM. This is a
; supplementary function set up to match with the Uzebox kernel's SetFont
; function.
;
;     r24: x
;     r22: y
;
; Returns:
;
; r25:r24: Tile ID (r25 always zero)
;
.section .text.GetFont
GetFont:

	ldi   r18,     VRAM_TILES_H
	mul   r22,     r18     ; Calculate Y line addr in vram
	movw  XL,      r0
	clr   r1
	add   XL,      r24     ; Add X offset
	adc   XH,      r1
	subi  XL,      lo8(-(vram))
	sbci  XH,      hi8(-(vram))
	lds   r0,      v_fbase
	ld    r24,     X
	add   r24,     r0
	clr   r25
	ret



;
; void SetFontTilesIndex(unsigned char index);
;
; Uzebox kernel function: sets the address of the space (0x20) character in
; the tileset, which is by default at tile 0x00.
;
;     r24: index
;
.section .text.SetFontTilesIndex
SetFontTilesIndex:

	sts   v_fbase, r24
	ret



#include "m80_cp437.s"
