/*
 *  Uzebox Kernel - Mode 45
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
; Video mode 45
;
; 1bpp attribute mode up to 40 8x8 tiles wide display
;
; Up to 320 pixels width (4.5 cycles / pixel)
; 8 pixels wide tiles
; 8 pixels tall tiles
; Attribute RAM allowing definition of FG & BG color for each tile
; 2 bytes used / tile: Video RAM / Attribute RAM
; RAM tiles are available, arbitrary split point between ROM / RAM tiles
; Vertical scrolling and vertical split-screen possible
; Sprites are possible by RAM tiles
;
;=============================================================================

;
; Configuring the RAM:
;
; To get RAM tiles, a fixed 2K sized RAM area has to be allocated. This is at
; M45_RAMTILES (normally placed on the top of the RAM). When using only a
; fraction of the RAM tiles, each 256 byte bank of this region has its lower
; bytes (up to the first RAM tile's index) unused.
;
; The most straightforward use of this RAM is locating the VRAM or ARAM in it
; as far as the rows fit.
;
; Row configuration for 32 tile rows is contained in a ROM structure:
;
; typedef struct{
;  unsigned char*       vram;
;  unsigned char*       aram;
;  unsigned const char* pal;
;  unsigned const char* tiles;
;  unsigned char        flags;
; }m45_row_t;
;
; Tiles points to the ROM tileset to be used for this row.
;
; Flags contain the following fields:
;
; - bit 0-3: Attribute mode type.
; - bit   4: If set, palette is in ROM.
; - bit   5: Disable RAM tiles for this row if set.
;

;
; m45_row_t const* m45_rowdesc;
;
; Points to the ROM structure describing the 32 rows which can be used to
; build the display.
;
.global m45_rowdesc

;
; unsigned char* m45_col0;
;
; Color 0 replacement table. If the feature is enabled, this is used to reload
; Color 0 on every physical display row.
;
.global m45_col0

;
; unsigned char* m45_linesel;
;
; Line selector list. Contains byte pairs, first byte is the line (from the 32
; rows) to start displaying, second byte is the next physical row to act on.
; If this byte is set unreachable (such as 255 or a previous row), the list
; ends.
;
.global m45_linesel

;
; unsigned char m45_lastromt;
;
; Last ROM tile's index. Above this, RAM tiles are displayed (unless RAM tiles
; are disabled for the row).
;
.global m45_lastromt

;
; unsigned char m45_config;
;
; Global mode configuration.
;
; - bit   0: If set, Color 0 replacement is used.
; - bit   1: If set, Color 0 is also the horizontal border color.
; - bit   2: If set, Row Descriptor table is fetched from RAM.
; - bit   7: If set, display is enabled (otherwise mode is blank).
;
.global m45_config

;
; unsigned char m45_border;
;
; The border color if a border is present and configured to use it.
;
.global m45_border

;
; void ClearVram(void);
;
; Uzebox kernel function: clears the VRAM. This function should only be used
; if all 32 rows in the current Row Descriptor are either defined proper or
; their VRAM pointer is set to NULL.
;
.global ClearVram

;
; void ClearAram(void);
;
; Complementary function: clears the ARAM (Attribute RAM). This function
; should only be used if all 32 rows in the current Row Descriptor are either
; defined proper or their ARAM pointer is set to NULL.
;
.global ClearAram

;
; void SetTile(char x, char y, unsigned int tileId);
;
; Uzebox kernel function: sets a tile at a given X:Y location on VRAM.
;
.global SetTile

;
; void SetAttr(char x, char y, unsigned char attr);
;
; Complementary function: sets a tile's attribute at a given X:Y location on
; ARAM.
;
.global SetAttr

;
; unsigned int GetTile(char x, char y);
;
; Retrieves a tile from a given X:Y location on VRAM. This is a supplementary
; function set up to match with the Uzebox kernel's SetTile function.
;
.global GetTile

;
; unsigned char GetAttr(char x, char y);
;
; Retrieves a tile's attribute from a given X:Y location on ARAM.
;
.global GetAttr

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



#define PIXOUT  VIDEO_PORT
#define GPR0    _SFR_IO_ADDR(GPIOR0)
#define GPR1    _SFR_IO_ADDR(GPIOR1)
#define GPR2    _SFR_IO_ADDR(GPIOR2)



.section .bss

	; Globals

	m45_rowdesc:   .space 2            ; Tile row descriptors in ROM
	m45_col0:      .space 2            ; Color 0 replacement table in RAM
	m45_linesel:   .space 2            ; Line selector table in RAM
	m45_lastromt:  .space 1            ; Last ROM tile index
	m45_config:    .space 1            ; Video mode configuration
	m45_border:    .space 1            ; Border color

	; Locals

	v_fbase:       .space 1            ; Font base for char output
	v_linesel:     .space 2            ; Line selector, current address

.section .text




;
; Video frame renderer
;

sub_video_mode45:

;
; Entry happens in cycle 467.
;

	; Save GPIO regs, they will be used during scanlines

	in    r0,      GPR0
	push  r0
	in    r0,      GPR1
	push  r0
	in    r0,      GPR2
	push  r0                    ; ( 476)

	; (10 cy) Prepare line selector

	lds   ZL,      m45_linesel + 0
	lds   ZH,      m45_linesel + 1
	ld    r23,     Z+           ; First logical scanline
	sts   v_linesel + 0, ZL
	sts   v_linesel + 1, ZH

	; ( 1 cy) Prepare physical scanline

	ldi   r22,     0

	; ( 4 cy) Check Display Enable, if not, blank display.
	; Also loads configuration for the scanline loop into r19

	lds   r19,     m45_config
	sbrs  r19,     7
	rjmp  scl_dis

	; Wait until next line

	WAIT  ZL,      1244

;
; Scanline loop.
;
; Every register expect r22 and r23 is used during actual tile output. These
; two registers are utilized as follows:
;
; r22: Physical scanline, 0 to FRAME_LINES.
; r23: Logical scanline
;
; Before entry, v_linesel is prepared by reading the first entry of the line
; selector to populate r23, and pointing this at the next byte (next line to
; act on).
;

	; ( 9 cy) Load scanline descriptor

	ldi   r18,     0
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	mov   r21,     r23
	andi  r21,     0xF8
	add   ZL,      r21
	adc   ZH,      r18

	rjmp  scl_0

scl_rowram:

	ld    XL,      Z+      ; VRAM row, low
	ld    XH,      Z+      ; VRAM row, high
	ld    YL,      Z+      ; ARAM row, low
	ld    YH,      Z+      ; ARAM row, high
	ld    r16,     Z+      ; Palette, low
	ld    r17,     Z+      ; Palette, high
	ld    r24,     Z+      ; ROM tiles, high (low is not used)
	ld    r21,     Z+      ; Configuration
	lpm   ZL,      Z
	rjmp  .
	rjmp  scl_rowrame

scl_palram:

	ld    r2,      Z+
	ld    r3,      Z+
	ld    r4,      Z+
	ld    r5,      Z+
	ld    r6,      Z+
	ld    r7,      Z+
	ld    r8,      Z+
	ld    r9,      Z+
	ld    r10,     Z+
	ld    r11,     Z+
	ld    r12,     Z+
	ld    r13,     Z+
	ld    r14,     Z+
	ld    r15,     Z+
	ld    r16,     Z+
	ld    r17,     Z+
	WAIT  ZL,      13
	rjmp  scl_palrame

scl_endp:

	; End: Update the sync_pulse variable for the kernel before return.

	out   PIXOUT,  r18
	lds   ZL,      sync_pulse
	subi  ZL,      FRAME_LINES
	sts   sync_pulse, ZL
	rjmp  scl_end

at_exit:

	; Return from display. Preload some for next scanline

	inc   r22              ; Physical scanline increment
	out   PIXOUT,  ZL
	lds   r19,     m45_config
	ldi   r18,     0
	out   PIXOUT,  ZH
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	out   PIXOUT,  r0
	mov   r21,     r23
	andi  r21,     0xF8
	add   ZL,      r21
	out   PIXOUT,  r1
	adc   ZH,      r18
#if (VRAM_TILES_H < 40)
	nop
	pop   r18              ; Border color (0 for 40 tiles width)
	out   PIXOUT,  r18
	WAIT  r18,     ((40 - VRAM_TILES_H) * 18) - 4
#endif
	cpi   r22,     FRAME_LINES
	breq  scl_endp
	nop
	out   PIXOUT,  r18

scl_0:

	; (26 cy) Load row descriptor

	sbrc  r19,     2
	rjmp  scl_rowram       ; Bit 2 set: RAM row descriptors
	lpm   XL,      Z+      ; VRAM row, low
	lpm   XH,      Z+      ; VRAM row, high
	lpm   YL,      Z+      ; ARAM row, low
	lpm   YH,      Z+      ; ARAM row, high
	lpm   r16,     Z+      ; Palette, low
	lpm   r17,     Z+      ; Palette, high
	lpm   r24,     Z+      ; ROM tiles, high (low is not used)
	lpm   r21,     Z+      ; Configuration
scl_rowrame:

	; (51 cy) Load palette

	movw  ZL,      r16
	sbrs  r21,     4
	rjmp  scl_palram       ; Bit 4 clear: RAM palette
	lpm   r2,      Z+
	lpm   r3,      Z+
	lpm   r4,      Z+
	lpm   r5,      Z+
	lpm   r6,      Z+
	lpm   r7,      Z+
	lpm   r8,      Z+
	lpm   r9,      Z+
	lpm   r10,     Z+
	lpm   r11,     Z+
	lpm   r12,     Z+
	lpm   r13,     Z+
	lpm   r14,     Z+
	lpm   r15,     Z+
	lpm   r16,     Z+
	lpm   r17,     Z+
scl_palrame:

	; Audio and Alignment (at cycle 1820 + 3 here)
	; The update_sound routine clobbers r0, r1, Z and the T flag.
	; Updating sync_pulse is omitted on this path, so has to be done on
	; returning.

	cbi   _SFR_IO_ADDR(SYNC_PORT), SYNC_PIN ; (   5)
	lds   r25,     m45_lastromt
	ldi   ZL,      2       ; (   8)
	call  update_sound     ; (  12) (+ AUDIO)
	WAIT  ZL,      (HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES)

	; (12 cy) Color 0 replacement

	sbrc  r19,     0
	rjmp  0f               ; Bit 0 set: Color 0 replace
	lpm   ZL,      Z
	lpm   ZL,      Z
	rjmp  .
	rjmp  1f
0:
	lds   ZL,      m45_col0 + 0
	lds   ZH,      m45_col0 + 1
	clr   r1
	add   ZL,      r22
	adc   ZH,      r1
	ld    r2,      Z
1:

	; ( 2 cy) RAM tiles

	sbrc  r21,     5       ; Bit 5 set: RAM tiles disabled for this row
	ldi   r25,     255

	; ( 4 cy) Prepare ROM tile row to use

	mov   r20,     r23
	andi  r20,     7
	add   r24,     r20
	out   GPR2,    r24

	; ( 2 cy) Prepare RAM tile row to use

	subi  r20,     hi8(-(M45_RAMTILES))
	out   GPR1,    r20

	; (15 cy) Prepare next logical scanline (r23 no longer used for this line)

	inc   r23              ; Logical scanline increment
	lds   ZL,      v_linesel + 0
	lds   ZH,      v_linesel + 1
	ld    r20,     Z+
	cp    r20,     r22
	brne  scl_prep_nl
	ld    r23,     Z+
	sts   v_linesel + 0, ZL
	sts   v_linesel + 1, ZH
scl_prep_nle:

	; ( 8 cy) Prepare attribute mode selection

	sbrc  r21,     0
	rjmp  0f
	ldi   r20,     hi8(pm(at_attr0_jt))
	sbrc  r21,     1
	ldi   r20,     hi8(pm(at_attr1_jt))
	rjmp  1f
0:
	nop
	ldi   r20,     hi8(pm(at_attr2_jt))
	sbrc  r21,     1
	ldi   r20,     hi8(pm(at_attr2_jt))
1:
	out   GPR0,    r20

	; Prepare entry into video mode

#if   (VRAM_TILES_H < 40)
	lds   r0,      m45_border
	sbrc  r19,     1       ; Bit 1 set: Border is the same as Color 0
	mov   r0,      r2
	push  r0               ; To retrieve border on the right half
	mov   r1,      r0
#else
	clr   r0
	clr   r1
#endif
#if   (VRAM_TILES_H < 39)
	WAIT  ZL,      30 - 5  ; (5 cy extra border fetch above)
	out   PIXOUT,  r0
	WAIT  ZL,      ((40 - VRAM_TILES_H) * 18) - 31
#elif (VRAM_TILES_H < 40)
	WAIT  ZL,      18 - 5  ; (5 cy extra border fetch above)
#else
#endif
	ldi   r21,     hi8(pm(at_head_jt))
	ldi   r24,     VRAM_TILES_H
	ld    ZL,      X+      ; Tile index
	cp    r25,     ZL      ; ROM (bottom) / RAM (top)?
	brcs  0f
	in    ZH,      GPR2    ; ROM tile row
	lpm   r20,     Z
	out   PIXOUT,  r0      ; 39 tiles width border start, 40 tiles: zero
	in    ZH,      GPR0
	ld    ZL,      Y+      ; Attributes
	dec   r24
	ijmp
0:
	in    ZH,      GPR1    ; RAM tile row
	ld    r20,     Z
	out   PIXOUT,  r0      ; 39 tiles width border start, 40 tiles: zero
	in    ZH,      GPR0
	ld    ZL,      Y+      ; Attributes
	dec   r24
	ijmp

scl_prep_nl:
	lpm   ZL,      Z
	rjmp  scl_prep_nle

scl_dis:

	; Display Disabled

	WAIT  ZL,      1327    ; (1819)

scl_dil:

	call  hsync_pulse      ; (22 + AUDIO)
	WAIT  ZL,      (HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES)
	WAIT  ZL,      768

	inc   r22
	cpi   r22,     FRAME_LINES
	breq  scl_endw

	WAIT  ZL,      805
	rjmp  scl_dil

scl_endw:

	WAIT  ZL,      740

scl_end:

	; All lines completed. Wait a hsync_pulse and then return.

	; Restore GPIO regs

	pop   r0
	out   GPR2,    r0
	pop   r0
	out   GPR1,    r0
	pop   r0
	out   GPR0,    r0

	; Wait the hsync (last cycle-sync operation)

	WAIT  ZL,      57
	call  hsync_pulse      ; (22 + AUDIO)

	; Set vsync flag & flip field

	lds   ZL,      sync_flags
	ldi   r20,     SYNC_FLAG_FIELD
	ori   ZL,      SYNC_FLAG_VSYNC
	eor   ZL,      r20
	sts   sync_flags, ZL

	; Clear any pending timer interrupt

	ldi   ZL,      (1<<OCF1A)
	sts   _SFR_MEM_ADDR(TIFR1), ZL

	ret



;
; Scanline loop core for the Attribute mode
;
; Register allocation:
;
;      r0: Temp. for Px 6
;      r1: Temp. for Px 7
;  r2-r17: Palette colors
; r19:r18: Current color pair to use
;     r20: Temp. for receiving tile data
;     r21: hi8(pm(at_head_jt))
;     r24: Count of tiles remaining
;     r25: Topmost ROM tile
;       X: Video RAM
;       Y: Attribute RAM
;    GPR0: Attribute mode renderer select, hi8(pm(at_attrx_jt))
;    GPR1: RAM tile row
;    GPR2: ROM tile row
;
; Entry is by preparing the first tile and performing an ijmp into the
; attribute loader with r0 and r1 set to the border color (or black if no
; border).
;
.macro AT_HEAD px0, px1, px6, px7, midl, exth
	out   PIXOUT,  \px0    ; Px 0 (bit 0)
	mov   r1,      \px7    ; Px 7 (bit 7)
	breq  \exth
	mov   r0,      \px6    ; Px 6 (bit 6)
	out   PIXOUT,  \px1    ; Px 1 (bit 1)
	rjmp  \midl
.endm
.macro AT_EXTH px1, px6, extm
	out   PIXOUT,  \px1    ; Px 1 (bit 1)
	mov   r0,      \px6    ; Px 6 (bit 6)
	rjmp  \extm
.endm
.macro AT_HDMW px0, hdmc
	out   PIXOUT,  \px0    ; Px 0 (bit 0)
	movw  r0,      r18     ; Px 6 & Px 7 (bit 6 & Bit 7)
	rjmp  \hdmc
.endm
.macro AT_HDMC px1, midl, extm
	out   PIXOUT,  \px1    ; Px 1 (bit 1)
	brne  \midl
	rjmp  \extm
.endm
.macro AT_MIDL px2, px3, px4, px5, ramt
	ld    ZL,      X+      ; Tile index
	out   PIXOUT,  \px2    ; Px 2 (bit 2)
	cp    r25,     ZL      ; ROM (bottom) / RAM (top)?
	brcs  \ramt
	in    ZH,      GPR2    ; ROM tile row
	out   PIXOUT,  \px3    ; Px 3 (bit 3)
	lpm   r20,     Z
	in    ZH,      GPR0
	out   PIXOUT,  \px4    ; Px 4 (bit 4)
	ld    ZL,      Y+      ; Attributes
	dec   r24
	out   PIXOUT,  \px5    ; Px 5 (bit 5)
	ijmp
.endm
.macro AT_RAMT px3, px4, px5
	out   PIXOUT,  \px3    ; Px 3 (bit 3)
	in    ZH,      GPR1    ; RAM tile row
	ld    r20,     Z
	in    ZH,      GPR0
	out   PIXOUT,  \px4    ; Px 4 (bit 4)
	ld    ZL,      Y+      ; Attributes
	dec   r24
	out   PIXOUT,  \px5    ; Px 5 (bit 5)
	ijmp
.endm
.macro AT_ATTR colf, colb
	out   PIXOUT,  r0      ; Px 6 (bit 6)
	movw  ZL,      r20     ; r21 is hi8(pm(at_head_jt))
	mov   r18,     \colb
	mov   r19,     \colf
	out   PIXOUT,  r1      ; Px 7 (bit 7)
	ijmp
.endm
.macro AT_EXTM px2, px4, extt
	mov   ZL,      \px4
	out   PIXOUT,  \px2    ; Px 2 (bit 2)
	rjmp  \extt
.endm
.macro AT_EXTT px3, px5
	mov   ZH,      \px5
	out   PIXOUT,  \px3    ; Px 3 (bit 3)
	jmp   at_exit
.endm


.balign 512

at_a00:	AT_ATTR  r2,  r2
at_a01:	AT_ATTR  r2,  r3
at_a02:	AT_ATTR  r2,  r4
at_a03:	AT_ATTR  r2,  r5
at_a04:	AT_ATTR  r2,  r6
at_a05:	AT_ATTR  r2,  r7
at_a06:	AT_ATTR  r2,  r8
at_a07:	AT_ATTR  r2,  r9
at_a08:	AT_ATTR  r2, r10
at_a09:	AT_ATTR  r2, r11
at_a0A:	AT_ATTR  r2, r12
at_a0B:	AT_ATTR  r2, r13
at_a0C:	AT_ATTR  r2, r14
at_a0D:	AT_ATTR  r2, r15
at_a0E:	AT_ATTR  r2, r16
at_a0F:	AT_ATTR  r2, r17
at_a10:	AT_ATTR  r3,  r2
at_a11:	AT_ATTR  r3,  r3
at_a12:	AT_ATTR  r3,  r4
at_a13:	AT_ATTR  r3,  r5
at_a14:	AT_ATTR  r3,  r6
at_a15:	AT_ATTR  r3,  r7
at_a16:	AT_ATTR  r3,  r8
at_a17:	AT_ATTR  r3,  r9
at_a18:	AT_ATTR  r3, r10
at_a19:	AT_ATTR  r3, r11
at_a1A:	AT_ATTR  r3, r12
at_a1B:	AT_ATTR  r3, r13
at_a1C:	AT_ATTR  r3, r14
at_a1D:	AT_ATTR  r3, r15
at_a1E:	AT_ATTR  r3, r16
at_a1F:	AT_ATTR  r3, r17
at_a20:	AT_ATTR  r4,  r2
at_a21:	AT_ATTR  r4,  r3
at_a22:	AT_ATTR  r4,  r4
at_a23:	AT_ATTR  r4,  r5
at_a24:	AT_ATTR  r4,  r6
at_a25:	AT_ATTR  r4,  r7
at_a26:	AT_ATTR  r4,  r8
at_a27:	AT_ATTR  r4,  r9
at_a28:	AT_ATTR  r4, r10
at_a29:	AT_ATTR  r4, r11
at_a2A:	AT_ATTR  r4, r12
at_a2B:	AT_ATTR  r4, r13
at_a2C:	AT_ATTR  r4, r14
at_a2D:	AT_ATTR  r4, r15
at_a2E:	AT_ATTR  r4, r16
at_a2F:	AT_ATTR  r4, r17
at_a30:	AT_ATTR  r5,  r2
at_a31:	AT_ATTR  r5,  r3
at_a32:	AT_ATTR  r5,  r4
at_a33:	AT_ATTR  r5,  r5
at_a34:	AT_ATTR  r5,  r6
at_a35:	AT_ATTR  r5,  r7
at_a36:	AT_ATTR  r5,  r8
at_a37:	AT_ATTR  r5,  r9
at_a38:	AT_ATTR  r5, r10
at_a39:	AT_ATTR  r5, r11
at_a3A:	AT_ATTR  r5, r12
at_a3B:	AT_ATTR  r5, r13
at_a3C:	AT_ATTR  r5, r14
at_a3D:	AT_ATTR  r5, r15
at_a3E:	AT_ATTR  r5, r16
at_a3F:	AT_ATTR  r5, r17
at_a40:	AT_ATTR  r6,  r2
at_a41:	AT_ATTR  r6,  r3
at_a42:	AT_ATTR  r6,  r4
at_a43:	AT_ATTR  r6,  r5
at_a44:	AT_ATTR  r6,  r6
at_a45:	AT_ATTR  r6,  r7
at_a46:	AT_ATTR  r6,  r8
at_a47:	AT_ATTR  r6,  r9
at_a48:	AT_ATTR  r6, r10
at_a49:	AT_ATTR  r6, r11
at_a4A:	AT_ATTR  r6, r12
at_a4B:	AT_ATTR  r6, r13
at_a4C:	AT_ATTR  r6, r14
at_a4D:	AT_ATTR  r6, r15
at_a4E:	AT_ATTR  r6, r16
at_a4F:	AT_ATTR  r6, r17
at_a50:	AT_ATTR  r7,  r2
at_a51:	AT_ATTR  r7,  r3
at_a52:	AT_ATTR  r7,  r4
at_a53:	AT_ATTR  r7,  r5
at_a54:	AT_ATTR  r7,  r6
at_a55:	AT_ATTR  r7,  r7
at_a56:	AT_ATTR  r7,  r8
at_a57:	AT_ATTR  r7,  r9
at_a58:	AT_ATTR  r7, r10
at_a59:	AT_ATTR  r7, r11
at_a5A:	AT_ATTR  r7, r12
at_a5B:	AT_ATTR  r7, r13
at_a5C:	AT_ATTR  r7, r14
at_a5D:	AT_ATTR  r7, r15
at_a5E:	AT_ATTR  r7, r16
at_a5F:	AT_ATTR  r7, r17
at_a60:	AT_ATTR  r8,  r2
at_a61:	AT_ATTR  r8,  r3
at_a62:	AT_ATTR  r8,  r4
at_a63:	AT_ATTR  r8,  r5
at_a64:	AT_ATTR  r8,  r6
at_a65:	AT_ATTR  r8,  r7
at_a66:	AT_ATTR  r8,  r8
at_a67:	AT_ATTR  r8,  r9
at_a68:	AT_ATTR  r8, r10
at_a69:	AT_ATTR  r8, r11
at_a6A:	AT_ATTR  r8, r12
at_a6B:	AT_ATTR  r8, r13
at_a6C:	AT_ATTR  r8, r14
at_a6D:	AT_ATTR  r8, r15
at_a6E:	AT_ATTR  r8, r16
at_a6F:	AT_ATTR  r8, r17
at_a70:	AT_ATTR  r9,  r2
at_a71:	AT_ATTR  r9,  r3
at_a72:	AT_ATTR  r9,  r4
at_a73:	AT_ATTR  r9,  r5
at_a74:	AT_ATTR  r9,  r6
at_a75:	AT_ATTR  r9,  r7
at_a76:	AT_ATTR  r9,  r8
at_a77:	AT_ATTR  r9,  r9
at_a78:	AT_ATTR  r9, r10
at_a79:	AT_ATTR  r9, r11
at_a7A:	AT_ATTR  r9, r12
at_a7B:	AT_ATTR  r9, r13
at_a7C:	AT_ATTR  r9, r14
at_a7D:	AT_ATTR  r9, r15
at_a7E:	AT_ATTR  r9, r16
at_a7F:	AT_ATTR  r9, r17

.balign 512

;
; Attribute mode 0: 4bpp attributes
; - bits 0-3: Background color
; - bits 4-7: Foreground color
;
at_attr0_jt:
	rjmp  at_a00
	rjmp  at_a01
	rjmp  at_a02
	rjmp  at_a03
	rjmp  at_a04
	rjmp  at_a05
	rjmp  at_a06
	rjmp  at_a07
	rjmp  at_a08
	rjmp  at_a09
	rjmp  at_a0A
	rjmp  at_a0B
	rjmp  at_a0C
	rjmp  at_a0D
	rjmp  at_a0E
	rjmp  at_a0F
	rjmp  at_a10
	rjmp  at_a11
	rjmp  at_a12
	rjmp  at_a13
	rjmp  at_a14
	rjmp  at_a15
	rjmp  at_a16
	rjmp  at_a17
	rjmp  at_a18
	rjmp  at_a19
	rjmp  at_a1A
	rjmp  at_a1B
	rjmp  at_a1C
	rjmp  at_a1D
	rjmp  at_a1E
	rjmp  at_a1F
	rjmp  at_a20
	rjmp  at_a21
	rjmp  at_a22
	rjmp  at_a23
	rjmp  at_a24
	rjmp  at_a25
	rjmp  at_a26
	rjmp  at_a27
	rjmp  at_a28
	rjmp  at_a29
	rjmp  at_a2A
	rjmp  at_a2B
	rjmp  at_a2C
	rjmp  at_a2D
	rjmp  at_a2E
	rjmp  at_a2F
	rjmp  at_a30
	rjmp  at_a31
	rjmp  at_a32
	rjmp  at_a33
	rjmp  at_a34
	rjmp  at_a35
	rjmp  at_a36
	rjmp  at_a37
	rjmp  at_a38
	rjmp  at_a39
	rjmp  at_a3A
	rjmp  at_a3B
	rjmp  at_a3C
	rjmp  at_a3D
	rjmp  at_a3E
	rjmp  at_a3F
	rjmp  at_a40
	rjmp  at_a41
	rjmp  at_a42
	rjmp  at_a43
	rjmp  at_a44
	rjmp  at_a45
	rjmp  at_a46
	rjmp  at_a47
	rjmp  at_a48
	rjmp  at_a49
	rjmp  at_a4A
	rjmp  at_a4B
	rjmp  at_a4C
	rjmp  at_a4D
	rjmp  at_a4E
	rjmp  at_a4F
	rjmp  at_a50
	rjmp  at_a51
	rjmp  at_a52
	rjmp  at_a53
	rjmp  at_a54
	rjmp  at_a55
	rjmp  at_a56
	rjmp  at_a57
	rjmp  at_a58
	rjmp  at_a59
	rjmp  at_a5A
	rjmp  at_a5B
	rjmp  at_a5C
	rjmp  at_a5D
	rjmp  at_a5E
	rjmp  at_a5F
	rjmp  at_a60
	rjmp  at_a61
	rjmp  at_a62
	rjmp  at_a63
	rjmp  at_a64
	rjmp  at_a65
	rjmp  at_a66
	rjmp  at_a67
	rjmp  at_a68
	rjmp  at_a69
	rjmp  at_a6A
	rjmp  at_a6B
	rjmp  at_a6C
	rjmp  at_a6D
	rjmp  at_a6E
	rjmp  at_a6F
	rjmp  at_a70
	rjmp  at_a71
	rjmp  at_a72
	rjmp  at_a73
	rjmp  at_a74
	rjmp  at_a75
	rjmp  at_a76
	rjmp  at_a77
	rjmp  at_a78
	rjmp  at_a79
	rjmp  at_a7A
	rjmp  at_a7B
	rjmp  at_a7C
	rjmp  at_a7D
	rjmp  at_a7E
	rjmp  at_a7F
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a87
	rjmp  at_a88
	rjmp  at_a89
	rjmp  at_a8A
	rjmp  at_a8B
	rjmp  at_a8C
	rjmp  at_a8D
	rjmp  at_a8E
	rjmp  at_a8F
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a97
	rjmp  at_a98
	rjmp  at_a99
	rjmp  at_a9A
	rjmp  at_a9B
	rjmp  at_a9C
	rjmp  at_a9D
	rjmp  at_a9E
	rjmp  at_a9F
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_aA7
	rjmp  at_aA8
	rjmp  at_aA9
	rjmp  at_aAA
	rjmp  at_aAB
	rjmp  at_aAC
	rjmp  at_aAD
	rjmp  at_aAE
	rjmp  at_aAF
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_aB7
	rjmp  at_aB8
	rjmp  at_aB9
	rjmp  at_aBA
	rjmp  at_aBB
	rjmp  at_aBC
	rjmp  at_aBD
	rjmp  at_aBE
	rjmp  at_aBF
	rjmp  at_aC0
	rjmp  at_aC1
	rjmp  at_aC2
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_aC7
	rjmp  at_aC8
	rjmp  at_aC9
	rjmp  at_aCA
	rjmp  at_aCB
	rjmp  at_aCC
	rjmp  at_aCD
	rjmp  at_aCE
	rjmp  at_aCF
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_aD3
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_aD7
	rjmp  at_aD8
	rjmp  at_aD9
	rjmp  at_aDA
	rjmp  at_aDB
	rjmp  at_aDC
	rjmp  at_aDD
	rjmp  at_aDE
	rjmp  at_aDF
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_aE4
	rjmp  at_aE5
	rjmp  at_aE6
	rjmp  at_aE7
	rjmp  at_aE8
	rjmp  at_aE9
	rjmp  at_aEA
	rjmp  at_aEB
	rjmp  at_aEC
	rjmp  at_aED
	rjmp  at_aEE
	rjmp  at_aEF
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_aF8
	rjmp  at_aF9
	rjmp  at_aFA
	rjmp  at_aFB
	rjmp  at_aFC
	rjmp  at_aFD
	rjmp  at_aFE
	rjmp  at_aFF

;
; Attribute mode 1: 3bpp attributes
; - bits 0-2: Background color (palette indices  0- 7 available)
; - bit    3: Unused, free for non-attribute usage
; - bits 4-6: Foreground color (palette indices  8-15 available)
; - bit    7: Unused, free for non-attribute usage
;
at_attr1_jt:
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a87
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a87
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a97
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a97
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_aA7
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_aA7
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_aB7
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_aB7
	rjmp  at_aC0
	rjmp  at_aC1
	rjmp  at_aC2
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_aC7
	rjmp  at_aC0
	rjmp  at_aC1
	rjmp  at_aC2
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_aC7
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_aD3
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_aD7
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_aD3
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_aD7
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_aE4
	rjmp  at_aE5
	rjmp  at_aE6
	rjmp  at_aE7
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_aE4
	rjmp  at_aE5
	rjmp  at_aE6
	rjmp  at_aE7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a87
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a87
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a97
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a97
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_aA7
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_aA7
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_aB7
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_aB7
	rjmp  at_aC0
	rjmp  at_aC1
	rjmp  at_aC2
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_aC7
	rjmp  at_aC0
	rjmp  at_aC1
	rjmp  at_aC2
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_aC7
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_aD3
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_aD7
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_aD3
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_aD7
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_aE4
	rjmp  at_aE5
	rjmp  at_aE6
	rjmp  at_aE7
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_aE4
	rjmp  at_aE5
	rjmp  at_aE6
	rjmp  at_aE7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7

;
; Attribute mode 2: 3bpp attributes, special foreground
; - bits 0-2: Background color (palette indices  0- 7 available)
; - bit    3: Unused, free for non-attribute usage
; - bits 4-6: Foreground color (palette indices  8-15 available mostly)
; - bit    7: Unused, free for non-attribute usage
;
; Fg. color varies though as follows:
; - For Bg. color 7, Fg. colors 0-6 are used instead of Fg. colors 8-14. Color
;   15 remains (so no Bg. color = 7 & Fg. color = 7 case).
; - For Fg. colors 12, 13 and 14 some positions are replaced to provide a
;   Color 6 foreground option. The replacements are tailored for eliminating
;   less useful color combinations in a palette providing an additional
;   Foreground color instead.
;
; The overall intention is using Color 15 for sprites, then bright colors for
; Foreground and dark ones for background. Black should be color 7.
;
at_attr2_jt:
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a07
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a07
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a17
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a17
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_a27
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_a27
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_a37
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_a37
	rjmp  at_a60
	rjmp  at_a61
	rjmp  at_a62
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_a47
	rjmp  at_a60
	rjmp  at_a61
	rjmp  at_a62
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_a47
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_a63
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_a57
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_a63
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_a57
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_a64
	rjmp  at_a65
	rjmp  at_aE6
	rjmp  at_a67
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_a64
	rjmp  at_a65
	rjmp  at_aE6
	rjmp  at_a67
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a07
	rjmp  at_a80
	rjmp  at_a81
	rjmp  at_a82
	rjmp  at_a83
	rjmp  at_a84
	rjmp  at_a85
	rjmp  at_a86
	rjmp  at_a07
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a17
	rjmp  at_a90
	rjmp  at_a91
	rjmp  at_a92
	rjmp  at_a93
	rjmp  at_a94
	rjmp  at_a95
	rjmp  at_a96
	rjmp  at_a17
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_a27
	rjmp  at_aA0
	rjmp  at_aA1
	rjmp  at_aA2
	rjmp  at_aA3
	rjmp  at_aA4
	rjmp  at_aA5
	rjmp  at_aA6
	rjmp  at_a27
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_a37
	rjmp  at_aB0
	rjmp  at_aB1
	rjmp  at_aB2
	rjmp  at_aB3
	rjmp  at_aB4
	rjmp  at_aB5
	rjmp  at_aB6
	rjmp  at_a37
	rjmp  at_a60
	rjmp  at_a61
	rjmp  at_a62
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_a47
	rjmp  at_a60
	rjmp  at_a61
	rjmp  at_a62
	rjmp  at_aC3
	rjmp  at_aC4
	rjmp  at_aC5
	rjmp  at_aC6
	rjmp  at_a47
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_a63
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_a57
	rjmp  at_aD0
	rjmp  at_aD1
	rjmp  at_aD2
	rjmp  at_a63
	rjmp  at_aD4
	rjmp  at_aD5
	rjmp  at_aD6
	rjmp  at_a57
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_a64
	rjmp  at_a65
	rjmp  at_aE6
	rjmp  at_a67
	rjmp  at_aE0
	rjmp  at_aE1
	rjmp  at_aE2
	rjmp  at_aE3
	rjmp  at_a64
	rjmp  at_a65
	rjmp  at_aE6
	rjmp  at_a67
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7
	rjmp  at_aF0
	rjmp  at_aF1
	rjmp  at_aF2
	rjmp  at_aF3
	rjmp  at_aF4
	rjmp  at_aF5
	rjmp  at_aF6
	rjmp  at_aF7

at_a80:	AT_ATTR r10,  r2
at_a81:	AT_ATTR r10,  r3
at_a82:	AT_ATTR r10,  r4
at_a83:	AT_ATTR r10,  r5
at_a84:	AT_ATTR r10,  r6
at_a85:	AT_ATTR r10,  r7
at_a86:	AT_ATTR r10,  r8
at_a87:	AT_ATTR r10,  r9
at_a88:	AT_ATTR r10, r10
at_a89:	AT_ATTR r10, r11
at_a8A:	AT_ATTR r10, r12
at_a8B:	AT_ATTR r10, r13
at_a8C:	AT_ATTR r10, r14
at_a8D:	AT_ATTR r10, r15
at_a8E:	AT_ATTR r10, r16
at_a8F:	AT_ATTR r10, r17
at_a90:	AT_ATTR r11,  r2
at_a91:	AT_ATTR r11,  r3
at_a92:	AT_ATTR r11,  r4
at_a93:	AT_ATTR r11,  r5
at_a94:	AT_ATTR r11,  r6
at_a95:	AT_ATTR r11,  r7
at_a96:	AT_ATTR r11,  r8
at_a97:	AT_ATTR r11,  r9
at_a98:	AT_ATTR r11, r10
at_a99:	AT_ATTR r11, r11
at_a9A:	AT_ATTR r11, r12
at_a9B:	AT_ATTR r11, r13
at_a9C:	AT_ATTR r11, r14
at_a9D:	AT_ATTR r11, r15
at_a9E:	AT_ATTR r11, r16
at_a9F:	AT_ATTR r11, r17
at_aA0:	AT_ATTR r12,  r2
at_aA1:	AT_ATTR r12,  r3
at_aA2:	AT_ATTR r12,  r4
at_aA3:	AT_ATTR r12,  r5
at_aA4:	AT_ATTR r12,  r6
at_aA5:	AT_ATTR r12,  r7
at_aA6:	AT_ATTR r12,  r8
at_aA7:	AT_ATTR r12,  r9
at_aA8:	AT_ATTR r12, r10
at_aA9:	AT_ATTR r12, r11
at_aAA:	AT_ATTR r12, r12
at_aAB:	AT_ATTR r12, r13
at_aAC:	AT_ATTR r12, r14
at_aAD:	AT_ATTR r12, r15
at_aAE:	AT_ATTR r12, r16
at_aAF:	AT_ATTR r12, r17
at_aB0:	AT_ATTR r13,  r2
at_aB1:	AT_ATTR r13,  r3
at_aB2:	AT_ATTR r13,  r4
at_aB3:	AT_ATTR r13,  r5
at_aB4:	AT_ATTR r13,  r6
at_aB5:	AT_ATTR r13,  r7
at_aB6:	AT_ATTR r13,  r8
at_aB7:	AT_ATTR r13,  r9
at_aB8:	AT_ATTR r13, r10
at_aB9:	AT_ATTR r13, r11
at_aBA:	AT_ATTR r13, r12
at_aBB:	AT_ATTR r13, r13
at_aBC:	AT_ATTR r13, r14
at_aBD:	AT_ATTR r13, r15
at_aBE:	AT_ATTR r13, r16
at_aBF:	AT_ATTR r13, r17
at_aC0:	AT_ATTR r14,  r2
at_aC1:	AT_ATTR r14,  r3
at_aC2:	AT_ATTR r14,  r4
at_aC3:	AT_ATTR r14,  r5
at_aC4:	AT_ATTR r14,  r6
at_aC5:	AT_ATTR r14,  r7
at_aC6:	AT_ATTR r14,  r8
at_aC7:	AT_ATTR r14,  r9
at_aC8:	AT_ATTR r14, r10
at_aC9:	AT_ATTR r14, r11
at_aCA:	AT_ATTR r14, r12
at_aCB:	AT_ATTR r14, r13
at_aCC:	AT_ATTR r14, r14
at_aCD:	AT_ATTR r14, r15
at_aCE:	AT_ATTR r14, r16
at_aCF:	AT_ATTR r14, r17
at_aD0:	AT_ATTR r15,  r2
at_aD1:	AT_ATTR r15,  r3
at_aD2:	AT_ATTR r15,  r4
at_aD3:	AT_ATTR r15,  r5
at_aD4:	AT_ATTR r15,  r6
at_aD5:	AT_ATTR r15,  r7
at_aD6:	AT_ATTR r15,  r8
at_aD7:	AT_ATTR r15,  r9
at_aD8:	AT_ATTR r15, r10
at_aD9:	AT_ATTR r15, r11
at_aDA:	AT_ATTR r15, r12
at_aDB:	AT_ATTR r15, r13
at_aDC:	AT_ATTR r15, r14
at_aDD:	AT_ATTR r15, r15
at_aDE:	AT_ATTR r15, r16
at_aDF:	AT_ATTR r15, r17
at_aE0:	AT_ATTR r16,  r2
at_aE1:	AT_ATTR r16,  r3
at_aE2:	AT_ATTR r16,  r4
at_aE3:	AT_ATTR r16,  r5
at_aE4:	AT_ATTR r16,  r6
at_aE5:	AT_ATTR r16,  r7
at_aE6:	AT_ATTR r16,  r8
at_aE7:	AT_ATTR r16,  r9
at_aE8:	AT_ATTR r16, r10
at_aE9:	AT_ATTR r16, r11
at_aEA:	AT_ATTR r16, r12
at_aEB:	AT_ATTR r16, r13
at_aEC:	AT_ATTR r16, r14
at_aED:	AT_ATTR r16, r15
at_aEE:	AT_ATTR r16, r16
at_aEF:	AT_ATTR r16, r17
at_aF0:	AT_ATTR r17,  r2
at_aF1:	AT_ATTR r17,  r3
at_aF2:	AT_ATTR r17,  r4
at_aF3:	AT_ATTR r17,  r5
at_aF4:	AT_ATTR r17,  r6
at_aF5:	AT_ATTR r17,  r7
at_aF6:	AT_ATTR r17,  r8
at_aF7:	AT_ATTR r17,  r9
at_aF8:	AT_ATTR r17, r10
at_aF9:	AT_ATTR r17, r11
at_aFA:	AT_ATTR r17, r12
at_aFB:	AT_ATTR r17, r13
at_aFC:	AT_ATTR r17, r14
at_aFD:	AT_ATTR r17, r15
at_aFE:	AT_ATTR r17, r16
at_aFF:	AT_ATTR r17, r17

.balign 512

at_head_jt:
	rjmp  at_h00
	rjmp  at_h01
	rjmp  at_h02
	rjmp  at_h03
	rjmp  at_h04
	rjmp  at_h05
	rjmp  at_h06
	rjmp  at_h07
	rjmp  at_h08
	rjmp  at_h09
	rjmp  at_h0A
	rjmp  at_h0B
	rjmp  at_h0C
	rjmp  at_h0D
	rjmp  at_h0E
	rjmp  at_h0F
	rjmp  at_h10
	rjmp  at_h11
	rjmp  at_h12
	rjmp  at_h13
	rjmp  at_h14
	rjmp  at_h15
	rjmp  at_h16
	rjmp  at_h17
	rjmp  at_h18
	rjmp  at_h19
	rjmp  at_h1A
	rjmp  at_h1B
	rjmp  at_h1C
	rjmp  at_h1D
	rjmp  at_h1E
	rjmp  at_h1F
	rjmp  at_h20
	rjmp  at_h21
	rjmp  at_h22
	rjmp  at_h23
	rjmp  at_h24
	rjmp  at_h25
	rjmp  at_h26
	rjmp  at_h27
	rjmp  at_h28
	rjmp  at_h29
	rjmp  at_h2A
	rjmp  at_h2B
	rjmp  at_h2C
	rjmp  at_h2D
	rjmp  at_h2E
	rjmp  at_h2F
	rjmp  at_h30
	rjmp  at_h31
	rjmp  at_h32
	rjmp  at_h33
	rjmp  at_h34
	rjmp  at_h35
	rjmp  at_h36
	rjmp  at_h37
	rjmp  at_h38
	rjmp  at_h39
	rjmp  at_h3A
	rjmp  at_h3B
	rjmp  at_h3C
	rjmp  at_h3D
	rjmp  at_h3E
	rjmp  at_h3F
	rjmp  at_h40
	rjmp  at_h41
	rjmp  at_h42
	rjmp  at_h43
	rjmp  at_h44
	rjmp  at_h45
	rjmp  at_h46
	rjmp  at_h47
	rjmp  at_h48
	rjmp  at_h49
	rjmp  at_h4A
	rjmp  at_h4B
	rjmp  at_h4C
	rjmp  at_h4D
	rjmp  at_h4E
	rjmp  at_h4F
	rjmp  at_h50
	rjmp  at_h51
	rjmp  at_h52
	rjmp  at_h53
	rjmp  at_h54
	rjmp  at_h55
	rjmp  at_h56
	rjmp  at_h57
	rjmp  at_h58
	rjmp  at_h59
	rjmp  at_h5A
	rjmp  at_h5B
	rjmp  at_h5C
	rjmp  at_h5D
	rjmp  at_h5E
	rjmp  at_h5F
	rjmp  at_h60
	rjmp  at_h61
	rjmp  at_h62
	rjmp  at_h63
	rjmp  at_h64
	rjmp  at_h65
	rjmp  at_h66
	rjmp  at_h67
	rjmp  at_h68
	rjmp  at_h69
	rjmp  at_h6A
	rjmp  at_h6B
	rjmp  at_h6C
	rjmp  at_h6D
	rjmp  at_h6E
	rjmp  at_h6F
	rjmp  at_h70
	rjmp  at_h71
	rjmp  at_h72
	rjmp  at_h73
	rjmp  at_h74
	rjmp  at_h75
	rjmp  at_h76
	rjmp  at_h77
	rjmp  at_h78
	rjmp  at_h79
	rjmp  at_h7A
	rjmp  at_h7B
	rjmp  at_h7C
	rjmp  at_h7D
	rjmp  at_h7E
	rjmp  at_h7F
	rjmp  at_h80
	rjmp  at_h81
	rjmp  at_h82
	rjmp  at_h83
	rjmp  at_h84
	rjmp  at_h85
	rjmp  at_h86
	rjmp  at_h87
	rjmp  at_h88
	rjmp  at_h89
	rjmp  at_h8A
	rjmp  at_h8B
	rjmp  at_h8C
	rjmp  at_h8D
	rjmp  at_h8E
	rjmp  at_h8F
	rjmp  at_h90
	rjmp  at_h91
	rjmp  at_h92
	rjmp  at_h93
	rjmp  at_h94
	rjmp  at_h95
	rjmp  at_h96
	rjmp  at_h97
	rjmp  at_h98
	rjmp  at_h99
	rjmp  at_h9A
	rjmp  at_h9B
	rjmp  at_h9C
	rjmp  at_h9D
	rjmp  at_h9E
	rjmp  at_h9F
	rjmp  at_hA0
	rjmp  at_hA1
	rjmp  at_hA2
	rjmp  at_hA3
	rjmp  at_hA4
	rjmp  at_hA5
	rjmp  at_hA6
	rjmp  at_hA7
	rjmp  at_hA8
	rjmp  at_hA9
	rjmp  at_hAA
	rjmp  at_hAB
	rjmp  at_hAC
	rjmp  at_hAD
	rjmp  at_hAE
	rjmp  at_hAF
	rjmp  at_hB0
	rjmp  at_hB1
	rjmp  at_hB2
	rjmp  at_hB3
	rjmp  at_hB4
	rjmp  at_hB5
	rjmp  at_hB6
	rjmp  at_hB7
	rjmp  at_hB8
	rjmp  at_hB9
	rjmp  at_hBA
	rjmp  at_hBB
	rjmp  at_hBC
	rjmp  at_hBD
	rjmp  at_hBE
	rjmp  at_hBF
	rjmp  at_hC0
	rjmp  at_hC1
	rjmp  at_hC2
	rjmp  at_hC3
	rjmp  at_hC4
	rjmp  at_hC5
	rjmp  at_hC6
	rjmp  at_hC7
	rjmp  at_hC8
	rjmp  at_hC9
	rjmp  at_hCA
	rjmp  at_hCB
	rjmp  at_hCC
	rjmp  at_hCD
	rjmp  at_hCE
	rjmp  at_hCF
	rjmp  at_hD0
	rjmp  at_hD1
	rjmp  at_hD2
	rjmp  at_hD3
	rjmp  at_hD4
	rjmp  at_hD5
	rjmp  at_hD6
	rjmp  at_hD7
	rjmp  at_hD8
	rjmp  at_hD9
	rjmp  at_hDA
	rjmp  at_hDB
	rjmp  at_hDC
	rjmp  at_hDD
	rjmp  at_hDE
	rjmp  at_hDF
	rjmp  at_hE0
	rjmp  at_hE1
	rjmp  at_hE2
	rjmp  at_hE3
	rjmp  at_hE4
	rjmp  at_hE5
	rjmp  at_hE6
	rjmp  at_hE7
	rjmp  at_hE8
	rjmp  at_hE9
	rjmp  at_hEA
	rjmp  at_hEB
	rjmp  at_hEC
	rjmp  at_hED
	rjmp  at_hEE
	rjmp  at_hEF
	rjmp  at_hF0
	rjmp  at_hF1
	rjmp  at_hF2
	rjmp  at_hF3
	rjmp  at_hF4
	rjmp  at_hF5
	rjmp  at_hF6
	rjmp  at_hF7
	rjmp  at_hF8
	rjmp  at_hF9
	rjmp  at_hFA
	rjmp  at_hFB
	rjmp  at_hFC
	rjmp  at_hFD
	rjmp  at_hFE
	rjmp  at_hFF

at_h00:	AT_HEAD r18, r18, r18, r18, at_m0, at_e00
at_h01:	AT_HEAD r19, r18, r18, r18, at_m0, at_e00
at_h02:	AT_HEAD r18, r19, r18, r18, at_m0, at_e02
at_h03:	AT_HEAD r19, r19, r18, r18, at_m0, at_e02
at_h80:	AT_HDMW r18, at_w80
at_h81:	AT_HDMW r19, at_w80
at_h82:	AT_HDMW r18, at_w82
at_h83:	AT_HDMW r19, at_w82
at_e00:	AT_EXTH r18, r18, at_x0
at_e02:	AT_EXTH r19, r18, at_x0
at_h40:	AT_HEAD r18, r18, r19, r18, at_m0, at_e40
at_h41:	AT_HEAD r19, r18, r19, r18, at_m0, at_e40
at_h42:	AT_HEAD r18, r19, r19, r18, at_m0, at_e42
at_h43:	AT_HEAD r19, r19, r19, r18, at_m0, at_e42
at_hC0:	AT_HEAD r18, r18, r19, r19, at_m0, at_e40
at_hC1:	AT_HEAD r19, r18, r19, r19, at_m0, at_e40
at_hC2:	AT_HEAD r18, r19, r19, r19, at_m0, at_e42
at_hC3:	AT_HEAD r19, r19, r19, r19, at_m0, at_e42
at_e40:	AT_EXTH r18, r19, at_x0
at_e42:	AT_EXTH r19, r19, at_x0

at_h04:	AT_HEAD r18, r18, r18, r18, at_m1, at_e04
at_h05:	AT_HEAD r19, r18, r18, r18, at_m1, at_e04
at_h06:	AT_HEAD r18, r19, r18, r18, at_m1, at_e06
at_h07:	AT_HEAD r19, r19, r18, r18, at_m1, at_e06
at_h84:	AT_HDMW r18, at_w84
at_h85:	AT_HDMW r19, at_w84
at_h86:	AT_HDMW r18, at_w86
at_h87:	AT_HDMW r19, at_w86
at_e04:	AT_EXTH r18, r18, at_x1
at_e06:	AT_EXTH r19, r18, at_x1
at_h44:	AT_HEAD r18, r18, r19, r18, at_m1, at_e44
at_h45:	AT_HEAD r19, r18, r19, r18, at_m1, at_e44
at_h46:	AT_HEAD r18, r19, r19, r18, at_m1, at_e46
at_h47:	AT_HEAD r19, r19, r19, r18, at_m1, at_e46
at_hC4:	AT_HEAD r18, r18, r19, r19, at_m1, at_e44
at_hC5:	AT_HEAD r19, r18, r19, r19, at_m1, at_e44
at_hC6:	AT_HEAD r18, r19, r19, r19, at_m1, at_e46
at_hC7:	AT_HEAD r19, r19, r19, r19, at_m1, at_e46
at_e44:	AT_EXTH r18, r19, at_x1
at_e46:	AT_EXTH r19, r19, at_x1

at_h08:	AT_HEAD r18, r18, r18, r18, at_m2, at_e08
at_h09:	AT_HEAD r19, r18, r18, r18, at_m2, at_e08
at_h0A:	AT_HEAD r18, r19, r18, r18, at_m2, at_e0A
at_h0B:	AT_HEAD r19, r19, r18, r18, at_m2, at_e0A
at_h88:	AT_HDMW r18, at_w88
at_h89:	AT_HDMW r19, at_w88
at_h8A:	AT_HDMW r18, at_w8A
at_h8B:	AT_HDMW r19, at_w8A
at_e08:	AT_EXTH r18, r18, at_x2
at_e0A:	AT_EXTH r19, r18, at_x2
at_h48:	AT_HEAD r18, r18, r19, r18, at_m2, at_e48
at_h49:	AT_HEAD r19, r18, r19, r18, at_m2, at_e48
at_h4A:	AT_HEAD r18, r19, r19, r18, at_m2, at_e4A
at_h4B:	AT_HEAD r19, r19, r19, r18, at_m2, at_e4A
at_hC8:	AT_HEAD r18, r18, r19, r19, at_m2, at_e48
at_hC9:	AT_HEAD r19, r18, r19, r19, at_m2, at_e48
at_hCA:	AT_HEAD r18, r19, r19, r19, at_m2, at_e4A
at_hCB:	AT_HEAD r19, r19, r19, r19, at_m2, at_e4A
at_e48:	AT_EXTH r18, r19, at_x2
at_e4A:	AT_EXTH r19, r19, at_x2

at_h0C:	AT_HEAD r18, r18, r18, r18, at_m3, at_e0C
at_h0D:	AT_HEAD r19, r18, r18, r18, at_m3, at_e0C
at_h0E:	AT_HEAD r18, r19, r18, r18, at_m3, at_e0E
at_h0F:	AT_HEAD r19, r19, r18, r18, at_m3, at_e0E
at_h8C:	AT_HDMW r18, at_w8C
at_h8D:	AT_HDMW r19, at_w8C
at_h8E:	AT_HDMW r18, at_w8E
at_h8F:	AT_HDMW r19, at_w8E
at_e0C:	AT_EXTH r18, r18, at_x3
at_e0E:	AT_EXTH r19, r18, at_x3
at_h4C:	AT_HEAD r18, r18, r19, r18, at_m3, at_e4C
at_h4D:	AT_HEAD r19, r18, r19, r18, at_m3, at_e4C
at_h4E:	AT_HEAD r18, r19, r19, r18, at_m3, at_e4E
at_h4F:	AT_HEAD r19, r19, r19, r18, at_m3, at_e4E
at_hCC:	AT_HEAD r18, r18, r19, r19, at_m3, at_e4C
at_hCD:	AT_HEAD r19, r18, r19, r19, at_m3, at_e4C
at_hCE:	AT_HEAD r18, r19, r19, r19, at_m3, at_e4E
at_hCF:	AT_HEAD r19, r19, r19, r19, at_m3, at_e4E
at_e4C:	AT_EXTH r18, r19, at_x3
at_e4E:	AT_EXTH r19, r19, at_x3

at_h10:	AT_HEAD r18, r18, r18, r18, at_m4, at_e10
at_h11:	AT_HEAD r19, r18, r18, r18, at_m4, at_e10
at_h12:	AT_HEAD r18, r19, r18, r18, at_m4, at_e12
at_h13:	AT_HEAD r19, r19, r18, r18, at_m4, at_e12
at_h90:	AT_HDMW r18, at_w90
at_h91:	AT_HDMW r19, at_w90
at_h92:	AT_HDMW r18, at_w92
at_h93:	AT_HDMW r19, at_w92
at_e10:	AT_EXTH r18, r18, at_x4
at_e12:	AT_EXTH r19, r18, at_x4
at_h50:	AT_HEAD r18, r18, r19, r18, at_m4, at_e50
at_h51:	AT_HEAD r19, r18, r19, r18, at_m4, at_e50
at_h52:	AT_HEAD r18, r19, r19, r18, at_m4, at_e52
at_h53:	AT_HEAD r19, r19, r19, r18, at_m4, at_e52
at_hD0:	AT_HEAD r18, r18, r19, r19, at_m4, at_e50
at_hD1:	AT_HEAD r19, r18, r19, r19, at_m4, at_e50
at_hD2:	AT_HEAD r18, r19, r19, r19, at_m4, at_e52
at_hD3:	AT_HEAD r19, r19, r19, r19, at_m4, at_e52
at_e50:	AT_EXTH r18, r19, at_x4
at_e52:	AT_EXTH r19, r19, at_x4

at_h14:	AT_HEAD r18, r18, r18, r18, at_m5, at_e14
at_h15:	AT_HEAD r19, r18, r18, r18, at_m5, at_e14
at_h16:	AT_HEAD r18, r19, r18, r18, at_m5, at_e16
at_h17:	AT_HEAD r19, r19, r18, r18, at_m5, at_e16
at_h94:	AT_HDMW r18, at_w94
at_h95:	AT_HDMW r19, at_w94
at_h96:	AT_HDMW r18, at_w96
at_h97:	AT_HDMW r19, at_w96
at_e14:	AT_EXTH r18, r18, at_x5
at_e16:	AT_EXTH r19, r18, at_x5
at_h54:	AT_HEAD r18, r18, r19, r18, at_m5, at_e54
at_h55:	AT_HEAD r19, r18, r19, r18, at_m5, at_e54
at_h56:	AT_HEAD r18, r19, r19, r18, at_m5, at_e56
at_h57:	AT_HEAD r19, r19, r19, r18, at_m5, at_e56
at_hD4:	AT_HEAD r18, r18, r19, r19, at_m5, at_e54
at_hD5:	AT_HEAD r19, r18, r19, r19, at_m5, at_e54
at_hD6:	AT_HEAD r18, r19, r19, r19, at_m5, at_e56
at_hD7:	AT_HEAD r19, r19, r19, r19, at_m5, at_e56
at_e54:	AT_EXTH r18, r19, at_x5
at_e56:	AT_EXTH r19, r19, at_x5

at_h18:	AT_HEAD r18, r18, r18, r18, at_m6, at_e18
at_h19:	AT_HEAD r19, r18, r18, r18, at_m6, at_e18
at_h1A:	AT_HEAD r18, r19, r18, r18, at_m6, at_e1A
at_h1B:	AT_HEAD r19, r19, r18, r18, at_m6, at_e1A
at_h98:	AT_HDMW r18, at_w98
at_h99:	AT_HDMW r19, at_w98
at_h9A:	AT_HDMW r18, at_w9A
at_h9B:	AT_HDMW r19, at_w9A
at_e18:	AT_EXTH r18, r18, at_x6
at_e1A:	AT_EXTH r19, r18, at_x6
at_h58:	AT_HEAD r18, r18, r19, r18, at_m6, at_e58
at_h59:	AT_HEAD r19, r18, r19, r18, at_m6, at_e58
at_h5A:	AT_HEAD r18, r19, r19, r18, at_m6, at_e5A
at_h5B:	AT_HEAD r19, r19, r19, r18, at_m6, at_e5A
at_hD8:	AT_HEAD r18, r18, r19, r19, at_m6, at_e58
at_hD9:	AT_HEAD r19, r18, r19, r19, at_m6, at_e58
at_hDA:	AT_HEAD r18, r19, r19, r19, at_m6, at_e5A
at_hDB:	AT_HEAD r19, r19, r19, r19, at_m6, at_e5A
at_e58:	AT_EXTH r18, r19, at_x6
at_e5A:	AT_EXTH r19, r19, at_x6

at_h1C:	AT_HEAD r18, r18, r18, r18, at_m7, at_e1C
at_h1D:	AT_HEAD r19, r18, r18, r18, at_m7, at_e1C
at_h1E:	AT_HEAD r18, r19, r18, r18, at_m7, at_e1E
at_h1F:	AT_HEAD r19, r19, r18, r18, at_m7, at_e1E
at_h9C:	AT_HDMW r18, at_w9C
at_h9D:	AT_HDMW r19, at_w9C
at_h9E:	AT_HDMW r18, at_w9E
at_h9F:	AT_HDMW r19, at_w9E
at_e1C:	AT_EXTH r18, r18, at_x7
at_e1E:	AT_EXTH r19, r18, at_x7
at_h5C:	AT_HEAD r18, r18, r19, r18, at_m7, at_e5C
at_h5D:	AT_HEAD r19, r18, r19, r18, at_m7, at_e5C
at_h5E:	AT_HEAD r18, r19, r19, r18, at_m7, at_e5E
at_h5F:	AT_HEAD r19, r19, r19, r18, at_m7, at_e5E
at_hDC:	AT_HEAD r18, r18, r19, r19, at_m7, at_e5C
at_hDD:	AT_HEAD r19, r18, r19, r19, at_m7, at_e5C
at_hDE:	AT_HEAD r18, r19, r19, r19, at_m7, at_e5E
at_hDF:	AT_HEAD r19, r19, r19, r19, at_m7, at_e5E
at_e5C:	AT_EXTH r18, r19, at_x7
at_e5E:	AT_EXTH r19, r19, at_x7

at_h20:	AT_HEAD r18, r18, r18, r18, at_m8, at_e20
at_h21:	AT_HEAD r19, r18, r18, r18, at_m8, at_e20
at_h22:	AT_HEAD r18, r19, r18, r18, at_m8, at_e22
at_h23:	AT_HEAD r19, r19, r18, r18, at_m8, at_e22
at_hA0:	AT_HDMW r18, at_wA0
at_hA1:	AT_HDMW r19, at_wA0
at_hA2:	AT_HDMW r18, at_wA2
at_hA3:	AT_HDMW r19, at_wA2
at_e20:	AT_EXTH r18, r18, at_x8
at_e22:	AT_EXTH r19, r18, at_x8
at_h60:	AT_HEAD r18, r18, r19, r18, at_m8, at_e60
at_h61:	AT_HEAD r19, r18, r19, r18, at_m8, at_e60
at_h62:	AT_HEAD r18, r19, r19, r18, at_m8, at_e62
at_h63:	AT_HEAD r19, r19, r19, r18, at_m8, at_e62
at_hE0:	AT_HEAD r18, r18, r19, r19, at_m8, at_e60
at_hE1:	AT_HEAD r19, r18, r19, r19, at_m8, at_e60
at_hE2:	AT_HEAD r18, r19, r19, r19, at_m8, at_e62
at_hE3:	AT_HEAD r19, r19, r19, r19, at_m8, at_e62
at_e60:	AT_EXTH r18, r19, at_x8
at_e62:	AT_EXTH r19, r19, at_x8

at_h24:	AT_HEAD r18, r18, r18, r18, at_m9, at_e24
at_h25:	AT_HEAD r19, r18, r18, r18, at_m9, at_e24
at_h26:	AT_HEAD r18, r19, r18, r18, at_m9, at_e26
at_h27:	AT_HEAD r19, r19, r18, r18, at_m9, at_e26
at_hA4:	AT_HDMW r18, at_wA4
at_hA5:	AT_HDMW r19, at_wA4
at_hA6:	AT_HDMW r18, at_wA6
at_hA7:	AT_HDMW r19, at_wA6
at_e24:	AT_EXTH r18, r18, at_x9
at_e26:	AT_EXTH r19, r18, at_x9
at_h64:	AT_HEAD r18, r18, r19, r18, at_m9, at_e64
at_h65:	AT_HEAD r19, r18, r19, r18, at_m9, at_e64
at_h66:	AT_HEAD r18, r19, r19, r18, at_m9, at_e66
at_h67:	AT_HEAD r19, r19, r19, r18, at_m9, at_e66
at_hE4:	AT_HEAD r18, r18, r19, r19, at_m9, at_e64
at_hE5:	AT_HEAD r19, r18, r19, r19, at_m9, at_e64
at_hE6:	AT_HEAD r18, r19, r19, r19, at_m9, at_e66
at_hE7:	AT_HEAD r19, r19, r19, r19, at_m9, at_e66
at_e64:	AT_EXTH r18, r19, at_x9
at_e66:	AT_EXTH r19, r19, at_x9

at_h28:	AT_HEAD r18, r18, r18, r18, at_mA, at_e28
at_h29:	AT_HEAD r19, r18, r18, r18, at_mA, at_e28
at_h2A:	AT_HEAD r18, r19, r18, r18, at_mA, at_e2A
at_h2B:	AT_HEAD r19, r19, r18, r18, at_mA, at_e2A
at_hA8:	AT_HDMW r18, at_wA8
at_hA9:	AT_HDMW r19, at_wA8
at_hAA:	AT_HDMW r18, at_wAA
at_hAB:	AT_HDMW r19, at_wAA
at_e28:	AT_EXTH r18, r18, at_xA
at_e2A:	AT_EXTH r19, r18, at_xA
at_h68:	AT_HEAD r18, r18, r19, r18, at_mA, at_e68
at_h69:	AT_HEAD r19, r18, r19, r18, at_mA, at_e68
at_h6A:	AT_HEAD r18, r19, r19, r18, at_mA, at_e6A
at_h6B:	AT_HEAD r19, r19, r19, r18, at_mA, at_e6A
at_hE8:	AT_HEAD r18, r18, r19, r19, at_mA, at_e68
at_hE9:	AT_HEAD r19, r18, r19, r19, at_mA, at_e68
at_hEA:	AT_HEAD r18, r19, r19, r19, at_mA, at_e6A
at_hEB:	AT_HEAD r19, r19, r19, r19, at_mA, at_e6A
at_e68:	AT_EXTH r18, r19, at_xA
at_e6A:	AT_EXTH r19, r19, at_xA

at_h2C:	AT_HEAD r18, r18, r18, r18, at_mB, at_e2C
at_h2D:	AT_HEAD r19, r18, r18, r18, at_mB, at_e2C
at_h2E:	AT_HEAD r18, r19, r18, r18, at_mB, at_e2E
at_h2F:	AT_HEAD r19, r19, r18, r18, at_mB, at_e2E
at_hAC:	AT_HDMW r18, at_wAC
at_hAD:	AT_HDMW r19, at_wAC
at_hAE:	AT_HDMW r18, at_wAE
at_hAF:	AT_HDMW r19, at_wAE
at_e2C:	AT_EXTH r18, r18, at_xB
at_e2E:	AT_EXTH r19, r18, at_xB
at_h6C:	AT_HEAD r18, r18, r19, r18, at_mB, at_e6C
at_h6D:	AT_HEAD r19, r18, r19, r18, at_mB, at_e6C
at_h6E:	AT_HEAD r18, r19, r19, r18, at_mB, at_e6E
at_h6F:	AT_HEAD r19, r19, r19, r18, at_mB, at_e6E
at_hEC:	AT_HEAD r18, r18, r19, r19, at_mB, at_e6C
at_hED:	AT_HEAD r19, r18, r19, r19, at_mB, at_e6C
at_hEE:	AT_HEAD r18, r19, r19, r19, at_mB, at_e6E
at_hEF:	AT_HEAD r19, r19, r19, r19, at_mB, at_e6E
at_e6C:	AT_EXTH r18, r19, at_xB
at_e6E:	AT_EXTH r19, r19, at_xB

at_h30:	AT_HEAD r18, r18, r18, r18, at_mC, at_e30
at_h31:	AT_HEAD r19, r18, r18, r18, at_mC, at_e30
at_h32:	AT_HEAD r18, r19, r18, r18, at_mC, at_e32
at_h33:	AT_HEAD r19, r19, r18, r18, at_mC, at_e32
at_hB0:	AT_HDMW r18, at_wB0
at_hB1:	AT_HDMW r19, at_wB0
at_hB2:	AT_HDMW r18, at_wB2
at_hB3:	AT_HDMW r19, at_wB2
at_e30:	AT_EXTH r18, r18, at_xC
at_e32:	AT_EXTH r19, r18, at_xC
at_h70:	AT_HEAD r18, r18, r19, r18, at_mC, at_e70
at_h71:	AT_HEAD r19, r18, r19, r18, at_mC, at_e70
at_h72:	AT_HEAD r18, r19, r19, r18, at_mC, at_e72
at_h73:	AT_HEAD r19, r19, r19, r18, at_mC, at_e72
at_hF0:	AT_HEAD r18, r18, r19, r19, at_mC, at_e70
at_hF1:	AT_HEAD r19, r18, r19, r19, at_mC, at_e70
at_hF2:	AT_HEAD r18, r19, r19, r19, at_mC, at_e72
at_hF3:	AT_HEAD r19, r19, r19, r19, at_mC, at_e72
at_e70:	AT_EXTH r18, r19, at_xC
at_e72:	AT_EXTH r19, r19, at_xC

at_h34:	AT_HEAD r18, r18, r18, r18, at_mD, at_e34
at_h35:	AT_HEAD r19, r18, r18, r18, at_mD, at_e34
at_h36:	AT_HEAD r18, r19, r18, r18, at_mD, at_e36
at_h37:	AT_HEAD r19, r19, r18, r18, at_mD, at_e36
at_hB4:	AT_HDMW r18, at_wB4
at_hB5:	AT_HDMW r19, at_wB4
at_hB6:	AT_HDMW r18, at_wB6
at_hB7:	AT_HDMW r19, at_wB6
at_e34:	AT_EXTH r18, r18, at_xD
at_e36:	AT_EXTH r19, r18, at_xD
at_h74:	AT_HEAD r18, r18, r19, r18, at_mD, at_e74
at_h75:	AT_HEAD r19, r18, r19, r18, at_mD, at_e74
at_h76:	AT_HEAD r18, r19, r19, r18, at_mD, at_e76
at_h77:	AT_HEAD r19, r19, r19, r18, at_mD, at_e76
at_hF4:	AT_HEAD r18, r18, r19, r19, at_mD, at_e74
at_hF5:	AT_HEAD r19, r18, r19, r19, at_mD, at_e74
at_hF6:	AT_HEAD r18, r19, r19, r19, at_mD, at_e76
at_hF7:	AT_HEAD r19, r19, r19, r19, at_mD, at_e76
at_e74:	AT_EXTH r18, r19, at_xD
at_e76:	AT_EXTH r19, r19, at_xD

at_h38:	AT_HEAD r18, r18, r18, r18, at_mE, at_e38
at_h39:	AT_HEAD r19, r18, r18, r18, at_mE, at_e38
at_h3A:	AT_HEAD r18, r19, r18, r18, at_mE, at_e3A
at_h3B:	AT_HEAD r19, r19, r18, r18, at_mE, at_e3A
at_hB8:	AT_HDMW r18, at_wB8
at_hB9:	AT_HDMW r19, at_wB8
at_hBA:	AT_HDMW r18, at_wBA
at_hBB:	AT_HDMW r19, at_wBA
at_e38:	AT_EXTH r18, r18, at_xE
at_e3A:	AT_EXTH r19, r18, at_xE
at_h78:	AT_HEAD r18, r18, r19, r18, at_mE, at_e78
at_h79:	AT_HEAD r19, r18, r19, r18, at_mE, at_e78
at_h7A:	AT_HEAD r18, r19, r19, r18, at_mE, at_e7A
at_h7B:	AT_HEAD r19, r19, r19, r18, at_mE, at_e7A
at_hF8:	AT_HEAD r18, r18, r19, r19, at_mE, at_e78
at_hF9:	AT_HEAD r19, r18, r19, r19, at_mE, at_e78
at_hFA:	AT_HEAD r18, r19, r19, r19, at_mE, at_e7A
at_hFB:	AT_HEAD r19, r19, r19, r19, at_mE, at_e7A
at_e78:	AT_EXTH r18, r19, at_xE
at_e7A:	AT_EXTH r19, r19, at_xE

at_h3C:	AT_HEAD r18, r18, r18, r18, at_mF, at_e3C
at_h3D:	AT_HEAD r19, r18, r18, r18, at_mF, at_e3C
at_h3E:	AT_HEAD r18, r19, r18, r18, at_mF, at_e3E
at_h3F:	AT_HEAD r19, r19, r18, r18, at_mF, at_e3E
at_hBC:	AT_HDMW r18, at_wBC
at_hBD:	AT_HDMW r19, at_wBC
at_hBE:	AT_HDMW r18, at_wBE
at_hBF:	AT_HDMW r19, at_wBE
at_e3C:	AT_EXTH r18, r18, at_xF
at_e3E:	AT_EXTH r19, r18, at_xF
at_h7C:	AT_HEAD r18, r18, r19, r18, at_mF, at_e7C
at_h7D:	AT_HEAD r19, r18, r19, r18, at_mF, at_e7C
at_h7E:	AT_HEAD r18, r19, r19, r18, at_mF, at_e7E
at_h7F:	AT_HEAD r19, r19, r19, r18, at_mF, at_e7E
at_hFC:	AT_HEAD r18, r18, r19, r19, at_mF, at_e7C
at_hFD:	AT_HEAD r19, r18, r19, r19, at_mF, at_e7C
at_hFE:	AT_HEAD r18, r19, r19, r19, at_mF, at_e7E
at_hFF:	AT_HEAD r19, r19, r19, r19, at_mF, at_e7E
at_e7C:	AT_EXTH r18, r19, at_xF
at_e7E:	AT_EXTH r19, r19, at_xF

at_w80:	AT_HDMC r18, at_m0, at_x0
at_w82:	AT_HDMC r19, at_m0, at_x0
at_m0:	AT_MIDL r18, r18, r18, r18, at_r0
at_r0:	AT_RAMT r18, r18, r18
at_x0:	AT_EXTM r18, r18, at_t0
at_t0:	AT_EXTT r18, r18

at_w84:	AT_HDMC r18, at_m1, at_x1
at_w86:	AT_HDMC r19, at_m1, at_x1
at_m1:	AT_MIDL r19, r18, r18, r18, at_r0
at_x1:	AT_EXTM r19, r18, at_t0

at_w88:	AT_HDMC r18, at_m2, at_x2
at_w8A:	AT_HDMC r19, at_m2, at_x2
at_m2:	AT_MIDL r18, r19, r18, r18, at_r2
at_r2:	AT_RAMT r19, r18, r18
at_x2:	AT_EXTM r18, r18, at_t2
at_t2:	AT_EXTT r19, r18

at_w8C:	AT_HDMC r18, at_m3, at_x3
at_w8E:	AT_HDMC r19, at_m3, at_x3
at_m3:	AT_MIDL r19, r19, r18, r18, at_r2
at_x3:	AT_EXTM r19, r18, at_t2

at_w90:	AT_HDMC r18, at_m4, at_x4
at_w92:	AT_HDMC r19, at_m4, at_x4
at_m4:	AT_MIDL r18, r18, r19, r18, at_r4
at_r4:	AT_RAMT r18, r19, r18
at_x4:	AT_EXTM r18, r19, at_t0

at_w94:	AT_HDMC r18, at_m5, at_x5
at_w96:	AT_HDMC r19, at_m5, at_x5
at_m5:	AT_MIDL r19, r18, r19, r18, at_r4
at_x5:	AT_EXTM r19, r19, at_t0

at_w98:	AT_HDMC r18, at_m6, at_x6
at_w9A:	AT_HDMC r19, at_m6, at_x6
at_m6:	AT_MIDL r18, r19, r19, r18, at_r6
at_r6:	AT_RAMT r19, r19, r18
at_x6:	AT_EXTM r18, r19, at_t2

at_w9C:	AT_HDMC r18, at_m7, at_x7
at_w9E:	AT_HDMC r19, at_m7, at_x7
at_m7:	AT_MIDL r19, r19, r19, r18, at_r6
at_x7:	AT_EXTM r19, r19, at_t2

at_wA0:	AT_HDMC r18, at_m8, at_x8
at_wA2:	AT_HDMC r19, at_m8, at_x8
at_m8:	AT_MIDL r18, r18, r18, r19, at_r8
at_r8:	AT_RAMT r18, r18, r19
at_x8:	AT_EXTM r18, r18, at_t8
at_t8:	AT_EXTT r18, r19

at_wA4:	AT_HDMC r18, at_m9, at_x9
at_wA6:	AT_HDMC r19, at_m9, at_x9
at_m9:	AT_MIDL r19, r18, r18, r19, at_r8
at_x9:	AT_EXTM r19, r18, at_t8

at_wA8:	AT_HDMC r18, at_mA, at_xA
at_wAA:	AT_HDMC r19, at_mA, at_xA
at_mA:	AT_MIDL r18, r19, r18, r19, at_rA
at_rA:	AT_RAMT r19, r18, r19
at_xA:	AT_EXTM r18, r18, at_tA
at_tA:	AT_EXTT r19, r19

at_wAC:	AT_HDMC r18, at_mB, at_xB
at_wAE:	AT_HDMC r19, at_mB, at_xB
at_mB:	AT_MIDL r19, r19, r18, r19, at_rA
at_xB:	AT_EXTM r19, r18, at_tA

at_wB0:	AT_HDMC r18, at_mC, at_xC
at_wB2:	AT_HDMC r19, at_mC, at_xC
at_mC:	AT_MIDL r18, r18, r19, r19, at_rC
at_rC:	AT_RAMT r18, r19, r19
at_xC:	AT_EXTM r18, r19, at_t8

at_wB4:	AT_HDMC r18, at_mD, at_xD
at_wB6:	AT_HDMC r19, at_mD, at_xD
at_mD:	AT_MIDL r19, r18, r19, r19, at_rC
at_xD:	AT_EXTM r19, r19, at_t8

at_wB8:	AT_HDMC r18, at_mE, at_xE
at_wBA:	AT_HDMC r19, at_mE, at_xE
at_mE:	AT_MIDL r18, r19, r19, r19, at_rE
at_rE:	AT_RAMT r19, r19, r19
at_xE:	AT_EXTM r18, r19, at_tA

at_wBC:	AT_HDMC r18, at_mF, at_xF
at_wBE:	AT_HDMC r19, at_mF, at_xF
at_mF:	AT_MIDL r19, r19, r19, r19, at_rE
at_xF:	AT_EXTM r19, r19, at_tA



;
; void ClearVram(void);
;
; Uzebox kernel function: clears the VRAM. This function should only be used
; if all 32 rows in the current Row Descriptor are either defined proper or
; their VRAM pointer is set to NULL.
;
.section .text.ClearVram
ClearVram:

	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r25,     32
0:
	lpm   XL,      Z+
	lpm   XH,      Z+      ; VRAM pointer
	adiw  ZL,      6       ; Skip other data
	cpi   XH,      0
	breq  2f               ; High byte 0, assume NULL, skip
	ldi   r24,     VRAM_TILES_H
	clr   r0
1:
	st    X+,      r0
	dec   r24
	brne  1b
2:
	dec   r25
	brne  0b
	ret



;
; void ClearAram(void);
;
; Complementary function: clears the ARAM (Attribute RAM). This function
; should only be used if all 32 rows in the current Row Descriptor are either
; defined proper or their ARAM pointer is set to NULL.
;
.section .text.ClearAram
ClearAram:

	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r25,     32
0:
	adiw  ZL,      2       ; Skip VRAM pointer
	lpm   XL,      Z+
	lpm   XH,      Z+      ; ARAM pointer
	adiw  ZL,      4       ; Skip other data
	cpi   XH,      0
	breq  2f               ; High byte 0, assume NULL, skip
	ldi   r24,     VRAM_TILES_H
	clr   r0
1:
	st    X+,      r0
	dec   r24
	brne  1b
2:
	dec   r25
	brne  0b
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

	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r25,     8
	andi  r22,     0x1F
	mul   r22,     r25     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	st    X,       r20
0:
	ret



;
; void SetAttr(char x, char y, unsigned char attr);
;
; Complementary function: sets a tile's attribute at a given X:Y location on
; ARAM.
;
;     r24: x
;     r22: y
;     r20: attribute
;
.section .text.SetAttr
SetAttr:

	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r25,     8
	andi  r22,     0x1F
	mul   r22,     r25     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	adiw  ZL,      2       ; To ARAM in structure
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	st    X,       r20
0:
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

	ldi   r25,     0
	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r23,     8
	andi  r22,     0x1F
	mul   r22,     r23     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	ld    r24,     X
	ret
0:
	ldi   r24,     0
	ret



;
; unsigned char GetAttr(char x, char y);
;
; Retrieves a tile's attribute from a given X:Y location on ARAM.
;
;     r24: x
;     r22: y
;
; Returns:
;
;     r24: Attribute
;
.section .text.GetAttr
GetAttr:

	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r23,     8
	andi  r22,     0x1F
	mul   r22,     r23     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	adiw  ZL,      2       ; To ARAM in structure
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	ld    r24,     X
	ret
0:
	ldi   r24,     0
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

	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r25,     8
	andi  r22,     0x1F
	mul   r22,     r25     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	lds   r0,      v_fbase
	add   r20,     r0
	st    X,       r20
0:
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

	ldi   r25,     0
	cpi   r24,     VRAM_TILES_H
	brcc  0f
	lds   ZL,      m45_rowdesc + 0
	lds   ZH,      m45_rowdesc + 1
	ldi   r23,     8
	andi  r22,     0x1F
	mul   r22,     r23     ; Offset of row structure for this Y
	add   ZL,      r0
	adc   ZH,      r1
	clr   r1
	lpm   XL,      Z+
	lpm   XH,      Z+
	cpi   XH,      0
	breq  0f               ; VRAM is NULL
	add   XL,      r24
	adc   XH,      r1
	ld    r24,     X
	lds   r0,      v_fbase
	sub   r24,     r0
	ret
0:
	ldi   r24,     0
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
