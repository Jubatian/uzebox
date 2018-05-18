;
; Uzebox Kernel - Video Mode 52 scanline loop
; Copyright (C) 2018 Sandor Zsuga (Jubatian)
;
; -----
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
; -----
;
; For usage notes and related see the main comments. The entry point is at
; m52_scloop.
;



;
; hsync_pulse notes:
;
; It takes 18 + 3 (rcall) cycles without the audio. Its first four
; instructions (and the 3 cycles of rcall) matters. The sync_pulse variable
; may be skipped altogether for the scanline loop if it is fixed afterwards.
;
; In total so 3 + 2 + 9 = 14 cycles can be gained by dropping it, to do its
; job directly.
;



.section .text



;
; Overall register usage
;
;  r1: r0: Temporaries
;      r2: Color 0 (r12 until loading it in Attribute mode 0)
;      r3: Color 1 (r12 until loading it in Attribute mode 1)
;      r4: Color 2
;      r5: Color 3
;  r7: r6: Code block 0 entry (r7 preloaded with appropriate jump table)
;  r9: r8: Code block 1 entry (r9 preloaded with appropriate jump table)
; r11:r10: Temporaries
;     r12: Temporary (for attribute load mostly)
;     r13: 0 (Zero), for calculations & terminating display line
; r15:r14: Row selector offset
;     r16: Scanline counter (Normally 0 => 223)
;     r17: Logical row counter (init from data at m52_rowsel_addr)
;     r18: Display width: Count of black pixels on the left / right
;     r19: m52_config
;     r20: Byte 0 of row descriptor
;     r21: First RAM tile index
;     r22: Temporary
;     r23: ROM tiles base
;     r24: 16, for tile address calculation
;     r25: Row select (0, 2, 4 ... 14)
;       X: VRAM address
;       Y: Temporary address
;       Z: Temporary address
;




;
; Right padding pixels
;
	rjmp  .
sclrpad:
	dec   r18
	brne  .-6
	rjmp  sclrpad_e

;
; Left padding pixels
;
	rjmp  .
scllpad:
	dec   r12
	brne  .-6
	rjmp  scllpad_e



;
; Return for exiting the scanline loop
;
sclpret:
	rjmp  m52_scloopr      ; (1703)



;
; Select row internal
;
mresn:
	rjmp  mrese            ; ( 8)



;
; Color replacements: No replace path
;
colr0_n:
	lpm   r2,      Z
	ldd   r2,      Z + 0
	rjmp  colr0_e
colr1_n:
	lpm   r3,      Z
	ldd   r3,      Z + 1
	rjmp  colr1_e



;
; End of scanline using Timer1 overflow
;
.global TIMER1_OVF_vect
TIMER1_OVF_vect:

	out   PIXOUT,  r13     ; Zero pixel terminating the line

	pop   r0               ; pop & discard OVF interrupt return address
	pop   r0               ; pop & discard OVF interrupt return address

	cpse  r18,     r13
	rjmp  sclrpad          ; Extra black pixels on the right
sclrpad_e:



;
; Loop test condition: If the scanline counter reached the count of lines to
; render, return. It is possible to request zero lines. Note: NO CALL! Upon
; entry the following registers are relied upon:
;
;     r13: 0 (Zero)
; r14:r15: Row selector offset (m52_rowsel_addr + 1)
;     r16: Scanline counter (Normally 0 => 223)
;     r17: Logical row counter (init from m52_rowsel_addr[0])
;     r19: m52_config
;     r21: First RAM tile index
;
; Entry is at cycle ?. (the rjmp must be issued at ?)
; Exit is at ?.
;
m52_scloop:
	lds   r20,     render_lines_count
	cp    r20,     r16     ; ()
	breq  sclpret          ; ( / )



