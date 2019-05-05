/*
 *  Uzebox video mode 45 simple demo
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
*/

;
; This is an assembly source as it involves defining precise memory layouts,
; beyond the level C provides.
;
; By default:
; - M45_RAMTILES is set at 0x0900 to occupy the upper 2K of Uzebox's RAM
; - UZEBOX_STACK_TOP is set at 0x08FF to start below that.
;
; You can move UZEBOX_STACK_TOP lower to reserve more memory for direct
; layout, while defining appropriate external variables in the accompanying
; header to make them accessible from C.
;

#include "defines.h"


.section .text


; Exporting the RAM tile area

.global memory_ramtiles
.equ memory_ramtiles, 0x0900

; EGA palette

.global memory_pal
memory_pal:

	.byte  0x00, 0x80, 0x28, 0xA8
	.byte  0x05, 0x85, 0x15, 0xAD
	.byte  0x52, 0xD2, 0x7A, 0xFA
	.byte  0x57, 0xD7, 0x7F, 0xFF

; A display layout allowing 96 RAM tiles. Requires UZEBOX_STACK_TOP to be set
; to (0x0900 - 1280), leaving 768 bytes of RAM for the application.

.global memory_rowdesc
memory_rowdesc:

	.word 0x0900 +   0, 0x0900 +  40, memory_pal ; Row 0
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 +  80, 0x0900 + 120, memory_pal ; Row 1
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0A00 +   0, 0x0A00 +  40, memory_pal ; Row 2
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0A00 +  80, 0x0A00 + 120, memory_pal ; Row 3
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0B00 +   0, 0x0B00 +  40, memory_pal ; Row 4
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0B00 +  80, 0x0B00 + 120, memory_pal ; Row 5
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0C00 +   0, 0x0C00 +  40, memory_pal ; Row 6
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0C00 +  80, 0x0C00 + 120, memory_pal ; Row 7
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0D00 +   0, 0x0D00 +  40, memory_pal ; Row 8
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0D00 +  80, 0x0D00 + 120, memory_pal ; Row 9
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0E00 +   0, 0x0E00 +  40, memory_pal ; Row 10
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0E00 +  80, 0x0E00 + 120, memory_pal ; Row 11
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0F00 +   0, 0x0F00 +  40, memory_pal ; Row 12
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0F00 +  80, 0x0F00 + 120, memory_pal ; Row 13
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x1000 +   0, 0x1000 +  40, memory_pal ; Row 14
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x1000 +  80, 0x1000 + 120, memory_pal ; Row 15
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 -  40, 0x0900 -  80, memory_pal ; Row 16
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 120, 0x0900 - 160, memory_pal ; Row 17
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 200, 0x0900 - 240, memory_pal ; Row 18
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 280, 0x0900 - 320, memory_pal ; Row 19
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 360, 0x0900 - 400, memory_pal ; Row 20
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 440, 0x0900 - 480, memory_pal ; Row 21
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 520, 0x0900 - 560, memory_pal ; Row 22
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 600, 0x0900 - 640, memory_pal ; Row 23
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 680, 0x0900 - 720, memory_pal ; Row 24
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 760, 0x0900 - 800, memory_pal ; Row 25
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 840, 0x0900 - 880, memory_pal ; Row 26
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 - 920, 0x0900 - 960, memory_pal ; Row 27
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 -1000, 0x0900 -1040, memory_pal ; Row 28
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 -1080, 0x0900 -1120, memory_pal ; Row 29
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 -1160, 0x0900 -1200, memory_pal ; Row 30
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
	.word 0x0900 -1240, 0x0900 -1280, memory_pal ; Row 31
	.byte hi8(m40_ibm_ascii), M45_ROW_ATTR0 | M45_ROW_ROMPAL
