/*
 *  Lisunow Li-2 demo
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
*/

#include <stdbool.h>
#include <avr/io.h>
#include <stdlib.h>
#include <avr/pgmspace.h>
#include <uzebox.h>

#include "tilestop.h"
#include "tilesbot.h"
#include "tilesmsk.h"
#include "fontdata.h"
#include "planemap.h"



#define PLANE_X    5U
#define PLANE_Y    10U


#define CFG0_PLANE (M52_CFG0_NOATTR | M52_CFG0_COL0_RELOAD)
#define CFG1_PLANE (M52_CFG1_ROMT_0 | M52_CFG1_PAL_0 | M52_CFG1_WIDTH_36)

#define CFG0_EXT   (M52_CFG0_NOATTR | M52_CFG0_SPR_OFF)
#define CFG1_EXT   (M52_CFG1_ROMT_2 | M52_CFG1_PAL_1 | M52_CFG1_WIDTH_36)


static u8 imgrows[30][40];
static u8 extrows[ 2][37];


static const m52_rowdesc_t rows[32] PROGMEM = {
 { imgrows[ 0], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 1], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 2], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 3], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 4], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 5], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 6], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 7], CFG0_PLANE, CFG1_PLANE },

 { imgrows[ 8], CFG0_PLANE, CFG1_PLANE },
 { imgrows[ 9], CFG0_PLANE, CFG1_PLANE },
 { imgrows[10], CFG0_PLANE, CFG1_PLANE },
 { imgrows[11], CFG0_PLANE, CFG1_PLANE },
 { imgrows[12], CFG0_PLANE, CFG1_PLANE },
 { imgrows[13], CFG0_PLANE, CFG1_PLANE },
 { imgrows[14], CFG0_PLANE, CFG1_PLANE },
 { imgrows[15], CFG0_PLANE, CFG1_PLANE },

 { imgrows[16], CFG0_PLANE, CFG1_PLANE },
 { imgrows[17], CFG0_PLANE, CFG1_PLANE },
 { imgrows[18], CFG0_PLANE, CFG1_PLANE },
 { imgrows[19], CFG0_PLANE, CFG1_PLANE },
 { imgrows[20], CFG0_PLANE, CFG1_PLANE },
 { imgrows[21], CFG0_PLANE, CFG1_PLANE },
 { imgrows[22], CFG0_PLANE, CFG1_PLANE },
 { imgrows[23], CFG0_PLANE, CFG1_PLANE },

 { imgrows[24], CFG0_PLANE, CFG1_PLANE },
 { imgrows[25], CFG0_PLANE, CFG1_PLANE },
 { imgrows[26], CFG0_PLANE, CFG1_PLANE },
 { imgrows[27], CFG0_PLANE, CFG1_PLANE },
 { imgrows[28], CFG0_PLANE, CFG1_PLANE },
 { imgrows[29], CFG0_PLANE, CFG1_PLANE },
 { extrows[ 0], CFG0_EXT,   CFG1_EXT   },
 { extrows[ 1], CFG0_EXT,   CFG1_EXT   },
};

static u8 rowsel[8] = { 0U, 255U, 0U, 0U, 0U, 0U, 0U, 0U };

static u8 sprite_ws[80U * 3U];

static u8 color0[224];

static u8 ramtmaskidx[128];


/* Background (Sky and ground imitation) */

