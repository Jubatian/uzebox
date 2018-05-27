;
; Uzebox Kernel - Video Mode 52 scanline loop core
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

;
; This scanline loop core contains the code blocks generating the video mode's
; display, and some other aligned components. The following interface points
; are available:
;
; t0_jt_nattr: Left jump table for no-attributes
; t0_jt_attr0: Left jump table for Color 0 attributes (if compiled in)
; t1_jt:       Right jump table
; t2_jt:       Left jump table for Color 1-2-3 attributes (if compiled in)
; t3_jt:       Right jump table for Color 1-2-3 attributes (if compiled in)
; t4_jt_nor:   Left jump table for Mirror-2-3, normal (if compiled in)
; t4_jt_mir:   Left jump table for Mirror-2-3, mirror (if compiled in)
; t5_jt_nor:   Right jump table for Mirror-2-3, normal (if compiled in)
; t5_jt_mir:   Right jump table for Mirror-2-3, mirror (if compiled in)
; sp_tmdec4:   Sprite mask decoder table for 3+1 color sprites (to low nybble)
; sp_1to2hi:   1bpp to 2bpp transformation, by high nybble
; sp_fl2bpp:   Flip (X mirror) 2bpp data
; sp_fl1bpp:   Flip (X mirror) 1bpp data
;
; The 4+1 color sprite's decoder is for both mask bits set. An OR mask has to
; be applied to combine the state of the mask bits (when the mask bit is
; clear, both corresponding pixels are visible, mask is 1).
;



;
; Code block macro for Tile left half (0)
;
; Register usage:
;
;  r1: r0: Temporaries
;      r2: Color 0 (r12 until loading it in Attribute mode 0)
;      r3: Color 1 (r12 until loading it in Attribute mode 1)
;      r4: Color 2
;      r5: Color 3
;  r7: r6: Code block 0 entry (r7 preloaded with appropriate jump table)
;  r9: r8: Code block 1 entry (r9 preloaded with appropriate jump table)
;     r12: Temporary, prev. tile's attribute
;     r13: 0 (Zero) used to terminate line & zero reg. for calculations
;     r21: First RAM tile index
;     r23: ROM tiles base
;     r24: 16, for tile address calculation
;     r25: Row select (0, 2, 4 ... 14)
;       X: VRAM address
;       Y: Temporary address
;       Z: Temporary address
;
#if   (M52_ENABLE_ATTR0 == 0)
.macro TB0_HEAD px0, pxa0, midl
	out   PIXOUT,  \px0    ; Tile pixel 0
	rjmp  \midl
.endm
.macro TB0_MIDL px1, px2, px3, tail
	ld    r22,     X+      ; Tile index
	out   PIXOUT,  \px1    ; Tile pixel 1
	rjmp  \tail
.endm
.macro TB0_TAIL px2, px3
	movw  ZL,      r8      ; r9: Code block 1 address high
	lsl   ZL
	out   PIXOUT,  \px2    ; Tile pixel 2
	adc   ZH,      r13     ; Added tile data * 2
	nop
	mul   r22,     r24     ; r24 = 16
	out   PIXOUT,  \px3    ; Tile pixel 3
	or    r0,      r25     ; r25 = row select
	cp    r22,     r21     ; r21 = first RAM tile address
	ijmp
.endm
#else
.macro TB0_HEAD px0, pxa0, midl
	out   PIXOUT,  \px0    ; Tile pixel 0
	rjmp  \midl
	out   PIXOUT,  \pxa0   ; +4: Entry for Attribute mode 0; Tile pixel 0
	mov   r2,      r12
	rjmp  \midl + 8
.endm
.macro TB0_MIDL px1, px2, px3, tail
	nop
	movw  ZL,      r8      ; r9: Code block 1 address high
	out   PIXOUT,  \px1    ; Tile pixel 1
	rjmp  .+6
	movw  ZL,      r8      ; r9: Code block 1 address high
	out   PIXOUT,  \px1    ; Tile pixel 1
	ld    r12,     X+      ; Attributes
	lsl   ZL
	adc   ZH,      r13     ; Added tile data * 2
	out   PIXOUT,  \px2    ; Tile pixel 2
	ld    r8,      X+      ; Tile index
	mul   r8,      r24     ; r24 = 16
	out   PIXOUT,  \px3    ; Tile pixel 3
	or    r0,      r25     ; r25 = row select
	cp    r8,      r21     ; r21 = first RAM tile address
	ijmp
.endm
.macro TB0_TAIL px2, px3
.endm
#endif

;
; Code block macro for Tile right half (1)
;
; Register usage: See above.
;
.macro TB1_HEAD px0, midl
	out   PIXOUT,  \px0    ; Tile pixel 4
	rjmp  \midl
.endm
.macro TB1_MIDL px1, px2, px3, tram
	brcc  .+18
	movw  ZL,      r0
	out   PIXOUT,  \px1    ; Tile pixel 5
	add   ZH,      r23     ; r23 = ROM tiles base
	lpm   r6,      Z+
	out   PIXOUT,  \px2    ; Tile pixel 6
	lpm   r8,      Z+
	movw  ZL,      r6      ; r7: Block 0 address high
	out   PIXOUT,  \px3    ; Tile pixel 7
	ijmp
	out   PIXOUT,  \px1    ; Tile pixel 5
	rjmp  \tram
.endm
.macro TB1_TRAM px2, px3
	movw  YL,      r0      ; RAM 0x0000 - 0x0FFF
	mov   ZH,      r7      ; r7: Block 0 address high
	out   PIXOUT,  \px2    ; Tile pixel 6
	ld    ZL,      Y+
	ld    r8,      Y+
	out   PIXOUT,  \px3    ; Tile pixel 7
	ijmp
.endm

;
; Code block for Tile left half, 3 attributes mode
;
; Register usage: See above with the following changes:
;
;  r7: r6: Attribute colors for index 2 and 3 (r4 and r5)
;
#if (M52_ENABLE_ATTR123 != 0)
.macro TB2_HEAD pxa0, midl
	out   PIXOUT,  \pxa0   ; Tile pixel 0
	rjmp  \midl
.endm
.macro TB2_MIDL px1, px2, px3
	movw  r4,      r6
	mov   r3,      r12     ; Update attribute colors
	out   PIXOUT,  \px1    ; Tile pixel 1
	ld    r0,      X+      ; Tile index
	ld    r12,     X+      ; Attribute 1
	out   PIXOUT,  \px2    ; Tile pixel 2
	mul   r0,      r24     ; r24 = 16
	or    r0,      r25     ; r25 = row select
	movw  ZL,      r8      ; r9: Code block 1 address high
	out   PIXOUT,  \px3    ; Tile pixel 3
	lsl   ZL
	adc   ZH,      r13     ; Added tile data * 2
	ijmp
.endm
#endif

;
; Code block for Tile right half, 3 attributes mode
;
; Register usage: See above
;
#if (M52_ENABLE_ATTR123 != 0)
.macro TB3_HEAD px0, midl
	out   PIXOUT,  \px0    ; Tile pixel 4
	rjmp  \midl
.endm
.macro TB3_MIDL px1, px2, px3
	movw  YL,      r0      ; RAM 0x0000 - 0x0FFF
	ldi   ZH,      hi8(pm(t2_jt))
	out   PIXOUT,  \px1    ; Tile pixel 5
	ld    r6,      X+      ; Attribute 2
	ld    r7,      X+      ; Attribute 3
	out   PIXOUT,  \px2    ; Tile pixel 6
	ld    ZL,      Y+
	ld    r8,      Y+
	out   PIXOUT,  \px3    ; Tile pixel 7
	lsl   ZL
	adc   ZH,      r13     ; Added tile data * 2
	ijmp
.endm
#endif

;
; Code block for Tile left half, Mirroring + 2 attributes mode
;
; Register usage: See above with the following changes:
;
;  r7: r6: Attribute colors for index 2 and 3 (r4 and r5)
;     r23: Block 1 address high for Mirrored tiles
;
#if (M52_ENABLE_ATTR23M != 0)
.macro TB4_HNOR pxa0, tail
	out   PIXOUT,  \pxa0   ; Tile pixel 0
	rjmp  \tail
.endm
.macro TB4_TNOR px1, px2, px3
	movw  ZL,      r8
	movw  r4,      r6
	out   PIXOUT,  \px1    ; Tile pixel 1
	ld    r22,     X+      ; Tile index
	muls  r22,     r24     ; r24 = 16
	out   PIXOUT,  \px2    ; Tile pixel 2
	ld    r6,      X+      ; Attribute 2
	ld    r7,      X+      ; Attribute 3
	out   PIXOUT,  \px3    ; Tile pixel 3
	ijmp
.endm
.macro TB4_HMIR pxa0, tail
	out   PIXOUT,  \pxa0   ; Tile pixel 0
	rjmp  \tail
.endm
.macro TB4_TMIR px1, px2, px3
	movw  ZL,      r22
	movw  r4,      r6
	out   PIXOUT,  \px1    ; Tile pixel 1
	ld    r22,     X+      ; Tile index
	muls  r22,     r24     ; r24 = 16
	out   PIXOUT,  \px2    ; Tile pixel 2
	ld    r6,      X+      ; Attribute 2
	ld    r7,      X+      ; Attribute 3
	out   PIXOUT,  \px3    ; Tile pixel 3
	ijmp
.endm
#endif

;
; Code block for Tile right half, Mirroring + 2 attributes mode
;
; Register usage: See above
;
#if (M52_ENABLE_ATTR23M != 0)
.macro TB5_HEAD px0, midl
	out   PIXOUT,  \px0    ; Tile pixel 4
	rjmp  \midl
.endm
.macro TB5_MIDL px1, px2, px3, tail
	or    r0,      r25     ; r25 = row select
	movw  YL,      r0
	out   PIXOUT,  \px1    ; Tile pixel 5
	brcc  \tail
	nop
	ldi   ZH,      hi8(pm(t4_jt_nor))
	subi  YH,      0xF0    ; RAM 0x0800 - 0x0FFF
	out   PIXOUT,  \px2    ; Tile pixel 6
	ld    ZL,      Y+
	ld    r8,      Y+      ; r9: Code block 1 (normal) address high
	out   PIXOUT,  \px3    ; Tile pixel 7
	lsl   ZL
	adc   ZH,      r13     ; Added tile data * 2
	ijmp
.endm
.macro TB5_TAIL px2, px3
	ldi   ZH,      hi8(pm(t4_jt_mir))
	subi  YH,      0xF8    ; RAM 0x0800 - 0x0FFF
	out   PIXOUT,  \px2    ; Tile pixel 6
	ld    r22,     Y+      ; r23: Code block 1 (mirrored) address high
	ld    ZL,      Y+
	out   PIXOUT,  \px3    ; Tile pixel 7
	lsl   ZL
	adc   ZH,      r13     ; Added tile data * 2
	ijmp
.endm
#endif



;
; No-attributes or Color 0 attributes left side code block assembly.
;

.balign 512

t0_jt_nattr:
	rjmp  t0_h00 + 0
	rjmp  t0_h01 + 0
	rjmp  t0_h02 + 0
	rjmp  t0_h03 + 0
	rjmp  t0_h04 + 0
	rjmp  t0_h05 + 0
	rjmp  t0_h06 + 0
	rjmp  t0_h07 + 0
	rjmp  t0_h08 + 0
	rjmp  t0_h09 + 0
	rjmp  t0_h0a + 0
	rjmp  t0_h0b + 0
	rjmp  t0_h0c + 0
	rjmp  t0_h0d + 0
	rjmp  t0_h0e + 0
	rjmp  t0_h0f + 0
	rjmp  t0_h10 + 0
	rjmp  t0_h11 + 0
	rjmp  t0_h12 + 0
	rjmp  t0_h13 + 0
	rjmp  t0_h14 + 0
	rjmp  t0_h15 + 0
	rjmp  t0_h16 + 0
	rjmp  t0_h17 + 0
	rjmp  t0_h18 + 0
	rjmp  t0_h19 + 0
	rjmp  t0_h1a + 0
	rjmp  t0_h1b + 0
	rjmp  t0_h1c + 0
	rjmp  t0_h1d + 0
	rjmp  t0_h1e + 0
	rjmp  t0_h1f + 0
	rjmp  t0_h20 + 0
	rjmp  t0_h21 + 0
	rjmp  t0_h22 + 0
	rjmp  t0_h23 + 0
	rjmp  t0_h24 + 0
	rjmp  t0_h25 + 0
	rjmp  t0_h26 + 0
	rjmp  t0_h27 + 0
	rjmp  t0_h28 + 0
	rjmp  t0_h29 + 0
	rjmp  t0_h2a + 0
	rjmp  t0_h2b + 0
	rjmp  t0_h2c + 0
	rjmp  t0_h2d + 0
	rjmp  t0_h2e + 0
	rjmp  t0_h2f + 0
	rjmp  t0_h30 + 0
	rjmp  t0_h31 + 0
	rjmp  t0_h32 + 0
	rjmp  t0_h33 + 0
	rjmp  t0_h34 + 0
	rjmp  t0_h35 + 0
	rjmp  t0_h36 + 0
	rjmp  t0_h37 + 0
	rjmp  t0_h38 + 0
	rjmp  t0_h39 + 0
	rjmp  t0_h3a + 0
	rjmp  t0_h3b + 0
	rjmp  t0_h3c + 0
	rjmp  t0_h3d + 0
	rjmp  t0_h3e + 0
	rjmp  t0_h3f + 0
	rjmp  t0_h40 + 0
	rjmp  t0_h41 + 0
	rjmp  t0_h42 + 0
	rjmp  t0_h43 + 0
	rjmp  t0_h44 + 0
	rjmp  t0_h45 + 0
	rjmp  t0_h46 + 0
	rjmp  t0_h47 + 0
	rjmp  t0_h48 + 0
	rjmp  t0_h49 + 0
	rjmp  t0_h4a + 0
	rjmp  t0_h4b + 0
	rjmp  t0_h4c + 0
	rjmp  t0_h4d + 0
	rjmp  t0_h4e + 0
	rjmp  t0_h4f + 0
	rjmp  t0_h50 + 0
	rjmp  t0_h51 + 0
	rjmp  t0_h52 + 0
	rjmp  t0_h53 + 0
	rjmp  t0_h54 + 0
	rjmp  t0_h55 + 0
	rjmp  t0_h56 + 0
	rjmp  t0_h57 + 0
	rjmp  t0_h58 + 0
	rjmp  t0_h59 + 0
	rjmp  t0_h5a + 0
	rjmp  t0_h5b + 0
	rjmp  t0_h5c + 0
	rjmp  t0_h5d + 0
	rjmp  t0_h5e + 0
	rjmp  t0_h5f + 0
	rjmp  t0_h60 + 0
	rjmp  t0_h61 + 0
	rjmp  t0_h62 + 0
	rjmp  t0_h63 + 0
	rjmp  t0_h64 + 0
	rjmp  t0_h65 + 0
	rjmp  t0_h66 + 0
	rjmp  t0_h67 + 0
	rjmp  t0_h68 + 0
	rjmp  t0_h69 + 0
	rjmp  t0_h6a + 0
	rjmp  t0_h6b + 0
	rjmp  t0_h6c + 0
	rjmp  t0_h6d + 0
	rjmp  t0_h6e + 0
	rjmp  t0_h6f + 0
	rjmp  t0_h70 + 0
	rjmp  t0_h71 + 0
	rjmp  t0_h72 + 0
	rjmp  t0_h73 + 0
	rjmp  t0_h74 + 0
	rjmp  t0_h75 + 0
	rjmp  t0_h76 + 0
	rjmp  t0_h77 + 0
	rjmp  t0_h78 + 0
	rjmp  t0_h79 + 0
	rjmp  t0_h7a + 0
	rjmp  t0_h7b + 0
	rjmp  t0_h7c + 0
	rjmp  t0_h7d + 0
	rjmp  t0_h7e + 0
	rjmp  t0_h7f + 0
	rjmp  t0_h80 + 0
	rjmp  t0_h81 + 0
	rjmp  t0_h82 + 0
	rjmp  t0_h83 + 0
	rjmp  t0_h84 + 0
	rjmp  t0_h85 + 0
	rjmp  t0_h86 + 0
	rjmp  t0_h87 + 0
	rjmp  t0_h88 + 0
	rjmp  t0_h89 + 0
	rjmp  t0_h8a + 0
	rjmp  t0_h8b + 0
	rjmp  t0_h8c + 0
	rjmp  t0_h8d + 0
	rjmp  t0_h8e + 0
	rjmp  t0_h8f + 0
	rjmp  t0_h90 + 0
	rjmp  t0_h91 + 0
	rjmp  t0_h92 + 0
	rjmp  t0_h93 + 0
	rjmp  t0_h94 + 0
	rjmp  t0_h95 + 0
	rjmp  t0_h96 + 0
	rjmp  t0_h97 + 0
	rjmp  t0_h98 + 0
	rjmp  t0_h99 + 0
	rjmp  t0_h9a + 0
	rjmp  t0_h9b + 0
	rjmp  t0_h9c + 0
	rjmp  t0_h9d + 0
	rjmp  t0_h9e + 0
	rjmp  t0_h9f + 0
	rjmp  t0_ha0 + 0
	rjmp  t0_ha1 + 0
	rjmp  t0_ha2 + 0
	rjmp  t0_ha3 + 0
	rjmp  t0_ha4 + 0
	rjmp  t0_ha5 + 0
	rjmp  t0_ha6 + 0
	rjmp  t0_ha7 + 0
	rjmp  t0_ha8 + 0
	rjmp  t0_ha9 + 0
	rjmp  t0_haa + 0
	rjmp  t0_hab + 0
	rjmp  t0_hac + 0
	rjmp  t0_had + 0
	rjmp  t0_hae + 0
	rjmp  t0_haf + 0
	rjmp  t0_hb0 + 0
	rjmp  t0_hb1 + 0
	rjmp  t0_hb2 + 0
	rjmp  t0_hb3 + 0
	rjmp  t0_hb4 + 0
	rjmp  t0_hb5 + 0
	rjmp  t0_hb6 + 0
	rjmp  t0_hb7 + 0
	rjmp  t0_hb8 + 0
	rjmp  t0_hb9 + 0
	rjmp  t0_hba + 0
	rjmp  t0_hbb + 0
	rjmp  t0_hbc + 0
	rjmp  t0_hbd + 0
	rjmp  t0_hbe + 0
	rjmp  t0_hbf + 0
	rjmp  t0_hc0 + 0
	rjmp  t0_hc1 + 0
	rjmp  t0_hc2 + 0
	rjmp  t0_hc3 + 0
	rjmp  t0_hc4 + 0
	rjmp  t0_hc5 + 0
	rjmp  t0_hc6 + 0
	rjmp  t0_hc7 + 0
	rjmp  t0_hc8 + 0
	rjmp  t0_hc9 + 0
	rjmp  t0_hca + 0
	rjmp  t0_hcb + 0
	rjmp  t0_hcc + 0
	rjmp  t0_hcd + 0
	rjmp  t0_hce + 0
	rjmp  t0_hcf + 0
	rjmp  t0_hd0 + 0
	rjmp  t0_hd1 + 0
	rjmp  t0_hd2 + 0
	rjmp  t0_hd3 + 0
	rjmp  t0_hd4 + 0
	rjmp  t0_hd5 + 0
	rjmp  t0_hd6 + 0
	rjmp  t0_hd7 + 0
	rjmp  t0_hd8 + 0
	rjmp  t0_hd9 + 0
	rjmp  t0_hda + 0
	rjmp  t0_hdb + 0
	rjmp  t0_hdc + 0
	rjmp  t0_hdd + 0
	rjmp  t0_hde + 0
	rjmp  t0_hdf + 0
	rjmp  t0_he0 + 0
	rjmp  t0_he1 + 0
	rjmp  t0_he2 + 0
	rjmp  t0_he3 + 0
	rjmp  t0_he4 + 0
	rjmp  t0_he5 + 0
	rjmp  t0_he6 + 0
	rjmp  t0_he7 + 0
	rjmp  t0_he8 + 0
	rjmp  t0_he9 + 0
	rjmp  t0_hea + 0
	rjmp  t0_heb + 0
	rjmp  t0_hec + 0
	rjmp  t0_hed + 0
	rjmp  t0_hee + 0
	rjmp  t0_hef + 0
	rjmp  t0_hf0 + 0
	rjmp  t0_hf1 + 0
	rjmp  t0_hf2 + 0
	rjmp  t0_hf3 + 0
	rjmp  t0_hf4 + 0
	rjmp  t0_hf5 + 0
	rjmp  t0_hf6 + 0
	rjmp  t0_hf7 + 0
	rjmp  t0_hf8 + 0
	rjmp  t0_hf9 + 0
	rjmp  t0_hfa + 0
	rjmp  t0_hfb + 0
	rjmp  t0_hfc + 0
	rjmp  t0_hfd + 0
	rjmp  t0_hfe + 0
	rjmp  t0_hff + 0

