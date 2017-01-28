/*
 *  Uzebox Kernel - Mode 72, Sprite mode 6
 *  Copyright (C) 2017 Sandor Zsuga (Jubatian)
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
; Video mode 72, Sprite mode 6
;
;  8 x 16 pixels wide 2bpp sprites ( 0 -  7)
; 12 x  4 pixels wide 2bpp sprites ( 8 - 19)
;
; Up to 4 * 16 pixels + 4 * 4 pixels wide sprites per scanline
;
; Muxed pairs: 0-1, 2-3, 4-5, 6-7, 8-9-(10-11) 12-13, 14-15, 16-17-(18-19)
;
; The 4 pixels wide sprites use the same three colors and the same bank as
; specified in Sprite 8.
;
; Sprites 10, 11 don't show at all if either 8 or 9 is displayed on the same
; scanline. Sprites 18, 19 don't show if either 16 or 17 is displayed on the
; same scanline (you should possibly order these small sprites by Y, the
; following should usually work well: 16,10,12,17,11,13,14,18,8,15,19,9).
;
;=============================================================================



.section .text



;
; Scanline notes:
;
; The horizontal layout with borders is constructed to show as if there were
; 24 tiles (or 48 in text mode).
;
; Cycles:
;
; Entry:                 ; (1633)
; out   PIXOUT,  (zero)  ; (1698) Black border begins
; cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
; sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
; out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
; Last cycle:            ; ( 461)
;
; Registers:
;
;  r1: r0: Temp
;  r2-r13: Background colors
; r14-r16: Temp
; r17:     Border color
; r18:     Physical scanline (use to check sprite Y)
; r19:     Log. scanline (no usage)
; r20-r23: Temp
; r24:     Sprite 0-7 X mirror
; r25:     Sprite 8-15 X mirror
;  ZH: ZL: Work pointer (code tiling etc.)
;  YH: YL: Work pointer (for sprite data access)
;  XH: XL: Line buffer access
; GPIOR0:  Sprite 16-19 X mirror on bits 4-7
;
; Return sequence (after last cycle):
;
; ldi   ZL,      31
; out   SPL,     ZL
; pop   r0
; out   PIXOUT,  r0      ; ( 466) Pixel 0
; jmp   m72_graf_scan_b
;
; Video stack top = LB_STACK - 1 may be used
;



;
; Sprite Y preparation & Entry point loads
;
; Stack is already on the line buffer (SPH: Line buffer bank)
;
; 400 cycles with ret
;
m72_sp6_yprep:

	ldi   XL,      lo8(sprites + SP_OFF)
	ldi   XH,      hi8(sprites + SP_OFF)
	ldi   YL,      lo8(sprites + SP_YPOS)
	ldi   YH,      hi8(sprites + SP_YPOS)
	ldi   ZL,      lo8(v_spoff)
	ldi   ZH,      hi8(v_spoff)

	ldi   r18,     8       ; (  7)
sp6_ypr_l:
	ld    r16,     Y
	ld    r17,     X
	sub   r17,     r16
	sub   r17,     r16
	sub   r17,     r16
	sub   r17,     r16
	subi  r17,     4
	st    Z+,      r17
	adiw  YL,      8
	adiw  XL,      8
	dec   r18
	brne  sp6_ypr_l        ; (150)

	ldi   r18,     12      ; (151)
sp6_ypr_n:
	ld    r16,     Y
	ld    r17,     X
	sub   r17,     r16
	subi  r17,     1
	st    Z+,      r17
	adiw  YL,      8
	adiw  XL,      8
	dec   r18
	brne  sp6_ypr_n        ; (330)

	in    XH,      STACKH
	ldi   XL,      LB_SPR_A
	ldi   r18,     hi8(pm(m72_sp6_a))
	st    X+,      r18
	ldi   r18,     lo8(pm(m72_sp6_a))
	st    X+,      r18
	ldi   r18,     hi8(pm(m72_sp6_b))
	st    X+,      r18
	ldi   r18,     lo8(pm(m72_sp6_b))
	st    X+,      r18     ; (344)

	WAIT  r18,     52
	ret                    ; (400)



;
; Entry point A
;
m72_sp6_a:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	mov   r1,      r18
	lsl   r1
	lsl   r1                    ; 4 x Phys. scanline for offsets


	; (1638) Preload

	lds   r15,     sprites + ( 2 * 8) + SP_YPOS
	lds   r16,     v_sphgt + ( 2)
	sub   r15,     r18
	lds   r0,      sprites + ( 3 * 8) + SP_YPOS
	clr   r20

	; (1646) Sprites 0/1

	lds   XL,      sprites + ( 0 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 0)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + ( 1 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 1)
	brcs  sp6_a_00act      ; (11 / 12) Sprite 0 has priority over Sprite 1
	sub   XL,      r18
	add   XL,      YL
	brcc  sp6_a_01ina      ; (14 / 15)

	; Sprite 1 renders

	lds   YL,      v_spoff + ( 1)
	lds   YH,      sprites + ( 1 * 8) + SP_BANK
	lds   XL,      sprites + ( 1 * 8) + SP_XPOS
	lds   r21,     sprites + ( 1 * 8) + SP_COL1
	lds   r22,     sprites + ( 1 * 8) + SP_COL2
	lds   r23,     sprites + ( 1 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     1       ; (28 / 29)
	rjmp  sp6_a_00mir      ; (30)

sp6_a_00nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_a_00mie      ; (91)

sp6_a_01ina:

	WAIT  YL,      36
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  YL,      55
	rjmp  sp6_a_00end      ; (91)

sp6_a_00act:

	; Sprite 0 renders, Sprite 1 skips

	lds   YL,      v_spoff + ( 0)
	lds   YH,      sprites + ( 0 * 8) + SP_BANK
	lds   XL,      sprites + ( 0 * 8) + SP_XPOS
	lds   r21,     sprites + ( 0 * 8) + SP_COL1
	lds   r22,     sprites + ( 0 * 8) + SP_COL2
	lds   r23,     sprites + ( 0 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     0       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_a_00nor      ; (29)
	rjmp  sp6_a_00mir      ; (30)

sp6_a_00mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_a_00mie:

	icall                  ; (108)

sp6_a_00end:


	; (1755) Preload

	lds   r14,     sprites + ( 4 * 8) + SP_YPOS
	lds   r20,     v_sphgt + ( 4)
	sub   r14,     r18

	; (1760) Sprites 2/3 (-7 cy)

	add   r15,     r16
	lds   YL,      v_sphgt + ( 3)
	brcs  sp6_a_02act      ; (11 / 12) Sprite 2 has priority over Sprite 3
	sub   r0,      r18
	add   r0,      YL
	brcc  sp6_a_03ina      ; (14 / 15)

	; Sprite 3 renders

	lds   YL,      v_spoff + ( 3)
	lds   YH,      sprites + ( 3 * 8) + SP_BANK
	lds   XL,      sprites + ( 3 * 8) + SP_XPOS
	lds   r21,     sprites + ( 3 * 8) + SP_COL1
	lds   r22,     sprites + ( 3 * 8) + SP_COL2
	lds   r23,     sprites + ( 3 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     3       ; (28 / 29)
	rjmp  sp6_a_02mir      ; (30)

sp6_a_02nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_a_02mie      ; (91)

sp6_a_03ina:

	WAIT  YL,      55
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  YL,      36
	rjmp  sp6_a_02end      ; (108)

sp6_a_02act:

	; Sprite 2 renders, Sprite 3 skips

	lds   YL,      v_spoff + ( 2)
	lds   YH,      sprites + ( 2 * 8) + SP_BANK
	lds   XL,      sprites + ( 2 * 8) + SP_XPOS
	lds   r21,     sprites + ( 2 * 8) + SP_COL1
	lds   r22,     sprites + ( 2 * 8) + SP_COL2
	lds   r23,     sprites + ( 2 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     2       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_a_02nor      ; (29)
	rjmp  sp6_a_02mir      ; (30)

sp6_a_02mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_a_02mie:

	icall                  ; (108)

sp6_a_02end:


	; (  43) Preload

	lds   r15,     sprites + ( 6 * 8) + SP_YPOS
	lds   r16,     v_sphgt + ( 6)
	sub   r15,     r18
	lds   r0,      sprites + ( 7 * 8) + SP_YPOS
	sub   r0,      r18

	; (  53) Sprites 4/5 (-5 cy)

	add   r14,     r20
	lds   r20,     v_sphgt + ( 7) ; Part of Preload (cycle counted to that block)
	lds   XL,      sprites + ( 5 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 5)
	brcs  sp6_a_04act      ; (11 / 12) Sprite 4 has priority over Sprite 5
	sub   XL,      r18
	add   XL,      YL
	brcc  sp6_a_05ina      ; (14 / 15)

	; Sprite 5 renders

	lds   YL,      v_spoff + ( 5)
	lds   YH,      sprites + ( 5 * 8) + SP_BANK
	lds   XL,      sprites + ( 5 * 8) + SP_XPOS
	lds   r21,     sprites + ( 5 * 8) + SP_COL1
	lds   r22,     sprites + ( 5 * 8) + SP_COL2
	lds   r23,     sprites + ( 5 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     5       ; (28 / 29)
	rjmp  sp6_a_04mir      ; (30)

sp6_a_04nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_a_04mie      ; (91)

sp6_a_05ina:

	WAIT  YL,      76
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  YL,      15
	rjmp  sp6_a_04end      ; (108)

sp6_a_04act:

	; Sprite 4 renders, Sprite 5 skips

	lds   YL,      v_spoff + ( 4)
	lds   YH,      sprites + ( 4 * 8) + SP_BANK
	lds   XL,      sprites + ( 4 * 8) + SP_XPOS
	lds   r21,     sprites + ( 4 * 8) + SP_COL1
	lds   r22,     sprites + ( 4 * 8) + SP_COL2
	lds   r23,     sprites + ( 4 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     4       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_a_04nor      ; (29)
	rjmp  sp6_a_04mir      ; (30)

sp6_a_04mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_a_04mie:

	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (108)

sp6_a_04end:


	; ( 158) Sprites 6/7 (-10 cy)

	add   r15,     r16
	brcs  sp6_a_06act      ; (11 + 1 / 12 + 1) Sprite 6 has priority over Sprite 7
	add   r0,      r20
	brcc  sp6_a_07ina      ; (14 / 15)

	; Sprite 7 renders

	lds   YL,      v_spoff + ( 7)
	lds   YH,      sprites + ( 7 * 8) + SP_BANK
	lds   XL,      sprites + ( 7 * 8) + SP_XPOS
	lds   r21,     sprites + ( 7 * 8) + SP_COL1
	lds   r22,     sprites + ( 7 * 8) + SP_COL2
	lds   r23,     sprites + ( 7 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     7       ; (28 / 29)
	rjmp  sp6_a_06mir      ; (30)

sp6_a_06nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_a_06mie      ; (91)

sp6_a_07ina:

	WAIT  YL,      91
	rjmp  sp6_a_06end      ; (108)

sp6_a_06act:

	; Sprite 6 renders, Sprite 7 skips

	lds   YL,      v_spoff + ( 6)
	lds   YH,      sprites + ( 6 * 8) + SP_BANK
	lds   XL,      sprites + ( 6 * 8) + SP_XPOS
	lds   r21,     sprites + ( 6 * 8) + SP_COL1
	lds   r22,     sprites + ( 6 * 8) + SP_COL2
	lds   r23,     sprites + ( 6 * 8) + SP_COL3
	add   YL,      r1      ; (25 + 1)
	sbrs  r24,     6       ; (26 + 1 / 27 + 1)
	rjmp  sp6_a_06nor      ; (29)
	rjmp  sp6_a_06mir      ; (30)

sp6_a_06mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_a_06mie:

	icall                  ; (108)

sp6_a_06end:


	; ( 256) Preload bank & colors for 4px wide sprites

	lds   YH,      sprites + ( 8 * 8) + SP_BANK
	lds   r21,     sprites + ( 8 * 8) + SP_COL1
	lds   r22,     sprites + ( 8 * 8) + SP_COL2
	lds   r23,     sprites + ( 8 * 8) + SP_COL3

	; ( 264) Sprites 8/9/(10/11)

	lds   XL,      sprites + ( 8 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 8)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + ( 9 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 9)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_a_08act      ; (12 / 13) Sprite 8 has priority over Sprite 9
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_a_09act      ; (15 / 16)
	lds   XL,      sprites + (10 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (10)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (11 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (11)
	brcs  sp6_a_10act      ; (26 / 27) Sprite 10 has priority over Sprite 11
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_a_11act      ; (29 / 30)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_a_08end      ; (56)

sp6_a_08act:

	; Sprite 8 renders, Sprite 9 skips (10,11 skips)

	nop
	lds   YL,      v_spoff + ( 8)
	lds   XL,      sprites + ( 8 * 8) + SP_XPOS
	sbrc  r25,     0
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_09acc      ; (22)

sp6_a_09act:

	; Sprite 9 renders (10,11 skips)

	lds   YL,      v_spoff + ( 9)
	lds   XL,      sprites + ( 9 * 8) + SP_XPOS
	sbrc  r25,     1
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_09acc:

	WAIT  ZL,      12
	rjmp  sp6_a_08mie      ; (36)

sp6_a_10act:

	; Sprite 10 renders, Sprite 11 skips

	nop
	lds   YL,      v_spoff + (10)
	lds   XL,      sprites + (10 * 8) + SP_XPOS
	sbrc  r25,     2
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_08mie      ; (36)

sp6_a_11act:

	; Sprite 11 renders

	lds   YL,      v_spoff + (11)
	lds   XL,      sprites + (11 * 8) + SP_XPOS
	sbrc  r25,     3
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_08mie:

	add   YL,      r18     ; (37)
	ldd   ZL,      Y + 0   ; (39)
	icall                  ; (56)

sp6_a_08end:


	; ( 320) Preload

	lds   r15,     sprites + (14 * 8) + SP_YPOS
	lds   r16,     v_sphgt + (14)
	lds   r0,      sprites + (15 * 8) + SP_YPOS
	lds   r20,     v_sphgt + (15)

	; ( 328) Sprites 12/13

	lds   XL,      sprites + (12 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (12)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (13 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (13)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_a_12act      ; (12 / 13) Sprite 10 has priority over Sprite 11
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_a_13act      ; (15 / 16)

	; No sprite

	WAIT  YL,      10
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  YL,      15
	rjmp  sp6_a_12end      ; (42)

sp6_a_12act:

	; Sprite 12 renders, Sprite 13 skips

	nop
	lds   YL,      v_spoff + (12)
	lds   XL,      sprites + (12 * 8) + SP_XPOS
	sbrc  r25,     4
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_12mie      ; (22)

sp6_a_13act:

	; Sprite 13 renders

	lds   YL,      v_spoff + (13)
	lds   XL,      sprites + (13 * 8) + SP_XPOS
	sbrc  r25,     5
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_12mie:

	add   YL,      r18     ; (23)
	ldd   ZL,      Y + 0   ; (25)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	icall                  ; (42)

sp6_a_12end:


	; ( 371) Sprites 14/15 (-8 cy)

	sub   r15,     r18
	add   r15,     r16
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_a_14act      ; (12 / 13) Sprite 14 has priority over Sprite 15
	sub   r0,      r18
	add   r0,      r20
	brcs  sp6_a_15act      ; (15 / 16)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_a_14end      ; (42)

sp6_a_14act:

	; Sprite 14 renders, Sprite 15 skips

	nop
	lds   YL,      v_spoff + (14)
	lds   XL,      sprites + (14 * 8) + SP_XPOS
	sbrc  r25,     6
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_14mie      ; (22)

sp6_a_15act:

	; Sprite 15 renders

	lds   YL,      v_spoff + (15)
	lds   XL,      sprites + (15 * 8) + SP_XPOS
	sbrc  r25,     7
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_14mie:

	add   YL,      r18     ; (23)
	ldd   ZL,      Y + 0   ; (25)
	icall                  ; (42)

sp6_a_14end:


	; ( 405) Sprites 16/17/(18/19)

	lds   XL,      sprites + (16 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (16)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (17 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (17)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_a_16act      ; (12 / 13) Sprite 16 has priority over Sprite 17
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_a_17act      ; (15 / 16)
	lds   XL,      sprites + (18 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (18)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (19 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (19)
	brcs  sp6_a_18act      ; (26 / 27) Sprite 18 has priority over Sprite 19
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_a_19act      ; (29 / 30)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_a_16end      ; (42)

sp6_a_16act:

	; Sprite 16 renders, Sprite 17 skips (18,19 skips)

	nop
	lds   YL,      v_spoff + (16)
	lds   XL,      sprites + (16 * 8) + SP_XPOS
	sbic  GPR0,    4
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_17acc      ; (22)

sp6_a_17act:

	; Sprite 17 renders (18,19 skips)

	lds   YL,      v_spoff + (17)
	lds   XL,      sprites + (17 * 8) + SP_XPOS
	sbic  GPR0,    5
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_17acc:

	WAIT  ZL,      12
	rjmp  sp6_a_16mie      ; (36)

sp6_a_18act:

	; Sprite 18 renders, Sprite 19 skips

	nop
	lds   YL,      v_spoff + (18)
	lds   XL,      sprites + (18 * 8) + SP_XPOS
	sbic  GPR0,    6
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_a_16mie      ; (36)

sp6_a_19act:

	; Sprite 19 renders

	lds   YL,      v_spoff + (19)
	lds   XL,      sprites + (19 * 8) + SP_XPOS
	sbic  GPR0,    7
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_a_16mie:

	add   YL,      r18     ; (37)
	ldd   ZL,      Y + 0   ; (39)
	icall                  ; (56)

sp6_a_16end:


	; ( 461) End

	; ( 461) Go on to next line

	ldi   ZL,      31
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b



;
; Entry point B
;
m72_sp6_b:

	ldi   ZL,      LB_STACK - 1 ; Back to video stack (at the end of the line buffer)
	out   STACKL,  ZL
	mov   r1,      r18
	lsl   r1
	lsl   r1                    ; 4 x Phys. scanline for offsets


	; (1638) Preload

	lds   r15,     sprites + ( 3 * 8) + SP_YPOS
	lds   r16,     v_sphgt + ( 3)
	sub   r15,     r18
	lds   r0,      sprites + ( 2 * 8) + SP_YPOS
	clr   r20

	; (1646) Sprites 0/1

	lds   XL,      sprites + ( 1 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 1)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + ( 0 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 0)
	brcs  sp6_b_00act      ; (11 / 12) Sprite 0 has priority over Sprite 1
	sub   XL,      r18
	add   XL,      YL
	brcc  sp6_b_01ina      ; (14 / 15)

	; Sprite 1 renders

	lds   YL,      v_spoff + ( 0)
	lds   YH,      sprites + ( 0 * 8) + SP_BANK
	lds   XL,      sprites + ( 0 * 8) + SP_XPOS
	lds   r21,     sprites + ( 0 * 8) + SP_COL1
	lds   r22,     sprites + ( 0 * 8) + SP_COL2
	lds   r23,     sprites + ( 0 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     0       ; (28 / 29)
	rjmp  sp6_b_00mir      ; (30)

sp6_b_00nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_b_00mie      ; (91)

sp6_b_01ina:

	WAIT  YL,      36
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	WAIT  YL,      55
	rjmp  sp6_b_00end      ; (91)

sp6_b_00act:

	; Sprite 0 renders, Sprite 1 skips

	lds   YL,      v_spoff + ( 1)
	lds   YH,      sprites + ( 1 * 8) + SP_BANK
	lds   XL,      sprites + ( 1 * 8) + SP_XPOS
	lds   r21,     sprites + ( 1 * 8) + SP_COL1
	lds   r22,     sprites + ( 1 * 8) + SP_COL2
	lds   r23,     sprites + ( 1 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     1       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_b_00nor      ; (29)
	rjmp  sp6_b_00mir      ; (30)

sp6_b_00mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	; --- (Display) ---
	out   PIXOUT,  r20     ; (1698) Black border
	; -----------------
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_b_00mie:

	icall                  ; (108)

sp6_b_00end:


	; (1755) Preload

	lds   r14,     sprites + ( 5 * 8) + SP_YPOS
	lds   r20,     v_sphgt + ( 5)
	sub   r14,     r18

	; (1760) Sprites 2/3 (-7 cy)

	add   r15,     r16
	lds   YL,      v_sphgt + ( 2)
	brcs  sp6_b_02act      ; (11 / 12) Sprite 2 has priority over Sprite 3
	sub   r0,      r18
	add   r0,      YL
	brcc  sp6_b_03ina      ; (14 / 15)

	; Sprite 3 renders

	lds   YL,      v_spoff + ( 2)
	lds   YH,      sprites + ( 2 * 8) + SP_BANK
	lds   XL,      sprites + ( 2 * 8) + SP_XPOS
	lds   r21,     sprites + ( 2 * 8) + SP_COL1
	lds   r22,     sprites + ( 2 * 8) + SP_COL2
	lds   r23,     sprites + ( 2 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     2       ; (28 / 29)
	rjmp  sp6_b_02mir      ; (30)

sp6_b_02nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_b_02mie      ; (91)

sp6_b_03ina:

	WAIT  YL,      55
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	WAIT  YL,      36
	rjmp  sp6_b_02end      ; (108)

sp6_b_02act:

	; Sprite 2 renders, Sprite 3 skips

	lds   YL,      v_spoff + ( 3)
	lds   YH,      sprites + ( 3 * 8) + SP_BANK
	lds   XL,      sprites + ( 3 * 8) + SP_XPOS
	lds   r21,     sprites + ( 3 * 8) + SP_COL1
	lds   r22,     sprites + ( 3 * 8) + SP_COL2
	lds   r23,     sprites + ( 3 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     3       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_b_02nor      ; (29)
	rjmp  sp6_b_02mir      ; (30)

sp6_b_02mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	; --- (Display) ---
	cbi   SYNC,    SYNC_P  ; (   5) Sync pulse goes low
	; -----------------
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_b_02mie:

	icall                  ; (108)

sp6_b_02end:


	; (  43) Preload

	lds   r15,     sprites + ( 7 * 8) + SP_YPOS
	lds   r16,     v_sphgt + ( 7)
	sub   r15,     r18
	lds   r0,      sprites + ( 6 * 8) + SP_YPOS
	sub   r0,      r18

	; (  53) Sprites 4/5 (-5 cy)

	add   r14,     r20
	lds   r20,     v_sphgt + ( 6) ; Part of Preload (cycle counted to that block)
	lds   XL,      sprites + ( 4 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 4)
	brcs  sp6_b_04act      ; (11 / 12) Sprite 4 has priority over Sprite 5
	sub   XL,      r18
	add   XL,      YL
	brcc  sp6_b_05ina      ; (14 / 15)

	; Sprite 5 renders

	lds   YL,      v_spoff + ( 4)
	lds   YH,      sprites + ( 4 * 8) + SP_BANK
	lds   XL,      sprites + ( 4 * 8) + SP_XPOS
	lds   r21,     sprites + ( 4 * 8) + SP_COL1
	lds   r22,     sprites + ( 4 * 8) + SP_COL2
	lds   r23,     sprites + ( 4 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     4       ; (28 / 29)
	rjmp  sp6_b_04mir      ; (30)

sp6_b_04nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_b_04mie      ; (91)

sp6_b_05ina:

	WAIT  YL,      76
	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	WAIT  YL,      15
	rjmp  sp6_b_04end      ; (108)

sp6_b_04act:

	; Sprite 4 renders, Sprite 5 skips

	lds   YL,      v_spoff + ( 5)
	lds   YH,      sprites + ( 5 * 8) + SP_BANK
	lds   XL,      sprites + ( 5 * 8) + SP_XPOS
	lds   r21,     sprites + ( 5 * 8) + SP_COL1
	lds   r22,     sprites + ( 5 * 8) + SP_COL2
	lds   r23,     sprites + ( 5 * 8) + SP_COL3
	add   YL,      r1      ; (25)
	sbrc  r24,     5       ; (26 / 27)
	rjmp  .+2              ; (28)
	rjmp  sp6_b_04nor      ; (29)
	rjmp  sp6_b_04mir      ; (30)

sp6_b_04mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_b_04mie:

	; --- (Display) ---
	sbi   SYNC,    SYNC_P  ; ( 141) Sync pulse goes high
	; -----------------
	icall                  ; (108)

sp6_b_04end:


	; ( 158) Sprites 6/7 (-10 cy)

	add   r15,     r16
	brcs  sp6_b_06act      ; (11 + 1 / 12 + 1) Sprite 6 has priority over Sprite 7
	add   r0,      r20
	brcc  sp6_b_07ina      ; (14 / 15)

	; Sprite 7 renders

	lds   YL,      v_spoff + ( 6)
	lds   YH,      sprites + ( 6 * 8) + SP_BANK
	lds   XL,      sprites + ( 6 * 8) + SP_XPOS
	lds   r21,     sprites + ( 6 * 8) + SP_COL1
	lds   r22,     sprites + ( 6 * 8) + SP_COL2
	lds   r23,     sprites + ( 6 * 8) + SP_COL3
	add   YL,      r1      ; (27)
	sbrc  r24,     6       ; (28 / 29)
	rjmp  sp6_b_06mir      ; (30)

sp6_b_06nor:

	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	ldd   ZL,      Y + 0   ; (32)
	icall                  ; (49)
	ldd   ZL,      Y + 1   ; (51)
	icall                  ; (68)
	ldd   ZL,      Y + 2   ; (70)
	icall                  ; (87)
	ldd   ZL,      Y + 3   ; (89)
	rjmp  sp6_b_06mie      ; (91)

sp6_b_07ina:

	WAIT  YL,      91
	rjmp  sp6_b_06end      ; (108)

sp6_b_06act:

	; Sprite 6 renders, Sprite 7 skips

	lds   YL,      v_spoff + ( 7)
	lds   YH,      sprites + ( 7 * 8) + SP_BANK
	lds   XL,      sprites + ( 7 * 8) + SP_XPOS
	lds   r21,     sprites + ( 7 * 8) + SP_COL1
	lds   r22,     sprites + ( 7 * 8) + SP_COL2
	lds   r23,     sprites + ( 7 * 8) + SP_COL3
	add   YL,      r1      ; (25 + 1)
	sbrs  r24,     7       ; (26 + 1 / 27 + 1)
	rjmp  sp6_b_06nor      ; (29)
	rjmp  sp6_b_06mir      ; (30)

sp6_b_06mir:

	nop
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	ldd   ZL,      Y + 3   ; (34)
	icall                  ; (51)
	ldd   ZL,      Y + 2   ; (53)
	icall                  ; (70)
	ldd   ZL,      Y + 1   ; (72)
	icall                  ; (89)
	ldd   ZL,      Y + 0   ; (91)

sp6_b_06mie:

	icall                  ; (108)

sp6_b_06end:


	; ( 256) Preload bank & colors for 4px wide sprites

	lds   YH,      sprites + ( 8 * 8) + SP_BANK
	lds   r21,     sprites + ( 8 * 8) + SP_COL1
	lds   r22,     sprites + ( 8 * 8) + SP_COL2
	lds   r23,     sprites + ( 8 * 8) + SP_COL3

	; ( 264) Sprites 8/9/(10/11)

	lds   XL,      sprites + ( 9 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 9)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + ( 8 * 8) + SP_YPOS
	lds   YL,      v_sphgt + ( 8)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_b_08act      ; (12 / 13) Sprite 8 has priority over Sprite 9
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_b_09act      ; (15 / 16)
	lds   XL,      sprites + (11 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (11)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (10 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (10)
	brcs  sp6_b_10act      ; (26 / 27) Sprite 10 has priority over Sprite 11
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_b_11act      ; (29 / 30)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_b_08end      ; (56)

sp6_b_08act:

	; Sprite 8 renders, Sprite 9 skips (10,11 skips)

	nop
	lds   YL,      v_spoff + ( 9)
	lds   XL,      sprites + ( 9 * 8) + SP_XPOS
	sbrc  r25,     1
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_09acc      ; (22)

sp6_b_09act:

	; Sprite 9 renders (10,11 skips)

	lds   YL,      v_spoff + ( 8)
	lds   XL,      sprites + ( 8 * 8) + SP_XPOS
	sbrc  r25,     0
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_09acc:

	WAIT  ZL,      12
	rjmp  sp6_b_08mie      ; (36)

sp6_b_10act:

	; Sprite 10 renders, Sprite 11 skips

	nop
	lds   YL,      v_spoff + (11)
	lds   XL,      sprites + (11 * 8) + SP_XPOS
	sbrc  r25,     3
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_08mie      ; (36)

sp6_b_11act:

	; Sprite 11 renders

	lds   YL,      v_spoff + (10)
	lds   XL,      sprites + (10 * 8) + SP_XPOS
	sbrc  r25,     2
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_08mie:

	add   YL,      r18     ; (37)
	ldd   ZL,      Y + 0   ; (39)
	icall                  ; (56)

sp6_b_08end:


	; ( 320) Preload

	lds   r15,     sprites + (15 * 8) + SP_YPOS
	lds   r16,     v_sphgt + (15)
	lds   r0,      sprites + (14 * 8) + SP_YPOS
	lds   r20,     v_sphgt + (14)

	; ( 328) Sprites 12/13

	lds   XL,      sprites + (13 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (13)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (12 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (12)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_b_12act      ; (12 / 13) Sprite 10 has priority over Sprite 11
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_b_13act      ; (15 / 16)

	; No sprite

	WAIT  YL,      10
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	WAIT  YL,      15
	rjmp  sp6_b_12end      ; (42)

sp6_b_12act:

	; Sprite 12 renders, Sprite 13 skips

	nop
	lds   YL,      v_spoff + (13)
	lds   XL,      sprites + (13 * 8) + SP_XPOS
	sbrc  r25,     5
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_12mie      ; (22)

sp6_b_13act:

	; Sprite 13 renders

	lds   YL,      v_spoff + (12)
	lds   XL,      sprites + (12 * 8) + SP_XPOS
	sbrc  r25,     4
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_12mie:

	add   YL,      r18     ; (23)
	ldd   ZL,      Y + 0   ; (25)
	; --- (Display) ---
	out   PIXOUT,  r17     ; ( 354) Next scanline colored border begins
	; -----------------
	icall                  ; (42)

sp6_b_12end:


	; ( 371) Sprites 14/15 (-8 cy)

	sub   r15,     r18
	add   r15,     r16
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_b_14act      ; (12 / 13) Sprite 14 has priority over Sprite 15
	sub   r0,      r18
	add   r0,      r20
	brcs  sp6_b_15act      ; (15 / 16)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_b_14end      ; (42)

sp6_b_14act:

	; Sprite 14 renders, Sprite 15 skips

	nop
	lds   YL,      v_spoff + (15)
	lds   XL,      sprites + (15 * 8) + SP_XPOS
	sbrc  r25,     7
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_14mie      ; (22)

sp6_b_15act:

	; Sprite 15 renders

	lds   YL,      v_spoff + (14)
	lds   XL,      sprites + (14 * 8) + SP_XPOS
	sbrc  r25,     6
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_14mie:

	add   YL,      r18     ; (23)
	ldd   ZL,      Y + 0   ; (25)
	icall                  ; (42)

sp6_b_14end:


	; ( 405) Sprites 16/17/(18/19)

	lds   XL,      sprites + (17 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (17)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (16 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (16)
	ldi   ZH,      hi8(pm(m72_sp2bpp_nor))
	brcs  sp6_b_16act      ; (12 / 13) Sprite 16 has priority over Sprite 17
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_b_17act      ; (15 / 16)
	lds   XL,      sprites + (19 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (19)
	sub   XL,      r18
	add   XL,      YL
	lds   XL,      sprites + (18 * 8) + SP_YPOS
	lds   YL,      v_sphgt + (18)
	brcs  sp6_b_18act      ; (26 / 27) Sprite 18 has priority over Sprite 19
	sub   XL,      r18
	add   XL,      YL
	brcs  sp6_b_19act      ; (29 / 30)

	; No sprite

	WAIT  YL,      25
	rjmp  sp6_b_16end      ; (42)

sp6_b_16act:

	; Sprite 16 renders, Sprite 17 skips (18,19 skips)

	nop
	lds   YL,      v_spoff + (17)
	lds   XL,      sprites + (17 * 8) + SP_XPOS
	sbic  GPR0,    5
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_17acc      ; (22)

sp6_b_17act:

	; Sprite 17 renders (18,19 skips)

	lds   YL,      v_spoff + (16)
	lds   XL,      sprites + (16 * 8) + SP_XPOS
	sbic  GPR0,    4
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_17acc:

	WAIT  ZL,      12
	rjmp  sp6_b_16mie      ; (36)

sp6_b_18act:

	; Sprite 18 renders, Sprite 19 skips

	nop
	lds   YL,      v_spoff + (19)
	lds   XL,      sprites + (19 * 8) + SP_XPOS
	sbic  GPR0,    7
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))
	rjmp  sp6_b_16mie      ; (36)

sp6_b_19act:

	; Sprite 19 renders

	lds   YL,      v_spoff + (18)
	lds   XL,      sprites + (18 * 8) + SP_XPOS
	sbic  GPR0,    6
	ldi   ZH,      hi8(pm(m72_sp2bpp_mir))

sp6_b_16mie:

	add   YL,      r18     ; (37)
	ldd   ZL,      Y + 0   ; (39)
	icall                  ; (56)

sp6_b_16end:


	; ( 461) End

	; ( 461) Go on to next line

	ldi   ZL,      31
	out   STACKL,  ZL
	pop   r0
	out   PIXOUT,  r0      ; ( 466) Pixel 0
	jmp   m72_graf_scan_b