/* Color bits: B2-G3-R3 */
#define CSK0 ((1U << 6) | (0U << 3) | (0U))
#define CSK1 ((1U << 6) | (0U << 3) | (1U))
#define CSK2 ((1U << 6) | (0U << 3) | (2U))
#define CSK3 ((1U << 6) | (1U << 3) | (2U))
#define CSK4 ((1U << 6) | (1U << 3) | (3U))
#define CSK5 ((2U << 6) | (1U << 3) | (3U))
#define CSK6 ((2U << 6) | (2U << 3) | (3U))
#define CSK7 ((2U << 6) | (2U << 3) | (4U))
#define CSK8 ((2U << 6) | (3U << 3) | (4U))
#define CSK9 ((2U << 6) | (3U << 3) | (5U))
#define CGD9 ((1U << 6) | (4U << 3) | (4U))
#define CGD8 ((1U << 6) | (3U << 3) | (4U))
#define CGD7 ((1U << 6) | (3U << 3) | (3U))
#define CGD6 ((1U << 6) | (2U << 3) | (3U))
#define CGD5 ((0U << 6) | (2U << 3) | (3U))
#define CGD4 ((0U << 6) | (2U << 3) | (2U))
#define CGD3 ((0U << 6) | (1U << 3) | (2U))
#define CGD2 ((0U << 6) | (1U << 3) | (1U))
#define CGD1 ((0U << 6) | (0U << 3) | (1U))

static const u8 color0_data[200] PROGMEM = {
 CSK0, CSK0, CSK0, CSK0, CSK0, CSK0, CSK0, CSK0,
 CSK0, CSK0, CSK0, CSK1, CSK0, CSK1, CSK0, CSK1,
 CSK0, CSK1, CSK0, CSK1, CSK0, CSK1, CSK1, CSK1,
 CSK1, CSK1, CSK1, CSK1, CSK1, CSK2, CSK1, CSK2,
 CSK1, CSK2, CSK1, CSK2, CSK1, CSK2, CSK2, CSK2,
 CSK2, CSK2, CSK3, CSK2, CSK3, CSK2, CSK3, CSK2,
 CSK3, CSK2, CSK3, CSK3, CSK3, CSK4, CSK3, CSK4,
 CSK3, CSK4, CSK3, CSK4, CSK3, CSK4, CSK3, CSK4,
 CSK4, CSK4, CSK4, CSK4, CSK5, CSK4, CSK5, CSK4,
 CSK5, CSK4, CSK5, CSK5, CSK5, CSK5, CSK6, CSK5,
 CSK6, CSK6, CSK7, CSK6, CSK7, CSK7, CSK8, CSK7,
 CSK8, CSK9, CGD9, CGD8, CGD7, CGD6, CGD7, CGD6,
 CGD5, CGD6, CGD5, CGD6, CGD5, CGD5, CGD5, CGD4,
 CGD5, CGD4, CGD5, CGD4, CGD5, CGD4, CGD4, CGD4,
 CGD4, CGD4, CGD3, CGD4, CGD3, CGD4, CGD3, CGD4,
 CGD3, CGD4, CGD3, CGD4, CGD3, CGD4, CGD3, CGD3,
 CGD3, CGD3, CGD3, CGD3, CGD3, CGD3, CGD3, CGD3,
 CGD3, CGD2, CGD3, CGD2, CGD3, CGD2, CGD3, CGD2,
 CGD3, CGD2, CGD3, CGD2, CGD2, CGD2, CGD2, CGD2,
 CGD2, CGD2, CGD2, CGD2, CGD2, CGD2, CGD2, CGD1,
 CGD2, CGD1, CGD2, CGD1, CGD2, CGD1, CGD2, CGD1,
 CGD2, CGD1, CGD2, CGD1, CGD2, CGD1, CGD2, CGD1,
 CGD2, CGD1, CGD2, CGD1, CGD2, CGD1, CGD1, CGD1,
 CGD1, CGD1, CGD1, CGD1, CGD1, CGD1, CGD1, CGD1,
 CGD1, CGD1, CGD1, CGD1, CGD1, CGD1, CGD1, CGD1
};