;
; Row management code.
;
;     r13: 0 (Zero)
; r14:r15: Row selector offset
;     r16: Scanline counter (Normally 0 => 223)
;     r17: Logical row counter
;     r19: m52_config
;     r21: First RAM tile index
;
; Cycles:
;   8 (Row select)
;  14 (VRAM pointer load)
; ---
;  22
;
	;
	; Select row
	;
	movw  ZL,      r14     ; ( 1)
	ld    r24,     Z+      ; ( 3)
	cp    r24,     r16     ; ( 4)
	brne  mresn            ; ( 5 /  6) At new split point if equal
	ld    r17,     Z+      ; ( 7) Load new logical row counter
	movw  r14,     ZL      ; ( 8)
mrese:
	;
	; Load tile descriptors
	;
	mov   ZL,      r17     ; ( 1)
	lsr   ZL               ; ( 2)
	andi  ZL,      0xFC    ; ( 3) Row descriptor offset from log. row counter
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_rowdesc))
	sbci  ZH,      hi8(-(m52_rowdesc))
	ld    XL,      Z+      ; ( 8) VRAM low
	ld    XH,      Z+      ; (10) VRAM high
	ld    r20,     Z+      ; (12) Tile descriptor data from RAM
	ld    r18,     Z+      ; (14)



;
; Prepare variables for scanline render
;
; Cycles: 42
;
	mov   ZL,      r18
	andi  ZL,      0x03
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_romt_pht))
	sbci  ZH,      hi8(-(m52_romt_pht))
	ld    r23,     Z       ; ( 7) ROM tiles base

	mov   ZL,      r18
	andi  ZL,      0x0C
	ldi   ZH,      0
	subi  ZL,      lo8(-(m52_palette))
	sbci  ZH,      hi8(-(m52_palette))

	mov   r22,     r16     ; (13) Color replacing by physical scanline
	sbrs  r19,     2
	mov   r22,     r17     ; (15) Color replacing by logical scanline
	sbrs  r20,     6
	rjmp  colr0_n
	lds   YL,      m52_col0_p + 0
	lds   YH,      m52_col0_p + 1
	add   YL,      r22
	adc   YH,      r13
	ld    r2,      Y       ; (25)
colr0_e:
	sbrs  r20,     7
	rjmp  colr1_n
	lds   YL,      m52_col1_p + 0
	lds   YH,      m52_col1_p + 1
	add   YL,      r22
	adc   YH,      r13
	ld    r3,      Y       ; (35)
colr1_e:
	ldd   r4,      Z + 2
	ldd   r5,      Z + 3   ; (39) Palette colors

	mov   r25,     r17
	andi  r25,     0x07
	lsl   r25              ; (42) Row select



;
; Calculate width (34 / 32 tiles max width)
;
; Cycles: 15
;
#if   (M52_TILES_MAX_H != 36)
	com   r18
	andi  r18,     0xF0    ; ( 2) 0xDx => 0x20 (36 tiles wide, max)
#if   (M52_TILES_MAX_H == 34)
	subi  r18,     0x30
#else
	subi  r18,     0x40
#endif
	brcc  .+2
	ldi   r18,     0       ; ( 5) Maximal width is 36 tiles
	mov   ZH,      r18
	swap  ZH
	ldi   ZL,      40
	mul   ZH,      ZL      ; (10) Termination point for timer (1 tile: 40 clocks)
	movw  YL,      r0
#if   (M52_TILES_MAX_H == 34)
	subi  YL,      lo8(34 * 40 + 98)
	sbci  YH,      hi8(34 * 40 + 98)
#else
	subi  YL,      lo8(32 * 40 + 98)
	sbci  YH,      hi8(32 * 40 + 98)
#endif
	lsr   r18              ; (14) 8 pixels / tile
	mov   r12,     r18     ; (15)
#if   (M52_TILES_MAX_H == 34)
	M52WT_R24      (40 - 15)
#else
	M52WT_R24      (80 - 15)
#endif
#endif