#if (M52_ENABLE_ATTR0 != 0)
t0_jt_attr0:
	rjmp  t0_h00 + 4
	rjmp  t0_h01 + 4
	rjmp  t0_h02 + 4
	rjmp  t0_h03 + 4
	rjmp  t0_h04 + 4
	rjmp  t0_h05 + 4
	rjmp  t0_h06 + 4
	rjmp  t0_h07 + 4
	rjmp  t0_h08 + 4
	rjmp  t0_h09 + 4
	rjmp  t0_h0a + 4
	rjmp  t0_h0b + 4
	rjmp  t0_h0c + 4
	rjmp  t0_h0d + 4
	rjmp  t0_h0e + 4
	rjmp  t0_h0f + 4
	rjmp  t0_h10 + 4
	rjmp  t0_h11 + 4
	rjmp  t0_h12 + 4
	rjmp  t0_h13 + 4
	rjmp  t0_h14 + 4
	rjmp  t0_h15 + 4
	rjmp  t0_h16 + 4
	rjmp  t0_h17 + 4
	rjmp  t0_h18 + 4
	rjmp  t0_h19 + 4
	rjmp  t0_h1a + 4
	rjmp  t0_h1b + 4
	rjmp  t0_h1c + 4
	rjmp  t0_h1d + 4
	rjmp  t0_h1e + 4
	rjmp  t0_h1f + 4
	rjmp  t0_h20 + 4
	rjmp  t0_h21 + 4
	rjmp  t0_h22 + 4
	rjmp  t0_h23 + 4
	rjmp  t0_h24 + 4
	rjmp  t0_h25 + 4
	rjmp  t0_h26 + 4
	rjmp  t0_h27 + 4
	rjmp  t0_h28 + 4
	rjmp  t0_h29 + 4
	rjmp  t0_h2a + 4
	rjmp  t0_h2b + 4
	rjmp  t0_h2c + 4
	rjmp  t0_h2d + 4
	rjmp  t0_h2e + 4
	rjmp  t0_h2f + 4
	rjmp  t0_h30 + 4
	rjmp  t0_h31 + 4
	rjmp  t0_h32 + 4
	rjmp  t0_h33 + 4
	rjmp  t0_h34 + 4
	rjmp  t0_h35 + 4
	rjmp  t0_h36 + 4
	rjmp  t0_h37 + 4
	rjmp  t0_h38 + 4
	rjmp  t0_h39 + 4
	rjmp  t0_h3a + 4
	rjmp  t0_h3b + 4
	rjmp  t0_h3c + 4
	rjmp  t0_h3d + 4
	rjmp  t0_h3e + 4
	rjmp  t0_h3f + 4
	rjmp  t0_h40 + 4
	rjmp  t0_h41 + 4
	rjmp  t0_h42 + 4
	rjmp  t0_h43 + 4
	rjmp  t0_h44 + 4
	rjmp  t0_h45 + 4
	rjmp  t0_h46 + 4
	rjmp  t0_h47 + 4
	rjmp  t0_h48 + 4
	rjmp  t0_h49 + 4
	rjmp  t0_h4a + 4
	rjmp  t0_h4b + 4
	rjmp  t0_h4c + 4
	rjmp  t0_h4d + 4
	rjmp  t0_h4e + 4
	rjmp  t0_h4f + 4
	rjmp  t0_h50 + 4
	rjmp  t0_h51 + 4
	rjmp  t0_h52 + 4
	rjmp  t0_h53 + 4
	rjmp  t0_h54 + 4
	rjmp  t0_h55 + 4
	rjmp  t0_h56 + 4
	rjmp  t0_h57 + 4
	rjmp  t0_h58 + 4
	rjmp  t0_h59 + 4
	rjmp  t0_h5a + 4
	rjmp  t0_h5b + 4
	rjmp  t0_h5c + 4
	rjmp  t0_h5d + 4
	rjmp  t0_h5e + 4
	rjmp  t0_h5f + 4
	rjmp  t0_h60 + 4
	rjmp  t0_h61 + 4
	rjmp  t0_h62 + 4
	rjmp  t0_h63 + 4
	rjmp  t0_h64 + 4
	rjmp  t0_h65 + 4
	rjmp  t0_h66 + 4
	rjmp  t0_h67 + 4
	rjmp  t0_h68 + 4
	rjmp  t0_h69 + 4
	rjmp  t0_h6a + 4
	rjmp  t0_h6b + 4
	rjmp  t0_h6c + 4
	rjmp  t0_h6d + 4
	rjmp  t0_h6e + 4
	rjmp  t0_h6f + 4
	rjmp  t0_h70 + 4
	rjmp  t0_h71 + 4
	rjmp  t0_h72 + 4
	rjmp  t0_h73 + 4
	rjmp  t0_h74 + 4
	rjmp  t0_h75 + 4
	rjmp  t0_h76 + 4
	rjmp  t0_h77 + 4
	rjmp  t0_h78 + 4
	rjmp  t0_h79 + 4
	rjmp  t0_h7a + 4
	rjmp  t0_h7b + 4
	rjmp  t0_h7c + 4
	rjmp  t0_h7d + 4
	rjmp  t0_h7e + 4
	rjmp  t0_h7f + 4
	rjmp  t0_h80 + 4
	rjmp  t0_h81 + 4
	rjmp  t0_h82 + 4
	rjmp  t0_h83 + 4
	rjmp  t0_h84 + 4
	rjmp  t0_h85 + 4
	rjmp  t0_h86 + 4
	rjmp  t0_h87 + 4
	rjmp  t0_h88 + 4
	rjmp  t0_h89 + 4
	rjmp  t0_h8a + 4
	rjmp  t0_h8b + 4
	rjmp  t0_h8c + 4
	rjmp  t0_h8d + 4
	rjmp  t0_h8e + 4
	rjmp  t0_h8f + 4
	rjmp  t0_h90 + 4
	rjmp  t0_h91 + 4
	rjmp  t0_h92 + 4
	rjmp  t0_h93 + 4
	rjmp  t0_h94 + 4
	rjmp  t0_h95 + 4
	rjmp  t0_h96 + 4
	rjmp  t0_h97 + 4
	rjmp  t0_h98 + 4
	rjmp  t0_h99 + 4
	rjmp  t0_h9a + 4
	rjmp  t0_h9b + 4
	rjmp  t0_h9c + 4
	rjmp  t0_h9d + 4
	rjmp  t0_h9e + 4
	rjmp  t0_h9f + 4
	rjmp  t0_ha0 + 4
	rjmp  t0_ha1 + 4
	rjmp  t0_ha2 + 4
	rjmp  t0_ha3 + 4
	rjmp  t0_ha4 + 4
	rjmp  t0_ha5 + 4
	rjmp  t0_ha6 + 4
	rjmp  t0_ha7 + 4
	rjmp  t0_ha8 + 4
	rjmp  t0_ha9 + 4
	rjmp  t0_haa + 4
	rjmp  t0_hab + 4
	rjmp  t0_hac + 4
	rjmp  t0_had + 4
	rjmp  t0_hae + 4
	rjmp  t0_haf + 4
	rjmp  t0_hb0 + 4
	rjmp  t0_hb1 + 4
	rjmp  t0_hb2 + 4
	rjmp  t0_hb3 + 4
	rjmp  t0_hb4 + 4
	rjmp  t0_hb5 + 4
	rjmp  t0_hb6 + 4
	rjmp  t0_hb7 + 4
	rjmp  t0_hb8 + 4
	rjmp  t0_hb9 + 4
	rjmp  t0_hba + 4
	rjmp  t0_hbb + 4
	rjmp  t0_hbc + 4
	rjmp  t0_hbd + 4
	rjmp  t0_hbe + 4
	rjmp  t0_hbf + 4
	rjmp  t0_hc0 + 4
	rjmp  t0_hc1 + 4
	rjmp  t0_hc2 + 4
	rjmp  t0_hc3 + 4
	rjmp  t0_hc4 + 4
	rjmp  t0_hc5 + 4
	rjmp  t0_hc6 + 4
	rjmp  t0_hc7 + 4
	rjmp  t0_hc8 + 4
	rjmp  t0_hc9 + 4
	rjmp  t0_hca + 4
	rjmp  t0_hcb + 4
	rjmp  t0_hcc + 4
	rjmp  t0_hcd + 4
	rjmp  t0_hce + 4
	rjmp  t0_hcf + 4
	rjmp  t0_hd0 + 4
	rjmp  t0_hd1 + 4
	rjmp  t0_hd2 + 4
	rjmp  t0_hd3 + 4
	rjmp  t0_hd4 + 4
	rjmp  t0_hd5 + 4
	rjmp  t0_hd6 + 4
	rjmp  t0_hd7 + 4
	rjmp  t0_hd8 + 4
	rjmp  t0_hd9 + 4
	rjmp  t0_hda + 4
	rjmp  t0_hdb + 4
	rjmp  t0_hdc + 4
	rjmp  t0_hdd + 4
	rjmp  t0_hde + 4
	rjmp  t0_hdf + 4
	rjmp  t0_he0 + 4
	rjmp  t0_he1 + 4
	rjmp  t0_he2 + 4
	rjmp  t0_he3 + 4
	rjmp  t0_he4 + 4
	rjmp  t0_he5 + 4
	rjmp  t0_he6 + 4
	rjmp  t0_he7 + 4
	rjmp  t0_he8 + 4
	rjmp  t0_he9 + 4
	rjmp  t0_hea + 4
	rjmp  t0_heb + 4
	rjmp  t0_hec + 4
	rjmp  t0_hed + 4
	rjmp  t0_hee + 4
	rjmp  t0_hef + 4
	rjmp  t0_hf0 + 4
	rjmp  t0_hf1 + 4
	rjmp  t0_hf2 + 4
	rjmp  t0_hf3 + 4
	rjmp  t0_hf4 + 4
	rjmp  t0_hf5 + 4
	rjmp  t0_hf6 + 4
	rjmp  t0_hf7 + 4
	rjmp  t0_hf8 + 4
	rjmp  t0_hf9 + 4
	rjmp  t0_hfa + 4
	rjmp  t0_hfb + 4
	rjmp  t0_hfc + 4
	rjmp  t0_hfd + 4
	rjmp  t0_hfe + 4
	rjmp  t0_hff + 4
#endif

t0_h00:	TB0_HEAD r2, r12, t0_m00
t0_h01:	TB0_HEAD r2, r12, t0_m01
t0_h02:	TB0_HEAD r2, r12, t0_m02
t0_h03:	TB0_HEAD r2, r12, t0_m03
t0_h04:	TB0_HEAD r2, r12, t0_m04
t0_h05:	TB0_HEAD r2, r12, t0_m05
t0_h06:	TB0_HEAD r2, r12, t0_m06
t0_h07:	TB0_HEAD r2, r12, t0_m07
t0_h08:	TB0_HEAD r2, r12, t0_m08
t0_h09:	TB0_HEAD r2, r12, t0_m09
t0_h0a:	TB0_HEAD r2, r12, t0_m0a
t0_h0b:	TB0_HEAD r2, r12, t0_m0b
t0_h0c:	TB0_HEAD r2, r12, t0_m0c
t0_h0d:	TB0_HEAD r2, r12, t0_m0d
t0_h0e:	TB0_HEAD r2, r12, t0_m0e
t0_h0f:	TB0_HEAD r2, r12, t0_m0f
t0_h10:	TB0_HEAD r2, r12, t0_m10
t0_h11:	TB0_HEAD r2, r12, t0_m11
t0_h12:	TB0_HEAD r2, r12, t0_m12
t0_h13:	TB0_HEAD r2, r12, t0_m13
t0_h14:	TB0_HEAD r2, r12, t0_m14
t0_h15:	TB0_HEAD r2, r12, t0_m15
t0_h16:	TB0_HEAD r2, r12, t0_m16
t0_h17:	TB0_HEAD r2, r12, t0_m17
t0_h18:	TB0_HEAD r2, r12, t0_m18
t0_h19:	TB0_HEAD r2, r12, t0_m19
t0_h1a:	TB0_HEAD r2, r12, t0_m1a
t0_h1b:	TB0_HEAD r2, r12, t0_m1b
t0_h1c:	TB0_HEAD r2, r12, t0_m1c
t0_h1d:	TB0_HEAD r2, r12, t0_m1d
t0_h1e:	TB0_HEAD r2, r12, t0_m1e
t0_h1f:	TB0_HEAD r2, r12, t0_m1f
t0_h20:	TB0_HEAD r2, r12, t0_m20
t0_h21:	TB0_HEAD r2, r12, t0_m21
t0_h22:	TB0_HEAD r2, r12, t0_m22
t0_h23:	TB0_HEAD r2, r12, t0_m23
t0_h24:	TB0_HEAD r2, r12, t0_m24
t0_h25:	TB0_HEAD r2, r12, t0_m25
t0_h26:	TB0_HEAD r2, r12, t0_m26
t0_h27:	TB0_HEAD r2, r12, t0_m27
t0_h28:	TB0_HEAD r2, r12, t0_m28
t0_h29:	TB0_HEAD r2, r12, t0_m29
t0_h2a:	TB0_HEAD r2, r12, t0_m2a
t0_h2b:	TB0_HEAD r2, r12, t0_m2b
t0_h2c:	TB0_HEAD r2, r12, t0_m2c
t0_h2d:	TB0_HEAD r2, r12, t0_m2d
t0_h2e:	TB0_HEAD r2, r12, t0_m2e
t0_h2f:	TB0_HEAD r2, r12, t0_m2f
t0_h30:	TB0_HEAD r2, r12, t0_m30
t0_h31:	TB0_HEAD r2, r12, t0_m31
t0_h32:	TB0_HEAD r2, r12, t0_m32
t0_h33:	TB0_HEAD r2, r12, t0_m33
t0_h34:	TB0_HEAD r2, r12, t0_m34
t0_h35:	TB0_HEAD r2, r12, t0_m35
t0_h36:	TB0_HEAD r2, r12, t0_m36
t0_h37:	TB0_HEAD r2, r12, t0_m37
t0_h38:	TB0_HEAD r2, r12, t0_m38
t0_h39:	TB0_HEAD r2, r12, t0_m39
t0_h3a:	TB0_HEAD r2, r12, t0_m3a
t0_h3b:	TB0_HEAD r2, r12, t0_m3b
t0_h3c:	TB0_HEAD r2, r12, t0_m3c
t0_h3d:	TB0_HEAD r2, r12, t0_m3d
t0_h3e:	TB0_HEAD r2, r12, t0_m3e
t0_h3f:	TB0_HEAD r2, r12, t0_m3f
t0_h40:	TB0_HEAD r3, r3,  t0_m00
t0_h41:	TB0_HEAD r3, r3,  t0_m01
t0_h42:	TB0_HEAD r3, r3,  t0_m02
t0_h43:	TB0_HEAD r3, r3,  t0_m03
t0_h44:	TB0_HEAD r3, r3,  t0_m04
t0_h45:	TB0_HEAD r3, r3,  t0_m05
t0_h46:	TB0_HEAD r3, r3,  t0_m06
t0_h47:	TB0_HEAD r3, r3,  t0_m07
t0_h48:	TB0_HEAD r3, r3,  t0_m08
t0_h49:	TB0_HEAD r3, r3,  t0_m09
t0_h4a:	TB0_HEAD r3, r3,  t0_m0a
t0_h4b:	TB0_HEAD r3, r3,  t0_m0b
t0_h4c:	TB0_HEAD r3, r3,  t0_m0c
t0_h4d:	TB0_HEAD r3, r3,  t0_m0d
t0_h4e:	TB0_HEAD r3, r3,  t0_m0e
t0_h4f:	TB0_HEAD r3, r3,  t0_m0f
t0_h50:	TB0_HEAD r3, r3,  t0_m10
t0_h51:	TB0_HEAD r3, r3,  t0_m11
t0_h52:	TB0_HEAD r3, r3,  t0_m12
t0_h53:	TB0_HEAD r3, r3,  t0_m13
t0_h54:	TB0_HEAD r3, r3,  t0_m14
t0_h55:	TB0_HEAD r3, r3,  t0_m15
t0_h56:	TB0_HEAD r3, r3,  t0_m16
t0_h57:	TB0_HEAD r3, r3,  t0_m17
t0_h58:	TB0_HEAD r3, r3,  t0_m18
t0_h59:	TB0_HEAD r3, r3,  t0_m19
t0_h5a:	TB0_HEAD r3, r3,  t0_m1a
t0_h5b:	TB0_HEAD r3, r3,  t0_m1b
t0_h5c:	TB0_HEAD r3, r3,  t0_m1c
t0_h5d:	TB0_HEAD r3, r3,  t0_m1d
t0_h5e:	TB0_HEAD r3, r3,  t0_m1e
t0_h5f:	TB0_HEAD r3, r3,  t0_m1f
t0_h60:	TB0_HEAD r3, r3,  t0_m20
t0_h61:	TB0_HEAD r3, r3,  t0_m21
t0_h62:	TB0_HEAD r3, r3,  t0_m22
t0_h63:	TB0_HEAD r3, r3,  t0_m23
t0_h64:	TB0_HEAD r3, r3,  t0_m24
t0_h65:	TB0_HEAD r3, r3,  t0_m25
t0_h66:	TB0_HEAD r3, r3,  t0_m26
t0_h67:	TB0_HEAD r3, r3,  t0_m27
t0_h68:	TB0_HEAD r3, r3,  t0_m28
t0_h69:	TB0_HEAD r3, r3,  t0_m29
t0_h6a:	TB0_HEAD r3, r3,  t0_m2a
t0_h6b:	TB0_HEAD r3, r3,  t0_m2b
t0_h6c:	TB0_HEAD r3, r3,  t0_m2c
t0_h6d:	TB0_HEAD r3, r3,  t0_m2d
t0_h6e:	TB0_HEAD r3, r3,  t0_m2e
t0_h6f:	TB0_HEAD r3, r3,  t0_m2f
t0_h70:	TB0_HEAD r3, r3,  t0_m30
t0_h71:	TB0_HEAD r3, r3,  t0_m31
t0_h72:	TB0_HEAD r3, r3,  t0_m32
t0_h73:	TB0_HEAD r3, r3,  t0_m33
t0_h74:	TB0_HEAD r3, r3,  t0_m34
t0_h75:	TB0_HEAD r3, r3,  t0_m35
t0_h76:	TB0_HEAD r3, r3,  t0_m36
t0_h77:	TB0_HEAD r3, r3,  t0_m37
t0_h78:	TB0_HEAD r3, r3,  t0_m38
t0_h79:	TB0_HEAD r3, r3,  t0_m39
t0_h7a:	TB0_HEAD r3, r3,  t0_m3a
t0_h7b:	TB0_HEAD r3, r3,  t0_m3b
t0_h7c:	TB0_HEAD r3, r3,  t0_m3c
t0_h7d:	TB0_HEAD r3, r3,  t0_m3d
t0_h7e:	TB0_HEAD r3, r3,  t0_m3e
t0_h7f:	TB0_HEAD r3, r3,  t0_m3f
t0_h80:	TB0_HEAD r4, r4,  t0_m00
t0_h81:	TB0_HEAD r4, r4,  t0_m01
t0_h82:	TB0_HEAD r4, r4,  t0_m02
t0_h83:	TB0_HEAD r4, r4,  t0_m03
t0_h84:	TB0_HEAD r4, r4,  t0_m04
t0_h85:	TB0_HEAD r4, r4,  t0_m05
t0_h86:	TB0_HEAD r4, r4,  t0_m06
t0_h87:	TB0_HEAD r4, r4,  t0_m07
t0_h88:	TB0_HEAD r4, r4,  t0_m08
t0_h89:	TB0_HEAD r4, r4,  t0_m09
t0_h8a:	TB0_HEAD r4, r4,  t0_m0a
t0_h8b:	TB0_HEAD r4, r4,  t0_m0b
t0_h8c:	TB0_HEAD r4, r4,  t0_m0c
t0_h8d:	TB0_HEAD r4, r4,  t0_m0d
t0_h8e:	TB0_HEAD r4, r4,  t0_m0e
t0_h8f:	TB0_HEAD r4, r4,  t0_m0f
t0_h90:	TB0_HEAD r4, r4,  t0_m10
t0_h91:	TB0_HEAD r4, r4,  t0_m11
t0_h92:	TB0_HEAD r4, r4,  t0_m12
t0_h93:	TB0_HEAD r4, r4,  t0_m13
t0_h94:	TB0_HEAD r4, r4,  t0_m14
t0_h95:	TB0_HEAD r4, r4,  t0_m15
t0_h96:	TB0_HEAD r4, r4,  t0_m16
t0_h97:	TB0_HEAD r4, r4,  t0_m17
t0_h98:	TB0_HEAD r4, r4,  t0_m18
t0_h99:	TB0_HEAD r4, r4,  t0_m19
t0_h9a:	TB0_HEAD r4, r4,  t0_m1a
t0_h9b:	TB0_HEAD r4, r4,  t0_m1b
t0_h9c:	TB0_HEAD r4, r4,  t0_m1c
t0_h9d:	TB0_HEAD r4, r4,  t0_m1d
t0_h9e:	TB0_HEAD r4, r4,  t0_m1e
t0_h9f:	TB0_HEAD r4, r4,  t0_m1f
t0_ha0:	TB0_HEAD r4, r4,  t0_m20
t0_ha1:	TB0_HEAD r4, r4,  t0_m21
t0_ha2:	TB0_HEAD r4, r4,  t0_m22
t0_ha3:	TB0_HEAD r4, r4,  t0_m23
t0_ha4:	TB0_HEAD r4, r4,  t0_m24
t0_ha5:	TB0_HEAD r4, r4,  t0_m25
t0_ha6:	TB0_HEAD r4, r4,  t0_m26
t0_ha7:	TB0_HEAD r4, r4,  t0_m27
t0_ha8:	TB0_HEAD r4, r4,  t0_m28
t0_ha9:	TB0_HEAD r4, r4,  t0_m29
t0_haa:	TB0_HEAD r4, r4,  t0_m2a
t0_hab:	TB0_HEAD r4, r4,  t0_m2b
t0_hac:	TB0_HEAD r4, r4,  t0_m2c
t0_had:	TB0_HEAD r4, r4,  t0_m2d
t0_hae:	TB0_HEAD r4, r4,  t0_m2e
t0_haf:	TB0_HEAD r4, r4,  t0_m2f
t0_hb0:	TB0_HEAD r4, r4,  t0_m30
t0_hb1:	TB0_HEAD r4, r4,  t0_m31
t0_hb2:	TB0_HEAD r4, r4,  t0_m32
t0_hb3:	TB0_HEAD r4, r4,  t0_m33
t0_hb4:	TB0_HEAD r4, r4,  t0_m34
t0_hb5:	TB0_HEAD r4, r4,  t0_m35
t0_hb6:	TB0_HEAD r4, r4,  t0_m36
t0_hb7:	TB0_HEAD r4, r4,  t0_m37
t0_hb8:	TB0_HEAD r4, r4,  t0_m38
t0_hb9:	TB0_HEAD r4, r4,  t0_m39
t0_hba:	TB0_HEAD r4, r4,  t0_m3a
t0_hbb:	TB0_HEAD r4, r4,  t0_m3b
t0_hbc:	TB0_HEAD r4, r4,  t0_m3c
t0_hbd:	TB0_HEAD r4, r4,  t0_m3d
t0_hbe:	TB0_HEAD r4, r4,  t0_m3e
t0_hbf:	TB0_HEAD r4, r4,  t0_m3f
t0_hc0:	TB0_HEAD r5, r5,  t0_m00
t0_hc1:	TB0_HEAD r5, r5,  t0_m01
t0_hc2:	TB0_HEAD r5, r5,  t0_m02
t0_hc3:	TB0_HEAD r5, r5,  t0_m03
t0_hc4:	TB0_HEAD r5, r5,  t0_m04
t0_hc5:	TB0_HEAD r5, r5,  t0_m05
t0_hc6:	TB0_HEAD r5, r5,  t0_m06
t0_hc7:	TB0_HEAD r5, r5,  t0_m07
t0_hc8:	TB0_HEAD r5, r5,  t0_m08
t0_hc9:	TB0_HEAD r5, r5,  t0_m09
t0_hca:	TB0_HEAD r5, r5,  t0_m0a
t0_hcb:	TB0_HEAD r5, r5,  t0_m0b
t0_hcc:	TB0_HEAD r5, r5,  t0_m0c
t0_hcd:	TB0_HEAD r5, r5,  t0_m0d
t0_hce:	TB0_HEAD r5, r5,  t0_m0e
t0_hcf:	TB0_HEAD r5, r5,  t0_m0f
t0_hd0:	TB0_HEAD r5, r5,  t0_m10
t0_hd1:	TB0_HEAD r5, r5,  t0_m11
t0_hd2:	TB0_HEAD r5, r5,  t0_m12
t0_hd3:	TB0_HEAD r5, r5,  t0_m13
t0_hd4:	TB0_HEAD r5, r5,  t0_m14
t0_hd5:	TB0_HEAD r5, r5,  t0_m15
t0_hd6:	TB0_HEAD r5, r5,  t0_m16
t0_hd7:	TB0_HEAD r5, r5,  t0_m17
t0_hd8:	TB0_HEAD r5, r5,  t0_m18
t0_hd9:	TB0_HEAD r5, r5,  t0_m19
t0_hda:	TB0_HEAD r5, r5,  t0_m1a
t0_hdb:	TB0_HEAD r5, r5,  t0_m1b
t0_hdc:	TB0_HEAD r5, r5,  t0_m1c
t0_hdd:	TB0_HEAD r5, r5,  t0_m1d
t0_hde:	TB0_HEAD r5, r5,  t0_m1e
t0_hdf:	TB0_HEAD r5, r5,  t0_m1f
t0_he0:	TB0_HEAD r5, r5,  t0_m20
t0_he1:	TB0_HEAD r5, r5,  t0_m21
t0_he2:	TB0_HEAD r5, r5,  t0_m22
t0_he3:	TB0_HEAD r5, r5,  t0_m23
t0_he4:	TB0_HEAD r5, r5,  t0_m24
t0_he5:	TB0_HEAD r5, r5,  t0_m25
t0_he6:	TB0_HEAD r5, r5,  t0_m26
t0_he7:	TB0_HEAD r5, r5,  t0_m27
t0_he8:	TB0_HEAD r5, r5,  t0_m28
t0_he9:	TB0_HEAD r5, r5,  t0_m29
t0_hea:	TB0_HEAD r5, r5,  t0_m2a
t0_heb:	TB0_HEAD r5, r5,  t0_m2b
t0_hec:	TB0_HEAD r5, r5,  t0_m2c
t0_hed:	TB0_HEAD r5, r5,  t0_m2d
t0_hee:	TB0_HEAD r5, r5,  t0_m2e
t0_hef:	TB0_HEAD r5, r5,  t0_m2f
t0_hf0:	TB0_HEAD r5, r5,  t0_m30
t0_hf1:	TB0_HEAD r5, r5,  t0_m31
t0_hf2:	TB0_HEAD r5, r5,  t0_m32
t0_hf3:	TB0_HEAD r5, r5,  t0_m33
t0_hf4:	TB0_HEAD r5, r5,  t0_m34
t0_hf5:	TB0_HEAD r5, r5,  t0_m35
t0_hf6:	TB0_HEAD r5, r5,  t0_m36
t0_hf7:	TB0_HEAD r5, r5,  t0_m37
t0_hf8:	TB0_HEAD r5, r5,  t0_m38
t0_hf9:	TB0_HEAD r5, r5,  t0_m39
t0_hfa:	TB0_HEAD r5, r5,  t0_m3a
t0_hfb:	TB0_HEAD r5, r5,  t0_m3b
t0_hfc:	TB0_HEAD r5, r5,  t0_m3c
t0_hfd:	TB0_HEAD r5, r5,  t0_m3d
t0_hfe:	TB0_HEAD r5, r5,  t0_m3e
t0_hff:	TB0_HEAD r5, r5,  t0_m3f