/* Sine table */
static const unsigned char sine[] PROGMEM = {
 0x81U, 0x84U, 0x87U, 0x8AU, 0x8EU, 0x91U, 0x94U, 0x97U,
 0x9AU, 0x9DU, 0xA0U, 0xA3U, 0xA6U, 0xA9U, 0xACU, 0xAFU,
 0xB2U, 0xB5U, 0xB7U, 0xBAU, 0xBDU, 0xC0U, 0xC2U, 0xC5U,
 0xC8U, 0xCAU, 0xCDU, 0xCFU, 0xD2U, 0xD4U, 0xD6U, 0xD9U,
 0xDBU, 0xDDU, 0xDFU, 0xE1U, 0xE3U, 0xE5U, 0xE7U, 0xE9U,
 0xEAU, 0xECU, 0xEEU, 0xEFU, 0xF1U, 0xF2U, 0xF3U, 0xF5U,
 0xF6U, 0xF7U, 0xF8U, 0xF9U, 0xFAU, 0xFBU, 0xFCU, 0xFCU,
 0xFDU, 0xFDU, 0xFEU, 0xFEU, 0xFFU, 0xFFU, 0xFFU, 0xFFU,
 0xFFU, 0xFFU, 0xFFU, 0xFFU, 0xFEU, 0xFEU, 0xFDU, 0xFDU,
 0xFCU, 0xFCU, 0xFBU, 0xFAU, 0xF9U, 0xF8U, 0xF7U, 0xF6U,
 0xF5U, 0xF3U, 0xF2U, 0xF1U, 0xEFU, 0xEEU, 0xECU, 0xEAU,
 0xE9U, 0xE7U, 0xE5U, 0xE3U, 0xE1U, 0xDFU, 0xDDU, 0xDBU,
 0xD9U, 0xD6U, 0xD4U, 0xD2U, 0xCFU, 0xCDU, 0xCAU, 0xC8U,
 0xC5U, 0xC2U, 0xC0U, 0xBDU, 0xBAU, 0xB7U, 0xB5U, 0xB2U,
 0xAFU, 0xACU, 0xA9U, 0xA6U, 0xA3U, 0xA0U, 0x9DU, 0x9AU,
 0x97U, 0x94U, 0x91U, 0x8EU, 0x8AU, 0x87U, 0x84U, 0x81U,
 0x7FU, 0x7CU, 0x79U, 0x76U, 0x72U, 0x6FU, 0x6CU, 0x69U,
 0x66U, 0x63U, 0x60U, 0x5DU, 0x5AU, 0x57U, 0x54U, 0x51U,
 0x4EU, 0x4BU, 0x49U, 0x46U, 0x43U, 0x40U, 0x3EU, 0x3BU,
 0x38U, 0x36U, 0x33U, 0x31U, 0x2EU, 0x2CU, 0x2AU, 0x27U,
 0x25U, 0x23U, 0x21U, 0x1FU, 0x1DU, 0x1BU, 0x19U, 0x17U,
 0x16U, 0x14U, 0x12U, 0x11U, 0x0FU, 0x0EU, 0x0DU, 0x0BU,
 0x0AU, 0x09U, 0x08U, 0x07U, 0x06U, 0x05U, 0x04U, 0x04U,
 0x03U, 0x03U, 0x02U, 0x02U, 0x01U, 0x01U, 0x01U, 0x01U,
 0x01U, 0x01U, 0x01U, 0x01U, 0x02U, 0x02U, 0x03U, 0x03U,
 0x04U, 0x04U, 0x05U, 0x06U, 0x07U, 0x08U, 0x09U, 0x0AU,
 0x0BU, 0x0DU, 0x0EU, 0x0FU, 0x11U, 0x12U, 0x14U, 0x16U,
 0x17U, 0x19U, 0x1BU, 0x1DU, 0x1FU, 0x21U, 0x23U, 0x25U,
 0x27U, 0x2AU, 0x2CU, 0x2EU, 0x31U, 0x33U, 0x36U, 0x38U,
 0x3BU, 0x3EU, 0x40U, 0x43U, 0x46U, 0x49U, 0x4BU, 0x4EU,
 0x51U, 0x54U, 0x57U, 0x5AU, 0x5DU, 0x60U, 0x63U, 0x66U,
 0x69U, 0x6CU, 0x6FU, 0x72U, 0x76U, 0x79U, 0x7CU, 0x7FU
};
#define sintb(x) pgm_read_byte(&(sine[((x)      ) & 0xFFU]))
#define costb(x) pgm_read_byte(&(sine[((x) + 64U) & 0xFFU]))