;
; The hsync_pulse part for the new scanline.
;
; Normally in "conventional" graphics modes this is an "rcall hsync_pulse"
; into the kernel, however here even those cycles were needed. I count the
; cycles of the line beginning with that rcall, so the hsync cbi ends on
; cycle 5.
;
; Note that the "sync_pulse" variable is not updated, which is normally a
; decrementing counter for managing the mode. It is not used within the
; display portion, so I only update it proper after the display ends (by
; subtracting r16, the amount of lines which skipped updating it).
;
; The "update_sound" function destroys r0, r1, Z and the T flag in SREG.
;
; HSYNC_USABLE_CYCLES:
; 234 (Allowing 4CH audio or either 5CH or the UART)
;
; From the prolog some calculations are moved here so to make it possible
; to shift the display a bit around for proper centering.
;
; Cycle counter is at 246 on its end
;
	cbi   _SFR_IO_ADDR(SYNC_PORT), SYNC_PIN ; (   5)
	inc   r16              ; (   6) Increment the physical line counter
	inc   r17              ; (   7) Increment the logical line counter
	ldi   ZL,      2       ; (   8)
	call  update_sound     ; (  12) (+ AUDIO)
	M52WT_R24      HSYNC_USABLE_CYCLES - AUDIO_OUT_HSYNC_CYCLES



;
; Calculate width (36 tiles max width)
;
; Cycles: 15
;
#if   (M52_TILES_MAX_H == 36)
	com   r18
	andi  r18,     0xF0    ; ( 2) 0xDx => 0x20 (36 tiles wide, max)
	subi  r18,     0x20
	brcc  .+2
	ldi   r18,     0       ; ( 5) Maximal width is 36 tiles
	mov   ZH,      r18
	swap  ZH
	ldi   ZL,      40
	mul   ZH,      ZL      ; (10) Termination point for timer (1 tile: 40 clocks)
	movw  YL,      r0
	subi  YL,      lo8(36 * 40 + 98)
	sbci  YH,      hi8(36 * 40 + 98)
	lsr   r18              ; (14) 8 pixels / tile
	mov   r12,     r18     ; (15)
#endif



;
; Set up Timer 1
;
	sts   _SFR_MEM_ADDR(TCNT1H), YH
	sts   _SFR_MEM_ADDR(TCNT1L), YL
	sei                    ; 7 cycles



;
; Process display width
;
	cpse  r12,     r13
	rjmp  scllpad          ; Extra black pixels on the left
scllpad_e:



;
; Lead-in
;

	; First partial tile (will be discarded when X shift is zero)
	; Also init stuff for code blocks

	ldi   r24,     16
	mov   ZL,      r20
	swap  ZL
	andi  ZL,      0x03    ; ( 4) Attribute mode select
	ldi   ZH,      0
	subi  ZL,      lo8(-(pm(attr_jt)))
	sbci  ZH,      hi8(-(pm(attr_jt)))
	ijmp                   ; ( 9)

attr_jt:
	rjmp  attrn            ; (11)
#if (M52_ENABLE_ATTR0 == 0)
	rjmp  attrn
#else
	rjmp  attr0
#endif
#if (M52_ENABLE_ATTR123 == 0)
	rjmp  attrn
#else
	rjmp  attr123
#endif
#if (M52_ENABLE_ATTR23M == 0)
	rjmp  attrn
#else
	rjmp  attr23m
#endif


attrn:
	rjmp  .
	ld    r8,      X+      ; (15) Tiles
	ldi   ZH,      hi8(pm(t0_jt_nattr))
	mov   r7,      ZH
	ldi   ZH,      hi8(pm(t1_jt))
	mov   r9,      ZH
	mul   r8,      r24     ; (21) r24 = 16
	or    r0,      r25     ; (22) r25 = row select
	cp    r8,      r21     ; (23) r21 = first RAM tile address
	brcc  attrn_0
	add   r1,      r23     ; (25) r23 = ROM tiles base
	movw  ZL,      r0
	lpm   r6,      Z+
	lpm   r8,      Z+      ; (32)
attrn_1:
	mov   ZL,      r6      ; (33)
	rjmp  attr_e           ; (35)
attrn_0:
	movw  YL,      r0
	ld    r6,      Y+
	ld    r8,      Y+
	rjmp  attrn_1          ; (32)