t0_m00:	TB0_MIDL r2, r2, r2, t0_t0
t0_m01:	TB0_MIDL r2, r2, r3, t0_t1
t0_m02:	TB0_MIDL r2, r2, r4, t0_t2
t0_m03:	TB0_MIDL r2, r2, r5, t0_t3
t0_m04:	TB0_MIDL r2, r3, r2, t0_t4
t0_m05:	TB0_MIDL r2, r3, r3, t0_t5
t0_m06:	TB0_MIDL r2, r3, r4, t0_t6
t0_m07:	TB0_MIDL r2, r3, r5, t0_t7
t0_m08:	TB0_MIDL r2, r4, r2, t0_t8
t0_m09:	TB0_MIDL r2, r4, r3, t0_t9
t0_m0a:	TB0_MIDL r2, r4, r4, t0_ta
t0_m0b:	TB0_MIDL r2, r4, r5, t0_tb
t0_m0c:	TB0_MIDL r2, r5, r2, t0_tc
t0_m0d:	TB0_MIDL r2, r5, r3, t0_td
t0_m0e:	TB0_MIDL r2, r5, r4, t0_te
t0_m0f:	TB0_MIDL r2, r5, r5, t0_tf
t0_m10:	TB0_MIDL r3, r2, r2, t0_t0
t0_m11:	TB0_MIDL r3, r2, r3, t0_t1
t0_m12:	TB0_MIDL r3, r2, r4, t0_t2
t0_m13:	TB0_MIDL r3, r2, r5, t0_t3
t0_m14:	TB0_MIDL r3, r3, r2, t0_t4
t0_m15:	TB0_MIDL r3, r3, r3, t0_t5
t0_m16:	TB0_MIDL r3, r3, r4, t0_t6
t0_m17:	TB0_MIDL r3, r3, r5, t0_t7
t0_m18:	TB0_MIDL r3, r4, r2, t0_t8
t0_m19:	TB0_MIDL r3, r4, r3, t0_t9
t0_m1a:	TB0_MIDL r3, r4, r4, t0_ta
t0_m1b:	TB0_MIDL r3, r4, r5, t0_tb
t0_m1c:	TB0_MIDL r3, r5, r2, t0_tc
t0_m1d:	TB0_MIDL r3, r5, r3, t0_td
t0_m1e:	TB0_MIDL r3, r5, r4, t0_te
t0_m1f:	TB0_MIDL r3, r5, r5, t0_tf
t0_m20:	TB0_MIDL r4, r2, r2, t0_t0
t0_m21:	TB0_MIDL r4, r2, r3, t0_t1
t0_m22:	TB0_MIDL r4, r2, r4, t0_t2
t0_m23:	TB0_MIDL r4, r2, r5, t0_t3
t0_m24:	TB0_MIDL r4, r3, r2, t0_t4
t0_m25:	TB0_MIDL r4, r3, r3, t0_t5
t0_m26:	TB0_MIDL r4, r3, r4, t0_t6
t0_m27:	TB0_MIDL r4, r3, r5, t0_t7
t0_m28:	TB0_MIDL r4, r4, r2, t0_t8
t0_m29:	TB0_MIDL r4, r4, r3, t0_t9
t0_m2a:	TB0_MIDL r4, r4, r4, t0_ta
t0_m2b:	TB0_MIDL r4, r4, r5, t0_tb
t0_m2c:	TB0_MIDL r4, r5, r2, t0_tc
t0_m2d:	TB0_MIDL r4, r5, r3, t0_td
t0_m2e:	TB0_MIDL r4, r5, r4, t0_te
t0_m2f:	TB0_MIDL r4, r5, r5, t0_tf
t0_m30:	TB0_MIDL r5, r2, r2, t0_t0
t0_m31:	TB0_MIDL r5, r2, r3, t0_t1
t0_m32:	TB0_MIDL r5, r2, r4, t0_t2
t0_m33:	TB0_MIDL r5, r2, r5, t0_t3
t0_m34:	TB0_MIDL r5, r3, r2, t0_t4
t0_m35:	TB0_MIDL r5, r3, r3, t0_t5
t0_m36:	TB0_MIDL r5, r3, r4, t0_t6
t0_m37:	TB0_MIDL r5, r3, r5, t0_t7
t0_m38:	TB0_MIDL r5, r4, r2, t0_t8
t0_m39:	TB0_MIDL r5, r4, r3, t0_t9
t0_m3a:	TB0_MIDL r5, r4, r4, t0_ta
t0_m3b:	TB0_MIDL r5, r4, r5, t0_tb
t0_m3c:	TB0_MIDL r5, r5, r2, t0_tc
t0_m3d:	TB0_MIDL r5, r5, r3, t0_td
t0_m3e:	TB0_MIDL r5, r5, r4, t0_te
t0_m3f:	TB0_MIDL r5, r5, r5, t0_tf

t0_t0:	TB0_TAIL r2, r2
t0_t1:	TB0_TAIL r2, r3
t0_t2:	TB0_TAIL r2, r4
t0_t3:	TB0_TAIL r2, r5
t0_t4:	TB0_TAIL r3, r2
t0_t5:	TB0_TAIL r3, r3
t0_t6:	TB0_TAIL r3, r4
t0_t7:	TB0_TAIL r3, r5
t0_t8:	TB0_TAIL r4, r2
t0_t9:	TB0_TAIL r4, r3
t0_ta:	TB0_TAIL r4, r4
t0_tb:	TB0_TAIL r4, r5
t0_tc:	TB0_TAIL r5, r2
t0_td:	TB0_TAIL r5, r3
t0_te:	TB0_TAIL r5, r4
t0_tf:	TB0_TAIL r5, r5



;
; sp_tmdec4:   Sprite mask decoder table for 3+1 color sprites (to low nybble)
;

.balign 256

sp_tmdec4:
	.byte 0x00, 0x01, 0x01, 0x01, 0x02, 0x03, 0x03, 0x03, 0x02, 0x03, 0x03, 0x03, 0x02, 0x03, 0x03, 0x03
	.byte 0x04, 0x05, 0x05, 0x05, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07
	.byte 0x04, 0x05, 0x05, 0x05, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07
	.byte 0x04, 0x05, 0x05, 0x05, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07, 0x06, 0x07, 0x07, 0x07
	.byte 0x08, 0x09, 0x09, 0x09, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x08, 0x09, 0x09, 0x09, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x08, 0x09, 0x09, 0x09, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B, 0x0A, 0x0B, 0x0B, 0x0B
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F
	.byte 0x0C, 0x0D, 0x0D, 0x0D, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F, 0x0E, 0x0F, 0x0F, 0x0F

;
; sp_1to2hi:   1bpp to 2bpp transformation, by high nybble
;

.balign 256

sp_1to2hi:
	.byte 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03
	.byte 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C, 0x0C
	.byte 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F, 0x0F
	.byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
	.byte 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33
	.byte 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C
	.byte 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F, 0x3F
	.byte 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0, 0xC0
	.byte 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3, 0xC3
	.byte 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC
	.byte 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF, 0xCF
	.byte 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0, 0xF0
	.byte 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3, 0xF3
	.byte 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC, 0xFC
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF

;
; sp_fl2bpp:   Flip (X mirror) 2bpp data
;

.balign 256

sp_fl2bpp:
	.byte 0x00, 0x40, 0x80, 0xC0, 0x10, 0x50, 0x90, 0xD0, 0x20, 0x60, 0xA0, 0xE0, 0x30, 0x70, 0xB0, 0xF0
	.byte 0x04, 0x44, 0x84, 0xC4, 0x14, 0x54, 0x94, 0xD4, 0x24, 0x64, 0xA4, 0xE4, 0x34, 0x74, 0xB4, 0xF4
	.byte 0x08, 0x48, 0x88, 0xC8, 0x18, 0x58, 0x98, 0xD8, 0x28, 0x68, 0xA8, 0xE8, 0x38, 0x78, 0xB8, 0xF8
	.byte 0x0C, 0x4C, 0x8C, 0xCC, 0x1C, 0x5C, 0x9C, 0xDC, 0x2C, 0x6C, 0xAC, 0xEC, 0x3C, 0x7C, 0xBC, 0xFC
	.byte 0x01, 0x41, 0x81, 0xC1, 0x11, 0x51, 0x91, 0xD1, 0x21, 0x61, 0xA1, 0xE1, 0x31, 0x71, 0xB1, 0xF1
	.byte 0x05, 0x45, 0x85, 0xC5, 0x15, 0x55, 0x95, 0xD5, 0x25, 0x65, 0xA5, 0xE5, 0x35, 0x75, 0xB5, 0xF5
	.byte 0x09, 0x49, 0x89, 0xC9, 0x19, 0x59, 0x99, 0xD9, 0x29, 0x69, 0xA9, 0xE9, 0x39, 0x79, 0xB9, 0xF9
	.byte 0x0D, 0x4D, 0x8D, 0xCD, 0x1D, 0x5D, 0x9D, 0xDD, 0x2D, 0x6D, 0xAD, 0xED, 0x3D, 0x7D, 0xBD, 0xFD
	.byte 0x02, 0x42, 0x82, 0xC2, 0x12, 0x52, 0x92, 0xD2, 0x22, 0x62, 0xA2, 0xE2, 0x32, 0x72, 0xB2, 0xF2
	.byte 0x06, 0x46, 0x86, 0xC6, 0x16, 0x56, 0x96, 0xD6, 0x26, 0x66, 0xA6, 0xE6, 0x36, 0x76, 0xB6, 0xF6
	.byte 0x0A, 0x4A, 0x8A, 0xCA, 0x1A, 0x5A, 0x9A, 0xDA, 0x2A, 0x6A, 0xAA, 0xEA, 0x3A, 0x7A, 0xBA, 0xFA
	.byte 0x0E, 0x4E, 0x8E, 0xCE, 0x1E, 0x5E, 0x9E, 0xDE, 0x2E, 0x6E, 0xAE, 0xEE, 0x3E, 0x7E, 0xBE, 0xFE
	.byte 0x03, 0x43, 0x83, 0xC3, 0x13, 0x53, 0x93, 0xD3, 0x23, 0x63, 0xA3, 0xE3, 0x33, 0x73, 0xB3, 0xF3
	.byte 0x07, 0x47, 0x87, 0xC7, 0x17, 0x57, 0x97, 0xD7, 0x27, 0x67, 0xA7, 0xE7, 0x37, 0x77, 0xB7, 0xF7
	.byte 0x0B, 0x4B, 0x8B, 0xCB, 0x1B, 0x5B, 0x9B, 0xDB, 0x2B, 0x6B, 0xAB, 0xEB, 0x3B, 0x7B, 0xBB, 0xFB
	.byte 0x0F, 0x4F, 0x8F, 0xCF, 0x1F, 0x5F, 0x9F, 0xDF, 0x2F, 0x6F, 0xAF, 0xEF, 0x3F, 0x7F, 0xBF, 0xFF


; sp_fl1bpp:   Flip (X mirror) 1bpp data

.balign 256

sp_fl1bpp:
	.byte 0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0, 0x10, 0x90, 0x50, 0xD0, 0x30, 0xB0, 0x70, 0xF0
	.byte 0x08, 0x88, 0x48, 0xC8, 0x28, 0xA8, 0x68, 0xE8, 0x18, 0x98, 0x58, 0xD8, 0x38, 0xB8, 0x78, 0xF8
	.byte 0x04, 0x84, 0x44, 0xC4, 0x24, 0xA4, 0x64, 0xE4, 0x14, 0x94, 0x54, 0xD4, 0x34, 0xB4, 0x74, 0xF4
	.byte 0x0C, 0x8C, 0x4C, 0xCC, 0x2C, 0xAC, 0x6C, 0xEC, 0x1C, 0x9C, 0x5C, 0xDC, 0x3C, 0xBC, 0x7C, 0xFC
	.byte 0x02, 0x82, 0x42, 0xC2, 0x22, 0xA2, 0x62, 0xE2, 0x12, 0x92, 0x52, 0xD2, 0x32, 0xB2, 0x72, 0xF2
	.byte 0x0A, 0x8A, 0x4A, 0xCA, 0x2A, 0xAA, 0x6A, 0xEA, 0x1A, 0x9A, 0x5A, 0xDA, 0x3A, 0xBA, 0x7A, 0xFA
	.byte 0x06, 0x86, 0x46, 0xC6, 0x26, 0xA6, 0x66, 0xE6, 0x16, 0x96, 0x56, 0xD6, 0x36, 0xB6, 0x76, 0xF6
	.byte 0x0E, 0x8E, 0x4E, 0xCE, 0x2E, 0xAE, 0x6E, 0xEE, 0x1E, 0x9E, 0x5E, 0xDE, 0x3E, 0xBE, 0x7E, 0xFE
	.byte 0x01, 0x81, 0x41, 0xC1, 0x21, 0xA1, 0x61, 0xE1, 0x11, 0x91, 0x51, 0xD1, 0x31, 0xB1, 0x71, 0xF1
	.byte 0x09, 0x89, 0x49, 0xC9, 0x29, 0xA9, 0x69, 0xE9, 0x19, 0x99, 0x59, 0xD9, 0x39, 0xB9, 0x79, 0xF9
	.byte 0x05, 0x85, 0x45, 0xC5, 0x25, 0xA5, 0x65, 0xE5, 0x15, 0x95, 0x55, 0xD5, 0x35, 0xB5, 0x75, 0xF5
	.byte 0x0D, 0x8D, 0x4D, 0xCD, 0x2D, 0xAD, 0x6D, 0xED, 0x1D, 0x9D, 0x5D, 0xDD, 0x3D, 0xBD, 0x7D, 0xFD
	.byte 0x03, 0x83, 0x43, 0xC3, 0x23, 0xA3, 0x63, 0xE3, 0x13, 0x93, 0x53, 0xD3, 0x33, 0xB3, 0x73, 0xF3
	.byte 0x0B, 0x8B, 0x4B, 0xCB, 0x2B, 0xAB, 0x6B, 0xEB, 0x1B, 0x9B, 0x5B, 0xDB, 0x3B, 0xBB, 0x7B, 0xFB
	.byte 0x07, 0x87, 0x47, 0xC7, 0x27, 0xA7, 0x67, 0xE7, 0x17, 0x97, 0x57, 0xD7, 0x37, 0xB7, 0x77, 0xF7
	.byte 0x0F, 0x8F, 0x4F, 0xCF, 0x2F, 0xAF, 0x6F, 0xEF, 0x1F, 0x9F, 0x5F, 0xDF, 0x3F, 0xBF, 0x7F, 0xFF



;
; No-attributes or Color 0 attributes right side code block assembly.
;

.balign 512