/*
** Scrolling overlay text
*/
static const char ovr_text[] PROGMEM =
 "This is Lisunov Li-2 demo by Jubatian for the Uzebox console. "
 "Mode 52 is a 2 bits per pixel video mode allowing to use lots of "
 "low-color graphics and sprites as the tiles are small (16 bytes "
 "each). Lots of sprites, although not that many to make the plane "
 "itself a sprite! It is background, just like how the dragon was "
 "realized in Tanathos for the Commodore 64. Anyway, it looks "
 "good, its nice to keep trusty old hardware running... Enjoy!";



/*
** Sprite text
*/
static const char sprite_text[] PROGMEM =
 "                                                            "
 "The Lisunov Li-2 was a Russian license-built version of the "
 "famous Douglas DC-3 which revolutionized air transport in the "
 "1930s and 1940s. The Russian variation was also produced in "
 "great quantities during the war, and later saw extensive use by "
 "Eastern-bloc countries until about the 1960s.             Today "
 "even though there are many DC-3's still in regular operation, "
 "only one of this variation exists in airworthy condition, the "
 "HA-LIX, formerly a MALEV plane operating on domestic flights. "
 "It was restored by the Hungarian Goldtimer Foundation between "
 "1997 and 2002, and they fly it ever since along with their "
 "other rare Hungarian aircraft.";



/*
** Sets background positions. x:y positions the main background, ovx:ovy the
** overlay segment.
*/
static void setbg(u8 x, u8 y, u8 ovx, u8 ovy)
{
	u8 j;

	rowsel[0] = y;
	rowsel[1] = ovy;
	rowsel[2] = 244U;
	rowsel[3] = ovy + 12U;
	rowsel[4] = 240U;
	rowsel[5] = ovy + 16U;
	rowsel[6] = ovy + 16U + y;
	rowsel[7] = 255U;

	for (j =  0U; j < 30U; j ++){
		m52_rowdesc[j].vram = &(imgrows[j][0]) + (x >> 3);
		m52_rowdesc[j].cfg0 = CFG0_PLANE | (x & 7U);
	}

	for (j = 30U; j < 32U; j ++){
		m52_rowdesc[j].vram = &(extrows[j - 30U][0]) + (ovx >> 3);
		m52_rowdesc[j].cfg0 = CFG0_EXT | (ovx & 7U);
	}
}



/*
** Outputs overlay scrolltext portion. X position 0 is off-screen to the
** right, it scrolls towards the left as X increments. To complete proper
** positioning, also call setbg() with the low 3 bits of X so it scrolls.
*/
static void ovr_gentext(u16 x)
{
	u8* vptr = &extrows[1][0];
	u8  i;
	u16 chx = x >> 3;
	u16 sln = sizeof(ovr_text) - 1U;

	chx -= 37U;

	for (i = 0U; i < 37U; i ++){
		if (chx < sln){
			*vptr = (u8)(pgm_read_byte(&ovr_text[chx]));
		}else{
			*vptr = (u8)(' ');
		}
		vptr ++;
		chx ++;
	}
}



/*
** Outputs sprite text. X position 0 is off-screen to the right, it scrolls
** towards the left as X increments. Compensates for Y by rowsel[0]. Frame is
** the wave animation's frame.
*/
static void sprite_gentext(u16 x, u16 frame)
{
	u16 i;
	u16 sln = sizeof(sprite_text) - 1U;
	u16 chx;
	u8  y;
	u8  chr;

	x  -= 8U * 36U;
	chx = 0U - x;

	if ((chx & 0x8000U) != 0U){
		i    = ((7U - chx) >> 3);
		chx &= 7U;
	}else{
		i    = 0U;
	}

	for (; i < sln; i ++){

		if (chx >= 312U){ break; } /* Gone off-screen */

		y   = 36U + (sintb((frame - i) & 0xFFU) >> 1) + rowsel[0];
		chr = pgm_read_byte(&sprite_text[i]);

		if (chr > (u8)(' ')){ /* Optimization: Don't draw spaces */
			M52_BlitSpriteRom(
			    &fontdata[(u16)(chr) * 16U],
			    chx,
			    y,
			    M52_SPR_I3 | M52_SPR_MASK);
		}

		chx += 8U;
	}
}