#if (M52_ENABLE_ATTR0 != 0)
attr0:
	ld    r2,      X+      ; (13) Color 0 Attributes
	ld    r8,      X+      ; (15) Tiles
	ldi   ZH,      hi8(pm(t0_jt_attr0))
	mov   r7,      ZH
	ldi   ZH,      hi8(pm(t1_jt))
	mov   r9,      ZH
	mul   r8,      r24     ; (21) r24 = 16
	or    r0,      r25     ; (22) r25 = row select
	cp    r8,      r21     ; (23) r21 = first RAM tile address
	brcc  attr0_0
	add   r1,      r23     ; (25) r23 = ROM tiles base
	movw  ZL,      r0
	lpm   r6,      Z+
	lpm   r8,      Z+      ; (32)
attr0_1:
	mov   ZL,      r6      ; (33)
	rjmp  attr_e           ; (35)
attr0_0:
	movw  YL,      r0
	ld    r6,      Y+
	ld    r8,      Y+
	rjmp  attr0_1          ; (32)
#endif

#if (M52_ENABLE_ATTR123 != 0)
attr123:
	ld    r8,      X+      ; (13) Tiles
	ld    r3,      X+      ; (15) Color 1 Attributes
	ld    r4,      X+      ; (17) Color 2 Attributes
	ld    r5,      X+      ; (19) Color 3 Attributes
	ldi   ZH,      hi8(pm(t3_jt))
	mov   r9,      ZH
	mul   r8,      r24     ; (23) r24 = 16
	or    r0,      r25     ; (24) r25 = row select
	movw  YL,      r0
	ld    ZL,      Y+
	ld    r8,      Y+      ; (29)
	rjmp  .
	rjmp  .
	rjmp  attr_e           ; (35)
#endif

#if (M52_ENABLE_ATTR23M != 0)
attr23m:
	ld    r22,     X+      ; (13) Tiles
	ld    r4,      X+      ; (15) Color 2 Attributes
	ld    r5,      X+      ; (17) Color 3 Attributes
	ldi   r23,     hi8(pm(t5_jt_mir))
	ldi   ZH,      hi8(pm(t5_jt_nor))
	mov   r9,      ZH
	muls  r22,     r24     ; (22) r24 = 16
	or    r0,      r25     ; (23) r25 = row select
	movw  YL,      r0
	brcc  attr23m_0
	nop
	subi  YH,      0xF0    ; (27) RAM 0x0800 - 0x0FFF
	ld    ZL,      Y+
	ld    r8,      Y+      ; (31)
	ldi   ZH,      hi8(pm(t4_jt_nor))
	mov   r7,      ZH      ; (33)
	rjmp  attr_e           ; (35) Use the common normal tile path

attr23m_0:
	subi  YH,      0xF8    ; (27) RAM 0x0800 - 0x0FFF
	ld    r22,     Y+
	ld    ZL,      Y+
	ldi   ZH,      hi8(pm(t4_jt_mir))
	mov   r7,      ZH      ; (33)
	rjmp  .                ; (35)

	; Mirrored tile lead-in
	; Select partial tile pixel output by X shift

	mov   ZH,      r20
	andi  ZH,      0x07    ; (37) X shift

	eor   r8,      r8
	eor   r0,      r0
	eor   r1,      r1
	movw  YL,      r0
	movw  r10,     r0      ; (42)

	; First pixel is output after 58 cycles

	cpi   ZH,      1
	breq  shfm_7
	cpi   ZH,      2
	breq  shfm_6
	cpi   ZH,      3
	breq  shfm_5
	cpi   ZH,      4
	breq  shfm_4
	cpi   ZH,      5
	breq  shfm_3
	cpi   ZH,      6
	breq  shfm_2
	cpi   ZH,      7
	breq  shfm_1
	rjmp  shf_0

	; Partial tile pixels (each block takes 7 cycles, with the above, it
	; comes out perfect to shift 5 cycles for each pixel).

shfm_7:
	mov   r8,      r2
	sbrc  r22,     3
	rjmp  .+6
	sbrc  r22,     2
	mov   r8,      r3
	rjmp  .+6
	mov   r8,      r4
	sbrc  r22,     2
	mov   r8,      r5