t1_jt:

	TB1_HEAD r2, t1_m00
	TB1_HEAD r2, t1_m01
	TB1_HEAD r2, t1_m02
	TB1_HEAD r2, t1_m03
	TB1_HEAD r2, t1_m04
	TB1_HEAD r2, t1_m05
	TB1_HEAD r2, t1_m06
	TB1_HEAD r2, t1_m07
	TB1_HEAD r2, t1_m08
	TB1_HEAD r2, t1_m09
	TB1_HEAD r2, t1_m0a
	TB1_HEAD r2, t1_m0b
	TB1_HEAD r2, t1_m0c
	TB1_HEAD r2, t1_m0d
	TB1_HEAD r2, t1_m0e
	TB1_HEAD r2, t1_m0f
	TB1_HEAD r2, t1_m10
	TB1_HEAD r2, t1_m11
	TB1_HEAD r2, t1_m12
	TB1_HEAD r2, t1_m13
	TB1_HEAD r2, t1_m14
	TB1_HEAD r2, t1_m15
	TB1_HEAD r2, t1_m16
	TB1_HEAD r2, t1_m17
	TB1_HEAD r2, t1_m18
	TB1_HEAD r2, t1_m19
	TB1_HEAD r2, t1_m1a
	TB1_HEAD r2, t1_m1b
	TB1_HEAD r2, t1_m1c
	TB1_HEAD r2, t1_m1d
	TB1_HEAD r2, t1_m1e
	TB1_HEAD r2, t1_m1f
	TB1_HEAD r2, t1_m20
	TB1_HEAD r2, t1_m21
	TB1_HEAD r2, t1_m22
	TB1_HEAD r2, t1_m23
	TB1_HEAD r2, t1_m24
	TB1_HEAD r2, t1_m25
	TB1_HEAD r2, t1_m26
	TB1_HEAD r2, t1_m27
	TB1_HEAD r2, t1_m28
	TB1_HEAD r2, t1_m29
	TB1_HEAD r2, t1_m2a
	TB1_HEAD r2, t1_m2b
	TB1_HEAD r2, t1_m2c
	TB1_HEAD r2, t1_m2d
	TB1_HEAD r2, t1_m2e
	TB1_HEAD r2, t1_m2f
	TB1_HEAD r2, t1_m30
	TB1_HEAD r2, t1_m31
	TB1_HEAD r2, t1_m32
	TB1_HEAD r2, t1_m33
	TB1_HEAD r2, t1_m34
	TB1_HEAD r2, t1_m35
	TB1_HEAD r2, t1_m36
	TB1_HEAD r2, t1_m37
	TB1_HEAD r2, t1_m38
	TB1_HEAD r2, t1_m39
	TB1_HEAD r2, t1_m3a
	TB1_HEAD r2, t1_m3b
	TB1_HEAD r2, t1_m3c
	TB1_HEAD r2, t1_m3d
	TB1_HEAD r2, t1_m3e
	TB1_HEAD r2, t1_m3f
	TB1_HEAD r3, t1_m00
	TB1_HEAD r3, t1_m01
	TB1_HEAD r3, t1_m02
	TB1_HEAD r3, t1_m03
	TB1_HEAD r3, t1_m04
	TB1_HEAD r3, t1_m05
	TB1_HEAD r3, t1_m06
	TB1_HEAD r3, t1_m07
	TB1_HEAD r3, t1_m08
	TB1_HEAD r3, t1_m09
	TB1_HEAD r3, t1_m0a
	TB1_HEAD r3, t1_m0b
	TB1_HEAD r3, t1_m0c
	TB1_HEAD r3, t1_m0d
	TB1_HEAD r3, t1_m0e
	TB1_HEAD r3, t1_m0f
	TB1_HEAD r3, t1_m10
	TB1_HEAD r3, t1_m11
	TB1_HEAD r3, t1_m12
	TB1_HEAD r3, t1_m13
	TB1_HEAD r3, t1_m14
	TB1_HEAD r3, t1_m15
	TB1_HEAD r3, t1_m16
	TB1_HEAD r3, t1_m17
	TB1_HEAD r3, t1_m18
	TB1_HEAD r3, t1_m19
	TB1_HEAD r3, t1_m1a
	TB1_HEAD r3, t1_m1b
	TB1_HEAD r3, t1_m1c
	TB1_HEAD r3, t1_m1d
	TB1_HEAD r3, t1_m1e
	TB1_HEAD r3, t1_m1f
	TB1_HEAD r3, t1_m20
	TB1_HEAD r3, t1_m21
	TB1_HEAD r3, t1_m22
	TB1_HEAD r3, t1_m23
	TB1_HEAD r3, t1_m24
	TB1_HEAD r3, t1_m25
	TB1_HEAD r3, t1_m26
	TB1_HEAD r3, t1_m27
	TB1_HEAD r3, t1_m28
	TB1_HEAD r3, t1_m29
	TB1_HEAD r3, t1_m2a
	TB1_HEAD r3, t1_m2b
	TB1_HEAD r3, t1_m2c
	TB1_HEAD r3, t1_m2d
	TB1_HEAD r3, t1_m2e
	TB1_HEAD r3, t1_m2f
	TB1_HEAD r3, t1_m30
	TB1_HEAD r3, t1_m31
	TB1_HEAD r3, t1_m32
	TB1_HEAD r3, t1_m33
	TB1_HEAD r3, t1_m34
	TB1_HEAD r3, t1_m35
	TB1_HEAD r3, t1_m36
	TB1_HEAD r3, t1_m37
	TB1_HEAD r3, t1_m38
	TB1_HEAD r3, t1_m39
	TB1_HEAD r3, t1_m3a
	TB1_HEAD r3, t1_m3b
	TB1_HEAD r3, t1_m3c
	TB1_HEAD r3, t1_m3d
	TB1_HEAD r3, t1_m3e
	TB1_HEAD r3, t1_m3f
	TB1_HEAD r4, t1_m00
	TB1_HEAD r4, t1_m01
	TB1_HEAD r4, t1_m02
	TB1_HEAD r4, t1_m03
	TB1_HEAD r4, t1_m04
	TB1_HEAD r4, t1_m05
	TB1_HEAD r4, t1_m06
	TB1_HEAD r4, t1_m07
	TB1_HEAD r4, t1_m08
	TB1_HEAD r4, t1_m09
	TB1_HEAD r4, t1_m0a
	TB1_HEAD r4, t1_m0b
	TB1_HEAD r4, t1_m0c
	TB1_HEAD r4, t1_m0d
	TB1_HEAD r4, t1_m0e
	TB1_HEAD r4, t1_m0f
	TB1_HEAD r4, t1_m10
	TB1_HEAD r4, t1_m11
	TB1_HEAD r4, t1_m12
	TB1_HEAD r4, t1_m13
	TB1_HEAD r4, t1_m14
	TB1_HEAD r4, t1_m15
	TB1_HEAD r4, t1_m16
	TB1_HEAD r4, t1_m17
	TB1_HEAD r4, t1_m18
	TB1_HEAD r4, t1_m19
	TB1_HEAD r4, t1_m1a
	TB1_HEAD r4, t1_m1b
	TB1_HEAD r4, t1_m1c
	TB1_HEAD r4, t1_m1d
	TB1_HEAD r4, t1_m1e
	TB1_HEAD r4, t1_m1f
	TB1_HEAD r4, t1_m20
	TB1_HEAD r4, t1_m21
	TB1_HEAD r4, t1_m22
	TB1_HEAD r4, t1_m23
	TB1_HEAD r4, t1_m24
	TB1_HEAD r4, t1_m25
	TB1_HEAD r4, t1_m26
	TB1_HEAD r4, t1_m27
	TB1_HEAD r4, t1_m28
	TB1_HEAD r4, t1_m29
	TB1_HEAD r4, t1_m2a
	TB1_HEAD r4, t1_m2b
	TB1_HEAD r4, t1_m2c
	TB1_HEAD r4, t1_m2d
	TB1_HEAD r4, t1_m2e
	TB1_HEAD r4, t1_m2f
	TB1_HEAD r4, t1_m30
	TB1_HEAD r4, t1_m31
	TB1_HEAD r4, t1_m32
	TB1_HEAD r4, t1_m33
	TB1_HEAD r4, t1_m34
	TB1_HEAD r4, t1_m35
	TB1_HEAD r4, t1_m36
	TB1_HEAD r4, t1_m37
	TB1_HEAD r4, t1_m38
	TB1_HEAD r4, t1_m39
	TB1_HEAD r4, t1_m3a
	TB1_HEAD r4, t1_m3b
	TB1_HEAD r4, t1_m3c
	TB1_HEAD r4, t1_m3d
	TB1_HEAD r4, t1_m3e
	TB1_HEAD r4, t1_m3f
	TB1_HEAD r5, t1_m00
	TB1_HEAD r5, t1_m01
	TB1_HEAD r5, t1_m02
	TB1_HEAD r5, t1_m03
	TB1_HEAD r5, t1_m04
	TB1_HEAD r5, t1_m05
	TB1_HEAD r5, t1_m06
	TB1_HEAD r5, t1_m07
	TB1_HEAD r5, t1_m08
	TB1_HEAD r5, t1_m09
	TB1_HEAD r5, t1_m0a
	TB1_HEAD r5, t1_m0b
	TB1_HEAD r5, t1_m0c
	TB1_HEAD r5, t1_m0d
	TB1_HEAD r5, t1_m0e
	TB1_HEAD r5, t1_m0f
	TB1_HEAD r5, t1_m10
	TB1_HEAD r5, t1_m11
	TB1_HEAD r5, t1_m12
	TB1_HEAD r5, t1_m13
	TB1_HEAD r5, t1_m14
	TB1_HEAD r5, t1_m15
	TB1_HEAD r5, t1_m16
	TB1_HEAD r5, t1_m17
	TB1_HEAD r5, t1_m18
	TB1_HEAD r5, t1_m19
	TB1_HEAD r5, t1_m1a
	TB1_HEAD r5, t1_m1b
	TB1_HEAD r5, t1_m1c
	TB1_HEAD r5, t1_m1d
	TB1_HEAD r5, t1_m1e
	TB1_HEAD r5, t1_m1f
	TB1_HEAD r5, t1_m20
	TB1_HEAD r5, t1_m21
	TB1_HEAD r5, t1_m22
	TB1_HEAD r5, t1_m23
	TB1_HEAD r5, t1_m24
	TB1_HEAD r5, t1_m25
	TB1_HEAD r5, t1_m26
	TB1_HEAD r5, t1_m27
	TB1_HEAD r5, t1_m28
	TB1_HEAD r5, t1_m29
	TB1_HEAD r5, t1_m2a
	TB1_HEAD r5, t1_m2b
	TB1_HEAD r5, t1_m2c
	TB1_HEAD r5, t1_m2d
	TB1_HEAD r5, t1_m2e
	TB1_HEAD r5, t1_m2f
	TB1_HEAD r5, t1_m30
	TB1_HEAD r5, t1_m31
	TB1_HEAD r5, t1_m32
	TB1_HEAD r5, t1_m33
	TB1_HEAD r5, t1_m34
	TB1_HEAD r5, t1_m35
	TB1_HEAD r5, t1_m36
	TB1_HEAD r5, t1_m37
	TB1_HEAD r5, t1_m38
	TB1_HEAD r5, t1_m39
	TB1_HEAD r5, t1_m3a
	TB1_HEAD r5, t1_m3b
	TB1_HEAD r5, t1_m3c
	TB1_HEAD r5, t1_m3d
	TB1_HEAD r5, t1_m3e
	TB1_HEAD r5, t1_m3f

t1_m00:	TB1_MIDL r2, r2, r2, t1_t0
t1_m01:	TB1_MIDL r2, r2, r3, t1_t1
t1_m02:	TB1_MIDL r2, r2, r4, t1_t2
t1_m03:	TB1_MIDL r2, r2, r5, t1_t3
t1_m04:	TB1_MIDL r2, r3, r2, t1_t4
t1_m05:	TB1_MIDL r2, r3, r3, t1_t5
t1_m06:	TB1_MIDL r2, r3, r4, t1_t6
t1_m07:	TB1_MIDL r2, r3, r5, t1_t7
t1_m08:	TB1_MIDL r2, r4, r2, t1_t8
t1_m09:	TB1_MIDL r2, r4, r3, t1_t9
t1_m0a:	TB1_MIDL r2, r4, r4, t1_ta
t1_m0b:	TB1_MIDL r2, r4, r5, t1_tb
t1_m0c:	TB1_MIDL r2, r5, r2, t1_tc
t1_m0d:	TB1_MIDL r2, r5, r3, t1_td
t1_m0e:	TB1_MIDL r2, r5, r4, t1_te
t1_m0f:	TB1_MIDL r2, r5, r5, t1_tf
t1_m10:	TB1_MIDL r3, r2, r2, t1_t0
t1_m11:	TB1_MIDL r3, r2, r3, t1_t1
t1_m12:	TB1_MIDL r3, r2, r4, t1_t2
t1_m13:	TB1_MIDL r3, r2, r5, t1_t3
t1_m14:	TB1_MIDL r3, r3, r2, t1_t4
t1_m15:	TB1_MIDL r3, r3, r3, t1_t5
t1_m16:	TB1_MIDL r3, r3, r4, t1_t6
t1_m17:	TB1_MIDL r3, r3, r5, t1_t7
t1_m18:	TB1_MIDL r3, r4, r2, t1_t8
t1_m19:	TB1_MIDL r3, r4, r3, t1_t9
t1_m1a:	TB1_MIDL r3, r4, r4, t1_ta
t1_m1b:	TB1_MIDL r3, r4, r5, t1_tb
t1_m1c:	TB1_MIDL r3, r5, r2, t1_tc
t1_m1d:	TB1_MIDL r3, r5, r3, t1_td
t1_m1e:	TB1_MIDL r3, r5, r4, t1_te
t1_m1f:	TB1_MIDL r3, r5, r5, t1_tf
t1_m20:	TB1_MIDL r4, r2, r2, t1_t0
t1_m21:	TB1_MIDL r4, r2, r3, t1_t1
t1_m22:	TB1_MIDL r4, r2, r4, t1_t2
t1_m23:	TB1_MIDL r4, r2, r5, t1_t3
t1_m24:	TB1_MIDL r4, r3, r2, t1_t4
t1_m25:	TB1_MIDL r4, r3, r3, t1_t5
t1_m26:	TB1_MIDL r4, r3, r4, t1_t6
t1_m27:	TB1_MIDL r4, r3, r5, t1_t7
t1_m28:	TB1_MIDL r4, r4, r2, t1_t8
t1_m29:	TB1_MIDL r4, r4, r3, t1_t9
t1_m2a:	TB1_MIDL r4, r4, r4, t1_ta
t1_m2b:	TB1_MIDL r4, r4, r5, t1_tb
t1_m2c:	TB1_MIDL r4, r5, r2, t1_tc
t1_m2d:	TB1_MIDL r4, r5, r3, t1_td
t1_m2e:	TB1_MIDL r4, r5, r4, t1_te
t1_m2f:	TB1_MIDL r4, r5, r5, t1_tf
t1_m30:	TB1_MIDL r5, r2, r2, t1_t0
t1_m31:	TB1_MIDL r5, r2, r3, t1_t1
t1_m32:	TB1_MIDL r5, r2, r4, t1_t2
t1_m33:	TB1_MIDL r5, r2, r5, t1_t3
t1_m34:	TB1_MIDL r5, r3, r2, t1_t4
t1_m35:	TB1_MIDL r5, r3, r3, t1_t5
t1_m36:	TB1_MIDL r5, r3, r4, t1_t6
t1_m37:	TB1_MIDL r5, r3, r5, t1_t7
t1_m38:	TB1_MIDL r5, r4, r2, t1_t8
t1_m39:	TB1_MIDL r5, r4, r3, t1_t9
t1_m3a:	TB1_MIDL r5, r4, r4, t1_ta
t1_m3b:	TB1_MIDL r5, r4, r5, t1_tb
t1_m3c:	TB1_MIDL r5, r5, r2, t1_tc
t1_m3d:	TB1_MIDL r5, r5, r3, t1_td
t1_m3e:	TB1_MIDL r5, r5, r4, t1_te
t1_m3f:	TB1_MIDL r5, r5, r5, t1_tf

t1_t0:	TB1_TRAM r2, r2
t1_t1:	TB1_TRAM r2, r3
t1_t2:	TB1_TRAM r2, r4
t1_t3:	TB1_TRAM r2, r5
t1_t4:	TB1_TRAM r3, r2
t1_t5:	TB1_TRAM r3, r3
t1_t6:	TB1_TRAM r3, r4
t1_t7:	TB1_TRAM r3, r5
t1_t8:	TB1_TRAM r4, r2
t1_t9:	TB1_TRAM r4, r3
t1_ta:	TB1_TRAM r4, r4
t1_tb:	TB1_TRAM r4, r5
t1_tc:	TB1_TRAM r5, r2
t1_td:	TB1_TRAM r5, r3
t1_te:	TB1_TRAM r5, r4
t1_tf:	TB1_TRAM r5, r5



;
; 3 attribute mode code blocks
;

#if (M52_ENABLE_ATTR123 != 0)

t2_m00:	TB2_MIDL r2, r2, r2
t2_m01:	TB2_MIDL r2, r2, r3
t2_m02:	TB2_MIDL r2, r2, r4
t2_m03:	TB2_MIDL r2, r2, r5
t2_m04:	TB2_MIDL r2, r3, r2
t2_m05:	TB2_MIDL r2, r3, r3
t2_m06:	TB2_MIDL r2, r3, r4
t2_m07:	TB2_MIDL r2, r3, r5
t2_m08:	TB2_MIDL r2, r4, r2
t2_m09:	TB2_MIDL r2, r4, r3
t2_m0a:	TB2_MIDL r2, r4, r4
t2_m0b:	TB2_MIDL r2, r4, r5
t2_m0c:	TB2_MIDL r2, r5, r2
t2_m0d:	TB2_MIDL r2, r5, r3
t2_m0e:	TB2_MIDL r2, r5, r4
t2_m0f:	TB2_MIDL r2, r5, r5
t2_m10:	TB2_MIDL r3, r2, r2
t2_m11:	TB2_MIDL r3, r2, r3
t2_m12:	TB2_MIDL r3, r2, r4
t2_m13:	TB2_MIDL r3, r2, r5
t2_m14:	TB2_MIDL r3, r3, r2
t2_m15:	TB2_MIDL r3, r3, r3
t2_m16:	TB2_MIDL r3, r3, r4
t2_m17:	TB2_MIDL r3, r3, r5
t2_m18:	TB2_MIDL r3, r4, r2
t2_m19:	TB2_MIDL r3, r4, r3
t2_m1a:	TB2_MIDL r3, r4, r4
t2_m1b:	TB2_MIDL r3, r4, r5
t2_m1c:	TB2_MIDL r3, r5, r2
t2_m1d:	TB2_MIDL r3, r5, r3
t2_m1e:	TB2_MIDL r3, r5, r4
t2_m1f:	TB2_MIDL r3, r5, r5
t2_m20:	TB2_MIDL r4, r2, r2
t2_m21:	TB2_MIDL r4, r2, r3
t2_m22:	TB2_MIDL r4, r2, r4
t2_m23:	TB2_MIDL r4, r2, r5
t2_m24:	TB2_MIDL r4, r3, r2
t2_m25:	TB2_MIDL r4, r3, r3
t2_m26:	TB2_MIDL r4, r3, r4
t2_m27:	TB2_MIDL r4, r3, r5
t2_m28:	TB2_MIDL r4, r4, r2
t2_m29:	TB2_MIDL r4, r4, r3
t2_m2a:	TB2_MIDL r4, r4, r4
t2_m2b:	TB2_MIDL r4, r4, r5
t2_m2c:	TB2_MIDL r4, r5, r2
t2_m2d:	TB2_MIDL r4, r5, r3
t2_m2e:	TB2_MIDL r4, r5, r4
t2_m2f:	TB2_MIDL r4, r5, r5
t2_m30:	TB2_MIDL r5, r2, r2
t2_m31:	TB2_MIDL r5, r2, r3
t2_m32:	TB2_MIDL r5, r2, r4
t2_m33:	TB2_MIDL r5, r2, r5
t2_m34:	TB2_MIDL r5, r3, r2
t2_m35:	TB2_MIDL r5, r3, r3
t2_m36:	TB2_MIDL r5, r3, r4
t2_m37:	TB2_MIDL r5, r3, r5
t2_m38:	TB2_MIDL r5, r4, r2
t2_m39:	TB2_MIDL r5, r4, r3
t2_m3a:	TB2_MIDL r5, r4, r4
t2_m3b:	TB2_MIDL r5, r4, r5
t2_m3c:	TB2_MIDL r5, r5, r2
t2_m3d:	TB2_MIDL r5, r5, r3
t2_m3e:	TB2_MIDL r5, r5, r4
t2_m3f:	TB2_MIDL r5, r5, r5

.balign 512