/*
** Animates plane propeller
*/
static void aniprop(u8 frame)
{
	u8* vptr;

	frame = frame << 4;

	vptr = &imgrows[PLANE_Y + 0U][PLANE_X];
	vptr[13] = 78U + frame;
	vptr = &imgrows[PLANE_Y + 1U][PLANE_X];
	vptr[ 6] = 66U + frame;
	vptr[ 7] = 67U + frame;
	vptr[ 8] = 68U + frame;
	vptr[12] = 79U + frame;
	vptr[13] = 80U + frame;
	vptr[14] = 81U + frame;
	vptr = &imgrows[PLANE_Y + 2U][PLANE_X];
	vptr[ 5] = 69U + frame;
	vptr[ 6] = 70U + frame;
	vptr[ 7] = 71U + frame;
	vptr[ 8] = 72U + frame;
	vptr = &imgrows[PLANE_Y + 3U][PLANE_X];
	vptr[ 5] = 73U + frame;
	vptr[ 6] = 74U + frame;
	vptr = &imgrows[PLANE_Y + 4U][PLANE_X];
	vptr[ 5] = 75U + frame;
	vptr[ 6] = 76U + frame;
	vptr[ 7] = 77U + frame;
}



/*
** Generates background image (plane) by filling the VRAM
*/
static void initbg(void)
{
	u8 y;
	u8 x;

	for (y = 0U; y < 30U; y ++){ /* Clear VRAM */
		for (x = 0U; x < 40U; x ++){
			m52_rowdesc[y].vram[x] = 101U; /* Blank tile in tilestop (loaded as tileset 0) */
		}
	}

	for (y = 0U; y < 9U; y ++){ /* Fill in plane graphics */
		if (y > 4U){ /* Has to use tilesbot (loaded as tileset 1), blank tile is 71 */
			m52_rowdesc[y + PLANE_Y].cfg1 |= M52_CFG1_ROMT_1;
			for (x = 0U; x < 40U; x ++){
				m52_rowdesc[y + PLANE_Y].vram[x] = 71U;
			}
		}
		for (x = 0U; x < 29U; x ++){
			m52_rowdesc[y + PLANE_Y].vram[x + PLANE_X] = pgm_read_byte(&planemap[((uint16_t)(y) * 29U) + x]);
		}
	}
}



/*
** Initializes overlay area (black bg. scrolltext)
*/
static void initovr(void)
{
	u8 x;

	for (x = 0U; x < 37U; x ++){
		extrows[0][x] = 127U; /* Top & Bottom border tile */
		extrows[1][x] = (u8)(' ');
	}
}



/*
** Initializes sky (color 0 replacements)
*/
static void initsky(void)
{
	u8 y;

	for (y = 0U; y < 200U; y ++){
		color0[y] = pgm_read_byte(&color0_data[y]);
	}
}