shfm_6:
	mov   r0,      r2
	sbrc  r22,     5
	rjmp  .+6
	sbrc  r22,     4
	mov   r0,      r3
	rjmp  .+6
	mov   r0,      r4
	sbrc  r22,     4
	mov   r0,      r5

shfm_5:
	mov   r1,      r2
	sbrc  r22,     7
	rjmp  .+6
	sbrc  r22,     6
	mov   r1,      r3
	rjmp  .+6
	mov   r1,      r4
	sbrc  r22,     6
	mov   r1,      r5

shfm_4:
	mov   YL,      r2
	sbrc  ZL,      1
	rjmp  .+6
	sbrc  ZL,      0
	mov   YL,      r3
	rjmp  .+6
	mov   YL,      r4
	sbrc  ZL,      0
	mov   YL,      r5

shfm_3:
	mov   YH,      r2
	sbrc  ZL,      3
	rjmp  .+6
	sbrc  ZL,      2
	mov   YH,      r3
	rjmp  .+6
	mov   YH,      r4
	sbrc  ZL,      2
	mov   YH,      r5

shfm_2:
	mov   r10,     r2
	sbrc  ZL,      5
	rjmp  .+6
	sbrc  ZL,      4
	mov   r10,     r3
	rjmp  .+6
	mov   r10,     r4
	sbrc  ZL,      4
	mov   r10,     r5

shfm_1:
	mov   r11,     r2
	sbrc  ZL,      7
	rjmp  .+6
	sbrc  ZL,      6
	mov   r11,     r3
	rjmp  .+6
	mov   r11,     r4
	sbrc  ZL,      6
	mov   r11,     r5


	; Load next tile for lead-in into the code blocks (starts by 1)

	mov   ZL,      r20
	swap  ZL
	andi  ZL,      0x03    ; ( 4) Attribute mode select
	ldi   ZH,      0
	subi  ZL,      lo8(-(pm(atti_jt)))
	sbci  ZH,      hi8(-(pm(atti_jt)))
	out   PIXOUT,  r8
	ijmp                   ; (10)

#endif


attr_e:

	; Select partial tile pixel output by X shift

	mov   ZH,      r20
	andi  ZH,      0x07    ; (37) X shift

	eor   r22,     r22
	eor   r0,      r0
	eor   r1,      r1
	movw  YL,      r0
	movw  r10,     r0      ; (42)

	; First pixel is output after 58 cycles

	cpi   ZH,      1
	breq  shf_7
	cpi   ZH,      2
	breq  shf_6
	cpi   ZH,      3
	breq  shf_5
	cpi   ZH,      4
	breq  shf_4
	cpi   ZH,      5
	breq  shf_3
	cpi   ZH,      6
	breq  shf_2
	cpi   ZH,      7
	breq  shf_1
	rjmp  shf_0

	; Partial tile pixels (each block takes 7 cycles, with the above, it
	; comes out perfect to shift 5 cycles for each pixel).

shf_7:
	mov   r22,     r2
	sbrc  ZL,      5
	rjmp  .+6
	sbrc  ZL,      4
	mov   r22,     r3
	rjmp  .+6
	mov   r22,     r4
	sbrc  ZL,      4
	mov   r22,     r5

shf_6:
	mov   r0,      r2
	sbrc  ZL,      3
	rjmp  .+6
	sbrc  ZL,      2
	mov   r0,      r3
	rjmp  .+6
	mov   r0,      r4
	sbrc  ZL,      2
	mov   r0,      r5

shf_5:
	mov   r1,      r2
	sbrc  ZL,      1
	rjmp  .+6
	sbrc  ZL,      0
	mov   r1,      r3
	rjmp  .+6
	mov   r1,      r4
	sbrc  ZL,      0
	mov   r1,      r5

shf_4:
	mov   YL,      r2
	sbrc  r8,      7
	rjmp  .+6
	sbrc  r8,      6
	mov   YL,      r3
	rjmp  .+6
	mov   YL,      r4
	sbrc  r8,      6
	mov   YL,      r5

shf_3:
	mov   YH,      r2
	sbrc  r8,      5
	rjmp  .+6
	sbrc  r8,      4
	mov   YH,      r3
	rjmp  .+6
	mov   YH,      r4
	sbrc  r8,      4
	mov   YH,      r5