t2_jt:

	TB2_HEAD r2,  t2_m00
	TB2_HEAD r2,  t2_m01
	TB2_HEAD r2,  t2_m02
	TB2_HEAD r2,  t2_m03
	TB2_HEAD r2,  t2_m04
	TB2_HEAD r2,  t2_m05
	TB2_HEAD r2,  t2_m06
	TB2_HEAD r2,  t2_m07
	TB2_HEAD r2,  t2_m08
	TB2_HEAD r2,  t2_m09
	TB2_HEAD r2,  t2_m0a
	TB2_HEAD r2,  t2_m0b
	TB2_HEAD r2,  t2_m0c
	TB2_HEAD r2,  t2_m0d
	TB2_HEAD r2,  t2_m0e
	TB2_HEAD r2,  t2_m0f
	TB2_HEAD r2,  t2_m10
	TB2_HEAD r2,  t2_m11
	TB2_HEAD r2,  t2_m12
	TB2_HEAD r2,  t2_m13
	TB2_HEAD r2,  t2_m14
	TB2_HEAD r2,  t2_m15
	TB2_HEAD r2,  t2_m16
	TB2_HEAD r2,  t2_m17
	TB2_HEAD r2,  t2_m18
	TB2_HEAD r2,  t2_m19
	TB2_HEAD r2,  t2_m1a
	TB2_HEAD r2,  t2_m1b
	TB2_HEAD r2,  t2_m1c
	TB2_HEAD r2,  t2_m1d
	TB2_HEAD r2,  t2_m1e
	TB2_HEAD r2,  t2_m1f
	TB2_HEAD r2,  t2_m20
	TB2_HEAD r2,  t2_m21
	TB2_HEAD r2,  t2_m22
	TB2_HEAD r2,  t2_m23
	TB2_HEAD r2,  t2_m24
	TB2_HEAD r2,  t2_m25
	TB2_HEAD r2,  t2_m26
	TB2_HEAD r2,  t2_m27
	TB2_HEAD r2,  t2_m28
	TB2_HEAD r2,  t2_m29
	TB2_HEAD r2,  t2_m2a
	TB2_HEAD r2,  t2_m2b
	TB2_HEAD r2,  t2_m2c
	TB2_HEAD r2,  t2_m2d
	TB2_HEAD r2,  t2_m2e
	TB2_HEAD r2,  t2_m2f
	TB2_HEAD r2,  t2_m30
	TB2_HEAD r2,  t2_m31
	TB2_HEAD r2,  t2_m32
	TB2_HEAD r2,  t2_m33
	TB2_HEAD r2,  t2_m34
	TB2_HEAD r2,  t2_m35
	TB2_HEAD r2,  t2_m36
	TB2_HEAD r2,  t2_m37
	TB2_HEAD r2,  t2_m38
	TB2_HEAD r2,  t2_m39
	TB2_HEAD r2,  t2_m3a
	TB2_HEAD r2,  t2_m3b
	TB2_HEAD r2,  t2_m3c
	TB2_HEAD r2,  t2_m3d
	TB2_HEAD r2,  t2_m3e
	TB2_HEAD r2,  t2_m3f
	TB2_HEAD r12, t2_m00
	TB2_HEAD r12, t2_m01
	TB2_HEAD r12, t2_m02
	TB2_HEAD r12, t2_m03
	TB2_HEAD r12, t2_m04
	TB2_HEAD r12, t2_m05
	TB2_HEAD r12, t2_m06
	TB2_HEAD r12, t2_m07
	TB2_HEAD r12, t2_m08
	TB2_HEAD r12, t2_m09
	TB2_HEAD r12, t2_m0a
	TB2_HEAD r12, t2_m0b
	TB2_HEAD r12, t2_m0c
	TB2_HEAD r12, t2_m0d
	TB2_HEAD r12, t2_m0e
	TB2_HEAD r12, t2_m0f
	TB2_HEAD r12, t2_m10
	TB2_HEAD r12, t2_m11
	TB2_HEAD r12, t2_m12
	TB2_HEAD r12, t2_m13
	TB2_HEAD r12, t2_m14
	TB2_HEAD r12, t2_m15
	TB2_HEAD r12, t2_m16
	TB2_HEAD r12, t2_m17
	TB2_HEAD r12, t2_m18
	TB2_HEAD r12, t2_m19
	TB2_HEAD r12, t2_m1a
	TB2_HEAD r12, t2_m1b
	TB2_HEAD r12, t2_m1c
	TB2_HEAD r12, t2_m1d
	TB2_HEAD r12, t2_m1e
	TB2_HEAD r12, t2_m1f
	TB2_HEAD r12, t2_m20
	TB2_HEAD r12, t2_m21
	TB2_HEAD r12, t2_m22
	TB2_HEAD r12, t2_m23
	TB2_HEAD r12, t2_m24
	TB2_HEAD r12, t2_m25
	TB2_HEAD r12, t2_m26
	TB2_HEAD r12, t2_m27
	TB2_HEAD r12, t2_m28
	TB2_HEAD r12, t2_m29
	TB2_HEAD r12, t2_m2a
	TB2_HEAD r12, t2_m2b
	TB2_HEAD r12, t2_m2c
	TB2_HEAD r12, t2_m2d
	TB2_HEAD r12, t2_m2e
	TB2_HEAD r12, t2_m2f
	TB2_HEAD r12, t2_m30
	TB2_HEAD r12, t2_m31
	TB2_HEAD r12, t2_m32
	TB2_HEAD r12, t2_m33
	TB2_HEAD r12, t2_m34
	TB2_HEAD r12, t2_m35
	TB2_HEAD r12, t2_m36
	TB2_HEAD r12, t2_m37
	TB2_HEAD r12, t2_m38
	TB2_HEAD r12, t2_m39
	TB2_HEAD r12, t2_m3a
	TB2_HEAD r12, t2_m3b
	TB2_HEAD r12, t2_m3c
	TB2_HEAD r12, t2_m3d
	TB2_HEAD r12, t2_m3e
	TB2_HEAD r12, t2_m3f
	TB2_HEAD r6,  t2_m00
	TB2_HEAD r6,  t2_m01
	TB2_HEAD r6,  t2_m02
	TB2_HEAD r6,  t2_m03
	TB2_HEAD r6,  t2_m04
	TB2_HEAD r6,  t2_m05
	TB2_HEAD r6,  t2_m06
	TB2_HEAD r6,  t2_m07
	TB2_HEAD r6,  t2_m08
	TB2_HEAD r6,  t2_m09
	TB2_HEAD r6,  t2_m0a
	TB2_HEAD r6,  t2_m0b
	TB2_HEAD r6,  t2_m0c
	TB2_HEAD r6,  t2_m0d
	TB2_HEAD r6,  t2_m0e
	TB2_HEAD r6,  t2_m0f
	TB2_HEAD r6,  t2_m10
	TB2_HEAD r6,  t2_m11
	TB2_HEAD r6,  t2_m12
	TB2_HEAD r6,  t2_m13
	TB2_HEAD r6,  t2_m14
	TB2_HEAD r6,  t2_m15
	TB2_HEAD r6,  t2_m16
	TB2_HEAD r6,  t2_m17
	TB2_HEAD r6,  t2_m18
	TB2_HEAD r6,  t2_m19
	TB2_HEAD r6,  t2_m1a
	TB2_HEAD r6,  t2_m1b
	TB2_HEAD r6,  t2_m1c
	TB2_HEAD r6,  t2_m1d
	TB2_HEAD r6,  t2_m1e
	TB2_HEAD r6,  t2_m1f
	TB2_HEAD r6,  t2_m20
	TB2_HEAD r6,  t2_m21
	TB2_HEAD r6,  t2_m22
	TB2_HEAD r6,  t2_m23
	TB2_HEAD r6,  t2_m24
	TB2_HEAD r6,  t2_m25
	TB2_HEAD r6,  t2_m26
	TB2_HEAD r6,  t2_m27
	TB2_HEAD r6,  t2_m28
	TB2_HEAD r6,  t2_m29
	TB2_HEAD r6,  t2_m2a
	TB2_HEAD r6,  t2_m2b
	TB2_HEAD r6,  t2_m2c
	TB2_HEAD r6,  t2_m2d
	TB2_HEAD r6,  t2_m2e
	TB2_HEAD r6,  t2_m2f
	TB2_HEAD r6,  t2_m30
	TB2_HEAD r6,  t2_m31
	TB2_HEAD r6,  t2_m32
	TB2_HEAD r6,  t2_m33
	TB2_HEAD r6,  t2_m34
	TB2_HEAD r6,  t2_m35
	TB2_HEAD r6,  t2_m36
	TB2_HEAD r6,  t2_m37
	TB2_HEAD r6,  t2_m38
	TB2_HEAD r6,  t2_m39
	TB2_HEAD r6,  t2_m3a
	TB2_HEAD r6,  t2_m3b
	TB2_HEAD r6,  t2_m3c
	TB2_HEAD r6,  t2_m3d
	TB2_HEAD r6,  t2_m3e
	TB2_HEAD r6,  t2_m3f
	TB2_HEAD r7,  t2_m00
	TB2_HEAD r7,  t2_m01
	TB2_HEAD r7,  t2_m02
	TB2_HEAD r7,  t2_m03
	TB2_HEAD r7,  t2_m04
	TB2_HEAD r7,  t2_m05
	TB2_HEAD r7,  t2_m06
	TB2_HEAD r7,  t2_m07
	TB2_HEAD r7,  t2_m08
	TB2_HEAD r7,  t2_m09
	TB2_HEAD r7,  t2_m0a
	TB2_HEAD r7,  t2_m0b
	TB2_HEAD r7,  t2_m0c
	TB2_HEAD r7,  t2_m0d
	TB2_HEAD r7,  t2_m0e
	TB2_HEAD r7,  t2_m0f
	TB2_HEAD r7,  t2_m10
	TB2_HEAD r7,  t2_m11
	TB2_HEAD r7,  t2_m12
	TB2_HEAD r7,  t2_m13
	TB2_HEAD r7,  t2_m14
	TB2_HEAD r7,  t2_m15
	TB2_HEAD r7,  t2_m16
	TB2_HEAD r7,  t2_m17
	TB2_HEAD r7,  t2_m18
	TB2_HEAD r7,  t2_m19
	TB2_HEAD r7,  t2_m1a
	TB2_HEAD r7,  t2_m1b
	TB2_HEAD r7,  t2_m1c
	TB2_HEAD r7,  t2_m1d
	TB2_HEAD r7,  t2_m1e
	TB2_HEAD r7,  t2_m1f
	TB2_HEAD r7,  t2_m20
	TB2_HEAD r7,  t2_m21
	TB2_HEAD r7,  t2_m22
	TB2_HEAD r7,  t2_m23
	TB2_HEAD r7,  t2_m24
	TB2_HEAD r7,  t2_m25
	TB2_HEAD r7,  t2_m26
	TB2_HEAD r7,  t2_m27
	TB2_HEAD r7,  t2_m28
	TB2_HEAD r7,  t2_m29
	TB2_HEAD r7,  t2_m2a
	TB2_HEAD r7,  t2_m2b
	TB2_HEAD r7,  t2_m2c
	TB2_HEAD r7,  t2_m2d
	TB2_HEAD r7,  t2_m2e
	TB2_HEAD r7,  t2_m2f
	TB2_HEAD r7,  t2_m30
	TB2_HEAD r7,  t2_m31
	TB2_HEAD r7,  t2_m32
	TB2_HEAD r7,  t2_m33
	TB2_HEAD r7,  t2_m34
	TB2_HEAD r7,  t2_m35
	TB2_HEAD r7,  t2_m36
	TB2_HEAD r7,  t2_m37
	TB2_HEAD r7,  t2_m38
	TB2_HEAD r7,  t2_m39
	TB2_HEAD r7,  t2_m3a
	TB2_HEAD r7,  t2_m3b
	TB2_HEAD r7,  t2_m3c
	TB2_HEAD r7,  t2_m3d
	TB2_HEAD r7,  t2_m3e
	TB2_HEAD r7,  t2_m3f

t3_jt:

	TB3_HEAD r2, t3_m00
	TB3_HEAD r2, t3_m01
	TB3_HEAD r2, t3_m02
	TB3_HEAD r2, t3_m03
	TB3_HEAD r2, t3_m04
	TB3_HEAD r2, t3_m05
	TB3_HEAD r2, t3_m06
	TB3_HEAD r2, t3_m07
	TB3_HEAD r2, t3_m08
	TB3_HEAD r2, t3_m09
	TB3_HEAD r2, t3_m0a
	TB3_HEAD r2, t3_m0b
	TB3_HEAD r2, t3_m0c
	TB3_HEAD r2, t3_m0d
	TB3_HEAD r2, t3_m0e
	TB3_HEAD r2, t3_m0f
	TB3_HEAD r2, t3_m10
	TB3_HEAD r2, t3_m11
	TB3_HEAD r2, t3_m12
	TB3_HEAD r2, t3_m13
	TB3_HEAD r2, t3_m14
	TB3_HEAD r2, t3_m15
	TB3_HEAD r2, t3_m16
	TB3_HEAD r2, t3_m17
	TB3_HEAD r2, t3_m18
	TB3_HEAD r2, t3_m19
	TB3_HEAD r2, t3_m1a
	TB3_HEAD r2, t3_m1b
	TB3_HEAD r2, t3_m1c
	TB3_HEAD r2, t3_m1d
	TB3_HEAD r2, t3_m1e
	TB3_HEAD r2, t3_m1f
	TB3_HEAD r2, t3_m20
	TB3_HEAD r2, t3_m21
	TB3_HEAD r2, t3_m22
	TB3_HEAD r2, t3_m23
	TB3_HEAD r2, t3_m24
	TB3_HEAD r2, t3_m25
	TB3_HEAD r2, t3_m26
	TB3_HEAD r2, t3_m27
	TB3_HEAD r2, t3_m28
	TB3_HEAD r2, t3_m29
	TB3_HEAD r2, t3_m2a
	TB3_HEAD r2, t3_m2b
	TB3_HEAD r2, t3_m2c
	TB3_HEAD r2, t3_m2d
	TB3_HEAD r2, t3_m2e
	TB3_HEAD r2, t3_m2f
	TB3_HEAD r2, t3_m30
	TB3_HEAD r2, t3_m31
	TB3_HEAD r2, t3_m32
	TB3_HEAD r2, t3_m33
	TB3_HEAD r2, t3_m34
	TB3_HEAD r2, t3_m35
	TB3_HEAD r2, t3_m36
	TB3_HEAD r2, t3_m37
	TB3_HEAD r2, t3_m38
	TB3_HEAD r2, t3_m39
	TB3_HEAD r2, t3_m3a
	TB3_HEAD r2, t3_m3b
	TB3_HEAD r2, t3_m3c
	TB3_HEAD r2, t3_m3d
	TB3_HEAD r2, t3_m3e
	TB3_HEAD r2, t3_m3f
	TB3_HEAD r3, t3_m00
	TB3_HEAD r3, t3_m01
	TB3_HEAD r3, t3_m02
	TB3_HEAD r3, t3_m03
	TB3_HEAD r3, t3_m04
	TB3_HEAD r3, t3_m05
	TB3_HEAD r3, t3_m06
	TB3_HEAD r3, t3_m07
	TB3_HEAD r3, t3_m08
	TB3_HEAD r3, t3_m09
	TB3_HEAD r3, t3_m0a
	TB3_HEAD r3, t3_m0b
	TB3_HEAD r3, t3_m0c
	TB3_HEAD r3, t3_m0d
	TB3_HEAD r3, t3_m0e
	TB3_HEAD r3, t3_m0f
	TB3_HEAD r3, t3_m10
	TB3_HEAD r3, t3_m11
	TB3_HEAD r3, t3_m12
	TB3_HEAD r3, t3_m13
	TB3_HEAD r3, t3_m14
	TB3_HEAD r3, t3_m15
	TB3_HEAD r3, t3_m16
	TB3_HEAD r3, t3_m17
	TB3_HEAD r3, t3_m18
	TB3_HEAD r3, t3_m19
	TB3_HEAD r3, t3_m1a
	TB3_HEAD r3, t3_m1b
	TB3_HEAD r3, t3_m1c
	TB3_HEAD r3, t3_m1d
	TB3_HEAD r3, t3_m1e
	TB3_HEAD r3, t3_m1f
	TB3_HEAD r3, t3_m20
	TB3_HEAD r3, t3_m21
	TB3_HEAD r3, t3_m22
	TB3_HEAD r3, t3_m23
	TB3_HEAD r3, t3_m24
	TB3_HEAD r3, t3_m25
	TB3_HEAD r3, t3_m26
	TB3_HEAD r3, t3_m27
	TB3_HEAD r3, t3_m28
	TB3_HEAD r3, t3_m29
	TB3_HEAD r3, t3_m2a
	TB3_HEAD r3, t3_m2b
	TB3_HEAD r3, t3_m2c
	TB3_HEAD r3, t3_m2d
	TB3_HEAD r3, t3_m2e
	TB3_HEAD r3, t3_m2f
	TB3_HEAD r3, t3_m30
	TB3_HEAD r3, t3_m31
	TB3_HEAD r3, t3_m32
	TB3_HEAD r3, t3_m33
	TB3_HEAD r3, t3_m34
	TB3_HEAD r3, t3_m35
	TB3_HEAD r3, t3_m36
	TB3_HEAD r3, t3_m37
	TB3_HEAD r3, t3_m38
	TB3_HEAD r3, t3_m39
	TB3_HEAD r3, t3_m3a
	TB3_HEAD r3, t3_m3b
	TB3_HEAD r3, t3_m3c
	TB3_HEAD r3, t3_m3d
	TB3_HEAD r3, t3_m3e
	TB3_HEAD r3, t3_m3f
	TB3_HEAD r4, t3_m00
	TB3_HEAD r4, t3_m01
	TB3_HEAD r4, t3_m02
	TB3_HEAD r4, t3_m03
	TB3_HEAD r4, t3_m04
	TB3_HEAD r4, t3_m05
	TB3_HEAD r4, t3_m06
	TB3_HEAD r4, t3_m07
	TB3_HEAD r4, t3_m08
	TB3_HEAD r4, t3_m09
	TB3_HEAD r4, t3_m0a
	TB3_HEAD r4, t3_m0b
	TB3_HEAD r4, t3_m0c
	TB3_HEAD r4, t3_m0d
	TB3_HEAD r4, t3_m0e
	TB3_HEAD r4, t3_m0f
	TB3_HEAD r4, t3_m10
	TB3_HEAD r4, t3_m11
	TB3_HEAD r4, t3_m12
	TB3_HEAD r4, t3_m13
	TB3_HEAD r4, t3_m14
	TB3_HEAD r4, t3_m15
	TB3_HEAD r4, t3_m16
	TB3_HEAD r4, t3_m17
	TB3_HEAD r4, t3_m18
	TB3_HEAD r4, t3_m19
	TB3_HEAD r4, t3_m1a
	TB3_HEAD r4, t3_m1b
	TB3_HEAD r4, t3_m1c
	TB3_HEAD r4, t3_m1d
	TB3_HEAD r4, t3_m1e
	TB3_HEAD r4, t3_m1f
	TB3_HEAD r4, t3_m20
	TB3_HEAD r4, t3_m21
	TB3_HEAD r4, t3_m22
	TB3_HEAD r4, t3_m23
	TB3_HEAD r4, t3_m24
	TB3_HEAD r4, t3_m25
	TB3_HEAD r4, t3_m26
	TB3_HEAD r4, t3_m27
	TB3_HEAD r4, t3_m28
	TB3_HEAD r4, t3_m29
	TB3_HEAD r4, t3_m2a
	TB3_HEAD r4, t3_m2b
	TB3_HEAD r4, t3_m2c
	TB3_HEAD r4, t3_m2d
	TB3_HEAD r4, t3_m2e
	TB3_HEAD r4, t3_m2f
	TB3_HEAD r4, t3_m30
	TB3_HEAD r4, t3_m31
	TB3_HEAD r4, t3_m32
	TB3_HEAD r4, t3_m33
	TB3_HEAD r4, t3_m34
	TB3_HEAD r4, t3_m35
	TB3_HEAD r4, t3_m36
	TB3_HEAD r4, t3_m37
	TB3_HEAD r4, t3_m38
	TB3_HEAD r4, t3_m39
	TB3_HEAD r4, t3_m3a
	TB3_HEAD r4, t3_m3b
	TB3_HEAD r4, t3_m3c
	TB3_HEAD r4, t3_m3d
	TB3_HEAD r4, t3_m3e
	TB3_HEAD r4, t3_m3f
	TB3_HEAD r5, t3_m00
	TB3_HEAD r5, t3_m01
	TB3_HEAD r5, t3_m02
	TB3_HEAD r5, t3_m03
	TB3_HEAD r5, t3_m04
	TB3_HEAD r5, t3_m05
	TB3_HEAD r5, t3_m06
	TB3_HEAD r5, t3_m07
	TB3_HEAD r5, t3_m08
	TB3_HEAD r5, t3_m09
	TB3_HEAD r5, t3_m0a
	TB3_HEAD r5, t3_m0b
	TB3_HEAD r5, t3_m0c
	TB3_HEAD r5, t3_m0d
	TB3_HEAD r5, t3_m0e
	TB3_HEAD r5, t3_m0f
	TB3_HEAD r5, t3_m10
	TB3_HEAD r5, t3_m11
	TB3_HEAD r5, t3_m12
	TB3_HEAD r5, t3_m13
	TB3_HEAD r5, t3_m14
	TB3_HEAD r5, t3_m15
	TB3_HEAD r5, t3_m16
	TB3_HEAD r5, t3_m17
	TB3_HEAD r5, t3_m18
	TB3_HEAD r5, t3_m19
	TB3_HEAD r5, t3_m1a
	TB3_HEAD r5, t3_m1b
	TB3_HEAD r5, t3_m1c
	TB3_HEAD r5, t3_m1d
	TB3_HEAD r5, t3_m1e
	TB3_HEAD r5, t3_m1f
	TB3_HEAD r5, t3_m20
	TB3_HEAD r5, t3_m21
	TB3_HEAD r5, t3_m22
	TB3_HEAD r5, t3_m23
	TB3_HEAD r5, t3_m24
	TB3_HEAD r5, t3_m25
	TB3_HEAD r5, t3_m26
	TB3_HEAD r5, t3_m27
	TB3_HEAD r5, t3_m28
	TB3_HEAD r5, t3_m29
	TB3_HEAD r5, t3_m2a
	TB3_HEAD r5, t3_m2b
	TB3_HEAD r5, t3_m2c
	TB3_HEAD r5, t3_m2d
	TB3_HEAD r5, t3_m2e
	TB3_HEAD r5, t3_m2f
	TB3_HEAD r5, t3_m30
	TB3_HEAD r5, t3_m31
	TB3_HEAD r5, t3_m32
	TB3_HEAD r5, t3_m33
	TB3_HEAD r5, t3_m34
	TB3_HEAD r5, t3_m35
	TB3_HEAD r5, t3_m36
	TB3_HEAD r5, t3_m37
	TB3_HEAD r5, t3_m38
	TB3_HEAD r5, t3_m39
	TB3_HEAD r5, t3_m3a
	TB3_HEAD r5, t3_m3b
	TB3_HEAD r5, t3_m3c
	TB3_HEAD r5, t3_m3d
	TB3_HEAD r5, t3_m3e
	TB3_HEAD r5, t3_m3f

t3_m00:	TB3_MIDL r2, r2, r2
t3_m01:	TB3_MIDL r2, r2, r3
t3_m02:	TB3_MIDL r2, r2, r4
t3_m03:	TB3_MIDL r2, r2, r5
t3_m04:	TB3_MIDL r2, r3, r2
t3_m05:	TB3_MIDL r2, r3, r3
t3_m06:	TB3_MIDL r2, r3, r4
t3_m07:	TB3_MIDL r2, r3, r5
t3_m08:	TB3_MIDL r2, r4, r2
t3_m09:	TB3_MIDL r2, r4, r3
t3_m0a:	TB3_MIDL r2, r4, r4
t3_m0b:	TB3_MIDL r2, r4, r5
t3_m0c:	TB3_MIDL r2, r5, r2
t3_m0d:	TB3_MIDL r2, r5, r3
t3_m0e:	TB3_MIDL r2, r5, r4
t3_m0f:	TB3_MIDL r2, r5, r5
t3_m10:	TB3_MIDL r3, r2, r2
t3_m11:	TB3_MIDL r3, r2, r3
t3_m12:	TB3_MIDL r3, r2, r4
t3_m13:	TB3_MIDL r3, r2, r5
t3_m14:	TB3_MIDL r3, r3, r2
t3_m15:	TB3_MIDL r3, r3, r3
t3_m16:	TB3_MIDL r3, r3, r4
t3_m17:	TB3_MIDL r3, r3, r5
t3_m18:	TB3_MIDL r3, r4, r2
t3_m19:	TB3_MIDL r3, r4, r3
t3_m1a:	TB3_MIDL r3, r4, r4
t3_m1b:	TB3_MIDL r3, r4, r5
t3_m1c:	TB3_MIDL r3, r5, r2
t3_m1d:	TB3_MIDL r3, r5, r3
t3_m1e:	TB3_MIDL r3, r5, r4
t3_m1f:	TB3_MIDL r3, r5, r5
t3_m20:	TB3_MIDL r4, r2, r2
t3_m21:	TB3_MIDL r4, r2, r3
t3_m22:	TB3_MIDL r4, r2, r4
t3_m23:	TB3_MIDL r4, r2, r5
t3_m24:	TB3_MIDL r4, r3, r2
t3_m25:	TB3_MIDL r4, r3, r3
t3_m26:	TB3_MIDL r4, r3, r4
t3_m27:	TB3_MIDL r4, r3, r5
t3_m28:	TB3_MIDL r4, r4, r2
t3_m29:	TB3_MIDL r4, r4, r3
t3_m2a:	TB3_MIDL r4, r4, r4
t3_m2b:	TB3_MIDL r4, r4, r5
t3_m2c:	TB3_MIDL r4, r5, r2
t3_m2d:	TB3_MIDL r4, r5, r3
t3_m2e:	TB3_MIDL r4, r5, r4
t3_m2f:	TB3_MIDL r4, r5, r5
t3_m30:	TB3_MIDL r5, r2, r2
t3_m31:	TB3_MIDL r5, r2, r3
t3_m32:	TB3_MIDL r5, r2, r4
t3_m33:	TB3_MIDL r5, r2, r5
t3_m34:	TB3_MIDL r5, r3, r2
t3_m35:	TB3_MIDL r5, r3, r3
t3_m36:	TB3_MIDL r5, r3, r4
t3_m37:	TB3_MIDL r5, r3, r5
t3_m38:	TB3_MIDL r5, r4, r2
t3_m39:	TB3_MIDL r5, r4, r3
t3_m3a:	TB3_MIDL r5, r4, r4
t3_m3b:	TB3_MIDL r5, r4, r5
t3_m3c:	TB3_MIDL r5, r5, r2
t3_m3d:	TB3_MIDL r5, r5, r3
t3_m3e:	TB3_MIDL r5, r5, r4
t3_m3f:	TB3_MIDL r5, r5, r5

#endif

#if (M52_ENABLE_ATTR23M != 0)