int main(){

	u16 frame = 0U;
	u16 xpos  = 0U;
	u16 ypos  = 0U;
	u8  xyvr  = 0U;
	u8  prop  = 0U;
	u8  ovxm;
	u8  vsync;

	/* Palette 0: The plane (color index 0 is not used, replaced by sky) */

	m52_palette[0] = 0x00U;
	m52_palette[1] = 0x52U;
	m52_palette[2] = 0xA4U;
	m52_palette[3] = 0xB6U;

	/* Palette 1: Black scrolltext */

	m52_palette[4] = 0x00U;
	m52_palette[5] = 0x5CU;
	m52_palette[6] = 0xF6U;
	m52_palette[7] = 0xF6U;

	/* Row selector controlling horizontal split regions */

	m52_rowsel_p = &rowsel[0];

	/* RAM tile split point: Above this, indices in VRAM are RAM tiles,
	** below, ROM tiles. Note that a RAM tile's absolute address is simply
	** tile_index * 16. */

	m52_ramt_base = 0xB0U;

	/* Color 0 replacement table. If enabled for the row, Color 0 for
	** every scanline will be taken from this table instead of the
	** palette's Color index 0. */

	m52_col0_p = &color0[0];

	/* Set up tilesets and their masks. Tilesets 0 and 1 are the plane
	** (which has masks so sprites can appear behind), Tileset 2 is used
	** for the black scrolltext. */

	M52_SetTileset(0U, tilestop, plane_top_msk);
	M52_SetTileset(1U, tilesbot, plane_bot_msk);
	M52_SetTileset(2U, fontdata, NULL);

	/* Load row descriptors into m52_rowdesc. This determines the
	** configuration of the available 32 tile rows (while the row selector
	** controls where each of them displays). */

	M52_LoadRowDesc(rows);

	/* Set up sprite workspace. This requires 3 bytes for each RAM tile
	** allocated to the sprite blitter. */

	m52_sprite_work_p = &sprite_ws[0];

	/* Set up RAM tile region used by the sprite blitter. It can be
	** anywhere within the RAM tiles. */

	m52_sprite_ramt_base = 0xB0U;
	m52_sprite_ramt_max = 80U;

	/* Set up mask pools, that is, the 8 byte mask images for the tiles,
	** which are used by the mask index tables set up with
	** M52_SetTileset(). RAM mask images may be useful if you have user
	** RAM tiles. */

	m52_mskpool_rom_p = tilesmsk;
	m52_mskpool_ram_p = NULL;

	/* Set up a mask index table for the RAM tiles. This is as many bytes
	** as many RAM tiles you are using (usually 256 - m52_ramt_base). It
	** is not mandatory, but masked sprites won't work properly without
	** this area. */

	m52_ramt_mski_p = &ramtmaskidx[0];

	/* Use a 200 lines tall screen. If you have many sprites, you need a
	** narrower screen to have time to draw all of them. */

	SetRenderingParameters(32U, 200U);

	/* Enable display, along with setting color replacements by physical
	** scanline. By default the color0 and color1 replacement tables are
	** indexed by logical scanline, that is, by the order of rows in the
	** row descriptor. */

	m52_config = M52_CFG_ENABLE | M52_CFG_COLREP_PHY;

	initsky();
	initbg();
	initovr();

	M52_ResReset();

	while(1){

		/* Logic determining placement of objects */

		frame ++;
		xyvr = (xyvr + 1U) & 0xFFU;
		xpos = xpos + 229U - (sintb(xyvr) >> 2);
		ypos = ypos + 241U - (costb(xyvr) >> 2);
		prop ++;
		if (prop >= 3U){ prop -= 3U; }

		/* Frame skipping if necessary (many sprites may require it
		** occasionally) */

		vsync = GetVsyncFlag(); /* Already passed next frame? */
		WaitVsync(1);
		if (vsync){ continue; } /* If so, then don't render */

		M52_VramRestore();

		ovr_gentext(frame & 0xFFFU); /* 512 chars * 8 pixels wrap */

		ovxm = (frame >> 7) & 7U;
		if      (ovxm == 0U){ ovxm =  36U; }
		else if (ovxm == 1U){ ovxm =  48U; }
		else if (ovxm == 2U){ ovxm =  40U; }
		else if (ovxm == 3U){ ovxm =  52U; }
		else if (ovxm == 4U){ ovxm = 160U; }
		else if (ovxm == 5U){ ovxm =  56U; }
		else if (ovxm == 6U){ ovxm =  32U; }
		else                { ovxm =  48U; }

		setbg(
		    (sintb((xpos >> 8) & 0xFFU) >> 3),
		    (costb((ypos >> 8) & 0xFFU) >> 4) + 12U, /* 200 lines tall, not 224 */
		    frame & 7U,
		    184U - (((u16)(costb(((frame << 1) + 128U) & 0xFFU)) * ovxm) >> 8) );

		aniprop(prop);

		sprite_gentext(frame & 0x1FFFU, frame); /* 1024 chars * 8 pixels wrap */

	}

}
