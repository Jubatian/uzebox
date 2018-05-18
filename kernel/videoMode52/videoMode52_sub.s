;
; Uzebox Kernel - Video Mode 52 renderer sub
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



.section .text



sub_video_mode52:

;
; Entry happens in cycle 467.
;



;
; Check for display enable
;
; If no display, then just consume the configured height without any of
; Mode 52's features
;
	lds   r19,     m52_config     ; ( 469)
	sbrs  r19,     0       ; ( 470 /  471)
	rjmp  ddis             ; ( 472) Display disabled



;
; Initialize scanline counters
; (m52_config is loaded into r19)
;
; Cycles: 10
; Ends:   1461
;
	clr   r16              ; ( 1) Scanline counter
	lds   ZL,      m52_rowsel_p + 0 ; ( 3)
	lds   ZH,      m52_rowsel_p + 1 ; ( 5)
	; Load the first value to get the initial scanline.
	ld    r17,     Z+      ; ( 7) Load first logical row counter
	rjmp  .                ; ( 9)
	movw  r14,     ZL      ; (10)



;
; Get RAM tiles base & prepare zero register
;
; Cycles:
; Ends:
;
	lds   r21,     m52_ramt_base
	clr   r13



;
; Prepare for Timer 1 use in the scanline loop for line termination
;
; Cycles:
; Ends:
;
	ldi   r24,     (1 << OCF1B) + (1 << OCF1A) + (1 << TOV1)
	sts   _SFR_MEM_ADDR(TIFR1), r24  ; Clear any pending timer int

	ldi   r24,     (0 << WGM12) + (1 << CS10)
	sts   _SFR_MEM_ADDR(TCCR1B), r24 ; Switch to timer1 normal mode (mode 0)

	ldi   r24,     (1 << TOIE1)
	sts   _SFR_MEM_ADDR(TIMSK1), r24 ; Enable Overflow interrupt



;
; Frame render loop
;
; Sandwiched between waits so it is simpler to shift it a bit around
; when tweaking the scanline loop.
;

#if   (M52_TILES_MAX_H == 36)
	M52WT_R24      (1260)
#elif (M52_TILES_MAX_H == 34)
	M52WT_R24      (1260 - 40)
#else
	M52WT_R24      (1260 - 80)
#endif
	rjmp  m52_scloop
m52_scloopr:
#if   (M52_TILES_MAX_H == 36)
	M52WT_R24      (47)    ; (1809)
#elif (M52_TILES_MAX_H == 34)
	M52WT_R24      (47 + 40)
#else
	M52WT_R24      (47 + 80)
#endif




;
; Frame lead-out
;

	; Update the sync_pulse variable which was neglected during the loop
	; In r16 the scanline counter now equals render_lines_count, ready to
	; be subtracted.

	lds   r0,      sync_pulse ; (1811)
	sub   r0,      r16     ; (1812)
	sts   sync_pulse, r0   ; (1814)

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



;
; Finalize, restoring stack as necessary
;
; (Not in cycle-synced part any more)
;

#if (M52_RESET_ENABLE != 0)
	lds   r24,     m52_reset + 0
	lds   r25,     m52_reset + 1
	mov   r1,      r24
	or    r1,      r25
	brne  lares            ; Zero: No reset, perform a normal return
#endif
	ret
#if (M52_RESET_ENABLE != 0)
lares:
	ldi   r22,     lo8(M52_MAIN_STACK - 1) ; Set up main program stack
	ldi   r23,     hi8(M52_MAIN_STACK - 1)
	out   STACKL,  r22
	out   STACKH,  r23
	clr   r1               ; For C language routines, r1 is zero
	push  r24              ; Return address is the reset vector
	push  r25
	reti
#endif



;
; Display Disabled frame. It still consumes the height set up by the kernel as
; the kernel requires that for proper function.
;

ddis:

	M52WT_R24      1814 - 472
	clr   r16              ; (1815) Scanline counter
ddisl:
	lds   r23,     render_lines_count ; (1817)
	cp    r23,     r16     ; (1818)
	breq  ddise            ; (1819 / 1820)
	inc   r16              ; (1820)
	rcall hsync_pulse      ; (21 + AUDIO)
	M52WT_R24      1813 - 21 - AUDIO_OUT_HSYNC_CYCLES
	rjmp  ddisl            ; (1815)

ddise:
	rcall hsync_pulse      ; Last hsync, from now cycle precise part over.

	; Set vsync flag & flip field

	lds   ZL,      sync_flags
	ldi   r20,     SYNC_FLAG_FIELD
	eor   ZL,      r20
	ori   ZL,      SYNC_FLAG_VSYNC
	sts   sync_flags, ZL

	; Clear any pending timer interrupt

	ldi   ZL,      (1<<OCF1A)
	sts   _SFR_MEM_ADDR(TIFR1), ZL

	ret                    ; All done






;
; Waits the given amount of cycles, assuming calling with "rcall".
;
; This routine is used to reduce the size of the video mode, these waits
; taking only two words (ldi + rcall), yet having the same effect like the
; WAIT macro.
;
; r24: Number of cycles to wait - 11 (not including the "ldi r24, ...").
;      Must be at least 4.
;
m52_wait:
	lsr   r24
	brcs  .                ; +1 if bit0 was set
	lsr   r24
	brcs  .                ; +1 if bit1 was set
	brcs  .                ; +1 if bit1 was set
	dec   r24
	nop
	brne  .-6              ; 4 cycle loop
	ret

m52_wait_15:
	nop
m52_wait_14:
	nop
m52_wait_13:
	nop
m52_wait_12:
	nop
m52_wait_11:
	nop
m52_wait_10:
	nop
m52_wait_9:
	nop
m52_wait_8:
	nop
m52_wait_7:
	ret