shf_2:
	mov   r10,     r2
	sbrc  r8,      3
	rjmp  .+6
	sbrc  r8,      2
	mov   r10,     r3
	rjmp  .+6
	mov   r10,     r4
	sbrc  r8,      2
	mov   r10,     r5

shf_1:
	mov   r11,     r2
	sbrc  r8,      1
	rjmp  .+6
	sbrc  r8,      0
	mov   r11,     r3
	rjmp  .+6
	mov   r11,     r4
	sbrc  r8,      0
	mov   r11,     r5


	; Load next tile for lead-in into the code blocks (starts by 1)

	mov   ZL,      r20
	swap  ZL
	andi  ZL,      0x03    ; ( 4) Attribute mode select
	ldi   ZH,      0
	subi  ZL,      lo8(-(pm(atti_jt)))
	sbci  ZH,      hi8(-(pm(atti_jt)))
	out   PIXOUT,  r22
	ijmp                   ; (10)

atti_jt:
	rjmp  attin            ; (12)
#if (M52_ENABLE_ATTR0 == 0)
	rjmp  attin
#else
	rjmp  atti0
#endif
#if (M52_ENABLE_ATTR123 == 0)
	rjmp  attin
#else
	rjmp  atti123
#endif
#if (M52_ENABLE_ATTR23M == 0)
	rjmp  attin
#else
	rjmp  atti23m
#endif


attin:
	out   PIXOUT,  r0
	rjmp  .
	rjmp  .
	out   PIXOUT,  r1
	ld    r8,      X+      ; (20) Tiles
	mul   r8,      r24     ; (22) r24 = 16
	out   PIXOUT,  YL
	or    r0,      r25     ; (24) r25 = row select
	cp    r8,      r21     ; (25) r21 = first RAM tile address
	brcc  attin_0
	add   r1,      r23     ; (27) r23 = ROM tiles base
	out   PIXOUT,  YH
	movw  ZL,      r0
	lpm   r6,      Z+
	out   PIXOUT,  r10
	lpm   r8,      Z+      ; (36)
	movw  ZL,      r6      ; (37)
	out   PIXOUT,  r11
	ijmp                   ; (40)
attin_0:
	out   PIXOUT,  YH
	rjmp  .
	movw  YL,      r0
	mov   ZH,      r7
	out   PIXOUT,  r10
	ld    ZL,      Y+
	ld    r8,      Y+
	out   PIXOUT,  r11
	ijmp                   ; (40)

#if (M52_ENABLE_ATTR0 != 0)
atti0:
	out   PIXOUT,  r0
	ld    r12,     X+      ; (15) Color 0 Attributes
	mov   r2,      r12
	nop
	out   PIXOUT,  r1
	ld    r8,      X+      ; (20) Tiles
	mul   r8,      r24     ; (22) r24 = 16
	out   PIXOUT,  YL
	or    r0,      r25     ; (24) r25 = row select
	cp    r8,      r21     ; (25) r21 = first RAM tile address
	brcc  atti0_0
	add   r1,      r23     ; (27) r23 = ROM tiles base
	out   PIXOUT,  YH
	movw  ZL,      r0
	lpm   r6,      Z+
	out   PIXOUT,  r10
	lpm   r8,      Z+      ; (36)
	movw  ZL,      r6      ; (37)
	out   PIXOUT,  r11
	ijmp                   ; (40)
atti0_0:
	out   PIXOUT,  YH
	rjmp  .
	movw  YL,      r0
	mov   ZH,      r7
	out   PIXOUT,  r10
	ld    ZL,      Y+
	ld    r8,      Y+
	out   PIXOUT,  r11
	ijmp                   ; (40)
#endif

