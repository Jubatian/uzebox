;
; Uzebox Kernel - Video Mode 52 sprite blitter
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
; Note: No section specification here! (.section .text)
; This is because this component belongs to the sprite blitter
; (M52_BlitSprite), sitting in its section.
;



;
; Blits a sprite onto a 8x8 2bpp RAM tile
;
; Outputs the appropriate fraction of a sprite on a RAM tile. The sprite has
; fixed 8x8 pixel layout, 2 bytes per line, 16 bytes total, high bits first
; for pixels. Color index 0 is transparent. For 4+1 color sprites, a 3rd byte
; for each line contains the transparency mask (1: Sprite pixel,
; 0: Background), 24 bytes total.
;
; r25:r24: Source 8x8 sprite start address
;       Y: Target RAM tile address
;     r23: Y location on tile (2's complement; 0xF9 - 0x07)
;     r22: X location on tile (2's complement; 0xF9 - 0x07)
;     r16: Flags
;          bit0: If set, flip horizontally
;          bit1: If set, sprite source is RAM
;          bit2: If set, flip vertically
;          bit4: If set, mask is used
;          bit5: If set, 4 color sprite
;          bit7: If set, mask source is RAM
;      r1: Zero
; r15:r14: Mask source offset (8 bytes). Only used if r16 bit4 is set
; Clobbered registers:
; r0, r14, r15, r17, r18, r19, r20, r21, r22, r23, XL, XH, YL, YH, ZL, ZH, T
;
m52_blitspritept:

	; Save a few registers to have something to work with

	push  r24
	push  r25              ; Preserve source start address

	; Calculate target offset including mask (which belongs / aligns with
	; the target).

	bst   r23,     7       ; T: Set if Y location negative, clear otherwise
	brts  .+4              ; Y location positive (move down?)
	add   r14,     r23
	adc   r15,     r1      ; Set up mask source
	brts  .+8              ; Y location positive (move down?)
	mov   r0,      r23     ; If positive, calculate offset on target
	lsl   r0               ; Destination increment is 4 bytes / row
	lsl   r0
	add   YL,      r0

	; Calculate source offset and increment (A sprite line is 2 or 3 bytes)

	sbrs  r16,     2
	rjmp  spbs0            ; No vertical flipping
	sbrs  r16,     5
	rjmp  .+10
	ldi   XL,      0xFD    ; 4+1 color sprite: 3 bytes / line
	ldi   XH,      0xFF    ; Source decrements after each line
	subi  r24,     0xEB
	sbci  r25,     0xFF    ; Add 21, to start at the last line
	rjmp  .+8
	ldi   XL,      0xFE    ; 3+1 color sprite: 2 bytes / line
	ldi   XH,      0xFF    ; Source decrements after each line
	subi  r24,     0xF2
	sbci  r25,     0xFF    ; Add 14, to start at the last line
	brtc  spbs2            ; If Y location is positive (moving down), then OK
	mov   r21,     r23
	rjmp  spbs1            ; Subtract lines to skip (Y loc. negative!)
spbs0:
	sbrs  r16,     5
	rjmp  .+6
	ldi   XL,      0x03    ; 4+1 color sprite: 3 bytes / line
	ldi   XH,      0x00    ; Source increments after each line
	rjmp  .+4
	ldi   XL,      0x02    ; 3+1 color sprite: 2 bytes / line
	ldi   XH,      0x00    ; Source increments after each line
	brtc  spbs2            ; If Y location is positive (moving down), then OK
	mov   r21,     r23
	neg   r21              ; Add lines to skip
spbs1:
	sbrs  r16,     5
	rjmp  .+8
	mov   r20,     r21     ; 4+1 color sprite: 3 bytes / line
	lsl   r21
	add   r21,     r20
	rjmp  .+2
	lsl   r21              ; 3+1 color sprite: 2 bytes / line
	add   r24,     r21
	adc   r25,     XH      ; Source start address calculated OK
spbs2:

	; Calculate number of lines to output

	ldi   r20,     8       ; Normally 8 lines
	brts  .+4
	sub   r20,     r23     ; Positive Y location: subtract
	brtc  .+2
	add   r20,     r23     ; Negative Y location: add
	mov   r23,     r20

	; Calculate jump target by X alignment into r1:r0

	subi  r22,     0xF9    ; Add 7; 0xF9 - 0x07 becomes 0x00 - 0x0E
	ldi   r20,     lo8(pm(spljta))
	ldi   r21,     hi8(pm(spljta))
	sbrc  r16,     0       ; Flipped (X Mirrored)?
	subi  r22,     0xF1    ; Cheat: Add 15 to reach flipped jump table (spljtaf)
	sbrc  r16,     1       ; RAM source?
	subi  r22,     0xE2    ; Cheat: Add 30 to reach RAM jump table (spljtar)
	sbrc  r16,     5       ; 4+1 color?
	subi  r22,     0xC4    ; Cheat: Add 60 to reach RAM jump table (spljtac)
	add   r20,     r22
	adc   r21,     r1
	movw  r0,      r20     ; From now r1 is not zero

	; Render the sprite part

	rjmp  spbl
spblret:
	dec   r23
	breq  spbex
	add   r24,     XL
	adc   r25,     XH      ; Source increment / decrement
	subi  YL,      0xFC    ; Destination increment
spbl:
	sbrc  r16,     4       ; Has mask?
	rjmp  spbml            ; Enter render loop with mask
	clr   r17              ; Use zero for mask
	movw  ZL,      r0      ; Load jump target
	ijmp
spbml:
	movw  ZL,      r14     ; Load mask offset
	sbrc  r16,     7
	rjmp  .+8
	lpm   r17,     Z+      ; ROM mask source
	movw  r14,     ZL      ; Save mask offset
	movw  ZL,      r0      ; Load jump target
	ijmp
	ld    r17,     Z+      ; RAM mask source
	movw  r14,     ZL      ; Save mask offset
	movw  ZL,      r0      ; Load jump target
	ijmp

	; Done, clean up and return

spbex:
	pop   r25
	pop   r24
	clr   r1
	ret



;
; Blits a single 8px wide sprite line onto a tile
;
; Outputs a single 8 pixels wide sprite line from a source sprite line onto a
; target 2bpp tile line. Number of pixels generated depends on the alignment.
;
; r24:r25: Source start address. Preserved.
; Y:       Destination start address. Preserved.
; r17:     Mask: set bits inhibit sprite pixel output.
; Clobbered registers:
; r17, r18, r19, r20, r21, ZL, ZH
;
spljta:
	rjmp  splr7            ; S0000000 ROM Normal 3+1 color sprite
	rjmp  splr6            ; SS000000
	rjmp  splr5            ; SSS00000
	rjmp  splr4            ; SSSS0000
	rjmp  splr3            ; SSSSS000
	rjmp  splr2            ; SSSSSS00
	rjmp  splr1            ; SSSSSSS0
	rjmp  spla0            ; SSSSSSSS
	rjmp  spll1            ; 0SSSSSSS
	rjmp  spll2            ; 00SSSSSS
	rjmp  spll3            ; 000SSSSS
	rjmp  spll4            ; 0000SSSS
	rjmp  spll5            ; 00000SSS
	rjmp  spll6            ; 000000SS
	rjmp  spll7            ; 0000000S
spljtaf:
	rjmp  splr7f           ; S0000000 ROM Mirrored 3+1 color sprite
	rjmp  splr6f           ; SS000000
	rjmp  splr5f           ; SSS00000
	rjmp  splr4f           ; SSSS0000
	rjmp  splr3f           ; SSSSS000
	rjmp  splr2f           ; SSSSSS00
	rjmp  splr1f           ; SSSSSSS0
	rjmp  spla0f           ; SSSSSSSS
	rjmp  spll1f           ; 0SSSSSSS
	rjmp  spll2f           ; 00SSSSSS
	rjmp  spll3f           ; 000SSSSS
	rjmp  spll4f           ; 0000SSSS
	rjmp  spll5f           ; 00000SSS
	rjmp  spll6f           ; 000000SS
	rjmp  spll7f           ; 0000000S
spljtar:
	rjmp  splr7r           ; S0000000 RAM Normal 3+1 color sprite
	rjmp  splr6r           ; SS000000
	rjmp  splr5r           ; SSS00000
	rjmp  splr4r           ; SSSS0000
	rjmp  splr3r           ; SSSSS000
	rjmp  splr2r           ; SSSSSS00
	rjmp  splr1r           ; SSSSSSS0
	rjmp  spla0r           ; SSSSSSSS
	rjmp  spll1r           ; 0SSSSSSS
	rjmp  spll2r           ; 00SSSSSS
	rjmp  spll3r           ; 000SSSSS
	rjmp  spll4r           ; 0000SSSS
	rjmp  spll5r           ; 00000SSS
	rjmp  spll6r           ; 000000SS
	rjmp  spll7r           ; 0000000S
spljtafr:
	rjmp  splr7fr          ; S0000000 RAM Mirrored 3+1 color sprite
	rjmp  splr6fr          ; SS000000
	rjmp  splr5fr          ; SSS00000
	rjmp  splr4fr          ; SSSS0000
	rjmp  splr3fr          ; SSSSS000
	rjmp  splr2fr          ; SSSSSS00
	rjmp  splr1fr          ; SSSSSSS0
	rjmp  spla0fr          ; SSSSSSSS
	rjmp  spll1fr          ; 0SSSSSSS
	rjmp  spll2fr          ; 00SSSSSS
	rjmp  spll3fr          ; 000SSSSS
	rjmp  spll4fr          ; 0000SSSS
	rjmp  spll5fr          ; 00000SSS
	rjmp  spll6fr          ; 000000SS
	rjmp  spll7fr          ; 0000000S
spljtac:
	rjmp  splr7c           ; S0000000 ROM Normal 4+1 color sprite
	rjmp  splr6c           ; SS000000
	rjmp  splr5c           ; SSS00000
	rjmp  splr4c           ; SSSS0000
	rjmp  splr3c           ; SSSSS000
	rjmp  splr2c           ; SSSSSS00
	rjmp  splr1c           ; SSSSSSS0
	rjmp  spla0c           ; SSSSSSSS
	rjmp  spll1c           ; 0SSSSSSS
	rjmp  spll2c           ; 00SSSSSS
	rjmp  spll3c           ; 000SSSSS
	rjmp  spll4c           ; 0000SSSS
	rjmp  spll5c           ; 00000SSS
	rjmp  spll6c           ; 000000SS
	rjmp  spll7c           ; 0000000S
spljtafc:
	rjmp  splr7fc          ; S0000000 ROM Mirrored 4+1 color sprite
	rjmp  splr6fc          ; SS000000
	rjmp  splr5fc          ; SSS00000
	rjmp  splr4fc          ; SSSS0000
	rjmp  splr3fc          ; SSSSS000
	rjmp  splr2fc          ; SSSSSS00
	rjmp  splr1fc          ; SSSSSSS0
	rjmp  spla0fc          ; SSSSSSSS
	rjmp  spll1fc          ; 0SSSSSSS
	rjmp  spll2fc          ; 00SSSSSS
	rjmp  spll3fc          ; 000SSSSS
	rjmp  spll4fc          ; 0000SSSS
	rjmp  spll5fc          ; 00000SSS
	rjmp  spll6fc          ; 000000SS
	rjmp  spll7fc          ; 0000000S
spljtarc:
	rjmp  splr7rc          ; S0000000 RAM Normal 4+1 color sprite
	rjmp  splr6rc          ; SS000000
	rjmp  splr5rc          ; SSS00000
	rjmp  splr4rc          ; SSSS0000
	rjmp  splr3rc          ; SSSSS000
	rjmp  splr2rc          ; SSSSSS00
	rjmp  splr1rc          ; SSSSSSS0
	rjmp  spla0rc          ; SSSSSSSS
	rjmp  spll1rc          ; 0SSSSSSS
	rjmp  spll2rc          ; 00SSSSSS
	rjmp  spll3rc          ; 000SSSSS
	rjmp  spll4rc          ; 0000SSSS
	rjmp  spll5rc          ; 00000SSS
	rjmp  spll6rc          ; 000000SS
	rjmp  spll7rc          ; 0000000S
spljtafrc:
	rjmp  splr7frc         ; S0000000 RAM Mirrored 4+1 color sprite
	rjmp  splr6frc         ; SS000000
	rjmp  splr5frc         ; SSS00000
	rjmp  splr4frc         ; SSSS0000
	rjmp  splr3frc         ; SSSSS000
	rjmp  splr2frc         ; SSSSSS00
	rjmp  splr1frc         ; SSSSSSS0
	rjmp  spla0frc         ; SSSSSSSS
	rjmp  spll1frc         ; 0SSSSSSS
	rjmp  spll2frc         ; 00SSSSSS
	rjmp  spll3frc         ; 000SSSSS
	rjmp  spll4frc         ; 0000SSSS
	rjmp  spll5frc         ; 00000SSS
	rjmp  spll6frc         ; 000000SS
	rjmp  spll7frc         ; 0000000S



	; S0000000

splr7:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r18,     Z+
	bst   r18,     0
	bld   r21,     6
	bst   r18,     1
	bld   r21,     7
	andi  r21,     0xC0

splr7comm:
	ldi   ZH,      hi8(sp_tmdec4)
	mov   ZL,      r21
	lpm   ZL,      Z
	swap  ZL
	rjmp  splpxl

splr7f:
	movw  ZL,      r24
	lpm   r21,     Z+
	andi  r21,     0xC0
	rjmp  splr7comm

splr7r:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r18,     Z+
	bst   r18,     0
	bld   r21,     6
	bst   r18,     1
	bld   r21,     7
	andi  r21,     0xC0
	rjmp  splr7comm

splr7fr:
	movw  ZL,      r24
	ld    r21,     Z+
	andi  r21,     0xC0
	rjmp  splr7comm

splr7c:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r18,     Z+
	lpm   ZL,      Z

splr7commc:
	bst   r18,     0
	bld   r21,     6
	bst   r18,     1
	bld   r21,     7
	bst   ZL,      0
	bld   ZL,      7
	andi  ZL,      0x80
	rjmp  splpxl

splr7fc:
	movw  ZL,      r24
	lpm   r21,     Z+
	adiw  Z,       1
	lpm   ZL,      Z
	andi  ZL,      0x80
	rjmp  splpxl

splr7rc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r18,     Z+
	ld    ZL,      Z
	rjmp  splr7commc

splr7frc:
	movw  ZL,      r24
	ld    r21,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	andi  ZL,      0x80
	rjmp  splpxl


	; SS000000

splr6:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	swap  r21
	andi  r21,     0xF0
	rjmp  splr7comm

splr6f:
	movw  ZL,      r24
	lpm   ZL,      Z
	swap  ZL
	andi  ZL,      0x0F
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	rjmp  splr7comm

splr6r:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	swap  r21
	andi  r21,     0xF0
	rjmp  splr7comm

splr6fr:
	movw  ZL,      r24
	ld    ZL,      Z
	swap  ZL
	andi  ZL,      0x0F
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	rjmp  splr7comm

splr6c:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	lpm   ZL,      Z

splr6commc:
	swap  r21
	swap  ZL
	lsl   ZL
	lsl   ZL
	andi  ZL,      0xC0
	rjmp  splpxl

splr6fc:
	movw  ZL,      r24
	lpm   r21,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

splr6commfc:
	bst   ZL,      7
	bld   r18,     6
	bst   ZL,      6
	bld   r18,     7
	mov   ZL,      r21
	swap  ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r18
	andi  ZL,      0xC0
	rjmp  splpxl

splr6rc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr6commc

splr6frc:
	movw  ZL,      r24
	ld    r21,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  splr6commfc


	; SSS00000

splr5:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	lsl   r21
	lsl   r21
	rjmp  splr7comm

splr5f:
	movw  ZL,      r24
	lpm   ZL,      Z
	lsr   ZL
	lsr   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	rjmp  splr7comm

splr5r:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	lsl   r21
	lsl   r21
	rjmp  splr7comm

splr5fr:
	movw  ZL,      r24
	ld    ZL,      Z
	lsr   ZL
	lsr   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	rjmp  splr7comm

splr5c:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	lpm   ZL,      Z

splr5commc:
	lsl   r21
	lsl   r21
	swap  ZL
	andi  ZL,      0xF0
	lsl   ZL
	rjmp  splpxl

splr5fc:
	movw  ZL,      r24
	lpm   r21,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

splr5commfc:
	bst   ZL,      7
	bld   r18,     5
	bst   ZL,      6
	bld   r18,     6
	bst   ZL,      5
	bld   r18,     7
	mov   ZL,      r21
	lsr   ZL
	lsr   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r18
	andi  ZL,      0xE0
	rjmp  splpxl

splr5rc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr5commc

splr5frc:
	movw  ZL,      r24
	ld    r21,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  splr5commfc


	; SSSS0000

splr4:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	rjmp  splr7comm

splr4f:
	movw  ZL,      r24
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	rjmp  splr7comm

splr4r:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	rjmp  splr7comm

splr4fr:
	movw  ZL,      r24
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	ld    r21,     Z
	rjmp  splr7comm

splr4c:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r21,     Z+
	lpm   ZL,      Z

splr4commc:
	swap  ZL
	andi  ZL,      0xF0
	rjmp  splpxl

splr4fc:
	movw  ZL,      r24
	lpm   r21,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

splr4commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r18,     Z
	swap  r18
	andi  r18,     0xF0
	mov   ZL,      r21
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r18
	rjmp  splpxl

splr4rc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr4commc

splr4frc:
	movw  ZL,      r24
	ld    r21,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  splr4commfc


	; SSSSS000

splr3:
	movw  ZL,      r24
	lpm   r18,     Z+
	lpm   r21,     Z+
	rjmp  splr3comm

splr3f:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r18,     Z
	mov   ZL,      r21
	lpm   r21,     Z
	rjmp  splr3comm

splr3r:
	movw  ZL,      r24
	ld    r18,     Z+
	ld    r21,     Z+
	rjmp  splr3comm

splr3fr:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r18,     Z
	mov   ZL,      r21
	lpm   r21,     Z

splr3comm:
	ldi   r20,     0
	lsr   r18
	ror   r21
	ror   r20
	lsr   r18
	ror   r21
	ror   r20

splr3comma:
	ldi   ZH,      hi8(sp_tmdec4)
	mov   ZL,      r21
	lpm   r18,     Z
	swap  r18
	mov   ZL,      r20
	lpm   ZL,      Z
	or    ZL,      r18
	rjmp  splpxb

splr3c:
	movw  ZL,      r24
	lpm   r18,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z
	rjmp  splr3commc

splr3fc:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r18,     Z+
	lpm   ZL,      Z

splr3commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r18
	lpm   r18,     Z
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r19

splr3commc:
	ldi   r20,     0
	lsr   r18
	ror   r21
	ror   r20
	lsr   r18
	ror   r21
	ror   r20
	lsl   ZL
	lsl   ZL
	lsl   ZL
	rjmp  splpxb

splr3rc:
	movw  ZL,      r24
	ld    r18,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr3commc

splr3frc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r18,     Z+
	ld    ZL,      Z
	rjmp  splr3commfc


	; SSSSSS00

splr2:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	rjmp  splr2comm

splr2f:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  splr2comm

splr2r:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	rjmp  splr2comm

splr2fr:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z

splr2comm:
	swap  r21
	swap  r20
	mov   r18,     r20
	andi  r20,     0xF0
	andi  r21,     0xF0
	andi  r18,     0x0F
	or    r21,     r18
	rjmp  splr3comma

splr2c:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z
	rjmp  splr2commc

splr2fc:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z

splr2commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r19

splr2commc:
	swap  r21
	swap  r20
	mov   r18,     r20
	andi  r20,     0xF0
	andi  r21,     0xF0
	andi  r18,     0x0F
	or    r21,     r18
	lsl   ZL
	lsl   ZL
	rjmp  splpxb

splr2rc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  splr2commc

splr2frc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr2commfc


	; SSSSSSS0

splr1:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	rjmp  splr1comm

splr1f:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  splr1comm

splr1r:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	rjmp  splr1comm

splr1fr:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z

splr1comm:
	lsl   r20
	rol   r21
	lsl   r20
	rol   r21
	rjmp  splr3comma

splr1c:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z
	rjmp  splr1commc

splr1fc:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z

splr1commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r19

splr1commc:
	lsl   r20
	rol   r21
	lsl   r20
	rol   r21
	lsl   ZL
	rjmp  splpxb

splr1rc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  splr1commc

splr1frc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  splr1commfc


	; SSSSSSSS

spla0:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	rjmp  splr3comma

spla0f:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  splr3comma

spla0r:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	rjmp  splr3comma

spla0fr:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  splr3comma

spla0c:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z
	rjmp  splpxb

spla0fc:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z

spla0commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r19
	rjmp  splpxb

spla0rc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  splpxb

spla0frc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  spla0commfc


	; 0SSSSSSS

spll1:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	rjmp  spll1comm

spll1f:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  spll1comm

spll1r:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	rjmp  spll1comm

spll1fr:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z

spll1comm:
	lsr   r21
	ror   r20
	lsr   r21
	ror   r20
	rjmp  splr3comma

spll1c:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z
	rjmp  spll1commc

spll1fc:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z

spll1commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r19

spll1commc:
	lsr   r21
	ror   r20
	lsr   r21
	ror   r20
	lsr   ZL
	rjmp  splpxb

spll1rc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll1commc

spll1frc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  spll1commfc


	; 00SSSSSS

spll2:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	rjmp  spll2comm

spll2f:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	rjmp  spll2comm

spll2r:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	rjmp  spll2comm

spll2fr:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z

spll2comm:
	swap  r21
	swap  r20
	mov   r18,     r21
	andi  r20,     0x0F
	andi  r21,     0x0F
	andi  r18,     0xF0
	or    r20,     r18
	rjmp  splr3comma

spll2c:
	movw  ZL,      r24
	lpm   r21,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z
	rjmp  spll2commc

spll2fc:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   ZL,      Z

spll2commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r21
	lpm   r21,     Z
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r19

spll2commc:
	swap  r21
	swap  r20
	mov   r18,     r21
	andi  r20,     0x0F
	andi  r21,     0x0F
	andi  r18,     0xF0
	or    r20,     r18
	lsr   ZL
	lsr   ZL
	rjmp  splpxb

spll2rc:
	movw  ZL,      r24
	ld    r21,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll2commc

spll2frc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r21,     Z+
	ld    ZL,      Z
	rjmp  spll2commfc


	; 000SSSSS

spll3:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r18,     Z+
	rjmp  spll3comm

spll3f:
	movw  ZL,      r24
	lpm   r18,     Z+
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r18
	lpm   r18,     Z
	rjmp  spll3comm

spll3r:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r18,     Z+
	rjmp  spll3comm

spll3fr:
	movw  ZL,      r24
	ld    r18,     Z+
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r21,     Z
	mov   ZL,      r18
	lpm   r18,     Z

spll3comm:
	ldi   r21,     0
	lsl   r18
	rol   r20
	rol   r21
	lsl   r18
	rol   r20
	rol   r21
	ldi   ZH,      hi8(sp_tmdec4)
	mov   ZL,      r21
	lpm   r18,     Z
	swap  r18
	mov   ZL,      r20
	lpm   ZL,      Z
	or    ZL,      r18
	rjmp  splpxb

spll3c:
	movw  ZL,      r24
	lpm   r20,     Z+
	lpm   r18,     Z+
	lpm   ZL,      Z
	rjmp  spll3commc

spll3fc:
	movw  ZL,      r24
	lpm   r18,     Z+
	lpm   r20,     Z+
	lpm   ZL,      Z

spll3commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r19,     Z
	ldi   ZH,      hi8(sp_fl2bpp)
	mov   ZL,      r20
	lpm   r20,     Z
	mov   ZL,      r18
	lpm   r18,     Z
	mov   ZL,      r19

spll3commc:
	ldi   r21,     0
	lsl   r18
	rol   r20
	rol   r21
	lsl   r18
	rol   r20
	rol   r21
	lsr   ZL
	lsr   ZL
	lsr   ZL
	rjmp  splpxb

spll3rc:
	movw  ZL,      r24
	ld    r20,     Z+
	ld    r18,     Z+
	ld    ZL,      Z
	rjmp  spll3commc

spll3frc:
	movw  ZL,      r24
	ld    r18,     Z+
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll3commfc


	; 0000SSSS

spll4:
	movw  ZL,      r24
	lpm   r20,     Z+
	rjmp  spll7comm

spll4f:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	rjmp  spll7comm

spll4r:
	movw  ZL,      r24
	ld    r20,     Z+
	rjmp  spll7comm

spll4fr:
	movw  ZL,      r24
	adiw  Z,       1
	ld    ZL,      Z
	ldi   ZH,      hi8(sp_fl2bpp)
	ld    r20,     Z
	rjmp  spll7comm

spll4c:
	movw  ZL,      r24
	lpm   r20,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

spll4commc:
	swap  ZL
	andi  ZL,      0x0F
	rjmp  splpxr

spll4fc:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r20,     Z+
	lpm   ZL,      Z

spll4commfc:
	ldi   ZH,      hi8(sp_fl1bpp)
	lpm   r18,     Z
	swap  r18
	andi  r18,     0x0F
	mov   ZL,      r20
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	mov   ZL,      r18
	rjmp  splpxr

spll4rc:
	movw  ZL,      r24
	ld    r20,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  spll4commc

spll4frc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll4commfc


	; 00000SSS

spll5:
	movw  ZL,      r24
	lpm   r20,     Z+
	lsr   r20
	lsr   r20
	rjmp  spll7comm

spll5f:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   ZL,      Z
	lsl   ZL
	lsl   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	rjmp  spll7comm

spll5r:
	movw  ZL,      r24
	ld    r20,     Z+
	lsr   r20
	lsr   r20
	rjmp  spll7comm

spll5fr:
	movw  ZL,      r24
	adiw  Z,       1
	ld    ZL,      Z
	lsl   ZL
	lsl   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	rjmp  spll7comm

spll5c:
	movw  ZL,      r24
	lpm   r20,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

spll5commc:
	lsr   r21
	lsr   r21
	swap  ZL
	andi  ZL,      0x0F
	lsr   ZL
	rjmp  splpxr

spll5fc:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r20,     Z+
	lpm   ZL,      Z

spll5commfc:
	bst   ZL,      0
	bld   r18,     2
	bst   ZL,      1
	bld   r18,     1
	bst   ZL,      2
	bld   r18,     0
	mov   ZL,      r20
	lsl   ZL
	lsl   ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	mov   ZL,      r18
	andi  ZL,      0x07
	rjmp  splpxr

spll5rc:
	movw  ZL,      r24
	ld    r20,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  spll5commc

spll5frc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll5commfc


	; 000000SS

spll6:
	movw  ZL,      r24
	lpm   r20,     Z+
	swap  r20
	andi  r20,     0x0F
	rjmp  spll7comm

spll6f:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   ZL,      Z
	swap  ZL
	andi  ZL,      0xF0
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	rjmp  spll7comm

spll6r:
	movw  ZL,      r24
	ld    r20,     Z+
	swap  r20
	andi  r20,     0x0F
	rjmp  spll7comm

spll6fr:
	movw  ZL,      r24
	adiw  Z,       1
	ld    ZL,      Z
	swap  ZL
	andi  ZL,      0xF0
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	rjmp  spll7comm

spll6c:
	movw  ZL,      r24
	lpm   r20,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

spll6commc:
	swap  r21
	swap  ZL
	lsr   ZL
	lsr   ZL
	andi  ZL,      0x03
	rjmp  splpxr

spll6fc:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r20,     Z+
	lpm   ZL,      Z

spll6commfc:
	bst   ZL,      0
	bld   r18,     1
	bst   ZL,      1
	bld   r18,     0
	mov   ZL,      r20
	swap  ZL
	ldi   ZH,      hi8(sp_fl2bpp)
	lpm   r20,     Z
	mov   ZL,      r18
	andi  ZL,      0x03
	rjmp  splpxr

spll6rc:
	movw  ZL,      r24
	ld    r20,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  spll6commc

spll6frc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r20,     Z+
	ld    ZL,      Z
	rjmp  spll6commfc


	; 0000000S

spll7:
	movw  ZL,      r24
	lpm   r18,     Z+
	bst   r18,     6
	bld   r20,     0
	bst   r18,     7
	bld   r20,     1
	andi  r20,     0x03

spll7comm:
	ldi   ZH,      hi8(sp_tmdec4)
	mov   ZL,      r20
	lpm   ZL,      Z
	rjmp  splpxr

spll7f:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r20,     Z+
	andi  r20,     0x03
	rjmp  spll7comm

spll7r:
	movw  ZL,      r24
	ld    r18,     Z+
	bst   r18,     6
	bld   r20,     0
	bst   r18,     7
	bld   r20,     1
	andi  r20,     0x03
	rjmp  spll7comm

spll7fr:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r21,     Z+
	andi  r21,     0x03
	rjmp  spll7comm

spll7c:
	movw  ZL,      r24
	lpm   r18,     Z+
	adiw  Z,       1
	lpm   ZL,      Z

spll7commc:
	bst   r18,     6
	bld   r20,     0
	bst   r18,     7
	bld   r20,     1
	bst   ZL,      7
	bld   ZL,      0
	andi  ZL,      0x01
	rjmp  splpxr

spll7fc:
	movw  ZL,      r24
	adiw  Z,       1
	lpm   r20,     Z+
	lpm   ZL,      Z
	andi  ZL,      0x01
	rjmp  splpxr

spll7rc:
	movw  ZL,      r24
	ld    r18,     Z+
	adiw  Z,       1
	ld    ZL,      Z
	rjmp  spll7commc

spll7frc:
	movw  ZL,      r24
	adiw  Z,       1
	ld    r20,     Z+
	ld    ZL,      Z
	andi  ZL,      0x01
	rjmp  splpxr



; Common pixel output for Left half only

splpxl:

	; Apply mask source

	com   r17
	and   ZL,      r17

	; Merge onto the RAM tile

	ldi   ZH,      hi8(sp_1to2hi)

	ldd   r18,     Y + 0   ; Pixels 7-6-5-4
	lpm   r19,     Z
	and   r21,     r19     ; Mask source pixels
	com   r19
	and   r18,     r19     ; Mask destination pixels
	or    r18,     r20
	std   Y + 0,   r18

	rjmp  spblret


; Common pixel output for both halves

splpxb:

	; Apply mask source

	com   r17
	and   ZL,      r17

	; Merge onto the RAM tile

	ldi   ZH,      hi8(sp_1to2hi)

	ldd   r18,     Y + 0   ; Pixels 7-6-5-4
	lpm   r19,     Z
	and   r21,     r19     ; Mask source pixels
	com   r19
	and   r18,     r19     ; Mask destination pixels
	or    r18,     r20
	std   Y + 0,   r18

	swap  ZL

	ldd   r18,     Y + 1   ; Pixels 3-2-1-0
	lpm   r19,     Z
	and   r20,     r19     ; Mask source pixels
	com   r19
	and   r18,     r19     ; Mask destination pixels
	or    r18,     r21
	std   Y + 1,   r18

	rjmp  spblret


; Common pixel output for Right half only

splpxr:

	; Apply mask source

	com   r17
	and   ZL,      r17

	; Merge onto the RAM tile

	ldi   ZH,      hi8(sp_1to2hi)
	swap  ZL

	ldd   r18,     Y + 1   ; Pixels 3-2-1-0
	lpm   r19,     Z
	and   r20,     r19     ; Mask source pixels
	com   r19
	and   r18,     r19     ; Mask destination pixels
	or    r18,     r21
	std   Y + 1,   r18

	rjmp  spblret