t4_t00:	TB4_TNOR r2, r2, r2
t4_t01:	TB4_TNOR r2, r2, r3
t4_t02:	TB4_TNOR r2, r2, r4
t4_t03:	TB4_TNOR r2, r2, r5
t4_t04:	TB4_TNOR r2, r3, r2
t4_t05:	TB4_TNOR r2, r3, r3
t4_t06:	TB4_TNOR r2, r3, r4
t4_t07:	TB4_TNOR r2, r3, r5
t4_t08:	TB4_TNOR r2, r4, r2
t4_t09:	TB4_TNOR r2, r4, r3
t4_t0a:	TB4_TNOR r2, r4, r4
t4_t0b:	TB4_TNOR r2, r4, r5
t4_t0c:	TB4_TNOR r2, r5, r2
t4_t0d:	TB4_TNOR r2, r5, r3
t4_t0e:	TB4_TNOR r2, r5, r4
t4_t0f:	TB4_TNOR r2, r5, r5
t4_t10:	TB4_TNOR r3, r2, r2
t4_t11:	TB4_TNOR r3, r2, r3
t4_t12:	TB4_TNOR r3, r2, r4
t4_t13:	TB4_TNOR r3, r2, r5
t4_t14:	TB4_TNOR r3, r3, r2
t4_t15:	TB4_TNOR r3, r3, r3
t4_t16:	TB4_TNOR r3, r3, r4
t4_t17:	TB4_TNOR r3, r3, r5
t4_t18:	TB4_TNOR r3, r4, r2
t4_t19:	TB4_TNOR r3, r4, r3
t4_t1a:	TB4_TNOR r3, r4, r4
t4_t1b:	TB4_TNOR r3, r4, r5
t4_t1c:	TB4_TNOR r3, r5, r2
t4_t1d:	TB4_TNOR r3, r5, r3
t4_t1e:	TB4_TNOR r3, r5, r4
t4_t1f:	TB4_TNOR r3, r5, r5
t4_t20:	TB4_TNOR r4, r2, r2
t4_t21:	TB4_TNOR r4, r2, r3
t4_t22:	TB4_TNOR r4, r2, r4
t4_t23:	TB4_TNOR r4, r2, r5
t4_t24:	TB4_TNOR r4, r3, r2
t4_t25:	TB4_TNOR r4, r3, r3
t4_t26:	TB4_TNOR r4, r3, r4
t4_t27:	TB4_TNOR r4, r3, r5
t4_t28:	TB4_TNOR r4, r4, r2
t4_t29:	TB4_TNOR r4, r4, r3
t4_t2a:	TB4_TNOR r4, r4, r4
t4_t2b:	TB4_TNOR r4, r4, r5
t4_t2c:	TB4_TNOR r4, r5, r2
t4_t2d:	TB4_TNOR r4, r5, r3
t4_t2e:	TB4_TNOR r4, r5, r4
t4_t2f:	TB4_TNOR r4, r5, r5
t4_t30:	TB4_TNOR r5, r2, r2
t4_t31:	TB4_TNOR r5, r2, r3
t4_t32:	TB4_TNOR r5, r2, r4
t4_t33:	TB4_TNOR r5, r2, r5
t4_t34:	TB4_TNOR r5, r3, r2
t4_t35:	TB4_TNOR r5, r3, r3
t4_t36:	TB4_TNOR r5, r3, r4
t4_t37:	TB4_TNOR r5, r3, r5
t4_t38:	TB4_TNOR r5, r4, r2
t4_t39:	TB4_TNOR r5, r4, r3
t4_t3a:	TB4_TNOR r5, r4, r4
t4_t3b:	TB4_TNOR r5, r4, r5
t4_t3c:	TB4_TNOR r5, r5, r2
t4_t3d:	TB4_TNOR r5, r5, r3
t4_t3e:	TB4_TNOR r5, r5, r4
t4_t3f:	TB4_TNOR r5, r5, r5

t4_u00:	TB4_TMIR r2, r2, r2
t4_u01:	TB4_TMIR r2, r2, r3
t4_u02:	TB4_TMIR r2, r2, r4
t4_u03:	TB4_TMIR r2, r2, r5
t4_u04:	TB4_TMIR r2, r3, r2
t4_u05:	TB4_TMIR r2, r3, r3
t4_u06:	TB4_TMIR r2, r3, r4
t4_u07:	TB4_TMIR r2, r3, r5
t4_u08:	TB4_TMIR r2, r4, r2
t4_u09:	TB4_TMIR r2, r4, r3
t4_u0a:	TB4_TMIR r2, r4, r4
t4_u0b:	TB4_TMIR r2, r4, r5
t4_u0c:	TB4_TMIR r2, r5, r2
t4_u0d:	TB4_TMIR r2, r5, r3
t4_u0e:	TB4_TMIR r2, r5, r4
t4_u0f:	TB4_TMIR r2, r5, r5
t4_u10:	TB4_TMIR r3, r2, r2
t4_u11:	TB4_TMIR r3, r2, r3
t4_u12:	TB4_TMIR r3, r2, r4
t4_u13:	TB4_TMIR r3, r2, r5
t4_u14:	TB4_TMIR r3, r3, r2
t4_u15:	TB4_TMIR r3, r3, r3
t4_u16:	TB4_TMIR r3, r3, r4
t4_u17:	TB4_TMIR r3, r3, r5
t4_u18:	TB4_TMIR r3, r4, r2
t4_u19:	TB4_TMIR r3, r4, r3
t4_u1a:	TB4_TMIR r3, r4, r4
t4_u1b:	TB4_TMIR r3, r4, r5
t4_u1c:	TB4_TMIR r3, r5, r2
t4_u1d:	TB4_TMIR r3, r5, r3
t4_u1e:	TB4_TMIR r3, r5, r4
t4_u1f:	TB4_TMIR r3, r5, r5
t4_u20:	TB4_TMIR r4, r2, r2
t4_u21:	TB4_TMIR r4, r2, r3
t4_u22:	TB4_TMIR r4, r2, r4
t4_u23:	TB4_TMIR r4, r2, r5
t4_u24:	TB4_TMIR r4, r3, r2
t4_u25:	TB4_TMIR r4, r3, r3
t4_u26:	TB4_TMIR r4, r3, r4
t4_u27:	TB4_TMIR r4, r3, r5
t4_u28:	TB4_TMIR r4, r4, r2
t4_u29:	TB4_TMIR r4, r4, r3
t4_u2a:	TB4_TMIR r4, r4, r4
t4_u2b:	TB4_TMIR r4, r4, r5
t4_u2c:	TB4_TMIR r4, r5, r2
t4_u2d:	TB4_TMIR r4, r5, r3
t4_u2e:	TB4_TMIR r4, r5, r4
t4_u2f:	TB4_TMIR r4, r5, r5
t4_u30:	TB4_TMIR r5, r2, r2
t4_u31:	TB4_TMIR r5, r2, r3
t4_u32:	TB4_TMIR r5, r2, r4
t4_u33:	TB4_TMIR r5, r2, r5
t4_u34:	TB4_TMIR r5, r3, r2
t4_u35:	TB4_TMIR r5, r3, r3
t4_u36:	TB4_TMIR r5, r3, r4
t4_u37:	TB4_TMIR r5, r3, r5
t4_u38:	TB4_TMIR r5, r4, r2
t4_u39:	TB4_TMIR r5, r4, r3
t4_u3a:	TB4_TMIR r5, r4, r4
t4_u3b:	TB4_TMIR r5, r4, r5
t4_u3c:	TB4_TMIR r5, r5, r2
t4_u3d:	TB4_TMIR r5, r5, r3
t4_u3e:	TB4_TMIR r5, r5, r4
t4_u3f:	TB4_TMIR r5, r5, r5

.balign 512

t4_jt_nor:

	TB4_HNOR r2,  t4_t00
	TB4_HNOR r2,  t4_t01
	TB4_HNOR r2,  t4_t02
	TB4_HNOR r2,  t4_t03
	TB4_HNOR r2,  t4_t04
	TB4_HNOR r2,  t4_t05
	TB4_HNOR r2,  t4_t06
	TB4_HNOR r2,  t4_t07
	TB4_HNOR r2,  t4_t08
	TB4_HNOR r2,  t4_t09
	TB4_HNOR r2,  t4_t0a
	TB4_HNOR r2,  t4_t0b
	TB4_HNOR r2,  t4_t0c
	TB4_HNOR r2,  t4_t0d
	TB4_HNOR r2,  t4_t0e
	TB4_HNOR r2,  t4_t0f
	TB4_HNOR r2,  t4_t10
	TB4_HNOR r2,  t4_t11
	TB4_HNOR r2,  t4_t12
	TB4_HNOR r2,  t4_t13
	TB4_HNOR r2,  t4_t14
	TB4_HNOR r2,  t4_t15
	TB4_HNOR r2,  t4_t16
	TB4_HNOR r2,  t4_t17
	TB4_HNOR r2,  t4_t18
	TB4_HNOR r2,  t4_t19
	TB4_HNOR r2,  t4_t1a
	TB4_HNOR r2,  t4_t1b
	TB4_HNOR r2,  t4_t1c
	TB4_HNOR r2,  t4_t1d
	TB4_HNOR r2,  t4_t1e
	TB4_HNOR r2,  t4_t1f
	TB4_HNOR r2,  t4_t20
	TB4_HNOR r2,  t4_t21
	TB4_HNOR r2,  t4_t22
	TB4_HNOR r2,  t4_t23
	TB4_HNOR r2,  t4_t24
	TB4_HNOR r2,  t4_t25
	TB4_HNOR r2,  t4_t26
	TB4_HNOR r2,  t4_t27
	TB4_HNOR r2,  t4_t28
	TB4_HNOR r2,  t4_t29
	TB4_HNOR r2,  t4_t2a
	TB4_HNOR r2,  t4_t2b
	TB4_HNOR r2,  t4_t2c
	TB4_HNOR r2,  t4_t2d
	TB4_HNOR r2,  t4_t2e
	TB4_HNOR r2,  t4_t2f
	TB4_HNOR r2,  t4_t30
	TB4_HNOR r2,  t4_t31
	TB4_HNOR r2,  t4_t32
	TB4_HNOR r2,  t4_t33
	TB4_HNOR r2,  t4_t34
	TB4_HNOR r2,  t4_t35
	TB4_HNOR r2,  t4_t36
	TB4_HNOR r2,  t4_t37
	TB4_HNOR r2,  t4_t38
	TB4_HNOR r2,  t4_t39
	TB4_HNOR r2,  t4_t3a
	TB4_HNOR r2,  t4_t3b
	TB4_HNOR r2,  t4_t3c
	TB4_HNOR r2,  t4_t3d
	TB4_HNOR r2,  t4_t3e
	TB4_HNOR r2,  t4_t3f
	TB4_HNOR r3,  t4_t00
	TB4_HNOR r3,  t4_t01
	TB4_HNOR r3,  t4_t02
	TB4_HNOR r3,  t4_t03
	TB4_HNOR r3,  t4_t04
	TB4_HNOR r3,  t4_t05
	TB4_HNOR r3,  t4_t06
	TB4_HNOR r3,  t4_t07
	TB4_HNOR r3,  t4_t08
	TB4_HNOR r3,  t4_t09
	TB4_HNOR r3,  t4_t0a
	TB4_HNOR r3,  t4_t0b
	TB4_HNOR r3,  t4_t0c
	TB4_HNOR r3,  t4_t0d
	TB4_HNOR r3,  t4_t0e
	TB4_HNOR r3,  t4_t0f
	TB4_HNOR r3,  t4_t10
	TB4_HNOR r3,  t4_t11
	TB4_HNOR r3,  t4_t12
	TB4_HNOR r3,  t4_t13
	TB4_HNOR r3,  t4_t14
	TB4_HNOR r3,  t4_t15
	TB4_HNOR r3,  t4_t16
	TB4_HNOR r3,  t4_t17
	TB4_HNOR r3,  t4_t18
	TB4_HNOR r3,  t4_t19
	TB4_HNOR r3,  t4_t1a
	TB4_HNOR r3,  t4_t1b
	TB4_HNOR r3,  t4_t1c
	TB4_HNOR r3,  t4_t1d
	TB4_HNOR r3,  t4_t1e
	TB4_HNOR r3,  t4_t1f
	TB4_HNOR r3,  t4_t20
	TB4_HNOR r3,  t4_t21
	TB4_HNOR r3,  t4_t22
	TB4_HNOR r3,  t4_t23
	TB4_HNOR r3,  t4_t24
	TB4_HNOR r3,  t4_t25
	TB4_HNOR r3,  t4_t26
	TB4_HNOR r3,  t4_t27
	TB4_HNOR r3,  t4_t28
	TB4_HNOR r3,  t4_t29
	TB4_HNOR r3,  t4_t2a
	TB4_HNOR r3,  t4_t2b
	TB4_HNOR r3,  t4_t2c
	TB4_HNOR r3,  t4_t2d
	TB4_HNOR r3,  t4_t2e
	TB4_HNOR r3,  t4_t2f
	TB4_HNOR r3,  t4_t30
	TB4_HNOR r3,  t4_t31
	TB4_HNOR r3,  t4_t32
	TB4_HNOR r3,  t4_t33
	TB4_HNOR r3,  t4_t34
	TB4_HNOR r3,  t4_t35
	TB4_HNOR r3,  t4_t36
	TB4_HNOR r3,  t4_t37
	TB4_HNOR r3,  t4_t38
	TB4_HNOR r3,  t4_t39
	TB4_HNOR r3,  t4_t3a
	TB4_HNOR r3,  t4_t3b
	TB4_HNOR r3,  t4_t3c
	TB4_HNOR r3,  t4_t3d
	TB4_HNOR r3,  t4_t3e
	TB4_HNOR r3,  t4_t3f
	TB4_HNOR r6,  t4_t00
	TB4_HNOR r6,  t4_t01
	TB4_HNOR r6,  t4_t02
	TB4_HNOR r6,  t4_t03
	TB4_HNOR r6,  t4_t04
	TB4_HNOR r6,  t4_t05
	TB4_HNOR r6,  t4_t06
	TB4_HNOR r6,  t4_t07
	TB4_HNOR r6,  t4_t08
	TB4_HNOR r6,  t4_t09
	TB4_HNOR r6,  t4_t0a
	TB4_HNOR r6,  t4_t0b
	TB4_HNOR r6,  t4_t0c
	TB4_HNOR r6,  t4_t0d
	TB4_HNOR r6,  t4_t0e
	TB4_HNOR r6,  t4_t0f
	TB4_HNOR r6,  t4_t10
	TB4_HNOR r6,  t4_t11
	TB4_HNOR r6,  t4_t12
	TB4_HNOR r6,  t4_t13
	TB4_HNOR r6,  t4_t14
	TB4_HNOR r6,  t4_t15
	TB4_HNOR r6,  t4_t16
	TB4_HNOR r6,  t4_t17
	TB4_HNOR r6,  t4_t18
	TB4_HNOR r6,  t4_t19
	TB4_HNOR r6,  t4_t1a
	TB4_HNOR r6,  t4_t1b
	TB4_HNOR r6,  t4_t1c
	TB4_HNOR r6,  t4_t1d
	TB4_HNOR r6,  t4_t1e
	TB4_HNOR r6,  t4_t1f
	TB4_HNOR r6,  t4_t20
	TB4_HNOR r6,  t4_t21
	TB4_HNOR r6,  t4_t22
	TB4_HNOR r6,  t4_t23
	TB4_HNOR r6,  t4_t24
	TB4_HNOR r6,  t4_t25
	TB4_HNOR r6,  t4_t26
	TB4_HNOR r6,  t4_t27
	TB4_HNOR r6,  t4_t28
	TB4_HNOR r6,  t4_t29
	TB4_HNOR r6,  t4_t2a
	TB4_HNOR r6,  t4_t2b
	TB4_HNOR r6,  t4_t2c
	TB4_HNOR r6,  t4_t2d
	TB4_HNOR r6,  t4_t2e
	TB4_HNOR r6,  t4_t2f
	TB4_HNOR r6,  t4_t30
	TB4_HNOR r6,  t4_t31
	TB4_HNOR r6,  t4_t32
	TB4_HNOR r6,  t4_t33
	TB4_HNOR r6,  t4_t34
	TB4_HNOR r6,  t4_t35
	TB4_HNOR r6,  t4_t36
	TB4_HNOR r6,  t4_t37
	TB4_HNOR r6,  t4_t38
	TB4_HNOR r6,  t4_t39
	TB4_HNOR r6,  t4_t3a
	TB4_HNOR r6,  t4_t3b
	TB4_HNOR r6,  t4_t3c
	TB4_HNOR r6,  t4_t3d
	TB4_HNOR r6,  t4_t3e
	TB4_HNOR r6,  t4_t3f
	TB4_HNOR r7,  t4_t00
	TB4_HNOR r7,  t4_t01
	TB4_HNOR r7,  t4_t02
	TB4_HNOR r7,  t4_t03
	TB4_HNOR r7,  t4_t04
	TB4_HNOR r7,  t4_t05
	TB4_HNOR r7,  t4_t06
	TB4_HNOR r7,  t4_t07
	TB4_HNOR r7,  t4_t08
	TB4_HNOR r7,  t4_t09
	TB4_HNOR r7,  t4_t0a
	TB4_HNOR r7,  t4_t0b
	TB4_HNOR r7,  t4_t0c
	TB4_HNOR r7,  t4_t0d
	TB4_HNOR r7,  t4_t0e
	TB4_HNOR r7,  t4_t0f
	TB4_HNOR r7,  t4_t10
	TB4_HNOR r7,  t4_t11
	TB4_HNOR r7,  t4_t12
	TB4_HNOR r7,  t4_t13
	TB4_HNOR r7,  t4_t14
	TB4_HNOR r7,  t4_t15
	TB4_HNOR r7,  t4_t16
	TB4_HNOR r7,  t4_t17
	TB4_HNOR r7,  t4_t18
	TB4_HNOR r7,  t4_t19
	TB4_HNOR r7,  t4_t1a
	TB4_HNOR r7,  t4_t1b
	TB4_HNOR r7,  t4_t1c
	TB4_HNOR r7,  t4_t1d
	TB4_HNOR r7,  t4_t1e
	TB4_HNOR r7,  t4_t1f
	TB4_HNOR r7,  t4_t20
	TB4_HNOR r7,  t4_t21
	TB4_HNOR r7,  t4_t22
	TB4_HNOR r7,  t4_t23
	TB4_HNOR r7,  t4_t24
	TB4_HNOR r7,  t4_t25
	TB4_HNOR r7,  t4_t26
	TB4_HNOR r7,  t4_t27
	TB4_HNOR r7,  t4_t28
	TB4_HNOR r7,  t4_t29
	TB4_HNOR r7,  t4_t2a
	TB4_HNOR r7,  t4_t2b
	TB4_HNOR r7,  t4_t2c
	TB4_HNOR r7,  t4_t2d
	TB4_HNOR r7,  t4_t2e
	TB4_HNOR r7,  t4_t2f
	TB4_HNOR r7,  t4_t30
	TB4_HNOR r7,  t4_t31
	TB4_HNOR r7,  t4_t32
	TB4_HNOR r7,  t4_t33
	TB4_HNOR r7,  t4_t34
	TB4_HNOR r7,  t4_t35
	TB4_HNOR r7,  t4_t36
	TB4_HNOR r7,  t4_t37
	TB4_HNOR r7,  t4_t38
	TB4_HNOR r7,  t4_t39
	TB4_HNOR r7,  t4_t3a
	TB4_HNOR r7,  t4_t3b
	TB4_HNOR r7,  t4_t3c
	TB4_HNOR r7,  t4_t3d
	TB4_HNOR r7,  t4_t3e
	TB4_HNOR r7,  t4_t3f