#if (M52_ENABLE_ATTR123 != 0)
atti123:
	out   PIXOUT,  r0
	ld    r8,      X+      ; (15) Tiles
	ld    r12,     X+      ; (17) Color 1 Attributes
	out   PIXOUT,  r1
	ld    r6,      X+      ; (20) Color 2 Attributes
	ld    r7,      X+      ; (22) Color 3 Attributes
	out   PIXOUT,  YL
	mov   r3,      r12
	movw  r4,      r6
	mul   r8,      r24     ; (27) r24 = 16
	out   PIXOUT,  YH
	or    r0,      r25     ; (29) r25 = row select
	movw  YL,      r0
	nop
	ldi   ZH,      hi8(pm(t2_jt))
	out   PIXOUT,  r10
	ld    ZL,      Y+
	ld    r8,      Y+      ; (37)
	out   PIXOUT,  r11
	lsl   ZL
	adc   ZH,      r13
	ijmp                   ; (42)
#endif

#if (M52_ENABLE_ATTR23M != 0)
atti23m:
	out   PIXOUT,  r0
	ld    r22,     X+      ; (15) Tiles
	ld    r6,      X+      ; (17) Color 2 Attributes
	out   PIXOUT,  r1
	ld    r7,      X+      ; (20) Color 3 Attributes
	movw  r4,      r6
	nop
	out   PIXOUT,  YL
	muls  r22,     r24     ; (25) r24 = 16
	brcc  atti23m_0
	nop
	out   PIXOUT,  YH
	or    r0,      r25     ; (29) r25 = row select
	movw  YL,      r0
	ldi   ZH,      hi8(pm(t4_jt_nor))
	subi  YH,      0xF0    ; (32) RAM 0x0800 - 0x0FFF
	out   PIXOUT,  r10
	ld    ZL,      Y+
	ld    r8,      Y+      ; (37)
	out   PIXOUT,  r11
	lsl   ZL
	adc   ZH,      r13     ; (40) Added tile data * 2
	ijmp                   ; (42)
atti23m_0:
	out   PIXOUT,  YH
	or    r0,      r25     ; (29) r25 = row select
	movw  YL,      r0
	ldi   ZH,      hi8(pm(t4_jt_mir))
	subi  YH,      0xF8    ; (32) RAM 0x0800 - 0x0FFF
	out   PIXOUT,  r10
	ld    r22,     Y+
	ld    ZL,      Y+
	out   PIXOUT,  r11
	lsl   ZL
	adc   ZH,      r13     ; (40) Added tile data * 2
	ijmp                   ; (42)
#endif


shf_0:
	M52WT_R24      22      ; 20cy here, 16cy for entry, this many needed for 58
	ldi   r24,     16      ; Tile is preloaded, prepare for display
	mov   YL,      ZL
	mov   ZL,      r20
	swap  ZL
	andi  ZL,      0x03    ; Attribute mode select
	ldi   ZH,      0
	subi  ZL,      lo8(-(pm(attx_jt)))
	sbci  ZH,      hi8(-(pm(attx_jt)))
	ijmp

attx_jt:
	rjmp  attxn            ; (12)
#if (M52_ENABLE_ATTR0 == 0)
	rjmp  attxn
#else
	rjmp  attx0
#endif
#if (M52_ENABLE_ATTR123 == 0)
	rjmp  attxn
#else
	rjmp  attx123
#endif
#if (M52_ENABLE_ATTR23M == 0)
	rjmp  attxn
#else
	rjmp  attx23m
#endif

attxn:
	mov   ZL,      YL
	mov   ZH,      r7
	rjmp  .
	ijmp                   ; (18)

#if (M52_ENABLE_ATTR0 != 0)
attx0:
	mov   ZL,      YL
	mov   ZH,      r7
	mov   r12,     r2
	nop
	ijmp                   ; (18)
#endif

#if (M52_ENABLE_ATTR123 != 0)
attx123:
	mov   ZL,      YL
	ldi   ZH,      hi8(pm(t2_jt))
	mov   r12,     r2
	movw  r6,      r4
	lsl   ZL
	adc   ZH,      r13
	ijmp                   ; (20)
#endif

#if (M52_ENABLE_ATTR23M != 0)
attx23m:
	mov   ZL,      YL
	mov   ZH,      r7
	movw  r6,      r4
	nop
	lsl   ZL
	adc   ZH,      r13
	ijmp                   ; (20)
#endif
