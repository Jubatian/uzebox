/*
 *  Uzebox Kernel - Video Mode 52
 *  Copyright (C) 2018 Sandor Zsuga (Jubatian)
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

/**
 * ===========================================================================
 *
 * This file contains global defines for video mode 52
 *
 * ===========================================================================
 */

#pragma once

#define VMODE_ASM_SOURCE "videoMode52/videoMode52.s"
#define VMODE_C_SOURCE "videoMode52/videoMode52.c"
#define VMODE_C_PROTOTYPES "videoMode52/videoMode52.h"
#define VMODE_FUNC sub_video_mode52


/* Since the mode is quite configurable, the widths and heights set up here
** only matter for using the Uzebox kernel functions. So they can be pretty
** arbitrary (even larger than the actual display, to be accessed by
** scrolling) as long as Mode 52 can be set up to display them. */

#ifndef TILE_WIDTH
	#define TILE_WIDTH     8
#endif
#if     (TILE_WIDTH == 8)
	#ifndef VRAM_TILES_H
		#define VRAM_TILES_H   36
	#endif
	#ifndef SCREEN_TILES_H
		#define SCREEN_TILES_H 36
	#endif
#else
	#error "Invalid value for TILE_WIDTH. Supported value is 8."
#endif

#ifndef TILE_HEIGHT
	#define TILE_HEIGHT    8
#endif
#if     (TILE_HEIGHT != 8)
	#error "Invalid value for TILE_HEIGHT. Supported value is 8."
#endif

#ifndef VRAM_TILES_V
	#define VRAM_TILES_V   (224 / TILE_HEIGHT)
#endif

#ifndef SCREEN_TILES_V
	#define SCREEN_TILES_V (224 / TILE_HEIGHT)
#endif

#ifndef FRAME_LINES
	#define FRAME_LINES (SCREEN_TILES_V * TILE_HEIGHT)
#endif

#ifndef FIRST_RENDER_LINE
	#define FIRST_RENDER_LINE 20 + ((224 - FRAME_LINES) / 2)
#endif

#define VRAM_SIZE       (VRAM_TILES_H * VRAM_TILES_V)
#define VRAM_ADDR_SIZE  1
#define VRAM_PTR_TYPE   u8

#ifndef SPRITES_ENABLED
	#define SPRITES_ENABLED 0
#endif



/* Notes: Don't use 'U' suffixes for the defines since they are used in
** assembler sources where the assembler doesn't understand them. */



/* Use Named Address Spaces if enabled. Otherwise pgmspace.h is used. This
** doesn't have a significant impact as normally you would use the
** M52_ROMTILESET macro for defining ROM tilesets */
#ifndef M52_USE_NAS
	#define M52_USE_NAS        0
#endif



/* Set maximal row width in tiles. A width of 36 tiles might crop the edges on
** some TV sets, you can ask for less to allow for a more complex inline
** mixer. */
#ifndef M52_TILES_MAX_H
	#define M52_TILES_MAX_H    34
#endif
#if   (M52_TILES_MAX_H == 36)
	#define HSYNC_USABLE_CYCLES 172
#elif (M52_TILES_MAX_H == 34)
	#define HSYNC_USABLE_CYCLES 227
#elif (M52_TILES_MAX_H == 32)
	#define HSYNC_USABLE_CYCLES 267
#else
	#error "Invalid value for M52_TILES_MAX_H. Supported are 32, 34 and 36"
#endif



/* You can put the 128 byte Row Descriptor Array at a fixed location using the
** following definition. Normally it is allocated by the linker. You might for
** example locate it at 0x1000, below the stack if you know your game doesn't
** use too much stack, which frees up RAM potentially useful for RAM tiles
** (which are below 0x1000). */
#ifndef M52_ROWDESC_ADDR
	#define M52_ROWDESC_ADDR   0
#endif



/* Reset on every frame. If this is enabled, then a video frame will reset
** onto a provided address (can be a C function with void parameters and
** return), saving a lot of memory (240 bytes) from stack, using the palette
** buffer for main program stack. However this also means that the main
** program might not complete (ideally onto a "do-nothing" empty loop) before
** the VBlank is over. You need to set m52_reset to an appropriate address
** before enabling display (if display is disabled, the reset mechanism is
** inactive). After enabling display from the initializing code, an empty
** loop should be provided so the video frame will reset onto the provided
** code. Enabling changes a few defaults to make space for the stack assuming
** default configuration (if you change stack locations, you need to also set
** up those proper).
**
** The main program stack: The definition gives the top of the stack (so first
** used stack position is the definition - 1). */

#ifndef M52_RESET_ENABLE
	#define M52_RESET_ENABLE   0
#endif
#ifndef M52_MAIN_STACK
	#define M52_MAIN_STACK     0x1100
#endif



/* Attribute modes can be enabled with these. Color 0 and Color 1 attributes
** take 2 Kbytes ROM space each, Color 1,2,3 attributes take 6 Kbytes. */
#ifndef M52_ENABLE_ATTR0
	#define M52_ENABLE_ATTR0   0
#endif
#ifndef M52_ENABLE_ATTR123
	#define M52_ENABLE_ATTR123 0
#endif
#ifndef M52_ENABLE_ATTR23M
	#define M52_ENABLE_ATTR23M 0
#endif



/* The followings belong to the sprite system. The sprite system should only
** be enabled if it is actually used (takes a considerable amount of flash),
** then the necessary components have to be defined. */

#ifndef M52_SPR_ENABLE
	#define M52_SPR_ENABLE     SPRITES_ENABLED
#endif



/* Enable the masking system. Masks allow sprites to show behind tiles, using
** 1bpp data. Masking costs 1 extra byte for each tile for holding indices
** into a mask table. It also takes some flash and extra CPU time. */

#ifndef M52_MSK_ENABLE
	#define M52_MSK_ENABLE     0
#endif

/* ROM mask index base. The ROM has 2048 tile slots, this list may have at
** most that many bytes. It doesn't need to be aligned to any boundary.
** Typically tile assets are packed together in the ROM taking one
** continuous region: this base offset may be forged so the first used
** location belongs to the first sprite. Example: If tiles begin at 0x8000,
** for 256 tiles, and you want to have the mask indices for them at 0xA000,
** 256 bytes, the base should be set up as (0xA000 - (0x8000 / 32)). */

#ifndef M52_ROMMASKIDX_OFF
	#if ((M52_SPR_ENABLE != 0) && (M52_MSK_ENABLE != 0))
		#error "A ROM mask index base (M52_ROMMASKIDX_OFF) has to be defined for the sprite system!"
	#endif
#endif

/* RAM mask index base. 1 byte is taken for each RAM tile available for the
** sprite engine. This is used to make it unnecessary to always look up mask
** indices by the background VRAM (in SPI RAM). It can be located under the
** palette buffer (as long as renders finish in one VBlank; as it is only
** needed for sprite rendering). */

#ifndef M52_RAMMASKIDX_OFF
	#define M52_RAMMASKIDX_OFF 0x1020
#endif

/* ROM mask pool's address. At most 256 x 8 bytes (depends on used masks).
** If no actual masks are used, this may be left zero. This has to be aligned
** at a 8 byte boundary. */

#ifndef M52_ROMMASK_OFF
	#define M52_ROMMASK_OFF    0
#endif