t4_jt_mir:

	TB4_HMIR r2,  t4_u00
	TB4_HMIR r3,  t4_u00
	TB4_HMIR r6,  t4_u00
	TB4_HMIR r7,  t4_u00
	TB4_HMIR r2,  t4_u10
	TB4_HMIR r3,  t4_u10
	TB4_HMIR r6,  t4_u10
	TB4_HMIR r7,  t4_u10
	TB4_HMIR r2,  t4_u20
	TB4_HMIR r3,  t4_u20
	TB4_HMIR r6,  t4_u20
	TB4_HMIR r7,  t4_u20
	TB4_HMIR r2,  t4_u30
	TB4_HMIR r3,  t4_u30
	TB4_HMIR r6,  t4_u30
	TB4_HMIR r7,  t4_u30
	TB4_HMIR r2,  t4_u04
	TB4_HMIR r3,  t4_u04
	TB4_HMIR r6,  t4_u04
	TB4_HMIR r7,  t4_u04
	TB4_HMIR r2,  t4_u14
	TB4_HMIR r3,  t4_u14
	TB4_HMIR r6,  t4_u14
	TB4_HMIR r7,  t4_u14
	TB4_HMIR r2,  t4_u24
	TB4_HMIR r3,  t4_u24
	TB4_HMIR r6,  t4_u24
	TB4_HMIR r7,  t4_u24
	TB4_HMIR r2,  t4_u34
	TB4_HMIR r3,  t4_u34
	TB4_HMIR r6,  t4_u34
	TB4_HMIR r7,  t4_u34
	TB4_HMIR r2,  t4_u08
	TB4_HMIR r3,  t4_u08
	TB4_HMIR r6,  t4_u08
	TB4_HMIR r7,  t4_u08
	TB4_HMIR r2,  t4_u18
	TB4_HMIR r3,  t4_u18
	TB4_HMIR r6,  t4_u18
	TB4_HMIR r7,  t4_u18
	TB4_HMIR r2,  t4_u28
	TB4_HMIR r3,  t4_u28
	TB4_HMIR r6,  t4_u28
	TB4_HMIR r7,  t4_u28
	TB4_HMIR r2,  t4_u38
	TB4_HMIR r3,  t4_u38
	TB4_HMIR r6,  t4_u38
	TB4_HMIR r7,  t4_u38
	TB4_HMIR r2,  t4_u0c
	TB4_HMIR r3,  t4_u0c
	TB4_HMIR r6,  t4_u0c
	TB4_HMIR r7,  t4_u0c
	TB4_HMIR r2,  t4_u1c
	TB4_HMIR r3,  t4_u1c
	TB4_HMIR r6,  t4_u1c
	TB4_HMIR r7,  t4_u1c
	TB4_HMIR r2,  t4_u2c
	TB4_HMIR r3,  t4_u2c
	TB4_HMIR r6,  t4_u2c
	TB4_HMIR r7,  t4_u2c
	TB4_HMIR r2,  t4_u3c
	TB4_HMIR r3,  t4_u3c
	TB4_HMIR r6,  t4_u3c
	TB4_HMIR r7,  t4_u3c
	TB4_HMIR r2,  t4_u01
	TB4_HMIR r3,  t4_u01
	TB4_HMIR r6,  t4_u01
	TB4_HMIR r7,  t4_u01
	TB4_HMIR r2,  t4_u11
	TB4_HMIR r3,  t4_u11
	TB4_HMIR r6,  t4_u11
	TB4_HMIR r7,  t4_u11
	TB4_HMIR r2,  t4_u21
	TB4_HMIR r3,  t4_u21
	TB4_HMIR r6,  t4_u21
	TB4_HMIR r7,  t4_u21
	TB4_HMIR r2,  t4_u31
	TB4_HMIR r3,  t4_u31
	TB4_HMIR r6,  t4_u31
	TB4_HMIR r7,  t4_u31
	TB4_HMIR r2,  t4_u05
	TB4_HMIR r3,  t4_u05
	TB4_HMIR r6,  t4_u05
	TB4_HMIR r7,  t4_u05
	TB4_HMIR r2,  t4_u15
	TB4_HMIR r3,  t4_u15
	TB4_HMIR r6,  t4_u15
	TB4_HMIR r7,  t4_u15
	TB4_HMIR r2,  t4_u25
	TB4_HMIR r3,  t4_u25
	TB4_HMIR r6,  t4_u25
	TB4_HMIR r7,  t4_u25
	TB4_HMIR r2,  t4_u35
	TB4_HMIR r3,  t4_u35
	TB4_HMIR r6,  t4_u35
	TB4_HMIR r7,  t4_u35
	TB4_HMIR r2,  t4_u09
	TB4_HMIR r3,  t4_u09
	TB4_HMIR r6,  t4_u09
	TB4_HMIR r7,  t4_u09
	TB4_HMIR r2,  t4_u19
	TB4_HMIR r3,  t4_u19
	TB4_HMIR r6,  t4_u19
	TB4_HMIR r7,  t4_u19
	TB4_HMIR r2,  t4_u29
	TB4_HMIR r3,  t4_u29
	TB4_HMIR r6,  t4_u29
	TB4_HMIR r7,  t4_u29
	TB4_HMIR r2,  t4_u39
	TB4_HMIR r3,  t4_u39
	TB4_HMIR r6,  t4_u39
	TB4_HMIR r7,  t4_u39
	TB4_HMIR r2,  t4_u0d
	TB4_HMIR r3,  t4_u0d
	TB4_HMIR r6,  t4_u0d
	TB4_HMIR r7,  t4_u0d
	TB4_HMIR r2,  t4_u1d
	TB4_HMIR r3,  t4_u1d
	TB4_HMIR r6,  t4_u1d
	TB4_HMIR r7,  t4_u1d
	TB4_HMIR r2,  t4_u2d
	TB4_HMIR r3,  t4_u2d
	TB4_HMIR r6,  t4_u2d
	TB4_HMIR r7,  t4_u2d
	TB4_HMIR r2,  t4_u3d
	TB4_HMIR r3,  t4_u3d
	TB4_HMIR r6,  t4_u3d
	TB4_HMIR r7,  t4_u3d
	TB4_HMIR r2,  t4_u02
	TB4_HMIR r3,  t4_u02
	TB4_HMIR r6,  t4_u02
	TB4_HMIR r7,  t4_u02
	TB4_HMIR r2,  t4_u12
	TB4_HMIR r3,  t4_u12
	TB4_HMIR r6,  t4_u12
	TB4_HMIR r7,  t4_u12
	TB4_HMIR r2,  t4_u22
	TB4_HMIR r3,  t4_u22
	TB4_HMIR r6,  t4_u22
	TB4_HMIR r7,  t4_u22
	TB4_HMIR r2,  t4_u32
	TB4_HMIR r3,  t4_u32
	TB4_HMIR r6,  t4_u32
	TB4_HMIR r7,  t4_u32
	TB4_HMIR r2,  t4_u06
	TB4_HMIR r3,  t4_u06
	TB4_HMIR r6,  t4_u06
	TB4_HMIR r7,  t4_u06
	TB4_HMIR r2,  t4_u16
	TB4_HMIR r3,  t4_u16
	TB4_HMIR r6,  t4_u16
	TB4_HMIR r7,  t4_u16
	TB4_HMIR r2,  t4_u26
	TB4_HMIR r3,  t4_u26
	TB4_HMIR r6,  t4_u26
	TB4_HMIR r7,  t4_u26
	TB4_HMIR r2,  t4_u36
	TB4_HMIR r3,  t4_u36
	TB4_HMIR r6,  t4_u36
	TB4_HMIR r7,  t4_u36
	TB4_HMIR r2,  t4_u0a
	TB4_HMIR r3,  t4_u0a
	TB4_HMIR r6,  t4_u0a
	TB4_HMIR r7,  t4_u0a
	TB4_HMIR r2,  t4_u1a
	TB4_HMIR r3,  t4_u1a
	TB4_HMIR r6,  t4_u1a
	TB4_HMIR r7,  t4_u1a
	TB4_HMIR r2,  t4_u2a
	TB4_HMIR r3,  t4_u2a
	TB4_HMIR r6,  t4_u2a
	TB4_HMIR r7,  t4_u2a
	TB4_HMIR r2,  t4_u3a
	TB4_HMIR r3,  t4_u3a
	TB4_HMIR r6,  t4_u3a
	TB4_HMIR r7,  t4_u3a
	TB4_HMIR r2,  t4_u0e
	TB4_HMIR r3,  t4_u0e
	TB4_HMIR r6,  t4_u0e
	TB4_HMIR r7,  t4_u0e
	TB4_HMIR r2,  t4_u1e
	TB4_HMIR r3,  t4_u1e
	TB4_HMIR r6,  t4_u1e
	TB4_HMIR r7,  t4_u1e
	TB4_HMIR r2,  t4_u2e
	TB4_HMIR r3,  t4_u2e
	TB4_HMIR r6,  t4_u2e
	TB4_HMIR r7,  t4_u2e
	TB4_HMIR r2,  t4_u3e
	TB4_HMIR r3,  t4_u3e
	TB4_HMIR r6,  t4_u3e
	TB4_HMIR r7,  t4_u3e
	TB4_HMIR r2,  t4_u03
	TB4_HMIR r3,  t4_u03
	TB4_HMIR r6,  t4_u03
	TB4_HMIR r7,  t4_u03
	TB4_HMIR r2,  t4_u13
	TB4_HMIR r3,  t4_u13
	TB4_HMIR r6,  t4_u13
	TB4_HMIR r7,  t4_u13
	TB4_HMIR r2,  t4_u23
	TB4_HMIR r3,  t4_u23
	TB4_HMIR r6,  t4_u23
	TB4_HMIR r7,  t4_u23
	TB4_HMIR r2,  t4_u33
	TB4_HMIR r3,  t4_u33
	TB4_HMIR r6,  t4_u33
	TB4_HMIR r7,  t4_u33
	TB4_HMIR r2,  t4_u07
	TB4_HMIR r3,  t4_u07
	TB4_HMIR r6,  t4_u07
	TB4_HMIR r7,  t4_u07
	TB4_HMIR r2,  t4_u17
	TB4_HMIR r3,  t4_u17
	TB4_HMIR r6,  t4_u17
	TB4_HMIR r7,  t4_u17
	TB4_HMIR r2,  t4_u27
	TB4_HMIR r3,  t4_u27
	TB4_HMIR r6,  t4_u27
	TB4_HMIR r7,  t4_u27
	TB4_HMIR r2,  t4_u37
	TB4_HMIR r3,  t4_u37
	TB4_HMIR r6,  t4_u37
	TB4_HMIR r7,  t4_u37
	TB4_HMIR r2,  t4_u0b
	TB4_HMIR r3,  t4_u0b
	TB4_HMIR r6,  t4_u0b
	TB4_HMIR r7,  t4_u0b
	TB4_HMIR r2,  t4_u1b
	TB4_HMIR r3,  t4_u1b
	TB4_HMIR r6,  t4_u1b
	TB4_HMIR r7,  t4_u1b
	TB4_HMIR r2,  t4_u2b
	TB4_HMIR r3,  t4_u2b
	TB4_HMIR r6,  t4_u2b
	TB4_HMIR r7,  t4_u2b
	TB4_HMIR r2,  t4_u3b
	TB4_HMIR r3,  t4_u3b
	TB4_HMIR r6,  t4_u3b
	TB4_HMIR r7,  t4_u3b
	TB4_HMIR r2,  t4_u0f
	TB4_HMIR r3,  t4_u0f
	TB4_HMIR r6,  t4_u0f
	TB4_HMIR r7,  t4_u0f
	TB4_HMIR r2,  t4_u1f
	TB4_HMIR r3,  t4_u1f
	TB4_HMIR r6,  t4_u1f
	TB4_HMIR r7,  t4_u1f
	TB4_HMIR r2,  t4_u2f
	TB4_HMIR r3,  t4_u2f
	TB4_HMIR r6,  t4_u2f
	TB4_HMIR r7,  t4_u2f
	TB4_HMIR r2,  t4_u3f
	TB4_HMIR r3,  t4_u3f
	TB4_HMIR r6,  t4_u3f
	TB4_HMIR r7,  t4_u3f

t5_jt_nor:

	rjmp  t5_h00
	rjmp  t5_h01
	rjmp  t5_h02
	rjmp  t5_h03
	rjmp  t5_h04
	rjmp  t5_h05
	rjmp  t5_h06
	rjmp  t5_h07
	rjmp  t5_h08
	rjmp  t5_h09
	rjmp  t5_h0a
	rjmp  t5_h0b
	rjmp  t5_h0c
	rjmp  t5_h0d
	rjmp  t5_h0e
	rjmp  t5_h0f
	rjmp  t5_h10
	rjmp  t5_h11
	rjmp  t5_h12
	rjmp  t5_h13
	rjmp  t5_h14
	rjmp  t5_h15
	rjmp  t5_h16
	rjmp  t5_h17
	rjmp  t5_h18
	rjmp  t5_h19
	rjmp  t5_h1a
	rjmp  t5_h1b
	rjmp  t5_h1c
	rjmp  t5_h1d
	rjmp  t5_h1e
	rjmp  t5_h1f
	rjmp  t5_h20
	rjmp  t5_h21
	rjmp  t5_h22
	rjmp  t5_h23
	rjmp  t5_h24
	rjmp  t5_h25
	rjmp  t5_h26
	rjmp  t5_h27
	rjmp  t5_h28
	rjmp  t5_h29
	rjmp  t5_h2a
	rjmp  t5_h2b
	rjmp  t5_h2c
	rjmp  t5_h2d
	rjmp  t5_h2e
	rjmp  t5_h2f
	rjmp  t5_h30
	rjmp  t5_h31
	rjmp  t5_h32
	rjmp  t5_h33
	rjmp  t5_h34
	rjmp  t5_h35
	rjmp  t5_h36
	rjmp  t5_h37
	rjmp  t5_h38
	rjmp  t5_h39
	rjmp  t5_h3a
	rjmp  t5_h3b
	rjmp  t5_h3c
	rjmp  t5_h3d
	rjmp  t5_h3e
	rjmp  t5_h3f
	rjmp  t5_h40
	rjmp  t5_h41
	rjmp  t5_h42
	rjmp  t5_h43
	rjmp  t5_h44
	rjmp  t5_h45
	rjmp  t5_h46
	rjmp  t5_h47
	rjmp  t5_h48
	rjmp  t5_h49
	rjmp  t5_h4a
	rjmp  t5_h4b
	rjmp  t5_h4c
	rjmp  t5_h4d
	rjmp  t5_h4e
	rjmp  t5_h4f
	rjmp  t5_h50
	rjmp  t5_h51
	rjmp  t5_h52
	rjmp  t5_h53
	rjmp  t5_h54
	rjmp  t5_h55
	rjmp  t5_h56
	rjmp  t5_h57
	rjmp  t5_h58
	rjmp  t5_h59
	rjmp  t5_h5a
	rjmp  t5_h5b
	rjmp  t5_h5c
	rjmp  t5_h5d
	rjmp  t5_h5e
	rjmp  t5_h5f
	rjmp  t5_h60
	rjmp  t5_h61
	rjmp  t5_h62
	rjmp  t5_h63
	rjmp  t5_h64
	rjmp  t5_h65
	rjmp  t5_h66
	rjmp  t5_h67
	rjmp  t5_h68
	rjmp  t5_h69
	rjmp  t5_h6a
	rjmp  t5_h6b
	rjmp  t5_h6c
	rjmp  t5_h6d
	rjmp  t5_h6e
	rjmp  t5_h6f
	rjmp  t5_h70
	rjmp  t5_h71
	rjmp  t5_h72
	rjmp  t5_h73
	rjmp  t5_h74
	rjmp  t5_h75
	rjmp  t5_h76
	rjmp  t5_h77
	rjmp  t5_h78
	rjmp  t5_h79
	rjmp  t5_h7a
	rjmp  t5_h7b
	rjmp  t5_h7c
	rjmp  t5_h7d
	rjmp  t5_h7e
	rjmp  t5_h7f
	rjmp  t5_h80
	rjmp  t5_h81
	rjmp  t5_h82
	rjmp  t5_h83
	rjmp  t5_h84
	rjmp  t5_h85
	rjmp  t5_h86
	rjmp  t5_h87
	rjmp  t5_h88
	rjmp  t5_h89
	rjmp  t5_h8a
	rjmp  t5_h8b
	rjmp  t5_h8c
	rjmp  t5_h8d
	rjmp  t5_h8e
	rjmp  t5_h8f
	rjmp  t5_h90
	rjmp  t5_h91
	rjmp  t5_h92
	rjmp  t5_h93
	rjmp  t5_h94
	rjmp  t5_h95
	rjmp  t5_h96
	rjmp  t5_h97
	rjmp  t5_h98
	rjmp  t5_h99
	rjmp  t5_h9a
	rjmp  t5_h9b
	rjmp  t5_h9c
	rjmp  t5_h9d
	rjmp  t5_h9e
	rjmp  t5_h9f
	rjmp  t5_ha0
	rjmp  t5_ha1
	rjmp  t5_ha2
	rjmp  t5_ha3
	rjmp  t5_ha4
	rjmp  t5_ha5
	rjmp  t5_ha6
	rjmp  t5_ha7
	rjmp  t5_ha8
	rjmp  t5_ha9
	rjmp  t5_haa
	rjmp  t5_hab
	rjmp  t5_hac
	rjmp  t5_had
	rjmp  t5_hae
	rjmp  t5_haf
	rjmp  t5_hb0
	rjmp  t5_hb1
	rjmp  t5_hb2
	rjmp  t5_hb3
	rjmp  t5_hb4
	rjmp  t5_hb5
	rjmp  t5_hb6
	rjmp  t5_hb7
	rjmp  t5_hb8
	rjmp  t5_hb9
	rjmp  t5_hba
	rjmp  t5_hbb
	rjmp  t5_hbc
	rjmp  t5_hbd
	rjmp  t5_hbe
	rjmp  t5_hbf
	rjmp  t5_hc0
	rjmp  t5_hc1
	rjmp  t5_hc2
	rjmp  t5_hc3
	rjmp  t5_hc4
	rjmp  t5_hc5
	rjmp  t5_hc6
	rjmp  t5_hc7
	rjmp  t5_hc8
	rjmp  t5_hc9
	rjmp  t5_hca
	rjmp  t5_hcb
	rjmp  t5_hcc
	rjmp  t5_hcd
	rjmp  t5_hce
	rjmp  t5_hcf
	rjmp  t5_hd0
	rjmp  t5_hd1
	rjmp  t5_hd2
	rjmp  t5_hd3
	rjmp  t5_hd4
	rjmp  t5_hd5
	rjmp  t5_hd6
	rjmp  t5_hd7
	rjmp  t5_hd8
	rjmp  t5_hd9
	rjmp  t5_hda
	rjmp  t5_hdb
	rjmp  t5_hdc
	rjmp  t5_hdd
	rjmp  t5_hde
	rjmp  t5_hdf
	rjmp  t5_he0
	rjmp  t5_he1
	rjmp  t5_he2
	rjmp  t5_he3
	rjmp  t5_he4
	rjmp  t5_he5
	rjmp  t5_he6
	rjmp  t5_he7
	rjmp  t5_he8
	rjmp  t5_he9
	rjmp  t5_hea
	rjmp  t5_heb
	rjmp  t5_hec
	rjmp  t5_hed
	rjmp  t5_hee
	rjmp  t5_hef
	rjmp  t5_hf0
	rjmp  t5_hf1
	rjmp  t5_hf2
	rjmp  t5_hf3
	rjmp  t5_hf4
	rjmp  t5_hf5
	rjmp  t5_hf6
	rjmp  t5_hf7
	rjmp  t5_hf8
	rjmp  t5_hf9
	rjmp  t5_hfa
	rjmp  t5_hfb
	rjmp  t5_hfc
	rjmp  t5_hfd
	rjmp  t5_hfe
	rjmp  t5_hff

t5_jt_mir:

	rjmp  t5_h00
	rjmp  t5_h40
	rjmp  t5_h80
	rjmp  t5_hc0
	rjmp  t5_h10
	rjmp  t5_h50
	rjmp  t5_h90
	rjmp  t5_hd0
	rjmp  t5_h20
	rjmp  t5_h60
	rjmp  t5_ha0
	rjmp  t5_he0
	rjmp  t5_h30
	rjmp  t5_h70
	rjmp  t5_hb0
	rjmp  t5_hf0
	rjmp  t5_h04
	rjmp  t5_h44
	rjmp  t5_h84
	rjmp  t5_hc4
	rjmp  t5_h14
	rjmp  t5_h54
	rjmp  t5_h94
	rjmp  t5_hd4
	rjmp  t5_h24
	rjmp  t5_h64
	rjmp  t5_ha4
	rjmp  t5_he4
	rjmp  t5_h34
	rjmp  t5_h74
	rjmp  t5_hb4
	rjmp  t5_hf4
	rjmp  t5_h08
	rjmp  t5_h48
	rjmp  t5_h88
	rjmp  t5_hc8
	rjmp  t5_h18
	rjmp  t5_h58
	rjmp  t5_h98
	rjmp  t5_hd8
	rjmp  t5_h28
	rjmp  t5_h68
	rjmp  t5_ha8
	rjmp  t5_he8
	rjmp  t5_h38
	rjmp  t5_h78
	rjmp  t5_hb8
	rjmp  t5_hf8
	rjmp  t5_h0c
	rjmp  t5_h4c
	rjmp  t5_h8c
	rjmp  t5_hcc
	rjmp  t5_h1c
	rjmp  t5_h5c
	rjmp  t5_h9c
	rjmp  t5_hdc
	rjmp  t5_h2c
	rjmp  t5_h6c
	rjmp  t5_hac
	rjmp  t5_hec
	rjmp  t5_h3c
	rjmp  t5_h7c
	rjmp  t5_hbc
	rjmp  t5_hfc
	rjmp  t5_h01
	rjmp  t5_h41
	rjmp  t5_h81
	rjmp  t5_hc1
	rjmp  t5_h11
	rjmp  t5_h51
	rjmp  t5_h91
	rjmp  t5_hd1
	rjmp  t5_h21
	rjmp  t5_h61
	rjmp  t5_ha1
	rjmp  t5_he1
	rjmp  t5_h31
	rjmp  t5_h71
	rjmp  t5_hb1
	rjmp  t5_hf1
	rjmp  t5_h05
	rjmp  t5_h45
	rjmp  t5_h85
	rjmp  t5_hc5
	rjmp  t5_h15
	rjmp  t5_h55
	rjmp  t5_h95
	rjmp  t5_hd5
	rjmp  t5_h25
	rjmp  t5_h65
	rjmp  t5_ha5
	rjmp  t5_he5
	rjmp  t5_h35
	rjmp  t5_h75
	rjmp  t5_hb5
	rjmp  t5_hf5
	rjmp  t5_h09
	rjmp  t5_h49
	rjmp  t5_h89
	rjmp  t5_hc9
	rjmp  t5_h19
	rjmp  t5_h59
	rjmp  t5_h99
	rjmp  t5_hd9
	rjmp  t5_h29
	rjmp  t5_h69
	rjmp  t5_ha9
	rjmp  t5_he9
	rjmp  t5_h39
	rjmp  t5_h79
	rjmp  t5_hb9
	rjmp  t5_hf9
	rjmp  t5_h0d
	rjmp  t5_h4d
	rjmp  t5_h8d
	rjmp  t5_hcd
	rjmp  t5_h1d
	rjmp  t5_h5d
	rjmp  t5_h9d
	rjmp  t5_hdd
	rjmp  t5_h2d
	rjmp  t5_h6d
	rjmp  t5_had
	rjmp  t5_hed
	rjmp  t5_h3d
	rjmp  t5_h7d
	rjmp  t5_hbd
	rjmp  t5_hfd
	rjmp  t5_h02
	rjmp  t5_h42
	rjmp  t5_h82
	rjmp  t5_hc2
	rjmp  t5_h12
	rjmp  t5_h52
	rjmp  t5_h92
	rjmp  t5_hd2
	rjmp  t5_h22
	rjmp  t5_h62
	rjmp  t5_ha2
	rjmp  t5_he2
	rjmp  t5_h32
	rjmp  t5_h72
	rjmp  t5_hb2
	rjmp  t5_hf2
	rjmp  t5_h06
	rjmp  t5_h46
	rjmp  t5_h86
	rjmp  t5_hc6
	rjmp  t5_h16
	rjmp  t5_h56
	rjmp  t5_h96
	rjmp  t5_hd6
	rjmp  t5_h26
	rjmp  t5_h66
	rjmp  t5_ha6
	rjmp  t5_he6
	rjmp  t5_h36
	rjmp  t5_h76
	rjmp  t5_hb6
	rjmp  t5_hf6
	rjmp  t5_h0a
	rjmp  t5_h4a
	rjmp  t5_h8a
	rjmp  t5_hca
	rjmp  t5_h1a
	rjmp  t5_h5a
	rjmp  t5_h9a
	rjmp  t5_hda
	rjmp  t5_h2a
	rjmp  t5_h6a
	rjmp  t5_haa
	rjmp  t5_hea
	rjmp  t5_h3a
	rjmp  t5_h7a
	rjmp  t5_hba
	rjmp  t5_hfa
	rjmp  t5_h0e
	rjmp  t5_h4e
	rjmp  t5_h8e
	rjmp  t5_hce
	rjmp  t5_h1e
	rjmp  t5_h5e
	rjmp  t5_h9e
	rjmp  t5_hde
	rjmp  t5_h2e
	rjmp  t5_h6e
	rjmp  t5_hae
	rjmp  t5_hee
	rjmp  t5_h3e
	rjmp  t5_h7e
	rjmp  t5_hbe
	rjmp  t5_hfe
	rjmp  t5_h03
	rjmp  t5_h43
	rjmp  t5_h83
	rjmp  t5_hc3
	rjmp  t5_h13
	rjmp  t5_h53
	rjmp  t5_h93
	rjmp  t5_hd3
	rjmp  t5_h23
	rjmp  t5_h63
	rjmp  t5_ha3
	rjmp  t5_he3
	rjmp  t5_h33
	rjmp  t5_h73
	rjmp  t5_hb3
	rjmp  t5_hf3
	rjmp  t5_h07
	rjmp  t5_h47
	rjmp  t5_h87
	rjmp  t5_hc7
	rjmp  t5_h17
	rjmp  t5_h57
	rjmp  t5_h97
	rjmp  t5_hd7
	rjmp  t5_h27
	rjmp  t5_h67
	rjmp  t5_ha7
	rjmp  t5_he7
	rjmp  t5_h37
	rjmp  t5_h77
	rjmp  t5_hb7
	rjmp  t5_hf7
	rjmp  t5_h0b
	rjmp  t5_h4b
	rjmp  t5_h8b
	rjmp  t5_hcb
	rjmp  t5_h1b
	rjmp  t5_h5b
	rjmp  t5_h9b
	rjmp  t5_hdb
	rjmp  t5_h2b
	rjmp  t5_h6b
	rjmp  t5_hab
	rjmp  t5_heb
	rjmp  t5_h3b
	rjmp  t5_h7b
	rjmp  t5_hbb
	rjmp  t5_hfb
	rjmp  t5_h0f
	rjmp  t5_h4f
	rjmp  t5_h8f
	rjmp  t5_hcf
	rjmp  t5_h1f
	rjmp  t5_h5f
	rjmp  t5_h9f
	rjmp  t5_hdf
	rjmp  t5_h2f
	rjmp  t5_h6f
	rjmp  t5_haf
	rjmp  t5_hef
	rjmp  t5_h3f
	rjmp  t5_h7f
	rjmp  t5_hbf
	rjmp  t5_hff

t5_h00:	TB5_HEAD r2, t5_m00
t5_h01:	TB5_HEAD r2, t5_m01
t5_h02:	TB5_HEAD r2, t5_m02
t5_h03:	TB5_HEAD r2, t5_m03
t5_h04:	TB5_HEAD r2, t5_m04
t5_h05:	TB5_HEAD r2, t5_m05
t5_h06:	TB5_HEAD r2, t5_m06
t5_h07:	TB5_HEAD r2, t5_m07
t5_h08:	TB5_HEAD r2, t5_m08
t5_h09:	TB5_HEAD r2, t5_m09
t5_h0a:	TB5_HEAD r2, t5_m0a
t5_h0b:	TB5_HEAD r2, t5_m0b
t5_h0c:	TB5_HEAD r2, t5_m0c
t5_h0d:	TB5_HEAD r2, t5_m0d
t5_h0e:	TB5_HEAD r2, t5_m0e
t5_h0f:	TB5_HEAD r2, t5_m0f
t5_h10:	TB5_HEAD r2, t5_m10
t5_h11:	TB5_HEAD r2, t5_m11
t5_h12:	TB5_HEAD r2, t5_m12
t5_h13:	TB5_HEAD r2, t5_m13
t5_h14:	TB5_HEAD r2, t5_m14
t5_h15:	TB5_HEAD r2, t5_m15
t5_h16:	TB5_HEAD r2, t5_m16
t5_h17:	TB5_HEAD r2, t5_m17
t5_h18:	TB5_HEAD r2, t5_m18
t5_h19:	TB5_HEAD r2, t5_m19
t5_h1a:	TB5_HEAD r2, t5_m1a
t5_h1b:	TB5_HEAD r2, t5_m1b
t5_h1c:	TB5_HEAD r2, t5_m1c
t5_h1d:	TB5_HEAD r2, t5_m1d
t5_h1e:	TB5_HEAD r2, t5_m1e
t5_h1f:	TB5_HEAD r2, t5_m1f
t5_h20:	TB5_HEAD r2, t5_m20
t5_h21:	TB5_HEAD r2, t5_m21
t5_h22:	TB5_HEAD r2, t5_m22
t5_h23:	TB5_HEAD r2, t5_m23
t5_h24:	TB5_HEAD r2, t5_m24
t5_h25:	TB5_HEAD r2, t5_m25
t5_h26:	TB5_HEAD r2, t5_m26
t5_h27:	TB5_HEAD r2, t5_m27
t5_h28:	TB5_HEAD r2, t5_m28
t5_h29:	TB5_HEAD r2, t5_m29
t5_h2a:	TB5_HEAD r2, t5_m2a
t5_h2b:	TB5_HEAD r2, t5_m2b
t5_h2c:	TB5_HEAD r2, t5_m2c
t5_h2d:	TB5_HEAD r2, t5_m2d
t5_h2e:	TB5_HEAD r2, t5_m2e
t5_h2f:	TB5_HEAD r2, t5_m2f
t5_h30:	TB5_HEAD r2, t5_m30
t5_h31:	TB5_HEAD r2, t5_m31
t5_h32:	TB5_HEAD r2, t5_m32
t5_h33:	TB5_HEAD r2, t5_m33
t5_h34:	TB5_HEAD r2, t5_m34
t5_h35:	TB5_HEAD r2, t5_m35
t5_h36:	TB5_HEAD r2, t5_m36
t5_h37:	TB5_HEAD r2, t5_m37
t5_h38:	TB5_HEAD r2, t5_m38
t5_h39:	TB5_HEAD r2, t5_m39
t5_h3a:	TB5_HEAD r2, t5_m3a
t5_h3b:	TB5_HEAD r2, t5_m3b
t5_h3c:	TB5_HEAD r2, t5_m3c
t5_h3d:	TB5_HEAD r2, t5_m3d
t5_h3e:	TB5_HEAD r2, t5_m3e
t5_h3f:	TB5_HEAD r2, t5_m3f
t5_h40:	TB5_HEAD r3, t5_m00
t5_h41:	TB5_HEAD r3, t5_m01
t5_h42:	TB5_HEAD r3, t5_m02
t5_h43:	TB5_HEAD r3, t5_m03
t5_h44:	TB5_HEAD r3, t5_m04
t5_h45:	TB5_HEAD r3, t5_m05
t5_h46:	TB5_HEAD r3, t5_m06
t5_h47:	TB5_HEAD r3, t5_m07
t5_h48:	TB5_HEAD r3, t5_m08
t5_h49:	TB5_HEAD r3, t5_m09
t5_h4a:	TB5_HEAD r3, t5_m0a
t5_h4b:	TB5_HEAD r3, t5_m0b
t5_h4c:	TB5_HEAD r3, t5_m0c
t5_h4d:	TB5_HEAD r3, t5_m0d
t5_h4e:	TB5_HEAD r3, t5_m0e
t5_h4f:	TB5_HEAD r3, t5_m0f
t5_h50:	TB5_HEAD r3, t5_m10
t5_h51:	TB5_HEAD r3, t5_m11
t5_h52:	TB5_HEAD r3, t5_m12
t5_h53:	TB5_HEAD r3, t5_m13
t5_h54:	TB5_HEAD r3, t5_m14
t5_h55:	TB5_HEAD r3, t5_m15
t5_h56:	TB5_HEAD r3, t5_m16
t5_h57:	TB5_HEAD r3, t5_m17
t5_h58:	TB5_HEAD r3, t5_m18
t5_h59:	TB5_HEAD r3, t5_m19
t5_h5a:	TB5_HEAD r3, t5_m1a
t5_h5b:	TB5_HEAD r3, t5_m1b
t5_h5c:	TB5_HEAD r3, t5_m1c
t5_h5d:	TB5_HEAD r3, t5_m1d
t5_h5e:	TB5_HEAD r3, t5_m1e
t5_h5f:	TB5_HEAD r3, t5_m1f
t5_h60:	TB5_HEAD r3, t5_m20
t5_h61:	TB5_HEAD r3, t5_m21
t5_h62:	TB5_HEAD r3, t5_m22
t5_h63:	TB5_HEAD r3, t5_m23
t5_h64:	TB5_HEAD r3, t5_m24
t5_h65:	TB5_HEAD r3, t5_m25
t5_h66:	TB5_HEAD r3, t5_m26
t5_h67:	TB5_HEAD r3, t5_m27
t5_h68:	TB5_HEAD r3, t5_m28
t5_h69:	TB5_HEAD r3, t5_m29
t5_h6a:	TB5_HEAD r3, t5_m2a
t5_h6b:	TB5_HEAD r3, t5_m2b
t5_h6c:	TB5_HEAD r3, t5_m2c
t5_h6d:	TB5_HEAD r3, t5_m2d
t5_h6e:	TB5_HEAD r3, t5_m2e
t5_h6f:	TB5_HEAD r3, t5_m2f
t5_h70:	TB5_HEAD r3, t5_m30
t5_h71:	TB5_HEAD r3, t5_m31
t5_h72:	TB5_HEAD r3, t5_m32
t5_h73:	TB5_HEAD r3, t5_m33
t5_h74:	TB5_HEAD r3, t5_m34
t5_h75:	TB5_HEAD r3, t5_m35
t5_h76:	TB5_HEAD r3, t5_m36
t5_h77:	TB5_HEAD r3, t5_m37
t5_h78:	TB5_HEAD r3, t5_m38
t5_h79:	TB5_HEAD r3, t5_m39
t5_h7a:	TB5_HEAD r3, t5_m3a
t5_h7b:	TB5_HEAD r3, t5_m3b
t5_h7c:	TB5_HEAD r3, t5_m3c
t5_h7d:	TB5_HEAD r3, t5_m3d
t5_h7e:	TB5_HEAD r3, t5_m3e
t5_h7f:	TB5_HEAD r3, t5_m3f
t5_h80:	TB5_HEAD r4, t5_m00
t5_h81:	TB5_HEAD r4, t5_m01
t5_h82:	TB5_HEAD r4, t5_m02
t5_h83:	TB5_HEAD r4, t5_m03
t5_h84:	TB5_HEAD r4, t5_m04
t5_h85:	TB5_HEAD r4, t5_m05
t5_h86:	TB5_HEAD r4, t5_m06
t5_h87:	TB5_HEAD r4, t5_m07
t5_h88:	TB5_HEAD r4, t5_m08
t5_h89:	TB5_HEAD r4, t5_m09
t5_h8a:	TB5_HEAD r4, t5_m0a
t5_h8b:	TB5_HEAD r4, t5_m0b
t5_h8c:	TB5_HEAD r4, t5_m0c
t5_h8d:	TB5_HEAD r4, t5_m0d
t5_h8e:	TB5_HEAD r4, t5_m0e
t5_h8f:	TB5_HEAD r4, t5_m0f
t5_h90:	TB5_HEAD r4, t5_m10
t5_h91:	TB5_HEAD r4, t5_m11
t5_h92:	TB5_HEAD r4, t5_m12
t5_h93:	TB5_HEAD r4, t5_m13
t5_h94:	TB5_HEAD r4, t5_m14
t5_h95:	TB5_HEAD r4, t5_m15
t5_h96:	TB5_HEAD r4, t5_m16
t5_h97:	TB5_HEAD r4, t5_m17
t5_h98:	TB5_HEAD r4, t5_m18
t5_h99:	TB5_HEAD r4, t5_m19
t5_h9a:	TB5_HEAD r4, t5_m1a
t5_h9b:	TB5_HEAD r4, t5_m1b
t5_h9c:	TB5_HEAD r4, t5_m1c
t5_h9d:	TB5_HEAD r4, t5_m1d
t5_h9e:	TB5_HEAD r4, t5_m1e
t5_h9f:	TB5_HEAD r4, t5_m1f
t5_ha0:	TB5_HEAD r4, t5_m20
t5_ha1:	TB5_HEAD r4, t5_m21
t5_ha2:	TB5_HEAD r4, t5_m22
t5_ha3:	TB5_HEAD r4, t5_m23
t5_ha4:	TB5_HEAD r4, t5_m24
t5_ha5:	TB5_HEAD r4, t5_m25
t5_ha6:	TB5_HEAD r4, t5_m26
t5_ha7:	TB5_HEAD r4, t5_m27
t5_ha8:	TB5_HEAD r4, t5_m28
t5_ha9:	TB5_HEAD r4, t5_m29
t5_haa:	TB5_HEAD r4, t5_m2a
t5_hab:	TB5_HEAD r4, t5_m2b
t5_hac:	TB5_HEAD r4, t5_m2c
t5_had:	TB5_HEAD r4, t5_m2d
t5_hae:	TB5_HEAD r4, t5_m2e
t5_haf:	TB5_HEAD r4, t5_m2f
t5_hb0:	TB5_HEAD r4, t5_m30
t5_hb1:	TB5_HEAD r4, t5_m31
t5_hb2:	TB5_HEAD r4, t5_m32
t5_hb3:	TB5_HEAD r4, t5_m33
t5_hb4:	TB5_HEAD r4, t5_m34
t5_hb5:	TB5_HEAD r4, t5_m35
t5_hb6:	TB5_HEAD r4, t5_m36
t5_hb7:	TB5_HEAD r4, t5_m37
t5_hb8:	TB5_HEAD r4, t5_m38
t5_hb9:	TB5_HEAD r4, t5_m39
t5_hba:	TB5_HEAD r4, t5_m3a
t5_hbb:	TB5_HEAD r4, t5_m3b
t5_hbc:	TB5_HEAD r4, t5_m3c
t5_hbd:	TB5_HEAD r4, t5_m3d
t5_hbe:	TB5_HEAD r4, t5_m3e
t5_hbf:	TB5_HEAD r4, t5_m3f
t5_hc0:	TB5_HEAD r5, t5_m00
t5_hc1:	TB5_HEAD r5, t5_m01
t5_hc2:	TB5_HEAD r5, t5_m02
t5_hc3:	TB5_HEAD r5, t5_m03
t5_hc4:	TB5_HEAD r5, t5_m04
t5_hc5:	TB5_HEAD r5, t5_m05
t5_hc6:	TB5_HEAD r5, t5_m06
t5_hc7:	TB5_HEAD r5, t5_m07
t5_hc8:	TB5_HEAD r5, t5_m08
t5_hc9:	TB5_HEAD r5, t5_m09
t5_hca:	TB5_HEAD r5, t5_m0a
t5_hcb:	TB5_HEAD r5, t5_m0b
t5_hcc:	TB5_HEAD r5, t5_m0c
t5_hcd:	TB5_HEAD r5, t5_m0d
t5_hce:	TB5_HEAD r5, t5_m0e
t5_hcf:	TB5_HEAD r5, t5_m0f
t5_hd0:	TB5_HEAD r5, t5_m10
t5_hd1:	TB5_HEAD r5, t5_m11
t5_hd2:	TB5_HEAD r5, t5_m12
t5_hd3:	TB5_HEAD r5, t5_m13
t5_hd4:	TB5_HEAD r5, t5_m14
t5_hd5:	TB5_HEAD r5, t5_m15
t5_hd6:	TB5_HEAD r5, t5_m16
t5_hd7:	TB5_HEAD r5, t5_m17
t5_hd8:	TB5_HEAD r5, t5_m18
t5_hd9:	TB5_HEAD r5, t5_m19
t5_hda:	TB5_HEAD r5, t5_m1a
t5_hdb:	TB5_HEAD r5, t5_m1b
t5_hdc:	TB5_HEAD r5, t5_m1c
t5_hdd:	TB5_HEAD r5, t5_m1d
t5_hde:	TB5_HEAD r5, t5_m1e
t5_hdf:	TB5_HEAD r5, t5_m1f
t5_he0:	TB5_HEAD r5, t5_m20
t5_he1:	TB5_HEAD r5, t5_m21
t5_he2:	TB5_HEAD r5, t5_m22
t5_he3:	TB5_HEAD r5, t5_m23
t5_he4:	TB5_HEAD r5, t5_m24
t5_he5:	TB5_HEAD r5, t5_m25
t5_he6:	TB5_HEAD r5, t5_m26
t5_he7:	TB5_HEAD r5, t5_m27
t5_he8:	TB5_HEAD r5, t5_m28
t5_he9:	TB5_HEAD r5, t5_m29
t5_hea:	TB5_HEAD r5, t5_m2a
t5_heb:	TB5_HEAD r5, t5_m2b
t5_hec:	TB5_HEAD r5, t5_m2c
t5_hed:	TB5_HEAD r5, t5_m2d
t5_hee:	TB5_HEAD r5, t5_m2e
t5_hef:	TB5_HEAD r5, t5_m2f
t5_hf0:	TB5_HEAD r5, t5_m30
t5_hf1:	TB5_HEAD r5, t5_m31
t5_hf2:	TB5_HEAD r5, t5_m32
t5_hf3:	TB5_HEAD r5, t5_m33
t5_hf4:	TB5_HEAD r5, t5_m34
t5_hf5:	TB5_HEAD r5, t5_m35
t5_hf6:	TB5_HEAD r5, t5_m36
t5_hf7:	TB5_HEAD r5, t5_m37
t5_hf8:	TB5_HEAD r5, t5_m38
t5_hf9:	TB5_HEAD r5, t5_m39
t5_hfa:	TB5_HEAD r5, t5_m3a
t5_hfb:	TB5_HEAD r5, t5_m3b
t5_hfc:	TB5_HEAD r5, t5_m3c
t5_hfd:	TB5_HEAD r5, t5_m3d
t5_hfe:	TB5_HEAD r5, t5_m3e
t5_hff:	TB5_HEAD r5, t5_m3f

t5_m00:	TB5_MIDL r2, r2, r2, t5_t0
t5_m10:	TB5_MIDL r3, r2, r2, t5_t0
t5_m20:	TB5_MIDL r4, r2, r2, t5_t0
t5_m30:	TB5_MIDL r5, r2, r2, t5_t0
t5_t0:	TB5_TAIL r2, r2
t5_m01:	TB5_MIDL r2, r2, r3, t5_t1
t5_m11:	TB5_MIDL r3, r2, r3, t5_t1
t5_m21:	TB5_MIDL r4, r2, r3, t5_t1
t5_m31:	TB5_MIDL r5, r2, r3, t5_t1
t5_t1:	TB5_TAIL r2, r3
t5_m02:	TB5_MIDL r2, r2, r4, t5_t2
t5_m12:	TB5_MIDL r3, r2, r4, t5_t2
t5_m22:	TB5_MIDL r4, r2, r4, t5_t2
t5_m32:	TB5_MIDL r5, r2, r4, t5_t2
t5_t2:	TB5_TAIL r2, r4
t5_m03:	TB5_MIDL r2, r2, r5, t5_t3
t5_m13:	TB5_MIDL r3, r2, r5, t5_t3
t5_m23:	TB5_MIDL r4, r2, r5, t5_t3
t5_m33:	TB5_MIDL r5, r2, r5, t5_t3
t5_t3:	TB5_TAIL r2, r5
t5_m04:	TB5_MIDL r2, r3, r2, t5_t4
t5_m14:	TB5_MIDL r3, r3, r2, t5_t4
t5_m24:	TB5_MIDL r4, r3, r2, t5_t4
t5_m34:	TB5_MIDL r5, r3, r2, t5_t4
t5_t4:	TB5_TAIL r3, r2
t5_m05:	TB5_MIDL r2, r3, r3, t5_t5
t5_m15:	TB5_MIDL r3, r3, r3, t5_t5
t5_m25:	TB5_MIDL r4, r3, r3, t5_t5
t5_m35:	TB5_MIDL r5, r3, r3, t5_t5
t5_t5:	TB5_TAIL r3, r3
t5_m06:	TB5_MIDL r2, r3, r4, t5_t6
t5_m16:	TB5_MIDL r3, r3, r4, t5_t6
t5_m26:	TB5_MIDL r4, r3, r4, t5_t6
t5_m36:	TB5_MIDL r5, r3, r4, t5_t6
t5_t6:	TB5_TAIL r3, r4
t5_m07:	TB5_MIDL r2, r3, r5, t5_t7
t5_m17:	TB5_MIDL r3, r3, r5, t5_t7
t5_m27:	TB5_MIDL r4, r3, r5, t5_t7
t5_m37:	TB5_MIDL r5, r3, r5, t5_t7
t5_t7:	TB5_TAIL r3, r5
t5_m08:	TB5_MIDL r2, r4, r2, t5_t8
t5_m18:	TB5_MIDL r3, r4, r2, t5_t8
t5_m28:	TB5_MIDL r4, r4, r2, t5_t8
t5_m38:	TB5_MIDL r5, r4, r2, t5_t8
t5_t8:	TB5_TAIL r4, r2
t5_m09:	TB5_MIDL r2, r4, r3, t5_t9
t5_m19:	TB5_MIDL r3, r4, r3, t5_t9
t5_m29:	TB5_MIDL r4, r4, r3, t5_t9
t5_m39:	TB5_MIDL r5, r4, r3, t5_t9
t5_t9:	TB5_TAIL r4, r3
t5_m0a:	TB5_MIDL r2, r4, r4, t5_ta
t5_m1a:	TB5_MIDL r3, r4, r4, t5_ta
t5_m2a:	TB5_MIDL r4, r4, r4, t5_ta
t5_m3a:	TB5_MIDL r5, r4, r4, t5_ta
t5_ta:	TB5_TAIL r4, r4
t5_m0b:	TB5_MIDL r2, r4, r5, t5_tb
t5_m1b:	TB5_MIDL r3, r4, r5, t5_tb
t5_m2b:	TB5_MIDL r4, r4, r5, t5_tb
t5_m3b:	TB5_MIDL r5, r4, r5, t5_tb
t5_tb:	TB5_TAIL r4, r5
t5_m0c:	TB5_MIDL r2, r5, r2, t5_tc
t5_m1c:	TB5_MIDL r3, r5, r2, t5_tc
t5_m2c:	TB5_MIDL r4, r5, r2, t5_tc
t5_m3c:	TB5_MIDL r5, r5, r2, t5_tc
t5_tc:	TB5_TAIL r5, r2
t5_m0d:	TB5_MIDL r2, r5, r3, t5_td
t5_m1d:	TB5_MIDL r3, r5, r3, t5_td
t5_m2d:	TB5_MIDL r4, r5, r3, t5_td
t5_m3d:	TB5_MIDL r5, r5, r3, t5_td
t5_td:	TB5_TAIL r5, r3
t5_m0e:	TB5_MIDL r2, r5, r4, t5_te
t5_m1e:	TB5_MIDL r3, r5, r4, t5_te
t5_m2e:	TB5_MIDL r4, r5, r4, t5_te
t5_m3e:	TB5_MIDL r5, r5, r4, t5_te
t5_te:	TB5_TAIL r5, r4
t5_m0f:	TB5_MIDL r2, r5, r5, t5_tf
t5_m1f:	TB5_MIDL r3, r5, r5, t5_tf
t5_m2f:	TB5_MIDL r4, r5, r5, t5_tf
t5_m3f:	TB5_MIDL r5, r5, r5, t5_tf
t5_tf:	TB5_TAIL r5, r5

#endif
